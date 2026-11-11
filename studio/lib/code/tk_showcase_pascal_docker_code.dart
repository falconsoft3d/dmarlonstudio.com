part of 'tk_examples.dart';

// El código en Pascal de «Docker en la barra de menús» (tk_showcase_pascal_docker.dart):
// la unidad Form1.pas entera; el estudio pone los textos en «// @TEXTS».
const _dockerBarCode = r'''
// @TITLE
unit Form1;

{$mode objfpc}{$H+}
{$IFDEF DARWIN}{$modeswitch objectivec1}{$ENDIF}

interface

uses
  {$IFDEF DARWIN}CocoaAll, CocoaGDIObjects,{$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Menus, dms, design, Math, Process, LCLIntf, LCLType,
  Clipbrd, IntfGraphics, GraphType, FPImage, LazUTF8;

type
  { Lo que se dibuja en el panel y se puede pulsar. }
  THit = record
    R: TRect;
    Act: string;
  end;
  THits = array of THit;

  { Una orden de docker en segundo plano: la lista o una acción. }
  TDockJob = class(TThread)
  public
    Exe: string;
    Args, Ids: TStringArray;
    IsList, WantVersion: Boolean;
    Output, Version: string;
    Code: Integer;
    procedure Execute; override;
  end;

  TForm1 = class(TFormDesign)
  private
    Tray: TTrayIcon;
    TrayMenu: TPopupMenu;
    Box: TPaintBox;
    FListing, FAgain, FQuitting: Boolean;
    FSig, FPending: string;
    FIconState, FHover, FScroll, FContentH: Integer;
    FHits: THits;
    procedure StartUp(Data: PtrInt);
    procedure DoPending(Data: PtrInt);
    procedure ToAccessory(Data: PtrInt);
    procedure TrayItem(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure LangItem(Sender: TObject);
    procedure JobDone(Sender: TObject);
    procedure PanelClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure BoxPaint(Sender: TObject);
    procedure BoxDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BoxMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BoxWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    function HitAt(X, Y: Integer): Integer;
    function LangMenu: TMenuItem;
    procedure Reload;
    procedure Run(const AArgs, AIds: array of string; const BusyText: string);
    procedure Rebuild;
    procedure SetIcon;
    procedure ShowPanel;
    procedure Quit;
    procedure Act(const H: string);
  public
    procedure form_create; override;
    procedure Tick_timer; override;
    procedure Menu1_click(const Item: string); override;
  end;

implementation

// Los textos (los traduce el estudio con el resto del ejemplo).
const
  // @TEXTS
  // ---- fin de los textos

// ================================================================ los datos
type
  { Un contenedor, como lo cuenta «docker ps». }
  TBox = record
    Id, Name, Image, State, Status, Ports, Project: string;
    Urls: TStringArray;
  end;
  TBoxArray = array of TBox;
  TDockState = (dsUnknown, dsMissing, dsDown, dsOk);

const
  // Una línea por contenedor, con los campos separados por tabuladores.
  ListFormat = '{{.ID}}'#9'{{.Names}}'#9'{{.Image}}'#9'{{.State}}'#9 +
    '{{.Status}}'#9'{{.Ports}}'#9'{{.Label "com.docker.compose.project"}}';
  DockerSite = 'https://www.docker.com/products/docker-desktop/';

var
  Boxes: TBoxArray;
  DockState: TDockState = dsUnknown;
  ErrorText: string = '';
  DockVersion: string = '';
  Updated: TDateTime = 0;
  { Las acciones en marcha: id=texto («parando…»). }
  Busy: TStringList;

// {0}, {1}… por los valores.
function Fmt(const S: string; const A: array of string): string;
var
  i: Integer;
begin
  Result := S;
  for i := 0 to High(A) do
    Result := StringReplace(Result, '{' + IntToStr(i) + '}', A[i], [rfReplaceAll]);
end;

function SplitBy(const S: string; Sep: Char): TStringArray;
var
  i, st, n: Integer;
begin
  Result := nil;
  n := 0;
  st := 1;
  for i := 1 to Length(S) + 1 do
    if (i > Length(S)) or (S[i] = Sep) then
    begin
      SetLength(Result, n + 1);
      Result[n] := Copy(S, st, i - st);
      Inc(n);
      st := i + 1;
    end;
end;

procedure Push(var A: TStringArray; const S: string);
begin
  SetLength(A, Length(A) + 1);
  A[High(A)] := S;
end;

function Shorten(const S: string; N: Integer): string;
begin
  if UTF8Length(S) <= N then Exit(S);
  Result := UTF8Copy(S, 1, N - 1) + '…';
end;

{ El ejecutable de docker. Abierta desde el Finder, la app no tiene el PATH
  de la terminal: se busca donde lo dejan Docker Desktop, Homebrew,
  OrbStack, Colima o Rancher Desktop. }
function FindDocker: string;
var
  Found, Home: string;

  procedure T(const P: string);
  begin
    if (Found = '') and (P <> '') and FileExists(P) then Found := P;
  end;

begin
  Found := '';
  T(GetEnvironmentVariable('DMS_DOCKER_BIN'));
  Home := IncludeTrailingPathDelimiter(GetUserDir);
  {$IFDEF MSWINDOWS}
  T(ExeSearch('docker.exe', GetEnvironmentVariable('PATH')));
  T(GetEnvironmentVariable('ProgramFiles') + '\Docker\Docker\resources\bin\docker.exe');
  T(Home + '.rd\bin\docker.exe');
  {$ELSE}
  T(ExeSearch('docker', GetEnvironmentVariable('PATH')));
  T('/usr/local/bin/docker');
  T('/opt/homebrew/bin/docker');
  T(Home + '.docker/bin/docker');
  T(Home + '.orbstack/bin/docker');
  T(Home + '.rd/bin/docker');
  T('/Applications/Docker.app/Contents/Resources/bin/docker');
  T('/Applications/OrbStack.app/Contents/MacOS/xbin/docker');
  T('/usr/bin/docker');
  T('/snap/bin/docker');
  {$ENDIF}
  Result := Found;
end;

{ Docker Desktop, para abrirlo cuando el motor está parado ('' si no está). }
function DesktopApp: string;
begin
  Result := '';
  {$IFDEF DARWIN}
  if DirectoryExists('/Applications/Docker.app') then Result := '/Applications/Docker.app';
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  Result := GetEnvironmentVariable('ProgramFiles') + '\Docker\Docker\Docker Desktop.exe';
  if not FileExists(Result) then Result := '';
  {$ENDIF}
end;

{ Ejecuta docker con [Args] y devuelve su código de salida (-1: no hay
  docker) y lo que escribió. }
function RunDocker(const Exe: string; const Args: array of string;
  out Output: string): Integer;
var
  P: TProcess;
  Buf: array[0..8191] of Char;
  N, i: Integer;
  S, Path: string;
  T0: QWord;
begin
  Output := '';
  if (Exe = '') or not FileExists(Exe) then Exit(-1);
  P := TProcess.Create(nil);
  try
    P.Executable := Exe;
    for i := 0 to High(Args) do P.Parameters.Add(Args[i]);
    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    {$IFDEF UNIX}
    // docker busca sus ayudantes (credenciales, compose) en el PATH.
    for i := 1 to GetEnvironmentVariableCount do
      if Pos('PATH=', GetEnvironmentString(i)) <> 1 then
        P.Environment.Add(GetEnvironmentString(i));
    Path := GetEnvironmentVariable('PATH');
    if Path = '' then Path := '/usr/bin:/bin:/usr/sbin:/sbin';
    P.Environment.Add('PATH=' + ExtractFileDir(Exe) +
      ':/usr/local/bin:/opt/homebrew/bin:' + Path);
    {$ENDIF}
    try
      P.Execute;
    except
      Exit(-1);
    end;
    T0 := GetTickCount64;
    repeat
      N := P.Output.NumBytesAvailable;
      if N > 0 then
      begin
        N := P.Output.Read(Buf, Min(N, SizeOf(Buf)));
        if N > 0 then
        begin
          SetString(S, PChar(@Buf[0]), N);
          Output := Output + S;
        end;
      end
      else if P.Running then
      begin
        // Nada tarda tanto: un motor colgado no deja la app esperando.
        if GetTickCount64 - T0 > 90000 then P.Terminate(1);
        Sleep(15);
      end
      else
        Break;
    until False;
    Result := P.ExitCode;
  finally
    P.Free;
  end;
end;

procedure TDockJob.Execute;
var
  V: string;
begin
  if IsList then
  begin
    Code := RunDocker(Exe, ['ps', '-a', '--no-trunc', '--format', ListFormat], Output);
    if (Code = 0) and WantVersion and
      (RunDocker(Exe, ['version', '--format', '{{.Server.Version}}'], V) = 0) then
      Version := Trim(V);
  end
  else
    Code := RunDocker(Exe, Args, Output);
end;

{ Las direcciones que se pueden abrir de los puertos publicados:
  «0.0.0.0:8080->80/tcp, :::8080->80/tcp» → http://localhost:8080. }
function PortUrls(const Ports: string): TStringArray;
var
  Parts: TStringArray;
  S, L, R, Host, HostPort, Proto, Url: string;
  i, k, j: Integer;
  Dup: Boolean;
begin
  Result := nil;
  Parts := SplitBy(Ports, ',');
  for i := 0 to High(Parts) do
  begin
    S := Trim(Parts[i]);
    k := Pos('->', S);
    if k = 0 then Continue;
    L := Copy(S, 1, k - 1);
    R := Copy(S, k + 2, MaxInt);
    Proto := 'tcp';
    k := Pos('/', R);
    if k > 0 then
    begin
      Proto := Copy(R, k + 1, MaxInt);
      R := Copy(R, 1, k - 1);
    end;
    if Proto <> 'tcp' then Continue;
    k := LastDelimiter(':', L);
    Host := Copy(L, 1, k - 1);
    HostPort := Copy(L, k + 1, MaxInt);
    // Un rango (8000-8001): el primero.
    k := Pos('-', HostPort);
    if k > 0 then HostPort := Copy(HostPort, 1, k - 1);
    k := Pos('-', R);
    if k > 0 then R := Copy(R, 1, k - 1);
    if HostPort = '' then Continue;
    if (Host = '') or (Host = '0.0.0.0') or (Host = '::') or (Host = '[::]') or
      (Host = '127.0.0.1') or (Host = '[::1]') or (Host = '::1') then
      Host := 'localhost'
    else if (Pos(':', Host) > 0) and (Host[1] <> '[') then
      Host := '[' + Host + ']';
    if (R = '443') or (R = '8443') or (HostPort = '443') or (HostPort = '8443') then
      Url := 'https://'
    else
      Url := 'http://';
    Url := Url + Host + ':' + HostPort;
    Dup := False;
    for j := 0 to High(Result) do
      if Result[j] = Url then Dup := True;
    if not Dup then Push(Result, Url);
  end;
end;

function IsUp(const B: TBox): Boolean;
begin
  Result := (B.State = 'running') or (B.State = 'restarting') or (B.State = 'paused');
end;

function CountUp: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Boxes) do
    if IsUp(Boxes[i]) then Inc(Result);
end;

{ Primero los que están en marcha; después por proyecto de Compose (los
  sueltos al final) y por nombre. }
function Before(const A, B: TBox): Boolean;
begin
  if IsUp(A) <> IsUp(B) then Exit(IsUp(A));
  if (A.Project = '') <> (B.Project = '') then Exit(A.Project <> '');
  if A.Project <> B.Project then Exit(CompareText(A.Project, B.Project) < 0);
  Result := CompareText(A.Name, B.Name) < 0;
end;

function ParseList(const Text: string): TBoxArray;
var
  Lines, F: TStringArray;
  i, j, n: Integer;
  B, T: TBox;
  L: string;
begin
  Result := nil;
  n := 0;
  Lines := SplitBy(Text, #10);
  for i := 0 to High(Lines) do
  begin
    L := Lines[i];
    if (L <> '') and (L[Length(L)] = #13) then SetLength(L, Length(L) - 1);
    F := SplitBy(L, #9);
    if (Length(F) < 7) or (F[0] = '') then Continue;
    B.Id := F[0];
    B.Name := F[1];
    B.Image := F[2];
    B.State := LowerCase(F[3]);
    B.Status := F[4];
    B.Ports := F[5];
    B.Project := F[6];
    B.Urls := PortUrls(B.Ports);
    SetLength(Result, n + 1);
    Result[n] := B;
    Inc(n);
  end;
  for i := 1 to n - 1 do
  begin
    T := Result[i];
    j := i - 1;
    while (j >= 0) and Before(T, Result[j]) do
    begin
      Result[j + 1] := Result[j];
      Dec(j);
    end;
    Result[j + 1] := T;
  end;
end;

function FirstLine(const S: string): string;
var
  L: TStringArray;
  i: Integer;
begin
  Result := '';
  L := SplitBy(S, #10);
  for i := 0 to High(L) do
    if Trim(L[i]) <> '' then Exit(Trim(L[i]));
end;

{ Lo que dijo «docker ps»: -1 (no hay docker), otro código (el motor no
  responde) o la lista. }
procedure ApplyList(Code: Integer; const Output: string);
begin
  Boxes := nil;
  ErrorText := '';
  if Code = -1 then
    DockState := dsMissing
  else if Code <> 0 then
  begin
    DockState := dsDown;
    ErrorText := FirstLine(Output);
  end
  else
  begin
    DockState := dsOk;
    Boxes := ParseList(Output);
  end;
  Updated := Now;
end;

function Signature: string;
var
  i: Integer;
begin
  Result := IntToStr(Ord(DockState)) + ErrorText + Busy.Text;
  for i := 0 to High(Boxes) do
    with Boxes[i] do
      Result := Result + #10 + Id + Name + Image + State + Status + Ports + Project;
end;

// ============================================================ el menú
function AddItem(Parent: TMenuItem; const Caption, Act: string;
  Handler: TNotifyEvent): TMenuItem;
begin
  Result := TMenuItem.Create(Parent.Owner);
  Result.Caption := Caption;
  Result.Hint := Act;
  Result.OnClick := Handler;
  Result.Enabled := Act <> '';
  Parent.Add(Result);
end;

procedure AddSep(Parent: TMenuItem);
begin
  AddItem(Parent, '-', '', nil);
end;

{ «:8080 :8443»: los puertos que se abren. }
function PortList(const B: TBox): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(B.Urls) do
    Result := Result + ' :' + Copy(B.Urls[i], LastDelimiter(':', B.Urls[i]) + 1, MaxInt);
  Result := Trim(Result);
end;

procedure AddBox(Root: TMenuItem; const B: TBox; H: TNotifyEvent);
var
  Sub: TMenuItem;
  k: Integer;
  Doing, Cap: string;
  Up: Boolean;
begin
  Up := IsUp(B);
  Doing := Busy.Values[B.Id];
  Cap := B.Name;
  if Doing <> '' then
    Cap := Cap + '  (' + Doing + ')'
  else if Up and (Length(B.Urls) > 0) then
    Cap := Cap + '    ' + PortList(B);
  if Up then Cap := '●  ' + Cap else Cap := '○  ' + Cap;
  Sub := AddItem(Root, Cap, 'sub', nil);
  if Up then
  begin
    for k := 0 to High(B.Urls) do
      AddItem(Sub, Fmt(tx_OPEN, [B.Urls[k]]), 'open'#9 + B.Urls[k], H);
    if Length(B.Urls) = 0 then AddItem(Sub, tx_NO_PORTS, '', nil);
    AddSep(Sub);
    if Doing = '' then
    begin
      AddItem(Sub, tx_STOP, 'stop'#9 + B.Id, H);
      AddItem(Sub, tx_RESTART, 'restart'#9 + B.Id, H);
    end
    else
      AddItem(Sub, Doing, '', nil);
  end
  else if Doing = '' then
    AddItem(Sub, tx_START, 'start'#9 + B.Id, H)
  else
    AddItem(Sub, Doing, '', nil);
  AddSep(Sub);
  AddItem(Sub, tx_COPY_ID, 'copy'#9 + Copy(B.Id, 1, 12), H);
  if Up then AddItem(Sub, tx_COPY_EXEC, 'copy'#9'docker exec -it ' + B.Name + ' sh', H);
  AddSep(Sub);
  AddItem(Sub, B.Image, '', nil);
  AddItem(Sub, B.Status, '', nil);
end;

{ El menú del icono: el estado de Docker, los contenedores en marcha
  (agrupados por proyecto de Compose), los parados y las órdenes. [Lang]:
  el menú Idioma de la ventana (las demos), que se repite aquí. }
procedure BuildTray(Root: TMenuItem; H: TNotifyEvent; Lang: TMenuItem;
  LangH: TNotifyEvent);
var
  i, j, run, stp: Integer;
  Sub, It: TMenuItem;
  Last: string;
begin
  Root.Clear;
  run := CountUp;
  stp := Length(Boxes) - run;
  case DockState of
    dsUnknown:
      AddItem(Root, tx_SEARCHING, '', nil);
    dsMissing:
      begin
        AddItem(Root, tx_MISSING, '', nil);
        AddItem(Root, tx_GET_DOCKER, 'url'#9 + DockerSite, H);
      end;
    dsDown:
      begin
        AddItem(Root, tx_DOWN, '', nil);
        if ErrorText <> '' then AddItem(Root, Shorten(ErrorText, 60), '', nil);
        if DesktopApp <> '' then AddItem(Root, tx_OPEN_DESKTOP, 'app', H);
      end;
    dsOk:
      begin
        if run = 0 then
          AddItem(Root, tx_NONE_RUNNING, '', nil)
        else
          AddItem(Root, Fmt(tx_HEAD, [IntToStr(run), IntToStr(stp)]), '', nil);
        Last := #0;
        for i := 0 to High(Boxes) do
        begin
          if not IsUp(Boxes[i]) then Continue;
          if Boxes[i].Project <> Last then
          begin
            AddSep(Root);
            if Boxes[i].Project <> '' then AddItem(Root, Boxes[i].Project, '', nil);
            Last := Boxes[i].Project;
          end;
          AddBox(Root, Boxes[i], H);
        end;
        if stp > 0 then
        begin
          AddSep(Root);
          Sub := AddItem(Root, Fmt(tx_STOPPED_MENU, [IntToStr(stp)]), 'sub', nil);
          for i := 0 to High(Boxes) do
            if not IsUp(Boxes[i]) then AddBox(Sub, Boxes[i], H);
        end;
      end;
  end;
  AddSep(Root);
  AddItem(Root, tx_PANEL, 'panel', H);
  AddItem(Root, tx_REFRESH, 'refresh', H);
  if run > 0 then AddItem(Root, tx_STOPALL, 'stopall', H);
  AddSep(Root);
  if Lang <> nil then
  begin
    Sub := AddItem(Root, Lang.Caption, 'sub', nil);
    for j := 0 to Lang.Count - 1 do
    begin
      It := AddItem(Sub, Lang[j].Caption, 'lang'#9 + IntToStr(j), LangH);
      It.Checked := Lang[j].Checked;
    end;
  end;
  AddItem(Root, tx_ABOUT, 'about', H);
  AddItem(Root, tx_QUIT, 'quit', H);
end;

// ============================================================ el icono
{ El dibujo del icono en una rejilla de 22×22: una barcaza con contenedores. }
function GlyphAt(X, Y: Double): Boolean;
const
  BX: array[0..5] of Double = (3.0, 7.6, 12.2, 7.6, 12.2, 12.2);
  BY: array[0..5] of Double = (10.6, 10.6, 10.6, 6.2, 6.2, 1.8);
var
  i: Integer;
begin
  for i := 0 to 5 do
    if (X >= BX[i]) and (X <= BX[i] + 4.0) and (Y >= BY[i]) and (Y <= BY[i] + 3.6) then
      Exit(True);
  Result := (Y >= 15) and (Y <= 19) and (X >= 1.5 + (Y - 15) * 0.8) and
    (X <= 20.5 - (Y - 15) * 1.2);
end;

{ Cuánto del píxel (X, Y) de un icono de [Size] cubre el dibujo (0..1). }
function GlyphCover(X, Y, Size: Integer): Double;
var
  sx, sy, n: Integer;
  k: Double;
begin
  k := 22 / Size;
  n := 0;
  for sy := 0 to 3 do
    for sx := 0 to 3 do
      if GlyphAt((X + (sx + 0.5) / 4) * k, (Y + (sy + 0.5) / 4) * k) then Inc(n);
  Result := n / 16;
end;

function NewImage(W, H: Integer): TLazIntfImage;
var
  d: TRawImageDescription;
begin
  d.Init_BPP32_B8G8R8A8_BIO_TTB(W, H);
  Result := TLazIntfImage.Create(0, 0);
  Result.DataDescription := d;
end;

{ El icono de la barra: en macOS, negro con transparencia (una «plantilla»
  que el sistema pinta del color de la barra); en Windows, azul. [Dim]:
  Docker no responde. }
function Glyph(Size: Integer; Dim: Boolean): TBitmap;
var
  Img: TLazIntfImage;
  x, y: Integer;
  a: Double;
  C: TFPColor;
begin
  Img := NewImage(Size, Size);
  try
    for y := 0 to Size - 1 do
      for x := 0 to Size - 1 do
      begin
        a := GlyphCover(x, y, Size);
        if Dim then a := a * 0.4;
        {$IFDEF DARWIN}
        C.Red := 0; C.Green := 0; C.Blue := 0;
        {$ELSE}
        C.Red := $1D1D; C.Green := $6363; C.Blue := $EDED;
        {$ENDIF}
        C.Alpha := Round(a * $FFFF);
        Img.Colors[x, y] := C;
      end;
    Result := TBitmap.Create;
    Result.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

// ============================================================ el panel
var
  Z: Double = 1;

function S(V: Double): Integer;
begin
  Result := Round(V * Z);
end;

function Hex(const H: string): TColor;
begin
  Result := DmsColor(H);
end;

procedure Pen(Cv: TCanvas; Px: Double; Bold: Boolean; Col: TColor);
begin
  Cv.Font.Height := -S(Px);
  if Bold then Cv.Font.Style := [fsBold] else Cv.Font.Style := [];
  Cv.Font.Color := Col;
  Cv.Brush.Style := bsClear;
end;

procedure Card(Cv: TCanvas; R: TRect; Fill, Border: TColor; Radius: Integer);
begin
  Cv.Brush.Style := bsSolid;
  Cv.Brush.Color := Fill;
  Cv.Pen.Color := Border;
  Cv.Pen.Width := 1;
  Cv.RoundRect(R, Radius, Radius);
end;

{ El texto que cabe en [W] píxeles (con «…» si no cabe). }
function Fit(Cv: TCanvas; const T: string; W: Integer): string;
var
  n: Integer;
begin
  Result := T;
  if Cv.TextWidth(Result) <= W then Exit;
  n := UTF8Length(T);
  while (n > 0) and (Cv.TextWidth(UTF8Copy(T, 1, n) + '…') > W) do Dec(n);
  Result := UTF8Copy(T, 1, n) + '…';
end;

{ Un texto en varias líneas de [W] píxeles, centradas en CX; devuelve el
  alto que ocupa. }
function Wrapped(Cv: TCanvas; const T: string; CX, Y, W: Integer): Integer;
var
  Words: TStringArray;
  Line, Try_: string;
  i, h: Integer;

  procedure Flush;
  begin
    Cv.TextOut(CX - Cv.TextWidth(Line) div 2, Y + Result, Line);
    Inc(Result, h);
    Line := '';
  end;

begin
  Result := 0;
  h := Cv.TextHeight('Ág') + S(4);
  Words := SplitBy(T, ' ');
  Line := '';
  for i := 0 to High(Words) do
  begin
    if Line = '' then Try_ := Words[i] else Try_ := Line + ' ' + Words[i];
    if (Line <> '') and (Cv.TextWidth(Try_) > W) then
    begin
      Flush;
      Line := Words[i];
    end
    else
      Line := Try_;
  end;
  if Line <> '' then Flush;
end;

{ Dibuja el panel en [Cv] (W×H píxeles) con el zoom [AZoom], desplazado
  [Scroll] píxeles; [Hover]: la zona bajo el ratón. Devuelve las zonas que
  se pueden pulsar y el alto del contenido. }
procedure PaintPanel(Cv: TCanvas; W, H: Integer; AZoom: Double;
  Scroll, Hover: Integer; out Hits: THits; out ContentH: Integer);
var
  run, stp, i, y, nHits: Integer;
  Ink, Grey, Line_, BG: TColor;

  function AddHit(R: TRect; const A: string): Boolean;
  begin
    SetLength(Hits, nHits + 1);
    Hits[nHits].R := R;
    Hits[nHits].Act := A;
    Result := nHits = Hover;
    Inc(nHits);
  end;

  { Un botón con el borde redondeado, alineado a la derecha en [Right]. }
  function Button(Right, Top: Integer; const T, A: string; Fg, Fill: TColor): Integer;
  var
    R: TRect;
    bw: Integer;
    Hot: Boolean;
  begin
    Pen(Cv, 13, True, Fg);
    bw := Cv.TextWidth(T) + S(28);
    R := Rect(Right - bw, Top, Right, Top + S(32));
    Hot := AddHit(R, A);
    if Hot then Card(Cv, R, Hex('#e8ecf3'), Hex('#b9c2d0'), S(10))
    else Card(Cv, R, Fill, Hex('#d5dae2'), S(10));
    Pen(Cv, 13, True, Fg);
    Cv.TextOut(R.Left + S(14), R.Top + (S(32) - Cv.TextHeight(T)) div 2, T);
    Result := R.Left;
  end;

  procedure Row(const B: TBox);
  var
    R, CR: TRect;
    x, rx, cy, k, nx, cw: Integer;
    Up: Boolean;
    Doing, T, Port: string;
    Dot: TColor;
  begin
    Up := IsUp(B);
    R := Rect(S(16), y, W - S(16), y + S(64));
    Card(Cv, R, clWhite, Line_, S(14));
    cy := y + S(32);
    if B.State = 'running' then Dot := Hex('#16a34a')
    else if Up then Dot := Hex('#f59e0b')
    else Dot := Hex('#a3a9b3');
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := Dot;
    Cv.Pen.Color := Dot;
    Cv.Ellipse(R.Left + S(16), cy - S(6), R.Left + S(28), cy + S(6));
    // A la derecha: las acciones y los puertos.
    rx := R.Right - S(14);
    Doing := Busy.Values[B.Id];
    if Doing <> '' then
    begin
      Pen(Cv, 13, False, Grey);
      rx := rx - Cv.TextWidth(Doing);
      Cv.TextOut(rx, cy - Cv.TextHeight(Doing) div 2, Doing);
    end
    else if Up then
    begin
      rx := Button(rx, cy - S(16), tx_STOP, 'stop'#9 + B.Id, Hex('#dc2626'), clWhite) - S(8);
      rx := Button(rx, cy - S(16), tx_RESTART, 'restart'#9 + B.Id, Ink, clWhite);
    end
    else
      rx := Button(rx, cy - S(16), tx_START, 'start'#9 + B.Id, Hex('#15803d'), clWhite);
    rx := rx - S(14);
    if Up then
      for k := Min(High(B.Urls), 2) downto 0 do
      begin
        Port := ':' + Copy(B.Urls[k], LastDelimiter(':', B.Urls[k]) + 1, MaxInt) + '  ↗';
        Pen(Cv, 13, True, Hex('#1d4ed8'));
        cw := Cv.TextWidth(Port) + S(22);
        CR := Rect(rx - cw, cy - S(14), rx, cy + S(14));
        if AddHit(CR, 'open'#9 + B.Urls[k]) then
          Card(Cv, CR, Hex('#dbe7ff'), Hex('#93b4f5'), S(28))
        else
          Card(Cv, CR, Hex('#eef4ff'), Hex('#c7d7fb'), S(28));
        Pen(Cv, 13, True, Hex('#1d4ed8'));
        Cv.TextOut(CR.Left + S(11), cy - Cv.TextHeight(Port) div 2, Port);
        rx := CR.Left - S(8);
      end;
    // A la izquierda: el nombre, el proyecto, la imagen y el estado.
    x := R.Left + S(42);
    Pen(Cv, 15.5, True, Ink);
    T := Fit(Cv, B.Name, Max(S(40), rx - x - S(10)));
    Cv.TextOut(x, y + S(11), T);
    nx := x + Cv.TextWidth(T) + S(10);
    if (B.Project <> '') and (nx + S(60) < rx) then
    begin
      Pen(Cv, 11.5, True, Hex('#4338ca'));
      T := Fit(Cv, B.Project, rx - nx - S(30));
      CR := Rect(nx, y + S(11), nx + Cv.TextWidth(T) + S(14), y + S(31));
      Card(Cv, CR, Hex('#eef0ff'), Hex('#eef0ff'), S(20));
      Pen(Cv, 11.5, True, Hex('#4338ca'));
      Cv.TextOut(nx + S(7), CR.Top + (CR.Bottom - CR.Top - Cv.TextHeight(T)) div 2, T);
    end;
    Pen(Cv, 12.5, False, Grey);
    Cv.TextOut(x, y + S(36), Fit(Cv, B.Image + '  ·  ' + B.Status, Max(S(40), rx - x - S(10))));
    y := y + S(74);
  end;

  procedure Section(const T: string);
  begin
    Pen(Cv, 11.5, True, Grey);
    Cv.TextOut(S(26), y, T);
    y := y + S(26);
  end;

  procedure Message(const Title, Help, BtnText, BtnAct: string);
  var
    R: TRect;
    cx, bw: Integer;
  begin
    R := Rect(S(16), y, W - S(16), y + S(200));
    Card(Cv, R, clWhite, Line_, S(14));
    cx := (R.Left + R.Right) div 2;
    Pen(Cv, 18, True, Ink);
    Cv.TextOut(cx - Cv.TextWidth(Title) div 2, R.Top + S(34), Title);
    Pen(Cv, 13.5, False, Grey);
    Wrapped(Cv, Help, cx, R.Top + S(72), Min(S(560), R.Right - R.Left - S(40)));
    if BtnText <> '' then
    begin
      Pen(Cv, 13, True, Ink);
      bw := Cv.TextWidth(BtnText) + S(28);
      Button(cx + bw div 2, R.Top + S(140), BtnText, BtnAct, Hex('#1d4ed8'), Hex('#f5f8ff'));
    end;
    y := R.Bottom + S(16);
  end;

var
  Sub: string;
begin
  Z := AZoom;
  nHits := 0;
  Hits := nil;
  Ink := Hex('#1f2937');
  Grey := Hex('#6b7280');
  Line_ := Hex('#e3e7ee');
  BG := Hex('#f4f6f9');
  Cv.Brush.Style := bsSolid;
  Cv.Brush.Color := BG;
  Cv.FillRect(0, 0, W, H);
  run := CountUp;
  stp := Length(Boxes) - run;
  y := S(20) - Scroll;
  // La cabecera: el título, el resumen y dos botones.
  Pen(Cv, 23, True, Ink);
  Cv.TextOut(S(24), y, tx_TITLE);
  case DockState of
    dsOk: Sub := Fmt(tx_HEAD, [IntToStr(run), IntToStr(stp)]);
    dsDown: Sub := tx_DOWN;
    dsMissing: Sub := tx_MISSING;
    else Sub := tx_SEARCHING;
  end;
  if DockVersion <> '' then Sub := Sub + '  ·  ' + Fmt(tx_VERSION, [DockVersion]);
  if Updated > 0 then Sub := Sub + '  ·  ' + Fmt(tx_UPDATED, [FormatDateTime('hh:nn:ss', Updated)]);
  Pen(Cv, 13, False, Grey);
  Cv.TextOut(S(24), y + S(36), Sub);
  i := Button(W - S(24), y + S(6), tx_REFRESH, 'refresh', Ink, clWhite);
  if run > 0 then
    Button(i - S(10), y + S(6), tx_STOPALL, 'stopall', Hex('#dc2626'), clWhite);
  y := y + S(80);
  case DockState of
    dsUnknown: Message(tx_SEARCHING, '', '', '');
    dsMissing: Message(tx_MISSING, tx_MISSING_HELP, tx_GET_DOCKER, 'url'#9 + DockerSite);
    dsDown:
      if DesktopApp <> '' then
        Message(tx_DOWN, tx_DOWN_HELP + ' ' + ErrorText, tx_OPEN_DESKTOP, 'app')
      else
        Message(tx_DOWN, tx_DOWN_HELP + ' ' + ErrorText, '', '');
    dsOk:
      if Length(Boxes) = 0 then
        Message(tx_NONE_RUNNING, tx_EMPTY, '', '')
      else
      begin
        if run > 0 then
        begin
          Section(Fmt(tx_SEC_RUN, [IntToStr(run)]));
          for i := 0 to High(Boxes) do
            if IsUp(Boxes[i]) then Row(Boxes[i]);
          y := y + S(10);
        end;
        if stp > 0 then
        begin
          Section(Fmt(tx_SEC_STOP, [IntToStr(stp)]));
          for i := 0 to High(Boxes) do
            if not IsUp(Boxes[i]) then Row(Boxes[i]);
        end;
      end;
  end;
  ContentH := y + Scroll + S(10);
end;

// ============================================================ las capturas
{ Unos contenedores de ejemplo (la salida de «docker ps» con ListFormat). }
function SampleList: string;
  function L(const Id, Name, Image, State, Status, Ports, Project: string): string;
  begin
    Result := Id + #9 + Name + #9 + Image + #9 + State + #9 + Status + #9 +
      Ports + #9 + Project + #10;
  end;
begin
  Result :=
    L('9f1c2b7a6d3e4f50a1b2c3d4e5f60718293a4b5c6d7e8f9012345678abcdef01',
      'grafana', 'grafana/grafana:11.2.0', 'running', 'Up 25 minutes',
      '0.0.0.0:3001->3000/tcp, :::3001->3000/tcp', '') +
    L('3a4b5c6d7e8f90123456789abcdef0123456789abcdef0123456789abcdef012',
      'tienda-web-1', 'nginx:1.27-alpine', 'running', 'Up 2 hours',
      '0.0.0.0:8080->80/tcp, :::8080->80/tcp, 0.0.0.0:8443->443/tcp', 'tienda') +
    L('7c8d9e0f1a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5',
      'tienda-api-1', 'node:22-alpine', 'running', 'Up 2 hours (healthy)',
      '0.0.0.0:3000->3000/tcp', 'tienda') +
    L('1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f',
      'tienda-db-1', 'postgres:16', 'running', 'Up 2 hours', '5432/tcp', 'tienda') +
    L('5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c',
      'redis-cache', 'redis:7', 'exited', 'Exited (0) 3 hours ago', '', '') +
    L('b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3',
      'odoo-18', 'odoo:18', 'exited', 'Exited (137) 2 days ago', '', '');
end;

function Mix(A, B: TColor; T: Double): TColor;
var
  ca, cb: LongInt;
begin
  ca := ColorToRGB(A);
  cb := ColorToRGB(B);
  Result := RGBToColor(
    Round(Red(ca) * (1 - T) + Red(cb) * T),
    Round(Green(ca) * (1 - T) + Green(cb) * T),
    Round(Blue(ca) * (1 - T) + Blue(cb) * T));
end;

function Wall(Y, H: Integer): TColor;
begin
  if Y < H div 2 then
    Result := Mix(Hex('#1e3a6e'), Hex('#5b4a8f'), Y / (H / 2))
  else
    Result := Mix(Hex('#5b4a8f'), Hex('#c06c84'), (Y - H / 2) / (H / 2));
end;

{ Un menú como los de macOS, con sus opciones: en (X, Y); [Hi]: la opción
  resaltada. Devuelve el rectángulo de la resaltada. }
function DrawMenu(Cv: TCanvas; X, Y: Integer; Items: TMenuItem; Hi: Integer): TRect;
const
  RowH = 36; SepH = 14; PadL = 30; PadR = 46;
var
  i, w, h, yy, k: Integer;
  R, IR: TRect;
  It: TMenuItem;
  Col: TColor;
begin
  Result := Rect(0, 0, 0, 0);
  Pen(Cv, 17, False, clBlack);
  w := 300;
  h := 12;
  for i := 0 to Items.Count - 1 do
  begin
    w := Max(w, Cv.TextWidth(Items[i].Caption) + PadL + PadR);
    if Items[i].Caption = '-' then Inc(h, SepH) else Inc(h, RowH);
  end;
  R := Rect(X, Y, X + w, Y + h);
  // La sombra, en capas.
  for k := 6 downto 1 do
    Card(Cv, Rect(R.Left - k, R.Top - k + 4, R.Right + k, R.Bottom + k + 4),
      Mix(Wall(R.Top + h div 2, 1000), clBlack, 0.035 * (7 - k)),
      Mix(Wall(R.Top + h div 2, 1000), clBlack, 0.035 * (7 - k)), 22 + k);
  Card(Cv, R, Hex('#f3f3f5'), Hex('#c4c4ca'), 20);
  yy := Y + 6;
  for i := 0 to Items.Count - 1 do
  begin
    It := Items[i];
    if It.Caption = '-' then
    begin
      Cv.Pen.Color := Hex('#d8d8dc');
      Cv.Line(X + 18, yy + SepH div 2, X + w - 18, yy + SepH div 2);
      Inc(yy, SepH);
      Continue;
    end;
    IR := Rect(X + 6, yy, X + w - 6, yy + RowH);
    if i = Hi then
    begin
      Card(Cv, IR, Hex('#2f6fea'), Hex('#2f6fea'), 12);
      Col := clWhite;
      Result := IR;
    end
    else if It.Enabled then Col := Hex('#1d1d1f')
    else Col := Hex('#8e8e93');
    Pen(Cv, 17, False, Col);
    if It.Checked then Cv.TextOut(X + 10, yy + (RowH - Cv.TextHeight('✓')) div 2, '✓');
    Cv.TextOut(X + PadL, yy + (RowH - Cv.TextHeight(It.Caption)) div 2, It.Caption);
    if It.Count > 0 then
    begin
      Pen(Cv, 22, False, Col);
      Cv.TextOut(X + w - 28, yy + (RowH - Cv.TextHeight('›')) div 2 - 1, '›');
    end;
    Inc(yy, RowH);
  end;
end;

{ La pantalla con la barra de menús, el icono y el menú abierto; [Open]:
  la opción con su submenú abierto y [SubHi], la resaltada en él. }
procedure Desk(const FileName: string; Root: TMenuItem; Open, SubHi: Integer);
const
  W = 1600; H = 1000; BarH = 44;
var
  Bmp: TBitmap;
  Png: TPortableNetworkGraphic;
  y, x, ix, iy, gs: Integer;
  Hi: TRect;
  a: Double;
  bar: TColor;
  T: string;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(W, H);
    Z := 1;
    for y := 0 to H - 1 do
    begin
      Bmp.Canvas.Pen.Color := Wall(y, H);
      Bmp.Canvas.Line(0, y, W, y);
    end;
    for y := 0 to BarH - 1 do
    begin
      Bmp.Canvas.Pen.Color := Mix(Wall(y, H), Hex('#f2f2f6'), 0.78);
      Bmp.Canvas.Line(0, y, W, y);
    end;
    // El reloj y el icono resaltado (el menú está abierto).
    Pen(Bmp.Canvas, 17, True, Hex('#1d1d1f'));
    T := FormatDateTime('hh:nn', Date + EncodeTime(17, 2, 0, 0));
    Bmp.Canvas.TextOut(W - 30 - Bmp.Canvas.TextWidth(T), (BarH - Bmp.Canvas.TextHeight(T)) div 2, T);
    ix := W - 820;
    gs := 34;
    Card(Bmp.Canvas, Rect(ix - 10, 5, ix + gs + 10, BarH - 5), Hex('#c9cad2'), Hex('#c9cad2'), 12);
    iy := (BarH - gs) div 2;
    bar := Hex('#c9cad2');
    for y := 0 to gs - 1 do
      for x := 0 to gs - 1 do
      begin
        a := GlyphCover(x, y, gs);
        if a > 0 then
          Bmp.Canvas.Pixels[ix + x, iy + y] := Mix(bar, Hex('#111114'), a);
      end;
    Hi := DrawMenu(Bmp.Canvas, ix - 14, BarH + 4, Root, Open);
    if (Open >= 0) and (Root[Open].Count > 0) then
      DrawMenu(Bmp.Canvas, Hi.Right + 2, Hi.Top - 6, Root[Open], SubHi);
    Png := TPortableNetworkGraphic.Create;
    try
      Png.Assign(Bmp);
      Png.SaveToFile(FileName);
    finally
      Png.Free;
    end;
  finally
    Bmp.Free;
  end;
end;

procedure PanelShot(const FileName: string);
var
  Bmp: TBitmap;
  Png: TPortableNetworkGraphic;
  Hits: THits;
  CH: Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(1600, 1000);
    PaintPanel(Bmp.Canvas, 1600, 1000, 1.5, 0, 3, Hits, CH);
    Png := TPortableNetworkGraphic.Create;
    try
      Png.Assign(Bmp);
      Png.SaveToFile(FileName);
    finally
      Png.Free;
    end;
  finally
    Bmp.Free;
  end;
end;

{ La opción del menú cuyo texto empieza por [Prefix] (o -1). }
function ItemIndex(Root: TMenuItem; const Prefix: string): Integer;
var
  i: Integer;
begin
  for i := 0 to Root.Count - 1 do
    if Pos(Prefix, Root[i].Caption) = 1 then Exit(i);
  Result := -1;
end;

{ DMS_DOCKER_SHOT=carpeta: las capturas de la web, sin ventana. }
function Shots(const Dir: string): Integer;
var
  M: TPopupMenu;
  web: Integer;
begin
  ForceDirectories(Dir);
  ApplyList(0, SampleList);
  DockVersion := '27.3.1';
  Updated := Date + EncodeTime(17, 2, 9, 0);
  M := TPopupMenu.Create(nil);
  try
    BuildTray(M.Items, nil, nil, nil);
    web := ItemIndex(M.Items, '●  tienda-web-1');
    Desk(Dir + '/menu.png', M.Items, -1, -1);
    Desk(Dir + '/menu-open.png', M.Items, web, 0);
    Desk(Dir + '/menu-stop.png', M.Items, web, ItemIndex(M.Items[web], tx_STOP));
    PanelShot(Dir + '/panel.png');
  finally
    M.Free;
  end;
  WriteLn('shots ok ', Dir);
  Result := 0;
end;

// ============================================================ las pruebas
{ Sin ventana: DMS_DOCKER_SELFTEST=1. Los puertos, la lista, el menú, el
  icono y el panel con datos de ejemplo; con DMS_DOCKER_LIVE=<contenedor>,
  además lo para y lo vuelve a arrancar de verdad. }
function SelfTest: Integer;
var
  fails, i, n, CH: Integer;
  M: TPopupMenu;
  U: TStringArray;
  Bmp: TBitmap;
  Hits: THits;
  Exe, Out_, Live, Id: string;
  Found: Boolean;

  procedure Check(Ok: Boolean; const What: string);
  begin
    if not Ok then
    begin
      WriteLn('FAIL ', What);
      Inc(fails);
    end;
  end;

  function Urls(const P: string): string;
  var
    k: Integer;
  begin
    U := PortUrls(P);
    Result := '';
    for k := 0 to High(U) do Result := Result + U[k] + ' ';
    Result := Trim(Result);
  end;

  { Busca [Act] en el menú (y sus submenús). }
  function Has(Root: TMenuItem; const Caption, Act: string): Boolean;
  var
    k: Integer;
  begin
    for k := 0 to Root.Count - 1 do
    begin
      if (Root[k].Caption = Caption) and ((Act = '') or (Root[k].Hint = Act)) then Exit(True);
      if Has(Root[k], Caption, Act) then Exit(True);
    end;
    Result := False;
  end;

  function State_(const Name: string): string;
  var
    k: Integer;
  begin
    Result := '';
    for k := 0 to High(Boxes) do
      if Boxes[k].Name = Name then
      begin
        Id := Boxes[k].Id;
        Exit(Boxes[k].State);
      end;
  end;

begin
  fails := 0;
  // Los puertos.
  Check(Urls('0.0.0.0:8080->80/tcp, :::8080->80/tcp') = 'http://localhost:8080', 'ipv4+ipv6');
  Check(Urls('0.0.0.0:8443->443/tcp') = 'https://localhost:8443', 'https');
  Check(Urls('5432/tcp') = '', 'sin publicar');
  Check(Urls('127.0.0.1:5000-5001->5000-5001/tcp, 0.0.0.0:53->53/udp') =
    'http://localhost:5000', 'rango y udp');
  Check(Urls('192.168.1.10:9000->9000/tcp') = 'http://192.168.1.10:9000', 'ip');
  Check(Urls('[::]:3000->3000/tcp') = 'http://localhost:3000', 'ipv6');
  Check(Urls('') = '', 'vacío');
  // La lista.
  ApplyList(0, SampleList);
  Check(DockState = dsOk, 'estado');
  Check(Length(Boxes) = 6, 'seis contenedores');
  Check(CountUp = 4, 'cuatro en marcha');
  Check((Boxes[0].Name = 'tienda-api-1') and (Boxes[2].Name = 'tienda-web-1') and
    (Boxes[3].Name = 'grafana'), 'orden');
  Check(not IsUp(Boxes[4]) and not IsUp(Boxes[5]), 'parados al final');
  Check(Length(Boxes[2].Urls) = 2, 'dos direcciones de la web');
  ApplyList(0, '');
  Check((DockState = dsOk) and (Length(Boxes) = 0), 'sin contenedores');
  // El menú.
  M := TPopupMenu.Create(nil);
  try
    ApplyList(0, SampleList);
    BuildTray(M.Items, nil, nil, nil);
    Check(Has(M.Items, Fmt(tx_OPEN, ['http://localhost:8080']), 'open'#9'http://localhost:8080'), 'abrir');
    Check(Has(M.Items, Fmt(tx_OPEN, ['https://localhost:8443']), ''), 'abrir https');
    Check(Has(M.Items, tx_STOP, 'stop'#9 + Boxes[0].Id), 'parar');
    Check(Has(M.Items, tx_START, 'start'#9 + Boxes[4].Id), 'iniciar');
    Check(Has(M.Items, 'tienda', ''), 'proyecto');
    Check(Has(M.Items, Fmt(tx_STOPPED_MENU, ['2']), 'sub'), 'parados');
    Check(Has(M.Items, tx_STOPALL, 'stopall'), 'parar todos');
    Check(ItemIndex(M.Items, '●  tienda-web-1') > 0, 'la web en el menú');
    Busy.Values[Boxes[0].Id] := tx_STOPPING;
    BuildTray(M.Items, nil, nil, nil);
    Check(not Has(M.Items, tx_STOP, 'stop'#9 + Boxes[0].Id), 'ocupado');
    Busy.Clear;
    ApplyList(1, 'Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?');
    BuildTray(M.Items, nil, nil, nil);
    Check((DockState = dsDown) and Has(M.Items, tx_DOWN, ''), 'motor parado');
    ApplyList(-1, '');
    BuildTray(M.Items, nil, nil, nil);
    Check((DockState = dsMissing) and Has(M.Items, tx_GET_DOCKER, 'url'#9 + DockerSite), 'sin docker');
  finally
    M.Free;
  end;
  // El icono y el panel.
  Bmp := Glyph(44, False);
  try
    Check((Bmp.Width = 44) and (Bmp.Height = 44), 'icono');
  finally
    Bmp.Free;
  end;
  n := 0;
  for i := 0 to 43 do
    if GlyphCover(i, 30, 44) > 0.5 then Inc(n);
  Check(n > 10, 'el dibujo del icono');
  ApplyList(0, SampleList);
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(900, 600);
    PaintPanel(Bmp.Canvas, 900, 600, 1, 0, -1, Hits, CH);
    Found := False;
    for i := 0 to High(Hits) do
      if Hits[i].Act = 'open'#9'http://localhost:8080' then Found := True;
    Check(Found, 'el panel abre la web');
    Check(CH > 600, 'el panel se desplaza');
  finally
    Bmp.Free;
  end;
  // Docker de verdad, si lo hay (sin fallar si el motor está parado).
  Exe := FindDocker;
  if Exe <> '' then
  begin
    i := RunDocker(Exe, ['ps', '-a', '--no-trunc', '--format', ListFormat], Out_);
    ApplyList(i, Out_);
    WriteLn('docker: ', Exe, ' · código ', i, ' · ', Length(Boxes), ' contenedores');
  end
  else
    WriteLn('docker: no está');
  Live := GetEnvironmentVariable('DMS_DOCKER_LIVE');
  if Live <> '' then
  begin
    Check(State_(Live) = 'running', 'live: en marcha');
    Check(RunDocker(Exe, ['stop', Id], Out_) = 0, 'live: parar');
    RunDocker(Exe, ['ps', '-a', '--no-trunc', '--format', ListFormat], Out_);
    ApplyList(0, Out_);
    Check(State_(Live) = 'exited', 'live: parado');
    Check(RunDocker(Exe, ['start', Id], Out_) = 0, 'live: iniciar');
    RunDocker(Exe, ['ps', '-a', '--no-trunc', '--format', ListFormat], Out_);
    ApplyList(0, Out_);
    Check(State_(Live) = 'running', 'live: otra vez en marcha');
    if fails = 0 then WriteLn('live ok');
  end;
  if fails = 0 then WriteLn('selftest ok');
  if fails = 0 then Result := 0 else Result := 1;
end;

// ============================================================ la ventana
procedure TForm1.form_create;
begin
  StageHint.Visible := False;
  if GetEnvironmentVariable('DMS_DOCKER_SELFTEST') <> '' then Halt(SelfTest);
  if GetEnvironmentVariable('DMS_DOCKER_SHOT') <> '' then
    Halt(Shots(GetEnvironmentVariable('DMS_DOCKER_SHOT')));
  // La app vive en la barra de menús: la ventana (el panel) no se abre sola.
  Application.ShowMainForm := False;
  Stage.Align := alClient;
  Stage.BevelOuter := bvNone;
  Stage.DoubleBuffered := True;
  DoubleBuffered := True;
  Box := TPaintBox.Create(Self);
  Box.Parent := Stage;
  Box.Align := alClient;
  Box.OnPaint := @BoxPaint;
  Box.OnMouseDown := @BoxDown;
  Box.OnMouseMove := @BoxMove;
  Box.OnMouseWheel := @BoxWheel;
  FHover := -1;
  FIconState := -1;
  OnClose := @PanelClose;
  TrayMenu := TPopupMenu.Create(Self);
  Tray := TTrayIcon.Create(Self);
  Tray.PopUpMenu := TrayMenu;
  Tray.OnClick := @TrayClick;
  Tray.Hint := tx_APP;
  Tick.Enabled := False;
  Application.QueueAsyncCall(@StartUp, 0);
end;

{ Ya con el bucle en marcha: fuera del Dock, el icono y la primera lista. }
procedure TForm1.StartUp(Data: PtrInt);
begin
  {$IFDEF DARWIN}
  NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory);
  {$ENDIF}
  Rebuild;
  SetIcon;
  Tray.Show;
  Tick.Enabled := True;
  Reload;
end;

procedure TForm1.SetIcon;
var
  B: TBitmap;
  I: TIcon;
  St: Integer;
begin
  St := Ord(DockState = dsOk);
  if St = FIconState then Exit;
  FIconState := St;
  B := Glyph({$IFDEF DARWIN}44{$ELSE}32{$ENDIF}, DockState <> dsOk);
  I := TIcon.Create;
  try
    I.Assign(B);
    Tray.Icon := I;
  finally
    I.Free;
    B.Free;
  end;
  {$IFDEF DARWIN}
  // Una plantilla: macOS la pinta blanca o negra según la barra.
  if Tray.Icon.Handle <> 0 then
    TCocoaBitmap(Tray.Icon.Handle).Image.setTemplate(True);
  Tray.InternalUpdate;
  {$ENDIF}
end;

procedure TForm1.Tick_timer;
begin
  Reload;
end;

procedure TForm1.Reload;
var
  J: TDockJob;
begin
  if FListing then
  begin
    FAgain := True;
    Exit;
  end;
  FListing := True;
  J := TDockJob.Create(True);
  J.Exe := FindDocker;
  J.IsList := True;
  J.WantVersion := DockVersion = '';
  J.FreeOnTerminate := True;
  J.OnTerminate := @JobDone;
  J.Start;
end;

procedure TForm1.Run(const AArgs, AIds: array of string; const BusyText: string);
var
  J: TDockJob;
  i: Integer;
begin
  J := TDockJob.Create(True);
  J.Exe := FindDocker;
  for i := 0 to High(AArgs) do Push(J.Args, AArgs[i]);
  for i := 0 to High(AIds) do
  begin
    Push(J.Ids, AIds[i]);
    Busy.Values[AIds[i]] := BusyText;
  end;
  J.FreeOnTerminate := True;
  J.OnTerminate := @JobDone;
  J.Start;
  Rebuild;
  if Visible then Box.Invalidate;
end;

procedure TForm1.JobDone(Sender: TObject);
var
  J: TDockJob;
  i, k: Integer;
begin
  J := TDockJob(Sender);
  if J.IsList then
  begin
    FListing := False;
    ApplyList(J.Code, J.Output);
    if J.Version <> '' then DockVersion := J.Version;
    if DockState <> dsOk then DockVersion := '';
    Rebuild;
    if Visible then Box.Invalidate;
    if FAgain then
    begin
      FAgain := False;
      Reload;
    end;
    Exit;
  end;
  for i := 0 to High(J.Ids) do
  begin
    k := Busy.IndexOfName(J.Ids[i]);
    if k >= 0 then Busy.Delete(k);
  end;
  Rebuild;
  Reload;
  if J.Code <> 0 then
  begin
    {$IFDEF DARWIN}
    NSApp.activateIgnoringOtherApps(True);
    {$ENDIF}
    MessageDlg(tx_APP, tx_FAILED + LineEnding + LineEnding + Trim(J.Output),
      mtError, [mbOK], 0);
  end;
end;

{ El menú Idioma de la ventana (lo añade la demo) o nil. }
function TForm1.LangMenu: TMenuItem;
var
  i: Integer;
begin
  Result := nil;
  if Menu = nil then Exit;
  for i := 0 to Menu.Items.Count - 1 do
    if (Menu.Items[i].Caption = 'Idioma') or (Menu.Items[i].Caption = 'Language') then
      Exit(Menu.Items[i]);
end;

{ Rehace el menú del icono si algo cambió (no mientras se mira igual). }
procedure TForm1.Rebuild;
var
  L: TMenuItem;
  Sg: string;
  i: Integer;
begin
  L := LangMenu;
  Sg := Signature;
  if L <> nil then
    for i := 0 to L.Count - 1 do
      Sg := Sg + L[i].Caption + BoolToStr(L[i].Checked, True);
  if Sg = FSig then Exit;
  FSig := Sg;
  BuildTray(TrayMenu.Items, @TrayItem, L, @LangItem);
  if DockState = dsOk then
    Tray.Hint := Fmt(tx_HINT, [IntToStr(CountUp)])
  else if DockState = dsDown then
    Tray.Hint := tx_DOWN
  else
    Tray.Hint := tx_APP;
  if FIconState >= 0 then SetIcon;
end;

{ Las opciones del menú se hacen después de cerrarse el menú. }
procedure TForm1.TrayItem(Sender: TObject);
begin
  FPending := TMenuItem(Sender).Hint;
  Application.QueueAsyncCall(@DoPending, 0);
end;

procedure TForm1.LangItem(Sender: TObject);
begin
  FPending := TMenuItem(Sender).Hint;
  Application.QueueAsyncCall(@DoPending, 0);
end;

procedure TForm1.DoPending(Data: PtrInt);
begin
  Act(FPending);
end;

{ En Windows, el clic en el icono abre el panel (el menú va con el derecho). }
procedure TForm1.TrayClick(Sender: TObject);
begin
  ShowPanel;
end;

procedure TForm1.ShowPanel;
begin
  {$IFDEF DARWIN}
  // Con la ventana abierta, una app normal: en el Dock y con su menú.
  NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular);
  {$ENDIF}
  Show;
  WindowState := wsNormal;
  BringToFront;
  Application.BringToFront;
  {$IFDEF DARWIN}
  NSApp.activateIgnoringOtherApps(True);
  {$ENDIF}
  Box.Invalidate;
  Reload;
end;

procedure TForm1.ToAccessory(Data: PtrInt);
begin
  {$IFDEF DARWIN}
  if not Visible then NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory);
  {$ENDIF}
end;

{ Cerrar la ventana la esconde: la app sigue en la barra de menús. }
procedure TForm1.PanelClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FQuitting then
    CloseAction := caFree
  else
  begin
    CloseAction := caHide;
    Application.QueueAsyncCall(@ToAccessory, 0);
  end;
end;

procedure TForm1.Quit;
begin
  FQuitting := True;
  Tray.Hide;
  Application.Terminate;
end;

procedure TForm1.Act(const H: string);
var
  K, V: string;
  p, i: Integer;
  Ids, A: TStringArray;
  L: TMenuItem;
begin
  p := Pos(#9, H);
  if p > 0 then
  begin
    K := Copy(H, 1, p - 1);
    V := Copy(H, p + 1, MaxInt);
  end
  else
  begin
    K := H;
    V := '';
  end;
  if (K = 'open') or (K = 'url') then
    OpenURL(V)
  else if K = 'app' then
    OpenDocument(DesktopApp)
  else if K = 'stop' then
    Run(['stop', V], [V], tx_STOPPING)
  else if K = 'start' then
    Run(['start', V], [V], tx_STARTING)
  else if K = 'restart' then
    Run(['restart', V], [V], tx_RESTARTING)
  else if K = 'copy' then
    Clipboard.AsText := V
  else if K = 'stopall' then
  begin
    Ids := nil;
    for i := 0 to High(Boxes) do
      if IsUp(Boxes[i]) and (Busy.Values[Boxes[i].Id] = '') then Push(Ids, Boxes[i].Id);
    if Length(Ids) = 0 then Exit;
    {$IFDEF DARWIN}
    NSApp.activateIgnoringOtherApps(True);
    {$ENDIF}
    if not Ask(Fmt(tx_ASK_STOPALL, [IntToStr(Length(Ids))])) then Exit;
    A := nil;
    Push(A, 'stop');
    for i := 0 to High(Ids) do Push(A, Ids[i]);
    Run(A, Ids, tx_STOPPING);
  end
  else if K = 'panel' then
    ShowPanel
  else if K = 'refresh' then
    Reload
  else if K = 'hide' then
    Close
  else if (K = 'about') or (K = 'howto') then
  begin
    {$IFDEF DARWIN}
    NSApp.activateIgnoringOtherApps(True);
    {$ENDIF}
    if K = 'about' then
      MessageDlg(tx_APP, tx_ABOUT_TEXT, mtInformation, [mbOK], 0)
    else
      MessageDlg(tx_L_HOWTO, tx_HOWTO_TEXT, mtInformation, [mbOK], 0);
  end
  else if K = 'lang' then
  begin
    // El menú Idioma de la demo cierra la app y abre la del otro idioma.
    L := LangMenu;
    if L = nil then Exit;
    p := StrToIntDef(V, -1);
    if (p < 0) or (p >= L.Count) then Exit;
    {$IFDEF DARWIN}
    NSApp.activateIgnoringOtherApps(True);
    {$ENDIF}
    FQuitting := True;
    L[p].Click;
    if not Application.Terminated then FQuitting := False;
  end
  else if K = 'quit' then
    Quit;
end;

procedure TForm1.Menu1_click(const Item: string);
begin
  if Item = tx_MP_REFRESH then Act('refresh')
  else if Item = tx_MP_STOPALL then Act('stopall')
  else if Item = tx_MP_HIDE then Act('hide')
  else if Item = tx_MP_QUIT then Act('quit')
  else if Item = tx_MP_HOWTO then Act('howto')
  else if Item = tx_MP_ABOUT then Act('about');
end;

procedure TForm1.BoxPaint(Sender: TObject);
var
  Most: Integer;
begin
  PaintPanel(Box.Canvas, Box.Width, Box.Height, 1, FScroll, FHover, FHits, FContentH);
  Most := Max(0, FContentH - Box.Height);
  if FScroll > Most then
  begin
    FScroll := Most;
    Box.Invalidate;
  end;
end;

function TForm1.HitAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FHits) do
    if PtInRect(FHits[i].R, Point(X, Y)) then Exit(i);
  Result := -1;
end;

procedure TForm1.BoxDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
begin
  i := HitAt(X, Y);
  if (Button = mbLeft) and (i >= 0) then Act(FHits[i].Act);
end;

procedure TForm1.BoxMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
begin
  i := HitAt(X, Y);
  if i >= 0 then Box.Cursor := crHandPoint else Box.Cursor := crDefault;
  if i <> FHover then
  begin
    FHover := i;
    Box.Invalidate;
  end;
end;

procedure TForm1.BoxWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  FScroll := Max(0, Min(FScroll - WheelDelta div 2, Max(0, FContentH - Box.Height)));
  FHover := -1;
  Box.Invalidate;
  Handled := True;
end;

initialization
  Busy := TStringList.Create;

finalization
  Busy.Free;
end.
''';
