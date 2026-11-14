part of 'tk_examples.dart';

// El código en Pascal de «Plan de viaje» (tk_showcase_pascal_travel.dart):
// la unidad Form1.pas entera; el estudio pone los textos en «// @TEXTS».
const _travelCode = r'''
// @TITLE
unit Form1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, dms, design, Math, Process, LCLIntf, LCLType, LazUTF8,
  fpjson, jsonparser, fppdf, FPImage, fpreadjpeg;

type
  { Un lugar del plan. }
  TStop = record
    Time, Name, Kind, Desc, Tip: string;
  end;
  { Un día: su título, de qué va, dónde comer y los lugares. }
  TDay = record
    Title, Theme, Food: string;
    Stops: array of TStop;
  end;
  { El plan entero, tal como lo devuelve Claude Code. }
  TPlan = record
    Title, Subtitle, Dest, Country, Origin: string;
    GetMode, GetTime, GetTip, BestTime, Budget: string;
    Tips: array of string;
    Days: array of TDay;
  end;

  { Claude Code en segundo plano: «claude -p» con el esquema del plan. }
  TClaudeJob = class(TThread)
  public
    Exe, Prompt: string;
    Output, Error: string;
    Code: Integer;
    procedure Execute; override;
  end;

  TForm1 = class(TFormDesign)
  private
    Box: TPaintBox;
    Plan: TPlan;
    IsSample, Busy: Boolean;
    Job: TClaudeJob;
    Started: TDateTime;
    Poster: TBitmap;
    Pages: array of TBitmap;
    FScroll: Integer;
    procedure BoxPaint(Sender: TObject);
    procedure BoxWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure JobDone(Sender: TObject);
    procedure FreeImages;
    procedure Rebuild;
    procedure SetPlan(const P: TPlan; Sample: Boolean);
    procedure Say(const T: string);
    procedure StartPlan;
    procedure SaveAs(AsPages: Boolean = False);
    procedure OpenPlan;
    procedure SavePlan;
    function Dossier: Boolean;
  public
    procedure form_create; override;
    procedure form_close; override;
    procedure Tick_timer; override;
    procedure Menu1_click(const Item: string); override;
    procedure BtnPlan_click; override;
    procedure BtnSave_click; override;
    procedure RadImage_click; override;
    procedure RadDossier_click; override;
    procedure Dest_enter; override;
  end;

implementation

// Los textos (los traduce el estudio con el resto del ejemplo).
const
  // @TEXTS

// ---- fin de los textos

// ============================================================ lo básico
{ «{0} días a {1}» con sus valores. }
function Fmt(const S: string; const Args: array of string): string;
var
  i: Integer;
begin
  Result := S;
  for i := 0 to High(Args) do
    Result := StringReplace(Result, '{' + IntToStr(i) + '}', Args[i], [rfReplaceAll]);
end;

function Hex(const H: string): TColor;
begin
  Result := DmsColor(H);
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

procedure Pen(Cv: TCanvas; Px: Double; Bold: Boolean; Col: TColor);
begin
  {$IFDEF DARWIN}
  Cv.Font.Name := 'Helvetica Neue';
  {$ENDIF}
  Cv.Font.Height := -Round(Px);
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

procedure Dot(Cv: TCanvas; CX, CY, R: Integer; Col: TColor);
begin
  Cv.Brush.Style := bsSolid;
  Cv.Brush.Color := Col;
  Cv.Pen.Color := Col;
  Cv.Ellipse(CX - R, CY - R, CX + R + 1, CY + R + 1);
end;

{ Un degradado vertical de A a B en R. }
procedure Gradient(Cv: TCanvas; R: TRect; A, B: TColor);
var
  y: Integer;
begin
  for y := R.Top to R.Bottom - 1 do
  begin
    Cv.Pen.Color := Mix(A, B, (y - R.Top) / Max(1, R.Bottom - R.Top - 1));
    Cv.Line(R.Left, y, R.Right, y);
  end;
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

{ Las líneas de un texto en [W] píxeles (con la letra actual). }
function Wrap(Cv: TCanvas; const T: string; W: Integer): TStringArray;
var
  Words: TStringArray;
  Line, Try_: string;
  i: Integer;
begin
  Result := nil;
  Words := StringReplace(T, #10, ' ', [rfReplaceAll]).Split([' ']);
  Line := '';
  for i := 0 to High(Words) do
  begin
    if Words[i] = '' then Continue;
    if Line = '' then Try_ := Words[i] else Try_ := Line + ' ' + Words[i];
    if (Line <> '') and (Cv.TextWidth(Try_) > W) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Line;
      Line := Words[i];
    end
    else
      Line := Try_;
  end;
  if Line <> '' then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Line;
  end;
end;

{ Un párrafo: como mucho [MaxLines] líneas (la última con «…»); devuelve
  el alto. Con [Draw] = False solo mide. }
function Para(Cv: TCanvas; const T: string; X, Y, W, LineH, MaxLines: Integer;
  Draw: Boolean = True): Integer;
var
  L: TStringArray;
  i, n: Integer;
  S: string;
begin
  L := Wrap(Cv, T, W);
  n := Length(L);
  if (MaxLines > 0) and (n > MaxLines) then n := MaxLines;
  if Draw then
    for i := 0 to n - 1 do
    begin
      S := L[i];
      if (i = n - 1) and (n < Length(L)) then S := Fit(Cv, S + ' ' + L[i + 1], W);
      Cv.TextOut(X, Y + i * LineH, S);
    end;
  Result := n * LineH;
end;

// ============================================================ el plan
const
  KINDS: array[0..11] of string = ('monument', 'museum', 'nature', 'viewpoint',
    'food', 'neighborhood', 'beach', 'shopping', 'night', 'religious', 'market', 'other');
  KIND_COLORS: array[0..11] of string = ('#c2410c', '#7c3aed', '#15803d', '#0891b2',
    '#db2777', '#ca8a04', '#0284c7', '#9333ea', '#4338ca', '#92400e', '#ea580c', '#64748b');
  DAY_COLORS: array[0..6] of string = ('#0f766e', '#c2410c', '#4338ca', '#be185d',
    '#15803d', '#b45309', '#1d4ed8');

  // El esquema JSON del plan: Claude Code responde con un objeto así.
  SCHEMA =
    '{"type":"object","properties":{"title":{"type":"string"},"subtitle":{"type":"string"},' +
    '"destination":{"type":"string"},"country":{"type":"string"},' +
    '"getting_there":{"type":"object","properties":{"mode":{"type":"string"},"duration":{"type":"string"},' +
    '"tip":{"type":"string"}},"required":["mode","duration","tip"],"additionalProperties":false},' +
    '"best_time":{"type":"string"},"budget":{"type":"string"},' +
    '"days":{"type":"array","items":{"type":"object","properties":{"title":{"type":"string"},' +
    '"theme":{"type":"string"},"food":{"type":"string"},"stops":{"type":"array","items":{"type":"object",' +
    '"properties":{"time":{"type":"string"},"name":{"type":"string"},"kind":{"type":"string","enum":' +
    '["monument","museum","nature","viewpoint","food","neighborhood","beach","shopping","night",' +
    '"religious","market","other"]},"description":{"type":"string"},"tip":{"type":"string"}},' +
    '"required":["time","name","kind","description","tip"],"additionalProperties":false}}},' +
    '"required":["title","theme","food","stops"],"additionalProperties":false}},' +
    '"tips":{"type":"array","items":{"type":"string"}}},' +
    '"required":["title","subtitle","destination","country","getting_there","best_time","budget","days","tips"],' +
    '"additionalProperties":false}';

function KindIndex(const K: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(KINDS) do
    if KINDS[i] = K then Exit(i);
  Result := High(KINDS);
end;

function KindColor(const K: string): TColor;
begin
  Result := Hex(KIND_COLORS[KindIndex(K)]);
end;

function KindName(const K: string): string;
const
  N: array[0..11] of string = (tx_K_MONUMENT, tx_K_MUSEUM, tx_K_NATURE, tx_K_VIEWPOINT,
    tx_K_FOOD, tx_K_NEIGHBORHOOD, tx_K_BEACH, tx_K_SHOPPING, tx_K_NIGHT, tx_K_RELIGIOUS,
    tx_K_MARKET, tx_K_OTHER);
begin
  Result := N[KindIndex(K)];
end;

function DayColor(i: Integer): TColor;
begin
  Result := Hex(DAY_COLORS[i mod Length(DAY_COLORS)]);
end;

function Str(O: TJSONObject; const K: string): string;
var
  D: TJSONData;
begin
  Result := '';
  if O = nil then Exit;
  D := O.Find(K);
  if (D <> nil) and (D.JSONType in [jtString, jtNumber]) then Result := Trim(D.AsString);
end;

function Obj(O: TJSONObject; const K: string): TJSONObject;
var
  D: TJSONData;
begin
  Result := nil;
  if O = nil then Exit;
  D := O.Find(K);
  if D is TJSONObject then Result := TJSONObject(D);
end;

function Arr(O: TJSONObject; const K: string): TJSONArray;
var
  D: TJSONData;
begin
  Result := nil;
  if O = nil then Exit;
  D := O.Find(K);
  if D is TJSONArray then Result := TJSONArray(D);
end;

{ «Día 1: El casco viejo» → «El casco viejo» (el número ya lo pone la app). }
function StripDay(const T: string): string;
var
  k, i: Integer;
  HasDigit: Boolean;
begin
  Result := T;
  k := Pos(':', T);
  if (k = 0) or (k > 14) then Exit;
  HasDigit := False;
  for i := 1 to k - 1 do
    if T[i] in ['0'..'9'] then HasDigit := True;
  if HasDigit then Result := Trim(Copy(T, k + 1, MaxInt));
end;

{ «Para comer, una francesinha…» → «Una francesinha…». }
function StripLead(const T, Lead: string): string;
begin
  Result := T;
  if (Lead <> '') and (UTF8LowerCase(Copy(T, 1, Length(Lead))) = UTF8LowerCase(Lead)) then
  begin
    Result := Trim(Copy(T, Length(Lead) + 1, MaxInt));
    while (Result <> '') and (Result[1] in [':', ',', '.', '-']) do Result := Trim(Copy(Result, 2, MaxInt));
    if Result <> '' then Result := UTF8UpperCase(UTF8Copy(Result, 1, 1)) + UTF8Copy(Result, 2, MaxInt);
  end;
end;

{ Un objeto JSON → el plan. False si no tiene días. }
function ParsePlan(O: TJSONObject; out P: TPlan): Boolean;
var
  G, DO_, SO: TJSONObject;
  A, SA: TJSONArray;
  i, k: Integer;
begin
  P := Default(TPlan);
  P.Title := Str(O, 'title');
  P.Subtitle := Str(O, 'subtitle');
  P.Dest := Str(O, 'destination');
  P.Country := Str(O, 'country');
  P.Origin := Str(O, 'origin');
  G := Obj(O, 'getting_there');
  P.GetMode := Str(G, 'mode');
  P.GetTime := Str(G, 'duration');
  P.GetTip := Str(G, 'tip');
  P.BestTime := Str(O, 'best_time');
  P.Budget := Str(O, 'budget');
  A := Arr(O, 'tips');
  if A <> nil then
    for i := 0 to A.Count - 1 do
      if A[i].JSONType = jtString then
      begin
        SetLength(P.Tips, Length(P.Tips) + 1);
        P.Tips[High(P.Tips)] := Trim(A[i].AsString);
      end;
  A := Arr(O, 'days');
  if A <> nil then
    for i := 0 to A.Count - 1 do
    begin
      if not (A[i] is TJSONObject) then Continue;
      DO_ := TJSONObject(A[i]);
      SetLength(P.Days, Length(P.Days) + 1);
      with P.Days[High(P.Days)] do
      begin
        Title := StripDay(Str(DO_, 'title'));
        Theme := Str(DO_, 'theme');
        Food := StripLead(Str(DO_, 'food'), tx_FOOD_T);
        SA := Arr(DO_, 'stops');
        if SA <> nil then
          for k := 0 to SA.Count - 1 do
          begin
            if not (SA[k] is TJSONObject) then Continue;
            SO := TJSONObject(SA[k]);
            SetLength(Stops, Length(Stops) + 1);
            Stops[High(Stops)].Time := Str(SO, 'time');
            Stops[High(Stops)].Name := Str(SO, 'name');
            Stops[High(Stops)].Kind := Str(SO, 'kind');
            Stops[High(Stops)].Desc := Str(SO, 'description');
            Stops[High(Stops)].Tip := Str(SO, 'tip');
          end;
      end;
    end;
  if P.Dest = '' then P.Dest := P.Title;
  Result := Length(P.Days) > 0;
end;

function ParsePlanText(const T: string; out P: TPlan): Boolean;
var
  D: TJSONData;
begin
  P := Default(TPlan);
  Result := False;
  try
    D := GetJSON(T);
  except
    Exit;
  end;
  try
    Result := (D is TJSONObject) and ParsePlan(TJSONObject(D), P);
  finally
    D.Free;
  end;
end;

{ El plan → JSON (para guardarlo y volver a abrirlo). }
function PlanJSON(const P: TPlan): string;
var
  O, G, DO_, SO: TJSONObject;
  Days, Stops, Tips: TJSONArray;
  i, k: Integer;
begin
  O := TJSONObject.Create;
  try
    O.Add('title', P.Title);
    O.Add('subtitle', P.Subtitle);
    O.Add('destination', P.Dest);
    O.Add('country', P.Country);
    O.Add('origin', P.Origin);
    G := TJSONObject.Create;
    G.Add('mode', P.GetMode);
    G.Add('duration', P.GetTime);
    G.Add('tip', P.GetTip);
    O.Add('getting_there', G);
    O.Add('best_time', P.BestTime);
    O.Add('budget', P.Budget);
    Days := TJSONArray.Create;
    for i := 0 to High(P.Days) do
    begin
      DO_ := TJSONObject.Create;
      DO_.Add('title', P.Days[i].Title);
      DO_.Add('theme', P.Days[i].Theme);
      DO_.Add('food', P.Days[i].Food);
      Stops := TJSONArray.Create;
      for k := 0 to High(P.Days[i].Stops) do
      begin
        SO := TJSONObject.Create;
        SO.Add('time', P.Days[i].Stops[k].Time);
        SO.Add('name', P.Days[i].Stops[k].Name);
        SO.Add('kind', P.Days[i].Stops[k].Kind);
        SO.Add('description', P.Days[i].Stops[k].Desc);
        SO.Add('tip', P.Days[i].Stops[k].Tip);
        Stops.Add(SO);
      end;
      DO_.Add('stops', Stops);
      Days.Add(DO_);
    end;
    O.Add('days', Days);
    Tips := TJSONArray.Create;
    for i := 0 to High(P.Tips) do Tips.Add(P.Tips[i]);
    O.Add('tips', Tips);
    Result := O.FormatJSON;
  finally
    O.Free;
  end;
end;

{ Lo que devuelve «claude -p --output-format json»: el plan (en
  structured_output, o en result como texto) o el error. }
function ParseClaude(const Output: string; out P: TPlan; out Err: string): Boolean;
var
  D, S: TJSONData;
  O: TJSONObject;
begin
  P := Default(TPlan);
  Err := '';
  Result := False;
  try
    D := GetJSON(Output);
  except
    Err := tx_ERR_ANSWER;
    Exit;
  end;
  try
    if not (D is TJSONObject) then begin Err := tx_ERR_ANSWER; Exit; end;
    O := TJSONObject(D);
    if O.Get('is_error', False) then
    begin
      Err := Fmt(tx_ERR_CLAUDE, [Str(O, 'result')]);
      Exit;
    end;
    S := O.Find('structured_output');
    if S is TJSONObject then Result := ParsePlan(TJSONObject(S), P)
    else Result := ParsePlanText(Str(O, 'result'), P);
    if not Result then Err := tx_ERR_ANSWER;
  finally
    D.Free;
  end;
end;

{ Lo que se le pide a Claude Code. }
function BuildPrompt(const Origin, Dest: string; Days: Integer; const Likes, Pace, Budget: string): string;
begin
  Result := Fmt(tx_PROMPT, [IntToStr(Days), Dest, Origin, Likes, Pace, Budget]);
end;

// ------------------------------------------------------------ Claude Code
{ Dónde está la orden «claude» (la de Claude Code). }
function FindClaude: string;
var
  C: TStringArray;
  H, P: string;
  i: Integer;
begin
  Result := GetEnvironmentVariable('DMS_CLAUDE');
  if Result <> '' then Exit;
  {$IFDEF WINDOWS}
  H := GetEnvironmentVariable('USERPROFILE');
  C := [H + '\.local\bin\claude.exe', GetEnvironmentVariable('APPDATA') + '\npm\claude.cmd'];
  {$ELSE}
  H := GetEnvironmentVariable('HOME');
  C := [H + '/.local/bin/claude', H + '/.claude/local/claude', '/opt/homebrew/bin/claude',
    '/usr/local/bin/claude', H + '/.npm-global/bin/claude'];
  {$ENDIF}
  for i := 0 to High(C) do
    if FileExists(C[i]) then Exit(C[i]);
  P := GetEnvironmentVariable('PATH');
  for H in P.Split([PathSeparator]) do
    if (H <> '') and FileExists(IncludeTrailingPathDelimiter(H) + {$IFDEF WINDOWS}'claude.exe'{$ELSE}'claude'{$ENDIF}) then
      Exit(IncludeTrailingPathDelimiter(H) + {$IFDEF WINDOWS}'claude.exe'{$ELSE}'claude'{$ENDIF});
  Result := '';
end;

{ Llama a Claude Code y espera (en el hilo que la llama): la salida y el código. }
function RunClaude(const Exe, Prompt: string; out Output, Error: string; Stop: PBoolean): Integer;
var
  P: TProcess;
  Buf: array[0..65535] of Char;
  n: Integer;
  S: string;
begin
  Output := '';
  Error := '';
  Result := -1;
  P := TProcess.Create(nil);
  try
    P.Executable := Exe;
    P.Parameters.Add('-p');
    P.Parameters.Add('--output-format');
    P.Parameters.Add('json');
    P.Parameters.Add('--no-session-persistence');
    P.Parameters.Add('--tools=');   // sin herramientas: solo escribe el plan
    P.Parameters.Add('--json-schema');
    P.Parameters.Add(SCHEMA);
    P.Options := [poUsePipes];
    P.ShowWindow := swoHide;
    try
      P.Execute;
    except
      on E: Exception do
      begin
        Error := E.Message;
        Exit;
      end;
    end;
    if Prompt <> '' then P.Input.Write(Prompt[1], Length(Prompt));
    P.CloseInput;
    while P.Running or (P.Output.NumBytesAvailable > 0) or (P.Stderr.NumBytesAvailable > 0) do
    begin
      if (Stop <> nil) and Stop^ then
      begin
        P.Terminate(1);
        Error := tx_CANCELLED;
        Exit;
      end;
      if P.Output.NumBytesAvailable > 0 then
      begin
        n := P.Output.Read(Buf, Min(SizeOf(Buf), P.Output.NumBytesAvailable));
        SetString(S, PChar(@Buf[0]), n);
        Output := Output + S;
      end
      else if P.Stderr.NumBytesAvailable > 0 then
      begin
        n := P.Stderr.Read(Buf, Min(SizeOf(Buf), P.Stderr.NumBytesAvailable));
        SetString(S, PChar(@Buf[0]), n);
        Error := Error + S;
      end
      else
        Sleep(40);
    end;
    Result := P.ExitStatus;
  finally
    P.Free;
  end;
end;

var
  StopJob: Boolean = False;

procedure TClaudeJob.Execute;
begin
  Code := RunClaude(Exe, Prompt, Output, Error, @StopJob);
end;

// ============================================================ dibujar
const
  PW = 1080; PH = 1920;   // la imagen vertical (como una historia)
  AW = 1240; AH = 1754;   // una página A4 a 150 ppp

function PlaceLine(const P: TPlan): string;
begin
  Result := P.Dest;
  if P.Country <> '' then Result := Result + ', ' + P.Country;
end;

function DaysText(n: Integer): string;
begin
  if n = 1 then Result := tx_ONE_DAY else Result := Fmt(tx_N_DAYS, [IntToStr(n)]);
end;

{ La imagen vertical. [Level]: 0 con las descripciones en dos líneas, 1 en
  una, 2 sin ellas; [Sc]: la escala de la letra. Devuelve dónde acaba. }
function DrawPoster(Cv: TCanvas; const P: TPlan; Level: Integer; Sc: Double; Draw: Boolean): Integer;
var
  y, x, i, k, top, h, lh, cardTop: Integer;
  S: string;
  col: TColor;
  function Z(v: Double): Integer;
  begin
    Result := Round(v * Sc);
  end;
begin
  if Draw then
  begin
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := Hex('#f6f2ea');
    Cv.FillRect(0, 0, PW, PH);
    Gradient(Cv, Rect(0, 0, PW, 560), Hex('#0b3954'), Hex('#1d7874'));
    // Un sol y unas colinas, para que no sea un bloque.
    Dot(Cv, PW - 150, 150, 70, Mix(Hex('#1d7874'), Hex('#f6c85f'), 0.9));
    Cv.Brush.Color := Mix(Hex('#0b3954'), Hex('#1d7874'), 0.6);
    Cv.Pen.Color := Cv.Brush.Color;
    Cv.Polygon([Point(0, 560), Point(0, 470), Point(260, 400), Point(520, 470), Point(760, 380),
      Point(PW, 460), Point(PW, 560)]);
    Pen(Cv, 30, True, Mix(Hex('#ffffff'), Hex('#1d7874'), 0.25));
    Cv.TextOut(80, 86, UTF8UpperCase(tx_KICKER));
    Pen(Cv, 104, True, clWhite);
    while (Cv.Font.Height < -50) and (Cv.TextWidth(P.Dest) > PW - 160) do Cv.Font.Height := Cv.Font.Height + 4;
    Cv.TextOut(80, 130, P.Dest);
    Pen(Cv, 36, False, Mix(clWhite, Hex('#1d7874'), 0.15));
    S := DaysText(Length(P.Days));
    if P.Country <> '' then S := P.Country + '  ·  ' + S;
    if P.Origin <> '' then S := S + '  ·  ' + Fmt(tx_FROM, [P.Origin]);
    Cv.TextOut(84, 262, Fit(Cv, S, PW - 168));
    Pen(Cv, 32, False, clWhite);
    Para(Cv, P.Subtitle, 84, 320, PW - 168, 42, 2);
  end;
  // Cómo llegar: una tarjeta encima del borde.
  if Draw then
  begin
    Card(Cv, Rect(60, 470, PW - 60, 590), clWhite, Hex('#e5ded1'), 36);
    Dot(Cv, 122, 530, 30, Hex('#f4a259'));
    Pen(Cv, 30, True, clWhite);
    Cv.TextOut(122 - Cv.TextWidth('→') div 2, 530 - Cv.TextHeight('→') div 2, '→');
    Pen(Cv, 28, True, Hex('#1f2933'));
    Cv.TextOut(170, 488, Fit(Cv, Fmt(tx_GET_THERE, [P.GetMode, P.GetTime]), PW - 260));
    Pen(Cv, 24, False, Hex('#52606d'));
    Cv.TextOut(170, 530, Fit(Cv, P.GetTip, PW - 260));
  end;
  // Los días.
  y := 630;
  for i := 0 to High(P.Days) do
  begin
    cardTop := y;
    col := DayColor(i);
    top := y + Z(20);
    y := top + Z(52);
    for k := 0 to High(P.Days[i].Stops) do
    begin
      lh := Z(30);
      Pen(Cv, 26 * Sc, False, Hex('#52606d'));
      if Level = 0 then h := Para(Cv, P.Days[i].Stops[k].Desc, 0, 0, PW - 330, lh, 2, False)
      else if Level = 1 then h := lh
      else h := 0;
      if Draw then
      begin
        Pen(Cv, 26 * Sc, True, col);
        Cv.TextOut(100, y, P.Days[i].Stops[k].Time);
        Dot(Cv, 222, y + Z(17), Z(9), KindColor(P.Days[i].Stops[k].Kind));
        Pen(Cv, 30 * Sc, True, Hex('#1f2933'));
        Cv.TextOut(250, y - Z(2), Fit(Cv, P.Days[i].Stops[k].Name, PW - 330));
        Pen(Cv, 26 * Sc, False, Hex('#52606d'));
        if Level = 0 then Para(Cv, P.Days[i].Stops[k].Desc, 250, y + Z(38), PW - 330, lh, 2)
        else if Level = 1 then Cv.TextOut(250, y + Z(38), Fit(Cv, P.Days[i].Stops[k].Desc, PW - 330));
      end;
      y := y + Z(42) + h + Z(14);
    end;
    if P.Days[i].Food <> '' then
    begin
      if Draw then
      begin
        Pen(Cv, 24 * Sc, False, Hex('#9a3412'));
        Cv.TextOut(100, y, Fit(Cv, Fmt(tx_EAT, [P.Days[i].Food]), PW - 200));
      end;
      y := y + Z(36);
    end;
    y := y + Z(10);
    // La cabecera del día y su raya (después de medir, para saber el alto).
    if Draw then
    begin
      Pen(Cv, 28 * Sc, True, col);
      S := UTF8UpperCase(Fmt(tx_DAY_N, [IntToStr(i + 1)]));
      x := 100;
      Cv.TextOut(x, top, S);
      x := x + Cv.TextWidth(S) + 16;
      Pen(Cv, 30 * Sc, True, Hex('#1f2933'));
      Cv.TextOut(x, top - Z(1), Fit(Cv, P.Days[i].Title, PW - 160 - x));
      Cv.Pen.Color := Mix(col, Hex('#f6f2ea'), 0.4);
      Cv.Pen.Width := 6;
      Cv.Line(70, cardTop + Z(16), 70, y - Z(16));
      Cv.Pen.Width := 1;
    end;
    y := y + Z(6);
  end;
  // Un consejo y la firma.
  if Draw and (Length(P.Tips) > 0) then
  begin
    Pen(Cv, 26, True, Hex('#1d7874'));
    Cv.TextOut(80, PH - 140, tx_TIP);
    Pen(Cv, 26, False, Hex('#1f2933'));
    Cv.TextOut(80 + Cv.TextWidth(tx_TIP + ' ') + 4, PH - 140, Fit(Cv, P.Tips[0], PW - 260));
  end;
  if Draw then
  begin
    Pen(Cv, 22, False, Hex('#9aa5b1'));
    Cv.TextOut(80, PH - 80, tx_MADE_WITH);
  end;
  Result := y;
end;

{ La imagen vertical, con el detalle que quepa. }
procedure RenderPoster(Cv: TCanvas; const P: TPlan);
var
  Level: Integer;
  Sc: Double;
begin
  for Level := 0 to 2 do
  begin
    Sc := 1;
    while (Sc > 0.79) and (DrawPoster(Cv, P, Level, Sc, False) > PH - 170) do Sc := Sc - 0.04;
    if DrawPoster(Cv, P, Level, Sc, False) <= PH - 170 then
    begin
      DrawPoster(Cv, P, Level, Sc, True);
      Exit;
    end;
  end;
  Sc := 0.8;
  while (Sc > 0.5) and (DrawPoster(Cv, P, 2, Sc, False) > PH - 170) do Sc := Sc - 0.04;
  DrawPoster(Cv, P, 2, Sc, True);
end;

{ El detalle con el que sale la imagen vertical (0 a 2), para las pruebas. }
function PosterLevel(Cv: TCanvas; const P: TPlan): Integer;
var
  Sc: Double;
begin
  for Result := 0 to 2 do
  begin
    Sc := 1;
    while (Sc > 0.79) and (DrawPoster(Cv, P, Result, Sc, False) > PH - 170) do Sc := Sc - 0.04;
    if DrawPoster(Cv, P, Result, Sc, False) <= PH - 170 then Exit;
  end;
  Result := 3;
end;

function PageCount(const P: TPlan): Integer;
begin
  Result := Length(P.Days) + 2;
end;

procedure PageFooter(Cv: TCanvas; const P: TPlan; Page: Integer);
begin
  Cv.Pen.Color := Hex('#e4e7eb');
  Cv.Line(90, AH - 100, AW - 90, AH - 100);
  Pen(Cv, 20, False, Hex('#9aa5b1'));
  Cv.TextOut(90, AH - 80, Fit(Cv, PlaceLine(P) + '  ·  ' + tx_MADE_WITH, AW - 400));
  Cv.TextOut(AW - 90 - Cv.TextWidth(Fmt(tx_PAGE, [IntToStr(Page + 1), IntToStr(PageCount(P))])), AH - 80,
    Fmt(tx_PAGE, [IntToStr(Page + 1), IntToStr(PageCount(P))]));
end;

{ Un recuadro con título y texto; devuelve el alto. }
function InfoBox(Cv: TCanvas; X, Y, W: Integer; const Title, Text: string; Col: TColor): Integer;
var
  h: Integer;
begin
  Pen(Cv, 24, False, Hex('#1f2933'));
  h := Para(Cv, Text, 0, 0, W - 60, 34, 4, False);
  Card(Cv, Rect(X, Y, X + W, Y + 76 + h), Mix(Col, clWhite, 0.92), Mix(Col, clWhite, 0.7), 24);
  Pen(Cv, 22, True, Col);
  Cv.TextOut(X + 30, Y + 22, UTF8UpperCase(Title));
  Pen(Cv, 24, False, Hex('#1f2933'));
  Para(Cv, Text, X + 30, Y + 58, W - 60, 34, 4);
  Result := 76 + h + 10;
end;

{ Una página del dosier: 0 la portada, después un día por página y al
  final los consejos. }
procedure RenderPage(Cv: TCanvas; const P: TPlan; Page: Integer);
var
  y, i, k, h, half: Integer;
  col: TColor;
  S: string;
begin
  Cv.Brush.Style := bsSolid;
  Cv.Brush.Color := clWhite;
  Cv.FillRect(0, 0, AW, AH);
  if Page = 0 then
  begin
    Gradient(Cv, Rect(0, 0, AW, 820), Hex('#0b3954'), Hex('#1d7874'));
    Dot(Cv, AW - 220, 230, 110, Mix(Hex('#1d7874'), Hex('#f6c85f'), 0.9));
    Cv.Brush.Color := Mix(Hex('#0b3954'), Hex('#1d7874'), 0.6);
    Cv.Pen.Color := Cv.Brush.Color;
    Cv.Polygon([Point(0, 820), Point(0, 690), Point(320, 600), Point(640, 690), Point(930, 570),
      Point(AW, 670), Point(AW, 820)]);
    Pen(Cv, 30, True, Mix(clWhite, Hex('#1d7874'), 0.25));
    Cv.TextOut(90, 120, UTF8UpperCase(tx_KICKER));
    Pen(Cv, 120, True, clWhite);
    while (Cv.Font.Height < -50) and (Cv.TextWidth(P.Dest) > AW - 180) do Cv.Font.Height := Cv.Font.Height + 4;
    Cv.TextOut(90, 170, P.Dest);
    Pen(Cv, 38, False, clWhite);
    S := DaysText(Length(P.Days));
    if P.Country <> '' then S := P.Country + '  ·  ' + S;
    if P.Origin <> '' then S := S + '  ·  ' + Fmt(tx_FROM, [P.Origin]);
    Cv.TextOut(94, 320, Fit(Cv, S, AW - 188));
    Pen(Cv, 34, False, clWhite);
    Para(Cv, P.Subtitle, 94, 390, AW - 400, 46, 3);
    y := 880;
    half := (AW - 180 - 30) div 2;
    h := InfoBox(Cv, 90, y, half, tx_HOW_GET, P.GetMode + ' · ' + P.GetTime + '. ' + P.GetTip, Hex('#f4a259'));
    h := Max(h, InfoBox(Cv, 90 + half + 30, y, half, tx_WHEN, P.BestTime, Hex('#1d7874')));
    y := y + h + 10;
    y := y + InfoBox(Cv, 90, y, AW - 180, tx_BUDGET_T, P.Budget, Hex('#4338ca')) + 20;
    Pen(Cv, 34, True, Hex('#1f2933'));
    Cv.TextOut(90, y, tx_ITINERARY);
    y := y + 64;
    for i := 0 to High(P.Days) do
    begin
      if y > AH - 170 then Break;
      Dot(Cv, 108, y + 18, 18, DayColor(i));
      Pen(Cv, 22, True, clWhite);
      S := IntToStr(i + 1);
      Cv.TextOut(108 - Cv.TextWidth(S) div 2, y + 18 - Cv.TextHeight(S) div 2, S);
      Pen(Cv, 28, True, Hex('#1f2933'));
      Cv.TextOut(146, y, Fit(Cv, P.Days[i].Title, AW - 240));
      Pen(Cv, 24, False, Hex('#52606d'));
      Cv.TextOut(146, y + 38, Fit(Cv, P.Days[i].Theme, AW - 240));
      y := y + 92;
    end;
  end
  else if Page <= Length(P.Days) then
  begin
    i := Page - 1;
    col := DayColor(i);
    Cv.Brush.Color := col;
    Cv.FillRect(0, 0, AW, 260);
    Pen(Cv, 30, True, Mix(col, clWhite, 0.7));
    Cv.TextOut(90, 70, UTF8UpperCase(Fmt(tx_DAY_N, [IntToStr(i + 1)])));
    Pen(Cv, 58, True, clWhite);
    Cv.TextOut(90, 110, Fit(Cv, P.Days[i].Title, AW - 180));
    Pen(Cv, 28, False, Mix(col, clWhite, 0.85));
    Cv.TextOut(92, 190, Fit(Cv, P.Days[i].Theme, AW - 180));
    y := 320;
    for k := 0 to High(P.Days[i].Stops) do
      with P.Days[i].Stops[k] do
      begin
        if y > AH - 260 then Break;
        // La hora, el punto en la línea de tiempo y el lugar.
        Pen(Cv, 30, True, col);
        Cv.TextOut(90, y, Time);
        if k < High(P.Days[i].Stops) then
        begin
          Cv.Pen.Color := Mix(col, clWhite, 0.65);
          Cv.Pen.Width := 4;
          Cv.Line(232, y + 30, 232, y + 300);
          Cv.Pen.Width := 1;
        end;
        Dot(Cv, 232, y + 18, 16, KindColor(Kind));
        Pen(Cv, 36, True, Hex('#1f2933'));
        Cv.TextOut(272, y - 4, Fit(Cv, Name, AW - 362 - 200));
        // La etiqueta del tipo de lugar, a la derecha.
        Pen(Cv, 20, True, KindColor(Kind));
        S := UTF8UpperCase(KindName(Kind));
        Card(Cv, Rect(AW - 90 - Cv.TextWidth(S) - 30, y, AW - 90, y + 38), Mix(KindColor(Kind), clWhite, 0.88),
          Mix(KindColor(Kind), clWhite, 0.88), 19);
        Pen(Cv, 20, True, KindColor(Kind));
        Cv.TextOut(AW - 90 - Cv.TextWidth(S) - 15, y + 8, S);
        Pen(Cv, 26, False, Hex('#3e4c59'));
        h := Para(Cv, Desc, 272, y + 50, AW - 362, 38, 4);
        y := y + 50 + h + 8;
        if Tip <> '' then
        begin
          Pen(Cv, 24, True, Hex('#9a3412'));
          Cv.TextOut(272, y, tx_TIP);
          Pen(Cv, 24, False, Hex('#9a3412'));
          h := Para(Cv, Tip, 272 + Cv.TextWidth(tx_TIP + ' ') + 8, y, AW - 362 - Cv.TextWidth(tx_TIP + ' ') - 8, 34, 2);
          y := y + h;
        end;
        y := y + 40;
      end;
    if P.Days[i].Food <> '' then
      InfoBox(Cv, 90, Max(y, AH - 330), AW - 180, tx_FOOD_T, P.Days[i].Food, Hex('#db2777'));
  end
  else
  begin
    Cv.Brush.Color := Hex('#1d7874');
    Cv.FillRect(0, 0, AW, 260);
    Pen(Cv, 30, True, Mix(Hex('#1d7874'), clWhite, 0.7));
    Cv.TextOut(90, 70, UTF8UpperCase(PlaceLine(P)));
    Pen(Cv, 58, True, clWhite);
    Cv.TextOut(90, 110, tx_TIPS_T);
    y := 330;
    for i := 0 to High(P.Tips) do
    begin
      if y > AH - 300 then Break;
      Card(Cv, Rect(90, y, 130, y + 40), Hex('#e6f2f1'), Hex('#1d7874'), 10);
      Pen(Cv, 24, True, Hex('#1d7874'));
      Cv.TextOut(110 - Cv.TextWidth('✓') div 2, y + 6, '✓');
      Pen(Cv, 28, False, Hex('#1f2933'));
      y := y + Para(Cv, P.Tips[i], 160, y + 2, AW - 250, 40, 4) + 34;
    end;
    InfoBox(Cv, 90, Max(y + 20, AH - 360), AW - 180, tx_ABOUT_PLAN, tx_PLAN_NOTE, Hex('#64748b'));
  end;
  PageFooter(Cv, P, Page);
end;

function NewBitmap(W, H: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(W, H);
end;

procedure SavePNG(B: TBitmap; const FileName: string);
var
  Png: TPortableNetworkGraphic;
begin
  Png := TPortableNetworkGraphic.Create;
  try
    Png.Assign(B);
    Png.SaveToFile(FileName);
  finally
    Png.Free;
  end;
end;

{ El dosier en PDF: cada página dibujada y metida como imagen (JPEG). }
procedure WritePDF(const P: TPlan; const FileName: string);
var
  Doc: TPDFDocument;
  Sec: TPDFSection;
  Pg: TPDFPage;
  B: TBitmap;
  J: TJPEGImage;
  Tmp: string;
  i, ix: Integer;
begin
  Doc := TPDFDocument.Create(nil);
  try
    Doc.Options := [poUseRawJPEG];   // el origen, abajo a la izquierda: la imagen ocupa la página entera
    Doc.DefaultPaperType := ptA4;
    Doc.DefaultUnitOfMeasure := uomMillimeters;
    Doc.Infos.Title := P.Title;
    Doc.Infos.Producer := 'DMarlon Studio';
    Doc.StartDocument;
    Sec := Doc.Sections.AddSection;
    for i := 0 to PageCount(P) - 1 do
    begin
      B := NewBitmap(AW, AH);
      J := TJPEGImage.Create;
      try
        RenderPage(B.Canvas, P, i);
        J.CompressionQuality := 88;
        J.Assign(B);
        Tmp := GetTempDir + 'dms-viaje-' + IntToStr(GetProcessID) + '-' + IntToStr(i) + '.jpg';
        J.SaveToFile(Tmp);
      finally
        J.Free;
        B.Free;
      end;
      ix := Doc.Images.AddFromFile(Tmp, False);
      DeleteFile(Tmp);
      Pg := Doc.Pages.AddPage;
      Sec.AddPage(Pg);
      Pg.DrawImage(0, 0, 210.0, 297.0, ix);
    end;
    Doc.SaveToFile(FileName);
  finally
    Doc.Free;
  end;
end;

{ El dosier en imágenes: una PNG por página («<base> - página 1.png»…).
  Devuelve los archivos escritos. }
function WritePages(const P: TPlan; const FileName: string): TStringArray;
var
  B: TBitmap;
  Base, F: string;
  i: Integer;
begin
  Result := nil;
  Base := ChangeFileExt(FileName, '');
  B := NewBitmap(AW, AH);
  try
    for i := 0 to PageCount(P) - 1 do
    begin
      RenderPage(B.Canvas, P, i);
      F := Fmt(tx_PAGE_FILE, [Base, IntToStr(i + 1)]) + '.png';
      SavePNG(B, F);
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := F;
    end;
  finally
    B.Free;
  end;
end;

// ------------------------------------------------------------ la vista previa
{ La vista previa en R: la imagen vertical entera, o las páginas una
  debajo de otra (desplazadas [Scroll] píxeles). }
procedure PaintPreview(Cv: TCanvas; R: TRect; Poster: TBitmap; const Pages: array of TBitmap;
  Dossier: Boolean; Scroll: Integer);
var
  w, h, x, y, i: Integer;
begin
  Cv.Brush.Style := bsSolid;
  Cv.Brush.Color := Hex('#e3e8ef');
  Cv.FillRect(R);
  if not Dossier then
  begin
    if Poster = nil then Exit;
    h := R.Bottom - R.Top - 48;
    w := Round(h * PW / PH);
    x := (R.Left + R.Right - w) div 2;
    y := R.Top + 24;
    Cv.Brush.Color := Hex('#c7ced8');
    Cv.FillRect(x + 6, y + 8, x + w + 6, y + h + 8);
    Cv.StretchDraw(Rect(x, y, x + w, y + h), Poster);
    Exit;
  end;
  w := Min(R.Right - R.Left - 80, 600);
  h := Round(w * AH / AW);
  x := (R.Left + R.Right - w) div 2;
  y := R.Top + 24 - Scroll;
  for i := 0 to High(Pages) do
  begin
    if (y + h > R.Top) and (y < R.Bottom) then
    begin
      Cv.Brush.Color := Hex('#c7ced8');
      Cv.FillRect(x + 5, y + 7, x + w + 5, y + h + 7);
      Cv.StretchDraw(Rect(x, y, x + w, y + h), Pages[i]);
    end;
    y := y + h + 24;
  end;
end;

function DossierHeight(n, Width: Integer): Integer;
var
  w: Integer;
begin
  w := Min(Width - 80, 600);
  Result := n * (Round(w * AH / AW) + 24) + 24;
end;

// ============================================================ el ejemplo
function SamplePlan: TPlan;
begin
  if not ParsePlanText(tx_SAMPLE, Result) then Result := Default(TPlan);
end;

// ============================================================ capturas y pruebas
type
  { Para probar el hilo como lo usa la ventana. }
  TJobProbe = class
    Done: Boolean;
    Output: string;
    procedure JobDone(Sender: TObject);
  end;

procedure TJobProbe.JobDone(Sender: TObject);
begin
  Output := TClaudeJob(Sender).Output;
  Done := True;
end;

{ Un campo como los de la ventana, para las capturas. }
procedure FakeField(Cv: TCanvas; X, Y, W: Integer; const L, V: string);
begin
  Pen(Cv, 13, True, Hex('#52606d'));
  Cv.TextOut(X, Y, L);
  Card(Cv, Rect(X, Y + 20, X + W, Y + 50), clWhite, Hex('#cbd2d9'), 8);
  Pen(Cv, 14, False, Hex('#1f2933'));
  Cv.TextOut(X + 10, Y + 27, V);
end;

procedure FakeCheck(Cv: TCanvas; X, Y: Integer; const L: string; On_, Round_: Boolean);
begin
  if Round_ then
  begin
    Dot(Cv, X + 8, Y + 9, 8, Hex('#9aa5b1'));
    Dot(Cv, X + 8, Y + 9, 7, clWhite);
    if On_ then Dot(Cv, X + 8, Y + 9, 4, Hex('#1d7874'));
  end
  else
  begin
    if On_ then Card(Cv, Rect(X, Y + 1, X + 17, Y + 18), Hex('#1d7874'), Hex('#1d7874'), 5)
    else Card(Cv, Rect(X, Y + 1, X + 17, Y + 18), clWhite, Hex('#9aa5b1'), 5);
    if On_ then
    begin
      Pen(Cv, 13, True, clWhite);
      Cv.TextOut(X + 3, Y + 2, '✓');
    end;
  end;
  Pen(Cv, 14, False, Hex('#1f2933'));
  Cv.TextOut(X + 26, Y + 1, L);
end;

{ La ventana, dibujada (para la web): el panel de la izquierda y la vista previa. }
procedure WindowShot(const FileName: string; const P: TPlan; Dossier: Boolean);
const
  W = 1180; H = 760; SW = 360;
var
  B, Po: TBitmap;
  Pg: array of TBitmap;
  i: Integer;
  S: string;
begin
  B := NewBitmap(W, H);
  Po := nil;
  Pg := nil;
  try
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(0, 0, W, H);
    Pen(B.Canvas, 22, True, Hex('#1f2933'));
    B.Canvas.TextOut(24, 22, tx_YOUR_TRIP);
    FakeField(B.Canvas, 24, 70, SW - 48, tx_L_ORIGIN, P.Origin);
    FakeField(B.Canvas, 24, 132, SW - 48, tx_L_DEST, P.Dest);
    FakeField(B.Canvas, 24, 194, 90, tx_L_DAYS, IntToStr(Length(P.Days)));
    FakeField(B.Canvas, 130, 194, 100, tx_L_PACE, tx_PACE_2);
    FakeField(B.Canvas, 246, 194, SW - 270, tx_L_BUDGET, tx_BUD_2);
    Pen(B.Canvas, 13, True, Hex('#52606d'));
    B.Canvas.TextOut(24, 262, tx_L_LIKES);
    FakeCheck(B.Canvas, 24, 286, tx_LIKE_HISTORY, True, False);
    FakeCheck(B.Canvas, 204, 286, tx_LIKE_ART, True, False);
    FakeCheck(B.Canvas, 24, 314, tx_LIKE_FOOD, True, False);
    FakeCheck(B.Canvas, 204, 314, tx_LIKE_NATURE, False, False);
    FakeCheck(B.Canvas, 24, 342, tx_LIKE_NIGHT, False, False);
    FakeCheck(B.Canvas, 204, 342, tx_LIKE_KIDS, False, False);
    Pen(B.Canvas, 13, True, Hex('#52606d'));
    B.Canvas.TextOut(24, 386, tx_L_FORMAT);
    FakeCheck(B.Canvas, 24, 410, tx_FORMAT_IMAGE, not Dossier, True);
    FakeCheck(B.Canvas, 204, 410, tx_FORMAT_DOSSIER, Dossier, True);
    Card(B.Canvas, Rect(24, 460, SW - 24, 506), Hex('#d97757'), Hex('#d97757'), 12);
    Pen(B.Canvas, 15, True, clWhite);
    B.Canvas.TextOut((SW - B.Canvas.TextWidth(tx_BTN_PLAN)) div 2, 474, tx_BTN_PLAN);
    Card(B.Canvas, Rect(24, 518, SW - 24, 556), Hex('#f5f7fa'), Hex('#cbd2d9'), 12);
    Pen(B.Canvas, 14, False, Hex('#1f2933'));
    B.Canvas.TextOut((SW - B.Canvas.TextWidth(tx_BTN_SAVE)) div 2, 528, tx_BTN_SAVE);
    Pen(B.Canvas, 12, False, Hex('#7b8794'));
    Para(B.Canvas, tx_SIDE_NOTE, 24, 580, SW - 48, 18, 6);
    Po := NewBitmap(PW, PH);
    RenderPoster(Po.Canvas, P);
    if Dossier then
    begin
      SetLength(Pg, 2);
      for i := 0 to 1 do
      begin
        Pg[i] := NewBitmap(AW, AH);
        RenderPage(Pg[i].Canvas, P, i);
      end;
    end;
    PaintPreview(B.Canvas, Rect(SW, 0, W, H - 24), Po, Pg, Dossier, 0);
    B.Canvas.Brush.Color := Hex('#eceff3');
    B.Canvas.FillRect(0, H - 24, W, H);
    Pen(B.Canvas, 12, False, Hex('#3e4c59'));
    if Dossier then S := Fmt(tx_PAGES, [IntToStr(PageCount(P))]) else S := tx_POSTER_SIZE;
    B.Canvas.TextOut(10, H - 19, Fmt(tx_STATUS_READY, [PlaceLine(P), DaysText(Length(P.Days))]) + '  ·  ' + S);
    SavePNG(B, FileName);
  finally
    for i := 0 to High(Pg) do Pg[i].Free;
    Po.Free;
    B.Free;
  end;
end;

{ DMS_TRAVEL_SHOT=carpeta: las capturas de la web, sin ventana. }
function Shots(const Dir: string): Integer;
var
  P: TPlan;
  B: TBitmap;
begin
  ForceDirectories(Dir);
  P := SamplePlan;
  WindowShot(Dir + '/window.png', P, False);
  WindowShot(Dir + '/dossier.png', P, True);
  B := NewBitmap(PW, PH);
  try
    RenderPoster(B.Canvas, P);
    SavePNG(B, Dir + '/poster.png');
  finally
    B.Free;
  end;
  B := NewBitmap(AW, AH);
  try
    RenderPage(B.Canvas, P, 0);
    SavePNG(B, Dir + '/page-cover.png');
    RenderPage(B.Canvas, P, 2);
    SavePNG(B, Dir + '/page-day.png');
    RenderPage(B.Canvas, P, PageCount(P) - 1);
    SavePNG(B, Dir + '/page-tips.png');
  finally
    B.Free;
  end;
  WritePDF(P, Dir + '/dosier.pdf');
  WriteLn('shots ok ', Dir);
  Result := 0;
end;

{ Sin ventana: DMS_TRAVEL_SELFTEST=1. Con DMS_TRAVEL_LIVE=1, además pide a
  Claude Code un plan de verdad (Madrid → Oporto, 2 días). }
function SelfTest: Integer;
var
  fails: Integer;
  P, Q: TPlan;
  B: TBitmap;
  Err, Out_, E2, Pdf, S: string;
  F: TFileStream;
  D: TJSONData;
  JS: TJSONString;
  k: Integer;
  procedure Check(Ok: Boolean; const What: string);
  begin
    if not Ok then
    begin
      WriteLn('FAIL ', What);
      Inc(fails);
    end;
  end;
begin
  fails := 0;
  Check(Fmt('{0} y {1} y {0}', ['a', 'b']) = 'a y b y a', 'Fmt');
  // El esquema es JSON de verdad.
  D := GetJSON(SCHEMA);
  Check(D is TJSONObject, 'esquema JSON');
  D.Free;
  // El ejemplo.
  P := SamplePlan;
  Check(Length(P.Days) = 3, 'ejemplo: tres días');
  Check((P.Dest <> '') and (P.Origin <> '') and (Length(P.Tips) >= 3), 'ejemplo: destino, origen y consejos');
  Check(Length(P.Days[0].Stops) >= 3, 'ejemplo: lugares');
  // Guardar y volver a leer.
  Check(ParsePlanText(PlanJSON(P), Q) and (Q.Dest = P.Dest) and (Length(Q.Days) = 3) and
    (Q.Days[1].Stops[0].Name = P.Days[1].Stops[0].Name) and (Q.Origin = P.Origin), 'JSON de ida y vuelta');
  // Lo que devuelve Claude Code.
  Check(ParseClaude('{"type":"result","is_error":false,"result":"","structured_output":' + PlanJSON(P) + '}', Q, Err)
    and (Length(Q.Days) = 3), 'salida de Claude: structured_output');
  JS := TJSONString.Create(PlanJSON(P));
  Check(ParseClaude('{"type":"result","is_error":false,"result":' + JS.AsJSON + '}', Q, Err)
    and (Length(Q.Days) = 3), 'salida de Claude: result como texto');
  JS.Free;
  Check(not ParseClaude('{"type":"result","is_error":true,"result":"Not logged in"}', Q, Err) and
    (Pos('Not logged in', Err) > 0), 'salida de Claude: error');
  Check(not ParseClaude('no es json', Q, Err) and (Err = tx_ERR_ANSWER), 'salida rota');
  Check(KindIndex('museum') = 1, 'tipo de lugar');
  Check(StripDay('Día 1: El casco viejo') = 'El casco viejo', 'título sin «Día 1:»');
  Check(StripDay('Belém: el río') = 'Belém: el río', 'título con dos puntos');
  Check(StripLead(tx_FOOD_T + ', una francesinha', tx_FOOD_T) = 'Una francesinha', 'comida sin «Para comer»');
  Check(KindIndex('raro') = High(KINDS), 'tipo desconocido');
  S := BuildPrompt('Madrid', 'Lisboa', 3, 'arte', 'normal', 'medio');
  Check((Pos('Lisboa', S) > 0) and (Pos('Madrid', S) > 0) and (Pos('3', S) > 0) and (Pos('{', S) = 0), 'el encargo');
  // Dibujar: la imagen vertical cabe y las páginas salen.
  B := NewBitmap(PW, PH);
  try
    Check(PosterLevel(B.Canvas, P) <= 1, 'la imagen vertical lleva las descripciones');
    RenderPoster(B.Canvas, P);
    Check(B.Canvas.Pixels[10, 10] <> B.Canvas.Pixels[10, PH - 10], 'la imagen vertical tiene cabecera');
  finally
    B.Free;
  end;
  // Un plan largo también cabe (con menos detalle).
  Q := P;
  SetLength(Q.Days, 7);
  Q.Days[3] := P.Days[0]; Q.Days[4] := P.Days[1]; Q.Days[5] := P.Days[2]; Q.Days[6] := P.Days[0];
  B := NewBitmap(PW, PH);
  try
    RenderPoster(B.Canvas, Q);
    Check(PosterLevel(B.Canvas, Q) >= 2, 'siete días: sin descripciones');
  finally
    B.Free;
  end;
  Check(PageCount(P) = 5, 'páginas del dosier');
  // El dosier en imágenes: una PNG por página.
  with TStringList.Create do
  try
    AddStrings(WritePages(P, GetTempDir + 'dms-viaje-test.png'));
    Check(Count = 5, 'cinco imágenes');
    if Count = 5 then
    begin
      Check(FileExists(Strings[0]) and FileExists(Strings[4]) and (Pos('1', ExtractFileName(Strings[0])) > 0), 'las imágenes existen');
      B := TBitmap.Create;
      try
        with TPortableNetworkGraphic.Create do
        try
          LoadFromFile(Strings[1]);
          Check((Width = AW) and (Height = AH), 'tamaño de la página');
        finally
          Free;
        end;
      finally
        B.Free;
      end;
    end;
    for k := 0 to Count - 1 do DeleteFile(Strings[k]);
  finally
    Free;
  end;
  // El hilo, como en la ventana: termina, avisa y se libera solo (con /bin/echo
  // en lugar de claude: escribe los argumentos, entre ellos --json-schema).
  {$IFNDEF WINDOWS}
  with TJobProbe.Create do
  try
    with TClaudeJob.Create(True) do
    begin
      FreeOnTerminate := True;
      Exe := '/bin/echo';
      Prompt := '';
      OnTerminate := @JobDone;
      Start;
    end;
    k := 0;
    while (not Done) and (k < 100) do
    begin
      CheckSynchronize(100);
      Inc(k);
    end;
    Check(Done and (Pos('--json-schema', Output) > 0), 'el hilo de Claude termina y avisa');
  finally
    Free;
  end;
  {$ENDIF}
  Pdf := GetTempDir + 'dms-viaje-test.pdf';
  WritePDF(P, Pdf);
  Check(FileExists(Pdf), 'PDF escrito');
  if FileExists(Pdf) then
  begin
    F := TFileStream.Create(Pdf, fmOpenRead);
    try
      SetLength(S, 5);
      F.ReadBuffer(S[1], 5);
      Check(S = '%PDF-', 'cabecera del PDF');
      Check(F.Size > 50000, 'el PDF lleva las páginas');
    finally
      F.Free;
    end;
    SetLength(S, 0);
    with TStringList.Create do
    try
      LoadFromFile(Pdf);
      S := Text;
    finally
      Free;
    end;
    Check(Pos('/Count 5', S) > 0, 'cinco páginas en el PDF');
    DeleteFile(Pdf);
  end;
  // De verdad, con Claude Code.
  if GetEnvironmentVariable('DMS_TRAVEL_LIVE') <> '' then
  begin
    S := FindClaude;
    Check(S <> '', 'encontrar claude');
    if S <> '' then
    begin
      RunClaude(S, BuildPrompt('Madrid', 'Oporto', 2, tx_LIKE_HISTORY + ', ' + tx_LIKE_FOOD, tx_PACE_2, tx_BUD_2), Out_, E2, nil);
      Check(ParseClaude(Out_, Q, Err), 'plan de Claude: ' + Err + ' ' + Copy(E2, 1, 300));
      Check(Length(Q.Days) = 2, 'plan de Claude: dos días');
      if Length(Q.Days) > 0 then
        WriteLn('live: ', Q.Title, ' · ', Length(Q.Days), ' días · ', Q.Days[0].Stops[0].Name);
      Q.Origin := 'Madrid';
      B := NewBitmap(PW, PH);
      try
        RenderPoster(B.Canvas, Q);
        if GetEnvironmentVariable('DMS_TRAVEL_LIVE_OUT') <> '' then
        begin
          SavePNG(B, GetEnvironmentVariable('DMS_TRAVEL_LIVE_OUT') + '/live-poster.png');
          WritePDF(Q, GetEnvironmentVariable('DMS_TRAVEL_LIVE_OUT') + '/live-dosier.pdf');
          with TStringList.Create do
          try
            Text := PlanJSON(Q);
            SaveToFile(GetEnvironmentVariable('DMS_TRAVEL_LIVE_OUT') + '/live-plan.json');
          finally
            Free;
          end;
        end;
      finally
        B.Free;
      end;
    end;
  end;
  if fails = 0 then WriteLn('selftest ok');
  if fails = 0 then Result := 0 else Result := 1;
end;

// ============================================================ la ventana
procedure TForm1.form_create;
begin
  StageHint.Visible := False;
  if GetEnvironmentVariable('DMS_TRAVEL_SELFTEST') <> '' then Halt(SelfTest);
  if GetEnvironmentVariable('DMS_TRAVEL_SHOT') <> '' then
    Halt(Shots(GetEnvironmentVariable('DMS_TRAVEL_SHOT')));
  Stage.BevelOuter := bvNone;
  Stage.DoubleBuffered := True;
  Side.BevelOuter := bvNone;
  DoubleBuffered := True;
  Box := TPaintBox.Create(Self);
  Box.Parent := Stage;
  Box.Align := alClient;
  Box.OnPaint := @BoxPaint;
  Box.OnMouseWheel := @BoxWheel;
  Side.Anchors := [akLeft, akTop, akBottom];
  Stage.Anchors := [akLeft, akTop, akRight, akBottom];
  ChkHistory.Checked := True;
  ChkArt.Checked := True;
  ChkFood.Checked := True;
  RadImage.Checked := True;
  if Days.ItemIndex < 0 then Days.ItemIndex := 2;
  if Pace.ItemIndex < 0 then Pace.ItemIndex := 1;
  if Budget.ItemIndex < 0 then Budget.ItemIndex := 1;
  Tick.Enabled := False;
  SetPlan(SamplePlan, True);
  Origin.Text := Plan.Origin;
  Dest.Text := Plan.Dest;
  Say(tx_SAMPLE_HINT);
end;

procedure TForm1.form_close;
begin
  StopJob := True;
  FreeImages;
end;

function TForm1.Dossier: Boolean;
begin
  Result := RadDossier.Checked;
end;

procedure TForm1.Say(const T: string);
begin
  Status.SimpleText := ' ' + T;
end;

procedure TForm1.FreeImages;
var
  i: Integer;
begin
  FreeAndNil(Poster);
  for i := 0 to High(Pages) do Pages[i].Free;
  Pages := nil;
end;

{ Dibuja otra vez la imagen y las páginas con el plan. }
procedure TForm1.Rebuild;
var
  i: Integer;
begin
  FreeImages;
  Poster := NewBitmap(PW, PH);
  RenderPoster(Poster.Canvas, Plan);
  SetLength(Pages, PageCount(Plan));
  for i := 0 to High(Pages) do
  begin
    Pages[i] := NewBitmap(AW, AH);
    RenderPage(Pages[i].Canvas, Plan, i);
  end;
  FScroll := 0;
  Box.Invalidate;
end;

procedure TForm1.SetPlan(const P: TPlan; Sample: Boolean);
begin
  Plan := P;
  IsSample := Sample;
  Rebuild;
end;

procedure TForm1.BoxPaint(Sender: TObject);
var
  S: string;
  secs: Integer;
begin
  PaintPreview(Box.Canvas, Rect(0, 0, Box.Width, Box.Height), Poster, Pages, Dossier, FScroll);
  if Busy then
  begin
    secs := Round((Now - Started) * 86400);
    Card(Box.Canvas, Rect(Box.Width div 2 - 230, Box.Height div 2 - 60, Box.Width div 2 + 230,
      Box.Height div 2 + 60), clWhite, Hex('#cbd2d9'), 18);
    Pen(Box.Canvas, 17, True, Hex('#1f2933'));
    S := Fmt(tx_BUSY, [Dest.Text]);
    Box.Canvas.TextOut((Box.Width - Box.Canvas.TextWidth(S)) div 2, Box.Height div 2 - 36, Fit(Box.Canvas, S, 420));
    Pen(Box.Canvas, 14, False, Hex('#52606d'));
    S := Fmt(tx_BUSY_TIME, [Format('%d:%.2d', [secs div 60, secs mod 60])]);
    Box.Canvas.TextOut((Box.Width - Box.Canvas.TextWidth(S)) div 2, Box.Height div 2 + 2, S);
    Dot(Box.Canvas, Box.Width div 2 - 30 + (secs mod 3) * 30, Box.Height div 2 + 36, 5, Hex('#d97757'));
  end;
end;

procedure TForm1.BoxWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint; var Handled: Boolean);
begin
  if not Dossier then Exit;
  FScroll := EnsureRange(FScroll - WheelDelta, 0, Max(0, DossierHeight(Length(Pages), Box.Width) - Box.Height));
  Box.Invalidate;
  Handled := True;
end;

{ Pide el plan a Claude Code (en otro hilo). }
procedure TForm1.StartPlan;
var
  Exe, Likes: string;
  procedure Like(C: TCheckBox; const T: string);
  begin
    if not C.Checked then Exit;
    if Likes <> '' then Likes := Likes + ', ';
    Likes := Likes + T;
  end;
begin
  if Busy then
  begin
    StopJob := True;
    Exit;
  end;
  if (Trim(Origin.Text) = '') or (Trim(Dest.Text) = '') then
  begin
    MessageDlg(tx_NEED_PLACES, mtInformation, [mbOK], 0);
    Exit;
  end;
  Exe := FindClaude;
  if Exe = '' then
  begin
    if MessageDlg(tx_NO_CLAUDE, mtWarning, [mbYes, mbNo], 0) = mrYes then
      OpenURL('https://claude.com/product/claude-code');
    Exit;
  end;
  Likes := '';
  Like(ChkHistory, tx_LIKE_HISTORY);
  Like(ChkArt, tx_LIKE_ART);
  Like(ChkFood, tx_LIKE_FOOD);
  Like(ChkNature, tx_LIKE_NATURE);
  Like(ChkNight, tx_LIKE_NIGHT);
  Like(ChkKids, tx_LIKE_KIDS);
  if Likes = '' then Likes := tx_LIKE_ALL;
  StopJob := False;
  Job := TClaudeJob.Create(True);
  // Se libera solo al terminar: liberarlo en su OnTerminate dejaría la
  // ventana esperando al hilo y el hilo a la ventana (la app se colgaba).
  Job.FreeOnTerminate := True;
  Job.Exe := Exe;
  Job.Prompt := BuildPrompt(Trim(Origin.Text), Trim(Dest.Text), Days.ItemIndex + 1, Likes, Pace.Text, Budget.Text);
  Job.OnTerminate := @JobDone;
  Busy := True;
  Started := Now;
  BtnPlan.Caption := tx_BTN_STOP;
  Tick.Interval := 500;
  Tick.Enabled := True;
  Say(Fmt(tx_BUSY, [Trim(Dest.Text)]));
  Job.Start;
  Box.Invalidate;
end;

procedure TForm1.JobDone(Sender: TObject);
var
  P: TPlan;
  Err, Out_, JobErr: string;
  secs: Integer;
begin
  Out_ := TClaudeJob(Sender).Output;
  JobErr := TClaudeJob(Sender).Error;
  Job := nil;
  Busy := False;
  Tick.Enabled := False;
  BtnPlan.Caption := tx_BTN_PLAN;
  secs := Round((Now - Started) * 86400);
  if ParseClaude(Out_, P, Err) then
  begin
    P.Origin := Trim(Origin.Text);
    SetPlan(P, False);
    Say(Fmt(tx_STATUS_DONE, [PlaceLine(P), DaysText(Length(P.Days)), IntToStr(secs)]));
  end
  else
  begin
    if JobErr = tx_CANCELLED then Err := tx_CANCELLED
    else if (Trim(Out_) = '') and (Trim(JobErr) <> '') then Err := Fmt(tx_ERR_CLAUDE, [Trim(JobErr)]);
    Say(Err);
    Box.Invalidate;
    if Err <> tx_CANCELLED then MessageDlg(Err, mtError, [mbOK], 0);
  end;
end;

{ Guarda la imagen (PNG) o el dosier (PDF), según el formato elegido. }
procedure TForm1.SaveAs(AsPages: Boolean);
var
  D: TSaveDialog;
  N: string;
begin
  D := TSaveDialog.Create(nil);
  try
    N := StringReplace(Plan.Dest, ' ', '-', [rfReplaceAll]);
    if Dossier and AsPages then
    begin
      D.Filter := tx_FILTER_PAGES;
      D.DefaultExt := 'png';
      D.FileName := Fmt(tx_FILE_DOSSIER, [N]) + '.png';
    end
    else if Dossier then
    begin
      // En PDF o en imágenes (una por página), según el tipo que se elija.
      D.Filter := tx_FILTER_PDF + '|' + tx_FILTER_PAGES;
      D.DefaultExt := 'pdf';
      D.FileName := Fmt(tx_FILE_DOSSIER, [N]) + '.pdf';
    end
    else
    begin
      D.Filter := tx_FILTER_PNG;
      D.DefaultExt := 'png';
      D.FileName := Fmt(tx_FILE_IMAGE, [N]) + '.png';
    end;
    D.Options := D.Options + [ofOverwritePrompt];
    if not D.Execute then Exit;
    try
      if Dossier and (AsPages or (D.FilterIndex = 2) or SameText(ExtractFileExt(D.FileName), '.png')) then
        Say(Fmt(tx_SAVED_PAGES, [IntToStr(Length(WritePages(Plan, D.FileName))), ExtractFilePath(D.FileName)]))
      else if Dossier then
      begin
        WritePDF(Plan, D.FileName);
        Say(Fmt(tx_SAVED, [D.FileName]));
      end
      else
      begin
        SavePNG(Poster, D.FileName);
        Say(Fmt(tx_SAVED, [D.FileName]));
      end;
    except
      on E: Exception do MessageDlg(Fmt(tx_SAVE_FAILED, [E.Message]), mtError, [mbOK], 0);
    end;
  finally
    D.Free;
  end;
end;

procedure TForm1.SavePlan;
var
  D: TSaveDialog;
begin
  D := TSaveDialog.Create(nil);
  try
    D.Filter := tx_FILTER_JSON;
    D.DefaultExt := 'json';
    D.FileName := StringReplace(Plan.Dest, ' ', '-', [rfReplaceAll]) + '.json';
    D.Options := D.Options + [ofOverwritePrompt];
    if not D.Execute then Exit;
    with TStringList.Create do
    try
      Text := PlanJSON(Plan);
      SaveToFile(D.FileName);
    finally
      Free;
    end;
    Say(Fmt(tx_SAVED, [D.FileName]));
  finally
    D.Free;
  end;
end;

procedure TForm1.OpenPlan;
var
  D: TOpenDialog;
  P: TPlan;
  S: TStringList;
begin
  D := TOpenDialog.Create(nil);
  S := TStringList.Create;
  try
    D.Filter := tx_FILTER_JSON;
    if not D.Execute then Exit;
    S.LoadFromFile(D.FileName);
    if not ParsePlanText(S.Text, P) then
    begin
      MessageDlg(tx_BAD_FILE, mtError, [mbOK], 0);
      Exit;
    end;
    SetPlan(P, False);
    Origin.Text := P.Origin;
    Dest.Text := P.Dest;
    Say(Fmt(tx_STATUS_READY, [PlaceLine(P), DaysText(Length(P.Days))]));
  finally
    S.Free;
    D.Free;
  end;
end;

procedure TForm1.Tick_timer;
begin
  if Busy and ((Now - Started) * 86400 > 480) then StopJob := True;
  Box.Invalidate;
end;

procedure TForm1.BtnPlan_click;
begin
  StartPlan;
end;

procedure TForm1.BtnSave_click;
begin
  SaveAs;
end;

procedure TForm1.RadImage_click;
begin
  FScroll := 0;
  Box.Invalidate;
end;

procedure TForm1.RadDossier_click;
begin
  FScroll := 0;
  Box.Invalidate;
end;

procedure TForm1.Dest_enter;
begin
  StartPlan;
end;

procedure TForm1.Menu1_click(const Item: string);
begin
  if Item = tx_MP_PLAN then StartPlan
  else if Item = tx_MP_SAVE then SaveAs
  else if Item = tx_MP_SAVE_PAGES then
  begin
    RadDossier.Checked := True;
    RadDossier_click;
    SaveAs(True);
  end
  else if Item = tx_MP_SAVE_JSON then SavePlan
  else if Item = tx_MP_OPEN_JSON then OpenPlan
  else if Item = tx_MP_SAMPLE then
  begin
    SetPlan(SamplePlan, True);
    Origin.Text := Plan.Origin;
    Dest.Text := Plan.Dest;
    Say(tx_SAMPLE_HINT);
  end
  else if Item = tx_MP_IMAGE then begin RadImage.Checked := True; RadImage_click; end
  else if Item = tx_MP_DOSSIER then begin RadDossier.Checked := True; RadDossier_click; end
  else if Item = tx_MP_QUIT then Close
  else if Item = tx_MP_HOW then MessageDlg(tx_HOW_TEXT, mtInformation, [mbOK], 0)
  else if Item = tx_MP_ABOUT then MessageDlg(tx_ABOUT_TEXT, mtInformation, [mbOK], 0);
end;

end.
''';
