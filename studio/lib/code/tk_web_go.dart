import 'dart:io';

import 'package:path/path.dart' as p;

import '../i18n/tr.dart';
import 'tk_model.dart';
import 'tk_web_html.dart';

/// Web con servidor en Go: las pantallas (el motor de la web en HTML, con la
/// lógica en app.js) servidas por un servidor de Go (net/http, solo la
/// biblioteca estándar) que las lleva dentro del ejecutable y da una API REST
/// con los datos guardados en archivos JSON: `/api/<colección>[/<id>]`. La
/// lógica la usa con `api.list`, `api.get`, `api.add`, `api.update` y
/// `api.remove`.
class TkWebGo {
  TkWebGo._();

  /// El cliente de la API (va al final de dms.js).
  static const apiJs = r'''

/// La API del servidor de Go: colecciones de registros con id y created_at
/// guardadas en el servidor.
const api = {
  async _call(method, path, body) {
    const r = await fetch("/api/" + path, {
      method,
      headers: body === undefined ? {} : { "content-type": "application/json" },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const data = r.status === 204 ? null : await r.json();
    if (!r.ok) throw new Error((data && data.error) || r.statusText);
    return data;
  },
  /// Todos los registros (con filtros opcionales: { campo: valor }).
  list(col, where) {
    const q = where ? "?" + new URLSearchParams(where) : "";
    return this._call("GET", col + q);
  },
  get(col, id) {
    return this._call("GET", col + "/" + id);
  },
  /// Añade un registro y lo devuelve con su id.
  add(col, row) {
    return this._call("POST", col, row);
  },
  update(col, id, changes) {
    return this._call("PATCH", col + "/" + id, changes);
  },
  remove(col, id) {
    return this._call("DELETE", col + "/" + id);
  },
};
''';

  /// main.go: el servidor.
  static const mainGo =
      r'''// Generado por DMarlon Studio: el servidor de la web (solo la biblioteca
// estándar de Go). Sirve la carpeta web (dentro del ejecutable) y la API
// REST /api/<colección>[/<id>] con los datos en archivos JSON.
//
//	go run .                 # http://127.0.0.1:8080
//	PORT=3000 go run .       # otro puerto
//	DMS_DATA=/ruta go run .  # dónde se guardan los datos (por omisión, data)
//	go build                 # un solo ejecutable con la web dentro
package main

import (
	"embed"
	"encoding/json"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

//go:embed web
var embedded embed.FS

// Row es un registro: id, created_at y lo que mande la web.
type Row = map[string]any

// Store guarda cada colección en <dir>/<colección>.json.
type Store struct {
	mu  sync.Mutex
	dir string
}

var validName = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_]*$`)

func (s *Store) file(col string) string { return filepath.Join(s.dir, col+".json") }

func (s *Store) load(col string) ([]Row, error) {
	b, err := os.ReadFile(s.file(col))
	if os.IsNotExist(err) {
		return []Row{}, nil
	}
	if err != nil {
		return nil, err
	}
	rows := []Row{}
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (s *Store) save(col string, rows []Row) error {
	if err := os.MkdirAll(s.dir, 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(rows, "", "  ")
	if err != nil {
		return err
	}
	tmp := s.file(col) + ".tmp"
	if err := os.WriteFile(tmp, b, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, s.file(col))
}

func idOf(r Row) int64 {
	switch v := r["id"].(type) {
	case float64:
		return int64(v)
	case int64:
		return v
	}
	return 0
}

func reply(w http.ResponseWriter, status int, v any) {
	w.Header().Set("content-type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func fail(w http.ResponseWriter, status int, msg string) {
	reply(w, status, map[string]string{"error": msg})
}

// api atiende /api/<colección> y /api/<colección>/<id>.
func (s *Store) api(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/"), "/"), "/")
	col := parts[0]
	if !validName.MatchString(col) || len(parts) > 2 {
		fail(w, http.StatusNotFound, "colección no válida")
		return
	}
	var id int64
	if len(parts) == 2 {
		n, err := strconv.ParseInt(parts[1], 10, 64)
		if err != nil {
			fail(w, http.StatusNotFound, "id no válido")
			return
		}
		id = n
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	rows, err := s.load(col)
	if err != nil {
		fail(w, http.StatusInternalServerError, err.Error())
		return
	}
	find := func() int {
		for i, row := range rows {
			if idOf(row) == id {
				return i
			}
		}
		return -1
	}
	switch {
	case r.Method == http.MethodGet && id == 0:
		out := []Row{}
		for _, row := range rows {
			ok := true
			for k, v := range r.URL.Query() {
				if fmt.Sprint(row[k]) != v[0] {
					ok = false
				}
			}
			if ok {
				out = append(out, row)
			}
		}
		reply(w, http.StatusOK, out)
	case r.Method == http.MethodGet:
		if i := find(); i >= 0 {
			reply(w, http.StatusOK, rows[i])
		} else {
			fail(w, http.StatusNotFound, "no existe")
		}
	case r.Method == http.MethodPost && id == 0:
		row := Row{}
		if err := json.NewDecoder(r.Body).Decode(&row); err != nil {
			fail(w, http.StatusBadRequest, err.Error())
			return
		}
		var next int64 = 1
		for _, old := range rows {
			if idOf(old) >= next {
				next = idOf(old) + 1
			}
		}
		row["id"] = next
		row["created_at"] = time.Now().UTC().Format(time.RFC3339)
		rows = append(rows, row)
		if err := s.save(col, rows); err != nil {
			fail(w, http.StatusInternalServerError, err.Error())
			return
		}
		reply(w, http.StatusCreated, row)
	case r.Method == http.MethodPatch && id != 0:
		i := find()
		if i < 0 {
			fail(w, http.StatusNotFound, "no existe")
			return
		}
		changes := Row{}
		if err := json.NewDecoder(r.Body).Decode(&changes); err != nil {
			fail(w, http.StatusBadRequest, err.Error())
			return
		}
		for k, v := range changes {
			if k != "id" && k != "created_at" {
				rows[i][k] = v
			}
		}
		if err := s.save(col, rows); err != nil {
			fail(w, http.StatusInternalServerError, err.Error())
			return
		}
		reply(w, http.StatusOK, rows[i])
	case r.Method == http.MethodDelete && id != 0:
		i := find()
		if i < 0 {
			fail(w, http.StatusNotFound, "no existe")
			return
		}
		rows = append(rows[:i], rows[i+1:]...)
		if err := s.save(col, rows); err != nil {
			fail(w, http.StatusInternalServerError, err.Error())
			return
		}
		w.WriteHeader(http.StatusNoContent)
	default:
		fail(w, http.StatusMethodNotAllowed, "método no permitido")
	}
}

// Con DMS_DEV=1 (el estudio) la web se lee del disco y se recarga sola al
// cambiar los archivos.
const reload = `<script>(() => { let v = null; setInterval(async () => { try { const n = await (await fetch("/__dms_version")).text(); if (v !== null && n !== v) location.reload(); v = n; } catch (_) {} }, 700); })();</script>`

func version(dir string) string {
	var last time.Time
	_ = filepath.Walk(dir, func(_ string, info os.FileInfo, err error) error {
		if err == nil && info.ModTime().After(last) {
			last = info.ModTime()
		}
		return nil
	})
	return fmt.Sprint(last.UnixNano())
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	data := os.Getenv("DMS_DATA")
	if data == "" {
		data = "data"
	}
	dev := os.Getenv("DMS_DEV") == "1"
	var site fs.FS
	if dev {
		site = os.DirFS("web")
	} else {
		sub, err := fs.Sub(embedded, "web")
		if err != nil {
			log.Fatal(err)
		}
		site = sub
	}
	store := &Store{dir: data}
	mux := http.NewServeMux()
	mux.HandleFunc("/api/", store.api)
	files := http.FileServer(http.FS(site))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if dev {
			w.Header().Set("cache-control", "no-store")
			if r.URL.Path == "/__dms_version" {
				fmt.Fprint(w, version("web"))
				return
			}
			if r.URL.Path == "/" || r.URL.Path == "/index.html" {
				b, err := fs.ReadFile(site, "index.html")
				if err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
				w.Header().Set("content-type", "text/html; charset=utf-8")
				fmt.Fprint(w, strings.Replace(string(b), "</body>", reload+"\n</body>", 1))
				return
			}
		}
		files.ServeHTTP(w, r)
	})
	addr := "127.0.0.1:" + port
	if os.Getenv("HOST") != "" {
		addr = os.Getenv("HOST") + ":" + port
	}
	fmt.Printf("Escuchando en http://%s/ (datos en %s)\n", addr, data)
	log.Fatal(http.ListenAndServe(addr, mux))
}
''';

  /// Todos los archivos: go.mod, main.go y la web en web/.
  static Map<String, String> files(
    TkDesign d,
    String code, {
    required String name,
  }) {
    final web = TkWebHtml.files(d, code, name: name, api: apiJs);
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .replaceAll(RegExp(r'^[0-9]+'), '');
    return {
      'go.mod': 'module ${slug.isEmpty ? 'dmsweb' : slug}\n\ngo 1.19\n',
      'main.go': mainGo,
      for (final e in web.entries)
        if (e.key != 'README.md') 'web/${e.key}': e.value,
      'README.md':
          '# $name\n\n'
          '${tr('Web con servidor en Go creada con DMarlon Studio: la web está en web/ y la API REST guarda los datos en data/.')}\n\n'
          '```\ngo run .        # http://127.0.0.1:8080\ngo build         # un solo ejecutable con la web dentro\n```\n\n'
          '${tr('En macOS, con Go anterior a 1.22: go build -ldflags=-linkmode=external')}\n',
    };
  }

  /// Los argumentos de `go build`. En macOS, Go anterior a 1.22 no pone el
  /// LC_UUID que exige el macOS actual: se enlaza con el enlazador del
  /// sistema.
  static Future<List<String>> buildArgs(String go, String exe) async {
    final extra = <String>[];
    if (Platform.isMacOS) {
      final v = await Process.run(go, ['env', 'GOVERSION']);
      final m = RegExp(r'go1\.(\d+)').firstMatch('${v.stdout}');
      if (m != null && int.parse(m[1]!) < 22) {
        extra.add('-ldflags=-linkmode=external');
      }
    }
    return ['build', ...extra, '-o', exe, '.'];
  }

  /// La orden `go` (null: no está instalado).
  static String? goBinary() {
    final path = Platform.environment['PATH'] ?? '';
    for (final dir in [
      ...path.split(Platform.isWindows ? ';' : ':'),
      '/usr/local/go/bin',
      '/opt/homebrew/bin',
      '/usr/local/bin',
      if (Platform.environment['HOME'] != null)
        p.join(Platform.environment['HOME']!, 'go', 'bin'),
      r'C:\Program Files\Go\bin',
    ]) {
      if (dir.isEmpty) continue;
      final f = File(p.join(dir, Platform.isWindows ? 'go.exe' : 'go'));
      if (f.existsSync()) return f.path;
    }
    return null;
  }
}
