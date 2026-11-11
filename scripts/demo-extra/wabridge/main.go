// wabridge: el puente de MyWhatsapp con WhatsApp como «dispositivo vinculado»
// (se enlaza leyendo un código QR con el teléfono, igual que WhatsApp Web).
//
// Habla con la app por stdin/stdout, una línea JSON por mensaje:
//
//	app → puente: {"cmd":"send","id":"r1","to":"346…@s.whatsapp.net","text":"Hola"}
//	              {"cmd":"send_file","id":"r2","to":"…","path":"/ruta/foto.jpg","caption":"…"}
//	              {"cmd":"logout"}
//	puente → app: {"ev":"qr","png":"/…/qr.png"}  {"ev":"ready","me":"…"}
//	              {"ev":"msg",…}  {"ev":"chat","jid":"…","name":"…"}
//	              {"ev":"sent","id":"r1","ok":true}  {"ev":"logged_out"}  {"ev":"error","text":"…"}
//	              {"ev":"locked"} (otro puente ya usa esta cuenta)
//
// Los mensajes también se guardan en <dir>/mensajes.jsonl (solo los lee el
// usuario) para que la app los tenga al abrirse otra vez.
//
// No es la API oficial: WhatsApp no lo permite en sus condiciones y puede
// bloquear la cuenta. La app lo avisa antes de activarlo.
package main

import (
	"bufio"
	"context"
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	qrcode "github.com/skip2/go-qrcode"
	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/proto/waE2E"
	"go.mau.fi/whatsmeow/store/sqlstore"
	"go.mau.fi/whatsmeow/types"
	"go.mau.fi/whatsmeow/types/events"
	waLog "go.mau.fi/whatsmeow/util/log"
	"google.golang.org/protobuf/proto"
	_ "modernc.org/sqlite"
)

// Los tipos de mensaje, los mismos números que usa WhatsApp Desktop.
const (
	kText    = 0
	kImage   = 1
	kVideo   = 2
	kAudio   = 3
	kDoc     = 8
	kSticker = 15
)

// Msg es un mensaje tal como lo recibe la app.
type Msg struct {
	Ev    string `json:"ev"`
	ID    string `json:"id"`
	Chat  string `json:"chat"`
	Who   string `json:"who,omitempty"`  // en los grupos, quién lo escribió
	Name  string `json:"name,omitempty"` // el nombre del contacto (en los privados)
	Mine  bool   `json:"mine"`
	Text  string `json:"text,omitempty"`
	T     int64  `json:"t"`
	Kind  int    `json:"kind"`
	Media string `json:"media,omitempty"` // el archivo en este equipo
	Title string `json:"title,omitempty"`
	Size  int64  `json:"size,omitempty"`
	Group bool   `json:"group,omitempty"`
	// Los míos: 5 enviado, 6 entregado, 8 leído (los mismos números que WhatsApp Desktop).
	Status int `json:"status,omitempty"`
}

type bridge struct {
	dir   string
	cli   *whatsmeow.Client
	outMu sync.Mutex
	store *os.File
}

func (b *bridge) emit(v any) {
	data, err := json.Marshal(v)
	if err != nil {
		return
	}
	b.outMu.Lock()
	defer b.outMu.Unlock()
	os.Stdout.Write(append(data, '\n'))
	// Lo que hay que recordar: los mensajes y los nombres de los chats.
	if b.store != nil {
		switch m := v.(type) {
		case Msg:
			b.store.Write(append(data, '\n'))
		case map[string]any:
			if m["ev"] == "chat" || m["ev"] == "receipt" || m["ev"] == "label" || m["ev"] == "label_chat" {
				b.store.Write(append(data, '\n'))
			}
		}
	}
}

func (b *bridge) fail(format string, a ...any) {
	b.emit(map[string]any{"ev": "error", "text": fmt.Sprintf(format, a...)})
}

// El chat con el número de teléfono (no el identificador oculto «@lid»).
func (b *bridge) phoneJID(ctx context.Context, jid, alt types.JID) types.JID {
	if jid.Server != types.HiddenUserServer {
		return jid.ToNonAD()
	}
	if !alt.IsEmpty() && alt.Server == types.DefaultUserServer {
		return alt.ToNonAD()
	}
	if b.cli != nil {
		if pn, err := b.cli.Store.LIDs.GetPNForLID(ctx, jid.ToNonAD()); err == nil && !pn.IsEmpty() {
			return pn.ToNonAD()
		}
	}
	return jid.ToNonAD()
}

// convert pasa un mensaje de WhatsApp a lo que entiende la app. [download]
// descarga los adjuntos (los del historial no: serían demasiados).
func (b *bridge) convert(ctx context.Context, ev *events.Message, download bool) (Msg, bool) {
	info := ev.Info
	m := ev.Message
	if m == nil || info.Chat.Server == types.BroadcastServer || info.Chat.Server == types.NewsletterServer {
		return Msg{}, false
	}
	alt := info.SenderAlt
	if info.IsFromMe {
		alt = info.RecipientAlt
	}
	chat := info.Chat
	if !info.IsGroup {
		chat = b.phoneJID(ctx, info.Chat, alt)
	}
	out := Msg{Ev: "msg", ID: info.ID, Chat: chat.String(), Mine: info.IsFromMe, T: info.Timestamp.Unix(), Group: info.IsGroup}
	if info.IsGroup && !info.IsFromMe {
		out.Who = info.PushName
	} else if !info.IsFromMe {
		out.Name = info.PushName
	}
	var media whatsmeow.DownloadableMessage
	ext := ""
	switch {
	case m.GetConversation() != "":
		out.Text = m.GetConversation()
	case m.GetExtendedTextMessage() != nil:
		out.Text = m.GetExtendedTextMessage().GetText()
	case m.GetImageMessage() != nil:
		im := m.GetImageMessage()
		out.Kind, out.Text, out.Size, media, ext = kImage, im.GetCaption(), int64(im.GetFileLength()), im, ".jpg"
	case m.GetVideoMessage() != nil:
		vm := m.GetVideoMessage()
		out.Kind, out.Text, out.Size, media, ext = kVideo, vm.GetCaption(), int64(vm.GetFileLength()), vm, ".mp4"
	case m.GetAudioMessage() != nil:
		am := m.GetAudioMessage()
		out.Kind, out.Size, media, ext = kAudio, int64(am.GetFileLength()), am, ".ogg"
	case m.GetDocumentMessage() != nil:
		dm := m.GetDocumentMessage()
		out.Kind, out.Text, out.Title, out.Size, media = kDoc, dm.GetCaption(), dm.GetFileName(), int64(dm.GetFileLength()), dm
		if out.Title == "" {
			out.Title = dm.GetTitle()
		}
		ext = filepath.Ext(out.Title)
	case m.GetStickerMessage() != nil:
		sm := m.GetStickerMessage()
		out.Kind, out.Size, media, ext = kSticker, int64(sm.GetFileLength()), sm, ".webp"
	default:
		return Msg{}, false // reacciones, encuestas, avisos del sistema…
	}
	if media != nil && download && b.cli != nil {
		path := filepath.Join(b.dir, "media", safeName(info.ID)+ext)
		if data, err := b.cli.Download(ctx, media); err == nil {
			os.MkdirAll(filepath.Dir(path), 0o700)
			if os.WriteFile(path, data, 0o600) == nil {
				out.Media = path
			}
		}
	}
	return out, true
}

func safeName(s string) string {
	var sb strings.Builder
	for _, r := range s {
		if r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' || r >= '0' && r <= '9' || r == '-' || r == '_' {
			sb.WriteRune(r)
		}
	}
	if sb.Len() == 0 {
		return "x"
	}
	return sb.String()
}

func (b *bridge) onEvent(evt any) {
	ctx := context.Background()
	switch e := evt.(type) {
	case *events.Message:
		if m, ok := b.convert(ctx, e, true); ok {
			b.emit(m)
		}
	case *events.HistorySync:
		// El historial que manda el teléfono al vincularse: los últimos de cada chat.
		for _, conv := range e.Data.GetConversations() {
			jid, err := types.ParseJID(conv.GetID())
			if err != nil {
				continue
			}
			if name := conv.GetName(); name != "" {
				b.emit(map[string]any{"ev": "chat", "jid": b.phoneJID(ctx, jid, types.EmptyJID).String(), "name": name})
			} else if name := conv.GetDisplayName(); name != "" {
				b.emit(map[string]any{"ev": "chat", "jid": b.phoneJID(ctx, jid, types.EmptyJID).String(), "name": name})
			}
			msgs := conv.GetMessages()
			if len(msgs) > 80 {
				msgs = msgs[:80] // vienen del más nuevo al más antiguo
			}
			for i := len(msgs) - 1; i >= 0; i-- {
				web := msgs[i].GetMessage()
				if web == nil {
					continue
				}
				pm, err := b.cli.ParseWebMessage(jid, web)
				if err != nil {
					continue
				}
				if m, ok := b.convert(ctx, pm, false); ok {
					b.emit(m)
				}
			}
		}
	case *events.Receipt:
		// Los acuses de mis mensajes: entregado o leído (y escuchado, en las notas de voz).
		if e.IsFromMe || len(e.MessageIDs) == 0 {
			return
		}
		status := 0
		switch e.Type {
		case types.ReceiptTypeDelivered:
			status = 6
		case types.ReceiptTypeRead, types.ReceiptTypePlayed:
			status = 8
		}
		if status > 0 {
			b.emit(map[string]any{"ev": "receipt", "ids": e.MessageIDs, "status": status})
		}
	case *events.LabelEdit:
		// Las etiquetas de WhatsApp (las de la cuenta): su nombre, su color o que se borró.
		if e.Action == nil {
			return
		}
		b.emit(map[string]any{"ev": "label", "id": e.LabelID, "name": e.Action.GetName(), "color": e.Action.GetColor(),
			"deleted": e.Action.GetDeleted()})
	case *events.LabelAssociationChat:
		// Una etiqueta puesta o quitada en un chat.
		if e.Action == nil {
			return
		}
		chat := e.JID
		if chat.Server != types.GroupServer {
			chat = b.phoneJID(context.Background(), e.JID, types.EmptyJID)
		}
		b.emit(map[string]any{"ev": "label_chat", "label": e.LabelID, "chat": chat.String(), "on": e.Action.GetLabeled()})
	case *events.Connected:
		me := ""
		if b.cli.Store.ID != nil {
			me = b.cli.Store.ID.ToNonAD().String()
		}
		b.emit(map[string]any{"ev": "ready", "me": me})
	case *events.LoggedOut:
		b.emit(map[string]any{"ev": "logged_out"})
	case *events.Disconnected:
		b.emit(map[string]any{"ev": "disconnected"})
	}
}

// El tipo de un archivo para mandarlo: foto, vídeo, audio o documento.
func mediaKind(path string, head []byte) (int, string) {
	mime := http.DetectContentType(head)
	switch strings.ToLower(filepath.Ext(path)) {
	case ".jpg", ".jpeg":
		mime = "image/jpeg"
	case ".png":
		mime = "image/png"
	case ".mp4":
		mime = "video/mp4"
	case ".mp3":
		mime = "audio/mpeg"
	case ".ogg", ".opus":
		mime = "audio/ogg; codecs=opus"
	case ".m4a":
		mime = "audio/mp4"
	case ".pdf":
		mime = "application/pdf"
	}
	switch {
	case mime == "image/jpeg" || mime == "image/png":
		return kImage, mime
	case strings.HasPrefix(mime, "video/mp4"):
		return kVideo, mime
	case strings.HasPrefix(mime, "audio/"):
		return kAudio, mime
	}
	if strings.HasPrefix(mime, "text/plain") {
		mime = "text/plain"
	}
	return kDoc, mime
}

// fileMessage arma el mensaje de un adjunto ya subido.
func fileMessage(kind int, mime, name, caption string, up whatsmeow.UploadResponse) *waE2E.Message {
	switch kind {
	case kImage:
		return &waE2E.Message{ImageMessage: &waE2E.ImageMessage{
			Caption: proto.String(caption), Mimetype: proto.String(mime), URL: proto.String(up.URL),
			DirectPath: proto.String(up.DirectPath), MediaKey: up.MediaKey, FileEncSHA256: up.FileEncSHA256,
			FileSHA256: up.FileSHA256, FileLength: proto.Uint64(up.FileLength)}}
	case kVideo:
		return &waE2E.Message{VideoMessage: &waE2E.VideoMessage{
			Caption: proto.String(caption), Mimetype: proto.String(mime), URL: proto.String(up.URL),
			DirectPath: proto.String(up.DirectPath), MediaKey: up.MediaKey, FileEncSHA256: up.FileEncSHA256,
			FileSHA256: up.FileSHA256, FileLength: proto.Uint64(up.FileLength)}}
	case kAudio:
		return &waE2E.Message{AudioMessage: &waE2E.AudioMessage{
			Mimetype: proto.String(mime), URL: proto.String(up.URL),
			DirectPath: proto.String(up.DirectPath), MediaKey: up.MediaKey, FileEncSHA256: up.FileEncSHA256,
			FileSHA256: up.FileSHA256, FileLength: proto.Uint64(up.FileLength)}}
	}
	return &waE2E.Message{DocumentMessage: &waE2E.DocumentMessage{
		Caption: proto.String(caption), FileName: proto.String(name), Title: proto.String(name), Mimetype: proto.String(mime),
		URL: proto.String(up.URL), DirectPath: proto.String(up.DirectPath), MediaKey: up.MediaKey,
		FileEncSHA256: up.FileEncSHA256, FileSHA256: up.FileSHA256, FileLength: proto.Uint64(up.FileLength)}}
}

var uploadType = map[int]whatsmeow.MediaType{
	kImage: whatsmeow.MediaImage, kVideo: whatsmeow.MediaVideo, kAudio: whatsmeow.MediaAudio, kDoc: whatsmeow.MediaDocument,
}

type command struct {
	Cmd     string `json:"cmd"`
	ID      string `json:"id"`
	To      string `json:"to"`
	Text    string `json:"text"`
	Path    string `json:"path"`
	Caption string `json:"caption"`
	// Para los estados de texto: el color de fondo (ARGB).
	Background uint32 `json:"background"`
}

func (b *bridge) handle(c command) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	sent := func(err error) {
		if err != nil {
			b.emit(map[string]any{"ev": "sent", "id": c.ID, "ok": false, "error": err.Error()})
		} else {
			b.emit(map[string]any{"ev": "sent", "id": c.ID, "ok": true})
		}
	}
	switch c.Cmd {
	case "send", "send_file":
		if !b.cli.IsLoggedIn() {
			sent(fmt.Errorf("not linked"))
			return
		}
		to, err := types.ParseJID(c.To)
		if err != nil {
			sent(err)
			return
		}
		var msg *waE2E.Message
		out := Msg{Ev: "msg", Chat: to.String(), Mine: true, Group: to.Server == types.GroupServer}
		if c.Cmd == "send" {
			msg = &waE2E.Message{Conversation: proto.String(c.Text)}
			out.Text = c.Text
		} else {
			data, err := os.ReadFile(c.Path)
			if err != nil {
				sent(err)
				return
			}
			head := data
			if len(head) > 512 {
				head = head[:512]
			}
			kind, mime := mediaKind(c.Path, head)
			up, err := b.cli.Upload(ctx, data, uploadType[kind])
			if err != nil {
				sent(err)
				return
			}
			msg = fileMessage(kind, mime, filepath.Base(c.Path), c.Caption, up)
			out.Kind, out.Media, out.Title, out.Size, out.Text = kind, c.Path, filepath.Base(c.Path), int64(len(data)), c.Caption
		}
		resp, err := b.cli.SendMessage(ctx, to, msg)
		if err == nil {
			out.ID, out.T, out.Status = resp.ID, resp.Timestamp.Unix(), 5
			b.emit(out)
		}
		sent(err)
	case "status":
		// Un estado: una imagen (con su pie) o un texto sobre un color.
		if !b.cli.IsLoggedIn() {
			sent(fmt.Errorf("not linked"))
			return
		}
		var msg *waE2E.Message
		if c.Path != "" {
			data, err := os.ReadFile(c.Path)
			if err != nil {
				sent(err)
				return
			}
			up, err := b.cli.Upload(ctx, data, whatsmeow.MediaImage)
			if err != nil {
				sent(err)
				return
			}
			mime := http.DetectContentType(data)
			msg = fileMessage(kImage, mime, filepath.Base(c.Path), c.Caption, up)
		} else {
			bg := uint32(0xFF25D366)
			if c.Background != 0 {
				bg = c.Background
			}
			msg = &waE2E.Message{ExtendedTextMessage: &waE2E.ExtendedTextMessage{
				Text: proto.String(c.Text), BackgroundArgb: proto.Uint32(bg), TextArgb: proto.Uint32(0xFFFFFFFF),
				Font: waE2E.ExtendedTextMessage_SYSTEM.Enum()}}
		}
		_, err := b.cli.SendMessage(ctx, types.StatusBroadcastJID, msg)
		sent(err)
	case "logout":
		if err := b.cli.Logout(ctx); err != nil {
			b.fail("%v", err)
		}
		os.Remove(filepath.Join(b.dir, "mensajes.jsonl"))
		b.emit(map[string]any{"ev": "logged_out"})
	}
}

func main() {
	dir := flag.String("dir", ".", "la carpeta de ajustes de MyWhatsapp")
	selftest := flag.Bool("selftest", false, "comprueba la conversión de mensajes sin conectarse")
	flag.Parse()
	if *selftest {
		os.Exit(runSelftest())
	}
	os.MkdirAll(*dir, 0o700)
	b := &bridge{dir: *dir}
	// Un solo puente por cuenta: si otro aún se está cerrando, se le espera un poco.
	var unlock func()
	for try := 0; ; try++ {
		ok, u := lockSession(filepath.Join(*dir, "wabridge.lock"))
		if ok {
			unlock = u
			break
		}
		if try >= 30 {
			b.emit(map[string]any{"ev": "locked"})
			os.Exit(3)
		}
		time.Sleep(500 * time.Millisecond)
	}
	defer unlock()
	if f, err := os.OpenFile(filepath.Join(*dir, "mensajes.jsonl"), os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600); err == nil {
		b.store = f
		defer f.Close()
	}
	ctx := context.Background()
	db, err := sql.Open("sqlite", "file:"+filepath.Join(*dir, "wabridge.db")+"?_pragma=foreign_keys(1)&_pragma=busy_timeout(5000)")
	if err != nil {
		b.fail("%v", err)
		os.Exit(1)
	}
	container := sqlstore.NewWithDB(db, "sqlite3", waLog.Noop)
	if err := container.Upgrade(ctx); err != nil {
		b.fail("%v", err)
		os.Exit(1)
	}
	// La sesión (las claves de la cuenta): solo la lee el usuario.
	for _, f := range []string{"wabridge.db", "wabridge.db-wal", "wabridge.db-shm"} {
		os.Chmod(filepath.Join(*dir, f), 0o600)
	}
	device, err := container.GetFirstDevice(ctx)
	if err != nil {
		b.fail("%v", err)
		os.Exit(1)
	}
	b.cli = whatsmeow.NewClient(device, waLog.Noop)
	b.cli.AddEventHandler(b.onEvent)
	if b.cli.Store.ID == nil {
		// Sin vincular: un código QR tras otro hasta que el teléfono lo lea.
		qr, _ := b.cli.GetQRChannel(ctx)
		if err := b.cli.Connect(); err != nil {
			b.fail("%v", err)
			os.Exit(1)
		}
		go func() {
			for item := range qr {
				if item.Event == "code" {
					path := filepath.Join(*dir, "qr.png")
					if err := qrcode.WriteFile(item.Code, qrcode.Medium, 512, path); err == nil {
						os.Chmod(path, 0o600)
						b.emit(map[string]any{"ev": "qr", "png": path})
					}
				} else {
					b.emit(map[string]any{"ev": "pair", "status": item.Event})
				}
			}
		}()
	} else if err := b.cli.Connect(); err != nil {
		b.fail("%v", err)
		os.Exit(1)
	}
	// Al terminar: desconectarse, pero sin quedarse colgado más de 3 segundos.
	var once sync.Once
	quit := func() {
		once.Do(func() {
			done := make(chan struct{})
			go func() {
				b.cli.Disconnect()
				close(done)
			}()
			select {
			case <-done:
			case <-time.After(3 * time.Second):
			}
			unlock()
			os.Exit(0)
		})
	}
	watchParent(quit)
	// Las órdenes de la app; si la app se cierra (stdin acaba), el puente también.
	in := bufio.NewScanner(os.Stdin)
	in.Buffer(make([]byte, 1<<20), 1<<24)
	for in.Scan() {
		var c command
		if json.Unmarshal(in.Bytes(), &c) == nil {
			go b.handle(c)
		}
	}
	quit()
}

func runSelftest() int {
	b := &bridge{dir: os.TempDir()}
	ctx := context.Background()
	chat, _ := types.ParseJID("34600111222@s.whatsapp.net")
	group, _ := types.ParseJID("120363000000000000@g.us")
	fails := 0
	check := func(ok bool, what string) {
		if !ok {
			fmt.Println("FAIL", what)
			fails++
		}
	}
	ts := time.Unix(1794365000, 0)
	ev := &events.Message{Info: types.MessageInfo{MessageSource: types.MessageSource{Chat: chat, Sender: chat},
		ID: "A1", PushName: "Laura", Timestamp: ts}, Message: &waE2E.Message{Conversation: proto.String("Hola")}}
	m, ok := b.convert(ctx, ev, false)
	check(ok && m.Text == "Hola" && m.Chat == "34600111222@s.whatsapp.net" && m.Name == "Laura" && m.T == 1794365000 && !m.Mine, "texto")
	ev = &events.Message{Info: types.MessageInfo{MessageSource: types.MessageSource{Chat: group, Sender: chat, IsGroup: true},
		ID: "A2", PushName: "Ana", Timestamp: ts}, Message: &waE2E.Message{DocumentMessage: &waE2E.DocumentMessage{
		FileName: proto.String("factura.pdf"), FileLength: proto.Uint64(1234)}}}
	m, ok = b.convert(ctx, ev, false)
	check(ok && m.Kind == kDoc && m.Title == "factura.pdf" && m.Size == 1234 && m.Who == "Ana" && m.Group, "documento en un grupo")
	ev.Message = &waE2E.Message{ReactionMessage: &waE2E.ReactionMessage{Text: proto.String("👍")}}
	_, ok = b.convert(ctx, ev, false)
	check(!ok, "las reacciones no son mensajes")
	k, mime := mediaKind("foto.jpg", []byte{0xff, 0xd8, 0xff})
	check(k == kImage && mime == "image/jpeg", "tipo de una foto")
	k, _ = mediaKind("informe.pdf", []byte("%PDF-1.7"))
	check(k == kDoc, "tipo de un documento")
	msg := fileMessage(kDoc, "application/pdf", "informe.pdf", "", whatsmeow.UploadResponse{URL: "u", FileLength: 9})
	check(msg.GetDocumentMessage().GetFileName() == "informe.pdf" && msg.GetDocumentMessage().GetFileLength() == 9, "mensaje de un documento")
	check(safeName("3EB0/../x") == "3EB0x", "nombre de archivo seguro")
	lockPath := filepath.Join(os.TempDir(), fmt.Sprintf("wabridge-selftest-%d.lock", os.Getpid()))
	ok1, u1 := lockSession(lockPath)
	ok2, _ := lockSession(lockPath)
	u1()
	ok3, u3 := lockSession(lockPath)
	u3()
	os.Remove(lockPath)
	check(ok1 && !ok2 && ok3, "un solo puente por cuenta")
	if fails == 0 {
		fmt.Println("selftest ok")
		return 0
	}
	return 1
}
