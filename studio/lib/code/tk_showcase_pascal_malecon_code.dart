part of 'tk_examples.dart';

// El código en Pascal de «Bajo la Sombra del Malecón» (tk_showcase_pascal_malecon.dart):
// la unidad Form1.pas entera; el estudio pone los textos en «// @TEXTS».
const _maleconCode = r'''
// @TITLE
unit Form1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Menus, dms, design, Math, LazUTF8, IntfGraphics,
  GraphType, FPImage, FPWritePNG;

type
  TForm1 = class(TFormDesign)
  private
    Box: TPaintBox;
    procedure BoxPaint(Sender: TObject);
    procedure BoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    function ToVirtual(X, Y: Integer; out VX, VY: Integer): Boolean;
    procedure Redraw;
  public
    procedure form_create; override;
    procedure form_close; override;
    procedure form_key; override;
    procedure Tick_timer; override;
    procedure Menu1_click(const Item: string); override;
  end;

implementation

// Los textos (los traduce el estudio con el resto del ejemplo).
const
  // @TEXTS
  // ---- fin de los textos

// ============================================================ la pantalla VGA
// Una pantalla de 360×220 píxeles con una paleta de 256 colores, como en
// MS-DOS: cada imagen se dibuja entera (con su paleta propia) y se amplía
// tres veces sin suavizar.
const
  VW = 360;
  VH = 220;
  SCALE = 3;
  // Las zonas de la interfaz
  LIST_X = 4; LIST_Y = 30; LIST_W = 178; ROW_H = 10; MAX_ROWS = 6;
  SCENE_X = 4; SCENE_Y = 94; SW = 178; SH = 122;
  PORT_X = 190; PORT_Y = 16; PW = 62; PH = 72;
  INFO_X = 259;
  TEXT_X = 192; TEXT_Y = 94; TEXT_W = 160; TEXT_LINES = 8; LINE_H = 10;
  BTN_X: array[0..3] of Integer = (188, 273, 188, 273);
  BTN_Y: array[0..3] of Integer = (183, 183, 201, 201);
  BTN_W = 83; BTN_H = 16;

  Bayer: array[0..3, 0..3] of Byte = ((0, 8, 2, 10), (12, 4, 14, 6),
    (3, 11, 1, 9), (15, 7, 13, 5));

var
  Pix: array[0..VH - 1, 0..VW - 1] of Byte;
  PalRGB: array[0..255] of LongWord;
  PalN: Integer = 0;
  PalFull: Boolean = False;
  PalMax: Integer = 0;
  CX0, CY0, CX1, CY1, OX, OY: Integer;
  RndSeed: LongWord = 1;

// El índice de un color en la paleta de esta imagen (se añade si no está).
function C(RGB: LongWord): Byte;
var
  i, best, d, bd: Integer;
begin
  for i := 0 to PalN - 1 do
    if PalRGB[i] = RGB then Exit(i);
  if PalN < 256 then
  begin
    PalRGB[PalN] := RGB;
    Result := PalN;
    Inc(PalN);
    PalMax := Max(PalMax, PalN);
    Exit;
  end;
  // La paleta está llena: el más parecido (no debería pasar).
  PalFull := True;
  best := 0;
  bd := MaxInt;
  for i := 0 to 255 do
  begin
    d := Sqr(Integer((PalRGB[i] shr 16) and 255) - Integer((RGB shr 16) and 255)) +
      Sqr(Integer((PalRGB[i] shr 8) and 255) - Integer((RGB shr 8) and 255)) +
      Sqr(Integer(PalRGB[i] and 255) - Integer(RGB and 255));
    if d < bd then
    begin
      bd := d;
      best := i;
    end;
  end;
  Result := best;
end;

function Mix(A, B: LongWord; T: Double): LongWord;
var
  r, g, bl: Integer;
begin
  T := Max(0, Min(1, T));
  r := Round(((A shr 16) and 255) * (1 - T) + ((B shr 16) and 255) * T);
  g := Round(((A shr 8) and 255) * (1 - T) + ((B shr 8) and 255) * T);
  bl := Round((A and 255) * (1 - T) + (B and 255) * T);
  Result := (LongWord(r) shl 16) or (LongWord(g) shl 8) or LongWord(bl);
end;

procedure SetClip(X, Y, W, H: Integer);
begin
  CX0 := Max(0, X);
  CY0 := Max(0, Y);
  CX1 := Min(VW - 1, X + W - 1);
  CY1 := Min(VH - 1, Y + H - 1);
end;

procedure Seed(S: LongWord);
begin
  RndSeed := S * 2654435761 + 12345;
  if RndSeed = 0 then RndSeed := 1;
end;

function Rnd(N: Integer): Integer;
begin
  RndSeed := RndSeed xor (RndSeed shl 13);
  RndSeed := RndSeed xor (RndSeed shr 17);
  RndSeed := RndSeed xor (RndSeed shl 5);
  if N <= 0 then Exit(0);
  Result := Integer(RndSeed mod LongWord(N));
end;

procedure Pt(X, Y: Integer; Col: Byte);
begin
  X := X + OX;
  Y := Y + OY;
  if (X >= CX0) and (X <= CX1) and (Y >= CY0) and (Y <= CY1) then Pix[Y, X] := Col;
end;

procedure Bar(X, Y, W, H: Integer; Col: Byte);
var
  i, j, x0, y0, x1, y1: Integer;
begin
  x0 := Max(CX0, X + OX);
  y0 := Max(CY0, Y + OY);
  x1 := Min(CX1, X + OX + W - 1);
  y1 := Min(CY1, Y + OY + H - 1);
  for j := y0 to y1 do
    for i := x0 to x1 do
      Pix[j, i] := Col;
end;

// Un tramado ordenado (Bayer): T es la parte de color B.
procedure Dith(X, Y, W, H: Integer; A, B: Byte; T: Double);
var
  i, j, x0, y0, x1, y1, lim: Integer;
begin
  lim := Round(Max(0, Min(1, T)) * 16);
  x0 := Max(CX0, X + OX);
  y0 := Max(CY0, Y + OY);
  x1 := Min(CX1, X + OX + W - 1);
  y1 := Min(CY1, Y + OY + H - 1);
  for j := y0 to y1 do
    for i := x0 to x1 do
      if Bayer[j and 3, i and 3] < lim then Pix[j, i] := B else Pix[j, i] := A;
end;

// Un velo tramado de un color sobre lo que ya hay (luces y sombras).
procedure Shade(X, Y, W, H: Integer; Col: Byte; T: Double);
var
  i, j, x0, y0, x1, y1, lim: Integer;
begin
  lim := Round(Max(0, Min(1, T)) * 16);
  x0 := Max(CX0, X + OX);
  y0 := Max(CY0, Y + OY);
  x1 := Min(CX1, X + OX + W - 1);
  y1 := Min(CY1, Y + OY + H - 1);
  for j := y0 to y1 do
    for i := x0 to x1 do
      if Bayer[j and 3, i and 3] < lim then Pix[j, i] := Col;
end;

// Degradado vertical tramado entre varios colores.
procedure Ramp(X, Y, W, H: Integer; const Cols: array of LongWord);
var
  i, j, k, n, lim, x0, y0, x1, y1: Integer;
  f: Double;
  ca, cb: Byte;
begin
  n := Length(Cols);
  if n = 0 then Exit;
  x0 := Max(CX0, X + OX);
  y0 := Max(CY0, Y + OY);
  x1 := Min(CX1, X + OX + W - 1);
  y1 := Min(CY1, Y + OY + H - 1);
  for j := y0 to y1 do
  begin
    if (H > 1) and (n > 1) then f := (j - Y - OY) / (H - 1) * (n - 1) else f := 0;
    k := Min(Max(0, n - 2), Trunc(f));
    ca := C(Cols[k]);
    cb := C(Cols[Min(n - 1, k + 1)]);
    lim := Round((f - k) * 16);
    for i := x0 to x1 do
      if Bayer[j and 3, i and 3] < lim then Pix[j, i] := cb else Pix[j, i] := ca;
  end;
end;

procedure Oval(CX, CY, RX, RY: Integer; Col: Byte);
var
  y, w: Integer;
begin
  if (RX <= 0) or (RY <= 0) then
  begin
    Pt(CX, CY, Col);
    Exit;
  end;
  for y := -RY to RY do
  begin
    w := Round(RX * Sqrt(Max(0.0, 1 - Sqr(y / RY))));
    Bar(CX - w, CY + y, 2 * w + 1, 1, Col);
  end;
end;

// Un halo: óvalos tramados cada vez más densos hacia el centro.
procedure Glow(CX, CY, RX, RY: Integer; Col: Byte; T: Double);
var
  y, w, k: Integer;
begin
  for k := 3 downto 1 do
    for y := -RY * k div 3 to RY * k div 3 do
    begin
      w := Round(RX * k / 3 * Sqrt(Max(0.0, 1 - Sqr(y / Max(1, RY * k / 3)))));
      Shade(CX - w, CY + y, 2 * w + 1, 1, Col, T * (4 - k) / 3);
    end;
end;

// Polígono relleno (pares x, y), por líneas horizontales.
procedure Poly(const P: array of Integer; Col: Byte; Amount: Double = 1);
var
  n, i, j, y, ymin, ymax, cnt, t, x0, y0, x1, y1: Integer;
  xs: array[0..31] of Integer;
begin
  n := Length(P) div 2;
  if n < 3 then Exit;
  ymin := MaxInt;
  ymax := -MaxInt;
  for i := 0 to n - 1 do
  begin
    ymin := Min(ymin, P[2 * i + 1]);
    ymax := Max(ymax, P[2 * i + 1]);
  end;
  for y := ymin to ymax - 1 do
  begin
    cnt := 0;
    for i := 0 to n - 1 do
    begin
      j := (i + 1) mod n;
      x0 := P[2 * i]; y0 := P[2 * i + 1];
      x1 := P[2 * j]; y1 := P[2 * j + 1];
      if ((y0 <= y) and (y1 > y)) or ((y1 <= y) and (y0 > y)) then
        if cnt < 32 then
        begin
          xs[cnt] := Round(x0 + (y + 0.5 - y0) * (x1 - x0) / (y1 - y0));
          Inc(cnt);
        end;
    end;
    for i := 1 to cnt - 1 do
    begin
      t := xs[i];
      j := i - 1;
      while (j >= 0) and (xs[j] > t) do
      begin
        xs[j + 1] := xs[j];
        Dec(j);
      end;
      xs[j + 1] := t;
    end;
    i := 0;
    while i + 1 < cnt do
    begin
      if Amount >= 1 then Bar(xs[i], y, xs[i + 1] - xs[i] + 1, 1, Col)
      else Shade(xs[i], y, xs[i + 1] - xs[i] + 1, 1, Col, Amount);
      Inc(i, 2);
    end;
  end;
end;

procedure Seg(X0, Y0, X1, Y1: Integer; Col: Byte);
var
  dx, dy, sx, sy, err, e2: Integer;
begin
  dx := Abs(X1 - X0);
  dy := -Abs(Y1 - Y0);
  if X0 < X1 then sx := 1 else sx := -1;
  if Y0 < Y1 then sy := 1 else sy := -1;
  err := dx + dy;
  while True do
  begin
    Pt(X0, Y0, Col);
    if (X0 = X1) and (Y0 = Y1) then Break;
    e2 := 2 * err;
    if e2 >= dy then
    begin
      Inc(err, dy);
      Inc(X0, sx);
    end;
    if e2 <= dx then
    begin
      Inc(err, dx);
      Inc(Y0, sy);
    end;
  end;
end;

// Un cable que cuelga entre dos puntos.
procedure Cable(X0, Y0, X1, Y1, Sag: Integer; Col: Byte);
var
  k, px, py, nx, ny: Integer;
  t: Double;
begin
  px := X0;
  py := Y0;
  for k := 1 to 12 do
  begin
    t := k / 12;
    nx := Round(X0 + (X1 - X0) * t);
    ny := Round(Y0 + (Y1 - Y0) * t + Sag * 4 * t * (1 - t));
    Seg(px, py, nx, ny, Col);
    px := nx;
    py := ny;
  end;
end;

// Un panel en relieve, como los de las interfaces VGA.
procedure Bevel(X, Y, W, H: Integer; Face, Hi, Lo: Byte);
begin
  Bar(X, Y, W, H, Face);
  Bar(X, Y, W, 1, Hi);
  Bar(X, Y, 1, H, Hi);
  Bar(X, Y + H - 1, W, 1, Lo);
  Bar(X + W - 1, Y, 1, H, Lo);
end;

// ============================================================ letras
// Las letras salen de la fuente del sistema dibujada sin suavizar y
// convertida en píxeles (una vez por texto: se guardan).
type
  TMask = class
    W, H, Adv: Integer;
    Bits: array of Byte;
  end;

var
  Masks: TStringList = nil;
  Wraps: TStringList = nil;
  MaskBmp: TBitmap = nil;

const
{$IFDEF DARWIN}
  FONT_NAME = 'Geneva';
{$ELSE}
  FONT_NAME = 'MS Sans Serif';
{$ENDIF}

procedure FontFor(Big: Boolean);
begin
  if MaskBmp = nil then
  begin
    MaskBmp := TBitmap.Create;
    MaskBmp.SetSize(8, 8);
  end;
  MaskBmp.Canvas.Font.Name := FONT_NAME;
  MaskBmp.Canvas.Font.Quality := fqNonAntialiased;
  if Big then
  begin
    MaskBmp.Canvas.Font.Height := -12;
    MaskBmp.Canvas.Font.Style := [fsBold];
  end
  else
  begin
    MaskBmp.Canvas.Font.Height := -10;
    MaskBmp.Canvas.Font.Style := [];
  end;
end;

function GetMask(const S: string; Big: Boolean): TMask; forward;

// Ancho de un texto: la suma de lo que avanza cada letra.
function TextW(const S: string; Big: Boolean = False): Integer;
var
  p, e: PChar;
  n: Integer;
begin
  Result := 0;
  if S = '' then Exit;
  p := PChar(S);
  e := p + Length(S);
  while p < e do
  begin
    n := Max(1, UTF8CodepointSize(p));
    Inc(Result, GetMask(Copy(S, p - PChar(S) + 1, n), Big).Adv);
    Inc(p, n);
  end;
end;

function GetMask(const S: string; Big: Boolean): TMask;
var
  key: string;
  i, x, y, w, h, x0, x1: Integer;
  img: TLazIntfImage;
  m: TMask;
  bits: array of Byte;
begin
  key := Chr(Ord('0') + Ord(Big)) + S;
  if Masks = nil then
  begin
    Masks := TStringList.Create;
    Masks.Sorted := True;
    Masks.CaseSensitive := True;
    Masks.OwnsObjects := True;
  end;
  if Masks.Find(key, i) then Exit(TMask(Masks.Objects[i]));
  FontFor(Big);
  w := Max(1, MaskBmp.Canvas.TextWidth(S) + 6);
  h := MaskBmp.Canvas.TextHeight('ÁÑgy') + 1;
  MaskBmp.SetSize(w, h);
  FontFor(Big);
  MaskBmp.Canvas.Brush.Style := bsSolid;
  MaskBmp.Canvas.Brush.Color := clBlack;
  MaskBmp.Canvas.FillRect(0, 0, w, h);
  MaskBmp.Canvas.Font.Color := clWhite;
  MaskBmp.Canvas.Brush.Style := bsClear;
  MaskBmp.Canvas.TextOut(2, 0, S);
  // Los píxeles de la letra, recortada a lo ancho: avanza su ancho y uno
  // más de separación (el espacio, lo que mide en la fuente).
  SetLength(bits, w * h);
  x0 := w;
  x1 := -1;
  img := MaskBmp.CreateIntfImage;
  try
    for y := 0 to h - 1 do
      for x := 0 to w - 1 do
        if img.Colors[x, y].green > $7FFF then
        begin
          bits[y * w + x] := 1;
          x0 := Min(x0, x);
          x1 := Max(x1, x);
        end;
  finally
    img.Free;
  end;
  m := TMask.Create;
  m.H := h;
  if x1 < 0 then
  begin
    m.W := 0;
    if Big then m.Adv := 4 else m.Adv := 3;
  end
  else
  begin
    m.W := x1 - x0 + 1;
    m.Adv := m.W + 1;
    SetLength(m.Bits, m.W * h);
    for y := 0 to h - 1 do
      for x := 0 to m.W - 1 do
        m.Bits[y * m.W + x] := bits[y * w + x + x0];
  end;
  Masks.AddObject(key, m);
  Result := m;
end;

procedure Glyph(X, Y: Integer; m: TMask; Col: Byte);
var
  i, j: Integer;
begin
  for j := 0 to m.H - 1 do
    for i := 0 to m.W - 1 do
      if m.Bits[j * m.W + i] <> 0 then Pt(X + i, Y + j, Col);
end;

// Un texto letra a letra: cada una en su píxel entero, como en VGA.
procedure Txt(X, Y: Integer; const S: string; Col: Byte; Big: Boolean = False;
  Sh: Integer = -1);
var
  p, e: PChar;
  n, cx, pass: Integer;
  m: TMask;
begin
  if S = '' then Exit;
  for pass := 0 to 1 do
  begin
    if (pass = 0) and (Sh < 0) then Continue;
    cx := X;
    p := PChar(S);
    e := p + Length(S);
    while p < e do
    begin
      n := Max(1, UTF8CodepointSize(p));
      m := GetMask(Copy(S, p - PChar(S) + 1, n), Big);
      if pass = 0 then Glyph(cx + 1, Y + 1, m, Sh) else Glyph(cx, Y, m, Col);
      Inc(cx, m.Adv);
      Inc(p, n);
    end;
  end;
end;

procedure TxtC(CX, Y: Integer; const S: string; Col: Byte; Big: Boolean = False;
  Sh: Integer = -1);
begin
  Txt(CX - TextW(S, Big) div 2, Y, S, Col, Big, Sh);
end;

// Un texto partido en líneas de MaxW píxeles como mucho.
function Wrap(const S: string; MaxW: Integer; Big: Boolean = False): TStringList;
var
  key, para, word, line: string;
  paras: TStringList;
  i, p, k: Integer;
begin
  key := IntToStr(MaxW) + Chr(Ord('0') + Ord(Big)) + S;
  if Wraps = nil then
  begin
    Wraps := TStringList.Create;
    Wraps.Sorted := True;
    Wraps.CaseSensitive := True;
    Wraps.OwnsObjects := True;
  end;
  if Wraps.Find(key, k) then Exit(TStringList(Wraps.Objects[k]));
  Result := TStringList.Create;
  paras := TStringList.Create;
  try
    paras.Text := S;
    for i := 0 to paras.Count - 1 do
    begin
      para := paras[i] + ' ';
      line := '';
      while para <> '' do
      begin
        p := Pos(' ', para);
        word := Copy(para, 1, p - 1);
        Delete(para, 1, p);
        if (line <> '') and (TextW(line + ' ' + word, Big) > MaxW) then
        begin
          Result.Add(line);
          line := word;
        end
        else if line = '' then line := word
        else line := line + ' ' + word;
      end;
      Result.Add(line);
    end;
  finally
    paras.Free;
  end;
  Wraps.AddObject(key, Result);
end;

function Fmt(const S: string; const Args: array of string): string;
var
  i: Integer;
begin
  Result := S;
  for i := 0 to High(Args) do
    Result := StringReplace(Result, '{' + IntToStr(i) + '}', Args[i], [rfReplaceAll]);
end;

// ============================================================ el juego
type
  TLoc = (lMalecon, lPaladar, lAlley, lGate, lCargo, lBox, lShop, lRoof,
    lGarden, lServers, lOffice);
  TWho = (wNone, wMikel, wYari, wSocio, wValdes, wFisher, wGirl, wCook,
    wGuard, wRamiro);
  TItem = (itCell, itLithium, itPass, itUSB, itList);
  TItems = set of TItem;
  TClue = (clBoat, clDebt, clTerminal, clBirds, clOldTown, clFraud, clMiramar);
  TClues = set of TClue;
  TFlag = (fLookMal, fLookPal, fLookCargo, fLookBox1, fLookBox2, fGuardOK,
    fYariHint, fDecrypted, fCaught);
  TFlags = set of TFlag;
  TMode = (mGo, mTalk, mChoice, mNotes);
  TRowKind = (rkGo, rkHide, rkTalk, rkChoice, rkItem, rkClues, rkInfo);
  TLine = record
    Who: TWho;
    Text: string;
  end;
  TChoice = record
    Code: Integer;
    Text: string;
  end;
  TRow = record
    Kind: TRowKind;
    Val: Integer;
    Text: string;
  end;
  TLocs = array of TLoc;
  TWhos = array of TWho;

const
  A_NONE = 0; A_ACT2 = 1; A_ACT3 = 2; A_ACT4 = 3; A_CHOICES = 4; A_END = 5;
  CH_TRADE = 1; CH_CHARGE = 2; CH_BYE = 3; CH_DECRYPT = 4; CH_LATER = 5;
  CH_KEY = 100; CH_END = 200;
  // El listado del contenedor: el que está en la Habana Vieja es la clave.
  KEYS: array[0..4] of string = ('CEIBA', 'TOCORORO', 'GARZA', 'MANGLE', 'BRISA');
  KEY_POS: array[0..4] of string = ('23,118 / -82,421', '23,142 / -82,382',
    '23,136 / -82,359', '23,129 / -82,329', '23,085 / -82,355');
  KEY_OK = 2;
  DARK = [lMalecon, lPaladar, lAlley, lCargo, lBox, lRoof, lGarden];
  ALL_CLUES = 7;

var
  Act, Minutes, Battery, Alert, Signal, Ending, Tries, Banner, Anim: Integer;
  Loc: TLoc;
  Items: TItems;
  Flags: TFlags;
  Clues: TClues;
  Charged: array[1..4] of Boolean;
  Lines: array of TLine;
  LineAt, Typed, After: Integer;
  Choices: array of TChoice;
  Mode: TMode;
  Rows: array of TRow;
  LastWho: TWho;
  ShowEnd: Boolean;
  HoverRow: Integer = -1;
  HoverBtn: Integer = -1;
  MaxWrap: Integer = 0;   // las líneas del texto más largo (pruebas)

function LocName(L: TLoc): string;
begin
  case L of
    lMalecon: Result := tx_LOC_MALECON;
    lPaladar: Result := tx_LOC_PALADAR;
    lAlley: Result := tx_LOC_ALLEY;
    lGate: Result := tx_LOC_GATE;
    lCargo: Result := tx_LOC_CARGO;
    lBox: Result := tx_LOC_BOX;
    lShop: Result := tx_LOC_SHOP;
    lRoof: Result := tx_LOC_ROOF;
    lGarden: Result := tx_LOC_GARDEN;
    lServers: Result := tx_LOC_SERVERS;
    lOffice: Result := tx_LOC_OFFICE;
  end;
end;

function WhoName(W: TWho): string;
begin
  case W of
    wYari: Result := tx_P_YARI;
    wSocio: Result := tx_P_SOCIO;
    wValdes: Result := tx_P_VALDES;
    wFisher: Result := tx_P_FISHER;
    wGirl: Result := tx_P_GIRL;
    wCook: Result := tx_P_COOK;
    wGuard: Result := tx_P_GUARD;
    wRamiro: Result := tx_P_RAMIRO;
  else
    Result := tx_P_MIKEL;
  end;
end;

function WhoRole(W: TWho): string;
begin
  case W of
    wYari: Result := tx_R_YARI;
    wSocio: Result := tx_R_SOCIO;
    wValdes: Result := tx_R_VALDES;
    wFisher: Result := tx_R_FISHER;
    wGirl: Result := tx_R_GIRL;
    wCook: Result := tx_R_COOK;
    wGuard: Result := tx_R_GUARD;
    wRamiro: Result := tx_R_RAMIRO;
  else
    Result := tx_R_MIKEL;
  end;
end;

function ItemName(I: TItem): string;
begin
  case I of
    itCell: Result := tx_IT_CELL;
    itLithium: Result := tx_IT_LITHIUM;
    itPass: Result := tx_IT_PASS;
    itUSB: Result := tx_IT_USB;
    itList: Result := tx_IT_LIST;
  end;
end;

function ClueText(K: TClue): string;
begin
  case K of
    clBoat: Result := tx_CL_BOAT;
    clDebt: Result := tx_CL_DEBT;
    clTerminal: Result := tx_CL_TERMINAL;
    clBirds: Result := tx_CL_BIRDS;
    clOldTown: Result := tx_CL_OLDTOWN;
    clFraud: Result := tx_CL_FRAUD;
    clMiramar: Result := tx_CL_MIRAMAR;
  end;
end;

function ActTitle(A: Integer): string;
begin
  case A of
    1: Result := tx_ACT1;
    2: Result := tx_ACT2;
    3: Result := tx_ACT3;
  else
    Result := tx_ACT4;
  end;
end;

// Las coordenadas con el separador decimal del idioma.
function KeyPos(K: Integer): string;
begin
  Result := StringReplace(KEY_POS[K], ',', tx_DEC, [rfReplaceAll]);
end;

function ClueCount: Integer;
var
  k: TClue;
begin
  Result := 0;
  for k := Low(TClue) to High(TClue) do
    if k in Clues then Inc(Result);
end;

function ActLocs(A: Integer): TLocs;
begin
  case A of
    1: Result := TLocs.Create(lMalecon, lPaladar, lAlley);
    2: Result := TLocs.Create(lGate, lCargo, lBox);
    3: Result := TLocs.Create(lShop, lRoof, lAlley);
  else
    Result := TLocs.Create(lGarden, lServers);
  end;
end;

function PeopleAt(L: TLoc): TWhos;
begin
  case L of
    lMalecon:
      if Act = 1 then Result := TWhos.Create(wFisher, wGirl, wValdes)
      else Result := TWhos.Create(wFisher, wGirl);
    lPaladar: Result := TWhos.Create(wYari, wCook);
    lAlley: Result := TWhos.Create(wSocio);
    lGate: Result := TWhos.Create(wGuard, wValdes);
    lShop: Result := TWhos.Create(wYari);
    lServers: Result := TWhos.Create(wRamiro);
  else
    Result := nil;
  end;
end;

procedure Say(W: TWho; const S: string);
var
  n: Integer;
begin
  n := Length(Lines);
  SetLength(Lines, n + 1);
  Lines[n].Who := W;
  Lines[n].Text := S;
  MaxWrap := Max(MaxWrap, Wrap(S, TEXT_W).Count);
  if Wrap(S, TEXT_W).Count > TEXT_LINES then WriteLn('FAIL texto largo: ', S);
end;

function Busy: Boolean;
begin
  Result := LineAt < Length(Lines);
end;

function ChoiceText(Code: Integer): string;
begin
  case Code of
    CH_TRADE: Result := tx_C_TRADE;
    CH_CHARGE: Result := tx_C_CHARGE;
    CH_BYE: Result := tx_C_BYE;
    CH_DECRYPT: Result := tx_C_DECRYPT;
    CH_LATER: Result := tx_C_LATER;
    CH_END: Result := tx_C_LEAK;
    CH_END + 1: Result := tx_C_DEAL;
    CH_END + 2: Result := tx_C_POLICE;
  else
    if (Code >= CH_KEY) and (Code <= CH_KEY + 4) then Result := KEYS[Code - CH_KEY]
    else Result := '?';
  end;
end;

// Opciones para elegir: después de lo que se está diciendo, si hay algo.
procedure Offer(const Codes: array of Integer);
var
  i: Integer;
begin
  SetLength(Choices, Length(Codes));
  for i := 0 to High(Codes) do
  begin
    Choices[i].Code := Codes[i];
    Choices[i].Text := ChoiceText(Codes[i]);
  end;
  if Busy then After := A_CHOICES else Mode := mChoice;
end;

procedure StartAct(N: Integer);
begin
  Act := N;
  Banner := 30;
  Mode := mGo;
  Alert := 0;
  case N of
    1: Loc := lMalecon;
    2: Loc := lGate;
    3:
      begin
        Loc := lShop;
        Signal := 100;
      end;
  else
    Loc := lGarden;
  end;
  LastWho := wMikel;
end;

procedure NewGame;
begin
  Minutes := 21 * 60 + 10;
  Battery := 60;
  Alert := 0;
  Signal := 100;
  Ending := 0;
  Tries := 0;
  Items := [];
  Flags := [];
  Clues := [];
  FillChar(Charged, SizeOf(Charged), 0);
  SetLength(Lines, 0);
  LineAt := 0;
  Typed := 0;
  SetLength(Choices, 0);
  After := A_NONE;
  ShowEnd := False;
  StartAct(1);
  Say(wMikel, tx_N_INTRO1);
  Say(wMikel, tx_N_INTRO2);
  Say(wMikel, tx_N_INTRO3);
end;

procedure Spend(M: Integer);
begin
  Inc(Minutes, M);
  if (Act = 3) and not (fDecrypted in Flags) then Signal := Max(0, Signal - M div 3);
end;

procedure RaiseAlert(N: Integer);
begin
  Alert := Min(100, Alert + N);
  if Alert < 100 then Exit;
  Say(wMikel, tx_CAUGHT);
  Say(wValdes, tx_VALDES_FREE);
  Include(Flags, fCaught);
  Alert := 30;
  Loc := lGate;
  Spend(60);
end;

procedure RunAfter;
var
  a: Integer;
begin
  a := After;
  After := A_NONE;
  case a of
    A_ACT2: StartAct(2);
    A_ACT3: StartAct(3);
    A_ACT4: StartAct(4);
    A_CHOICES: Mode := mChoice;
    A_END: ShowEnd := True;
  end;
end;

// Clic o Intro: termina de escribir la línea o pasa a la siguiente.
procedure Advance;
begin
  if not Busy then Exit;
  if Typed < UTF8Length(Lines[LineAt].Text) then
  begin
    Typed := MaxInt div 2;
    Exit;
  end;
  LastWho := Lines[LineAt].Who;
  Inc(LineAt);
  Typed := 0;
  if not Busy then
  begin
    SetLength(Lines, 0);
    LineAt := 0;
    RunAfter;
  end;
end;

procedure Travel(L: TLoc);
begin
  if L = Loc then Exit;
  if (Act = 2) and (L in [lCargo, lBox]) and not (fGuardOK in Flags) then
  begin
    Say(wMikel, tx_GUARD_STOP);
    Exit;
  end;
  Loc := L;
  Spend(15);
  if (Act = 2) and (L in [lCargo, lBox]) then RaiseAlert(10);
end;

procedure TalkTo(W: TWho);
var
  codes: array of Integer;
begin
  Spend(10);
  case W of
    wFisher:
      begin
        Say(W, tx_FISHER_1);
        Say(W, tx_FISHER_2);
        Include(Clues, clBoat);
      end;
    wGirl: Say(W, tx_GIRL_1);
    wValdes:
      if Act = 1 then
      begin
        Say(W, tx_VALDES_1);
        Say(W, tx_VALDES_2);
      end
      else Say(W, tx_VALDES_GATE);
    wCook:
      begin
        Say(W, tx_COOK_1);
        Say(W, tx_COOK_2);
        Include(Clues, clDebt);
      end;
    wYari:
      if Act = 1 then
      begin
        Say(W, tx_YARI_1);
        Say(W, tx_YARI_2);
      end
      else
      begin
        if not (fYariHint in Flags) then
        begin
          Say(W, tx_YARI_SHOP_1);
          Say(W, tx_YARI_SHOP_2);
          Include(Flags, fYariHint);
          Include(Clues, clOldTown);
        end
        else Say(W, tx_YARI_SHOP_3);
        Offer([CH_DECRYPT, CH_LATER]);
      end;
    wSocio:
      begin
        codes := nil;
        if Act = 1 then
        begin
          Say(W, tx_SOCIO_1);
          if (itCell in Items) and (itLithium in Items) then
          begin
            SetLength(codes, 1);
            codes[0] := CH_TRADE;
          end
          else Say(W, tx_SOCIO_NO);
        end
        else
        begin
          Say(W, tx_SOCIO_BIRDS);
          Include(Clues, clBirds);
        end;
        if not Charged[Act] and (Battery < 100) then
        begin
          SetLength(codes, Length(codes) + 1);
          codes[High(codes)] := CH_CHARGE;
        end;
        SetLength(codes, Length(codes) + 1);
        codes[High(codes)] := CH_BYE;
        Offer(codes);
      end;
    wGuard:
      if not (fGuardOK in Flags) then
      begin
        Say(W, tx_GUARD_1);
        Include(Flags, fGuardOK);
      end
      else Say(W, tx_GUARD_2);
    wRamiro:
      begin
        Say(W, tx_RAMIRO_1);
        Say(W, tx_RAMIRO_2);
        Offer([CH_END, CH_END + 1, CH_END + 2]);
      end;
  end;
end;

procedure Look;
begin
  Spend(15);
  if Loc in DARK then
  begin
    if Battery < 10 then
    begin
      Say(wMikel, tx_NO_BATTERY);
      Exit;
    end;
    Dec(Battery, 10);
  end;
  case Loc of
    lMalecon:
      if not (fLookMal in Flags) then
      begin
        Include(Flags, fLookMal);
        Include(Items, itCell);
        Say(wMikel, tx_LOOK_MALECON);
      end
      else Say(wMikel, tx_LOOK_MALECON_2);
    lPaladar:
      if not (fLookPal in Flags) then
      begin
        Include(Flags, fLookPal);
        Include(Items, itLithium);
        Say(wMikel, tx_LOOK_PALADAR);
      end
      else Say(wMikel, tx_NOTHING);
    lAlley: Say(wMikel, tx_LOOK_ALLEY);
    lGate: Say(wMikel, tx_LOOK_GATE);
    lCargo:
      begin
        if not (fLookCargo in Flags) then
        begin
          Include(Flags, fLookCargo);
          Include(Items, itUSB);
          Say(wMikel, tx_LOOK_CARGO);
        end
        else Say(wMikel, tx_NOTHING);
        RaiseAlert(25);
      end;
    lBox:
      begin
        if not (fLookBox1 in Flags) then
        begin
          Include(Flags, fLookBox1);
          Include(Clues, clTerminal);
          Say(wMikel, tx_LOOK_BOX_1);
        end
        else if not (fLookBox2 in Flags) then
        begin
          Include(Flags, fLookBox2);
          Include(Items, itList);
          Say(wMikel, tx_LOOK_BOX_2);
        end
        else Say(wMikel, tx_NOTHING);
        RaiseAlert(20);
      end;
    lShop: Say(wMikel, tx_LOOK_SHOP);
    lRoof:
      begin
        Include(Clues, clMiramar);
        if (Signal < 100) and not (fDecrypted in Flags) then
        begin
          Signal := 100;
          Say(wMikel, tx_LOOK_ROOF);
        end
        else Say(wMikel, tx_LOOK_ROOF_OK);
      end;
    lGarden:
      begin
        Include(Clues, clMiramar);
        Say(wMikel, tx_LOOK_GARDEN);
      end;
    lServers: Say(wMikel, tx_LOOK_SERVERS);
  end;
end;

procedure Hide;
begin
  Alert := Max(0, Alert - 40);
  Spend(20);
  Say(wMikel, tx_HIDE_DONE);
end;

procedure TryKey(K: Integer);
begin
  Spend(10);
  if K = KEY_OK then
  begin
    Include(Flags, fDecrypted);
    Include(Clues, clFraud);
    Say(wYari, tx_RIGHT);
    Say(wYari, tx_TWIST_1);
    Say(wYari, tx_TWIST_2);
    Say(wYari, tx_TWIST_3);
    After := A_ACT4;
    Exit;
  end;
  Inc(Tries);
  Signal := Max(0, Signal - 25);
  Say(wYari, tx_WRONG);
  if Signal <= 0 then Say(wYari, tx_SIGNAL_LOST)
  else
  begin
    Say(wYari, tx_YARI_SHOP_3);
    Offer([CH_DECRYPT, CH_LATER]);
  end;
end;

procedure Finish(K: Integer);
begin
  Ending := K + 1;
  case K of
    0:
      begin
        Loc := lRoof;
        Say(wMikel, tx_END_A_1);
        Say(wMikel, tx_END_A_2);
      end;
    1:
      begin
        Loc := lMalecon;
        Say(wMikel, tx_END_B_1);
        Say(wMikel, tx_END_B_2);
      end;
  else
    Loc := lOffice;
    Say(wMikel, tx_END_C_1);
    Say(wMikel, tx_END_C_2);
  end;
  Mode := mGo;
  After := A_END;
end;

procedure Choose(Code: Integer);
begin
  Mode := mGo;
  case Code of
    CH_TRADE:
      begin
        Exclude(Items, itCell);
        Exclude(Items, itLithium);
        Include(Items, itPass);
        Say(wSocio, tx_SOCIO_DEAL);
      end;
    CH_CHARGE:
      begin
        Battery := 100;
        Charged[Act] := True;
        Say(wSocio, tx_SOCIO_CHARGE);
      end;
    CH_BYE: Say(wSocio, tx_SOCIO_BYE);
    CH_DECRYPT:
      if Signal <= 0 then Say(wYari, tx_SIGNAL_LOST)
      else Offer([CH_KEY, CH_KEY + 1, CH_KEY + 2, CH_KEY + 3, CH_KEY + 4]);
    CH_LATER: ;
  else
    if (Code >= CH_KEY) and (Code <= CH_KEY + 4) then TryKey(Code - CH_KEY)
    else if (Code >= CH_END) and (Code <= CH_END + 2) then Finish(Code - CH_END);
  end;
end;

procedure DescribeItem(I: TItem);
var
  s: string;
  k: Integer;
begin
  case I of
    itCell: s := tx_D_CELL;
    itLithium: s := tx_D_LITHIUM;
    itPass: s := tx_D_PASS;
    itUSB: s := tx_D_USB;
  else
    begin
      // La descripción y, en otra página, lo que pone el papel.
      Say(wMikel, tx_D_LIST);
      s := '';
      for k := 0 to High(KEYS) do s := s + KEYS[k] + '  ' + KeyPos(k) + #10;
      Say(wMikel, Trim(s));
      Exit;
    end;
  end;
  Say(wMikel, s);
end;

procedure ShowClues;
var
  k: TClue;
begin
  if Clues = [] then
  begin
    Say(wMikel, tx_NO_CLUES);
    Exit;
  end;
  for k := Low(TClue) to High(TClue) do
    if k in Clues then Say(wMikel, '• ' + ClueText(k));
end;

// Lo que toca hacer cuando se cumple el objetivo del acto.
procedure CheckProgress;
begin
  if After <> A_NONE then Exit;
  if (Act = 1) and (itPass in Items) then
  begin
    Say(wMikel, tx_GO_PORT);
    After := A_ACT2;
  end
  else if (Act = 2) and (itUSB in Items) and (itList in Items) then
  begin
    Say(wMikel, tx_GO_SHOP);
    After := A_ACT3;
  end;
end;

procedure AddRow(K: TRowKind; V: Integer; const S: string);
var
  n: Integer;
begin
  n := Length(Rows);
  SetLength(Rows, n + 1);
  Rows[n].Kind := K;
  Rows[n].Val := V;
  Rows[n].Text := S;
end;

procedure BuildRows;
var
  locs: TLocs;
  who: TWhos;
  i: Integer;
  it: TItem;
begin
  SetLength(Rows, 0);
  if ShowEnd or (Ending > 0) then Exit;
  case Mode of
    mGo:
      begin
        locs := ActLocs(Act);
        for i := 0 to High(locs) do AddRow(rkGo, Ord(locs[i]), LocName(locs[i]));
        if (Act = 2) and (Loc in [lCargo, lBox]) then AddRow(rkHide, 0, tx_HIDE);
      end;
    mTalk:
      begin
        who := PeopleAt(Loc);
        for i := 0 to High(who) do AddRow(rkTalk, Ord(who[i]), WhoName(who[i]));
        if Length(who) = 0 then AddRow(rkInfo, 0, tx_NOBODY);
      end;
    mChoice:
      for i := 0 to High(Choices) do AddRow(rkChoice, Choices[i].Code, Choices[i].Text);
    mNotes:
      begin
        for it := Low(TItem) to High(TItem) do
          if it in Items then AddRow(rkItem, Ord(it), ItemName(it));
        AddRow(rkClues, 0, tx_CLUES + ' (' + IntToStr(ClueCount) + ')');
      end;
  end;
end;

procedure DoRow(I: Integer);
begin
  BuildRows;
  if (I < 0) or (I > High(Rows)) or Busy or ShowEnd then Exit;
  case Rows[I].Kind of
    rkGo: Travel(TLoc(Rows[I].Val));
    rkHide: Hide;
    rkTalk: TalkTo(TWho(Rows[I].Val));
    rkChoice: Choose(Rows[I].Val);
    rkItem: DescribeItem(TItem(Rows[I].Val));
    rkClues: ShowClues;
    rkInfo: ;
  end;
  CheckProgress;
end;

procedure DoButton(I: Integer);
begin
  if Busy or ShowEnd or (Mode = mChoice) or (Ending > 0) then Exit;
  case I of
    0: Mode := mTalk;
    1:
      begin
        Look;
        CheckProgress;
      end;
    2: Mode := mGo;
    3: Mode := mNotes;
  end;
end;

function RowIndex(K: TRowKind; V: Integer): Integer;
var
  i: Integer;
begin
  BuildRows;
  for i := 0 to High(Rows) do
    if (Rows[i].Kind = K) and (Rows[i].Val = V) then Exit(i);
  Result := -1;
end;

function Clock: string;
begin
  Result := Format('%.2d:%.2d', [(Minutes div 60) mod 24, Minutes mod 60]);
end;

// ============================================================ escenas
// Cada escena se dibuja en su recuadro (178×122) con coordenadas propias.

procedure Stars(N, MaxY: Integer; S: LongWord);
var
  i, x, y: Integer;
begin
  Seed(S);
  for i := 1 to N do
  begin
    x := Rnd(SW);
    y := Rnd(MaxY);
    if (Anim + i * 7) mod 23 <> 0 then Pt(x, y, C($C8C8F0));
  end;
end;

// Una fachada de Centro Habana: portales abajo y ventanas con velas.
procedure Facade(X, Y, W, H: Integer; Base: LongWord; Lit: Boolean; S: LongWord);
var
  i, j, wx, wy, k: Integer;
  win: LongWord;
begin
  Bar(X, Y, W, H, C(Base));
  Bar(X, Y, W, 2, C(Mix(Base, $000000, 0.4)));
  Bar(X - 1, Y + 2, W + 2, 2, C(Mix(Base, $FFFFFF, 0.12)));
  Seed(S);
  for j := 0 to (H - 24) div 14 - 1 do
    for i := 0 to (W - 4) div 10 - 1 do
    begin
      wx := X + 3 + i * 10;
      wy := Y + 7 + j * 14;
      k := Rnd(10);
      if Lit then win := $FFE08A
      else if k < 2 then
      begin
        if (Anim + i * 3 + j) mod 9 < 6 then win := $F0A040 else win := $C87028;
      end
      else win := $0C0A14;
      Bar(wx, wy, 6, 9, C(win));
      Bar(wx - 1, wy + 9, 8, 1, C(Mix(Base, $FFFFFF, 0.2)));
      if (k < 2) and not Lit then Glow(wx + 3, wy + 4, 7, 6, C($6A4030), 0.5);
    end;
  // Portales con columnas
  for i := 0 to W div 8 do
    Bar(X + i * 8, Y + H - 12, 3, 12, C(Mix(Base, $FFFFFF, 0.15)));
  Bar(X, Y + H - 14, W, 2, C(Mix(Base, $FFFFFF, 0.18)));
end;

procedure SceneMalecon(Lit: Boolean);
var
  i, x, y: Integer;
begin
  if Lit then
    Ramp(0, 0, SW, 56, [$0A0A26, $14184A, $25306A, $3A4A8A])
  else
    Ramp(0, 0, SW, 56, [$0A0820, $1C1442, $3A1F5E, $6B2A5F, $A8445C, $DE7A50]);
  Stars(36, 34, 11);
  if not Lit then
  begin
    Glow(128, 56, 26, 7, C($F2A05A), 0.6);
    Oval(128, 57, 9, 3, C($FFD080));
  end
  else Oval(140, 14, 5, 5, C($F0F0D8));
  // El Morro, a lo lejos, con su faro
  Poly([150, 57, 178, 57, 178, 50, 156, 50], C($241A36));
  Bar(166, 36, 5, 15, C($2C2040));
  Bar(165, 34, 7, 3, C($2C2040));
  if (Anim div 6) mod 2 = 0 then
  begin
    Bar(167, 35, 3, 2, C($FFF0A0));
    Glow(168, 36, 10, 4, C($FFE890), 0.4);
  end;
  // El mar
  if Lit then Ramp(0, 56, SW, 26, [$1C2A5A, $14204A, $0C1634, $081024])
  else Ramp(0, 56, SW, 26, [$4A2D5C, $2A2A5A, $172248, $0D1734]);
  if not Lit then
    for y := 58 to 72 do
      if y mod 2 = 0 then
        Bar(122 - (y - 58) div 2 + (Anim + y) mod 3, y, 10 + (y - 58) div 2, 1, C($D8865A));
  for i := 0 to 30 do
  begin
    y := 58 + (i * 7) mod 23;
    x := (i * 37 + Anim * (1 + i mod 3)) mod (SW + 20) - 10;
    Bar(x, y, 3 + i mod 4, 1, C($6A6AA0));
  end;
  // El muro del Malecón
  Ramp(0, 82, SW, 10, [$9A96A6, $76728A, $555268]);
  Bar(0, 82, SW, 1, C($C4C0D0));
  for i := 0 to SW div 12 do Bar(i * 12 + (i mod 2) * 6, 85, 1, 7, C($4A475C));
  if Anim mod 30 < 6 then
  begin
    Seed(Anim div 30 + 3);
    for i := 1 to 16 do Pt(70 + Rnd(70), 79 + Rnd(4) - (Anim mod 30), C($E0E8FF));
  end;
  // La avenida
  Ramp(0, 92, SW, 30, [$2C2838, $1E1B28, $15131D]);
  for i := 0 to 8 do Bar(i * 22 + 4, 107, 10, 1, C($7A7058));
  // Edificios de Centro Habana a la izquierda
  Facade(0, 14, 30, 78, $2A2236, Lit, 5);
  Facade(30, 34, 22, 58, $32283E, Lit, 9);
  // Farola
  Bar(110, 52, 2, 40, C($2A2836));
  Bar(106, 50, 10, 3, C($2A2836));
  if Lit then
  begin
    Bar(108, 53, 6, 2, C($FFF0B0));
    Glow(111, 60, 16, 14, C($FFE080), 0.45);
  end;
  // El pescador sentado en el muro, con su caña
  Bar(86, 74, 6, 8, C($181520));
  Oval(88, 71, 2, 2, C($181520));
  Bar(84, 68, 9, 1, C($3A3020));
  Bar(86, 66, 5, 2, C($3A3020));
  Seg(91, 74, 116, 58, C($3A3446));
  Seg(116, 58, 120, 80, C($5A5670));
  // La muchacha con el móvil
  Bar(60, 75, 5, 7, C($1C1824));
  Oval(62, 72, 2, 2, C($1C1824));
  Bar(64, 75, 2, 2, C($B0E8FF));
  Glow(64, 74, 6, 5, C($6AA0D0), 0.5);
  // La patrulla de Valdés
  if (Act = 1) and not Lit then
  begin
    Poly([128, 112, 132, 104, 140, 100, 158, 100, 164, 104, 170, 106, 170, 113, 128, 113], C($D8D8D8));
    Bar(142, 102, 7, 4, C($30384A));
    Bar(151, 102, 7, 4, C($30384A));
    Bar(128, 108, 42, 2, C($2A50B0));
    Oval(136, 114, 4, 3, C($101010));
    Oval(162, 114, 4, 3, C($101010));
    if (Anim div 3) mod 2 = 0 then
    begin
      Bar(148, 97, 4, 3, C($3A6AFF));
      Glow(150, 98, 12, 8, C($3A6AFF), 0.4);
    end
    else Bar(148, 97, 4, 3, C($FF3A3A));
  end;
end;

procedure ScenePaladar;
var
  i, x, y, f: Integer;
begin
  Ramp(0, 0, SW, 78, [$3C1A18, $552420, $461C1A]);
  for y := 0 to 9 do
    for x := 0 to 12 do
      Bar(x * 14 + (y mod 2) * 7, y * 8, 1, 8, C($34160F));
  for y := 1 to 9 do Bar(0, y * 8, SW, 1, C($34160F));
  // Ventana con rejas
  Bevel(12, 12, 38, 36, C($5A3A20), C($7A5A30), C($3A2410));
  Ramp(15, 15, 32, 30, [$0A0C26, $1A1A40, $2A2250]);
  Oval(38, 22, 3, 3, C($E8E8D0));
  for i := 0 to 4 do Bar(17 + i * 6, 15, 1, 30, C($1A1A1A));
  // Un cartel antiguo
  Bar(78, 12, 28, 36, C($E8D8A8));
  Bar(80, 14, 24, 14, C($C03030));
  Oval(92, 34, 6, 6, C($2A2A2A));
  Bar(82, 42, 20, 2, C($302020));
  Glow(92, 30, 18, 20, C($6A3A20), 0.2);
  // La repisa y el quinqué
  Bar(126, 30, 44, 3, C($6A4A28));
  f := (Anim * 7) mod 5;
  Glow(146, 18, 26, 18, C($E8903A), 0.2 + f * 0.02);
  Bar(143, 25, 7, 5, C($8A6A3A));
  Oval(146, 19, 4, 6, C($F0E0C0));
  Oval(146, 19, 1, 2 + f mod 2, C($FFD060));
  // El suelo de madera
  Ramp(0, 78, SW, 44, [$6A4428, $4E3018, $3A2410]);
  for y := 0 to 7 do
  begin
    Bar(0, 80 + y * 6, SW, 1, C($2E1C0C));
    for x := 0 to 5 do Bar((x * 34 + y * 13) mod SW, 80 + y * 6, 1, 6, C($2E1C0C));
  end;
  // Mesas con mantel de cuadros y velas
  for i := 0 to 1 do
  begin
    x := 20 + i * 76;
    y := 84 + i * 10;
    for f := 0 to 9 do
      Bar(x + f * 4, y, 4, 4, C(IfThen((f + i) mod 2 = 0, $E8E0E0, $C03030)));
    for f := 0 to 9 do
      Bar(x + f * 4, y + 4, 4, 4, C(IfThen((f + i + 1) mod 2 = 0, $E8E0E0, $C03030)));
    Bar(x + 2, y + 8, 2, 12, C($3A2410));
    Bar(x + 36, y + 8, 2, 12, C($3A2410));
    Bar(x + 18, y - 6, 3, 6, C($F0E8D0));
    Oval(x + 19, y - 8, 1, 2, C(IfThen((Anim + i) mod 4 < 2, $FFD060, $FFA030)));
    Glow(x + 19, y - 6, 12, 8, C($E8903A), 0.2);
    // Sillas
    Bar(x - 8, y + 2, 6, 2, C($5A3A20));
    Bar(x - 8, y - 8, 2, 20, C($5A3A20));
    Bar(x + 42, y + 2, 6, 2, C($5A3A20));
    Bar(x + 46, y - 8, 2, 20, C($5A3A20));
  end;
  // La nevera vieja
  Ramp(150, 38, 24, 56, [$E8E8E0, $C8C8C0, $A0A098]);
  Oval(161, 39, 11, 3, C($E8E8E0));
  Bar(152, 58, 20, 1, C($8A8A84));
  Bar(168, 44, 2, 10, C($6A6A64));
  Bar(155, 42, 8, 2, C($C03030));
  // Comensales en penumbra
  Oval(70, 80, 4, 4, C($1E120C));
  Bar(66, 84, 9, 12, C($1E120C));
end;

procedure SceneAlley;
var
  i, x: Integer;
begin
  Ramp(0, 0, SW, 40, [$080A22, $141640, $231F52]);
  Stars(14, 24, 21);
  Oval(124, 9, 4, 4, C($F0F0D0));
  // Al fondo
  Bar(64, 22, 50, 74, C($2A2440));
  for i := 0 to 3 do Bar(70 + i * 11, 30, 5, 8, C(IfThen(i = 2, $C8903A, $14101E)));
  for i := 0 to 3 do Bar(70 + i * 11, 48, 5, 8, C($14101E));
  // Fachadas a los lados
  Poly([0, 0, 64, 22, 64, 96, 0, 122], C($3A3050));
  Poly([SW, 0, 114, 22, 114, 96, SW, 122], C($342E4A));
  for i := 0 to 2 do
  begin
    Poly([0, 18 + i * 28, 56, 34 + i * 22, 56, 36 + i * 22, 0, 22 + i * 28], C($1E1830));
    Seg(0, 12 + i * 28, 56, 30 + i * 22, C($6A6080));
    Poly([SW, 18 + i * 28, 122, 34 + i * 22, 122, 36 + i * 22, SW, 22 + i * 28], C($1E1830));
    Seg(SW, 12 + i * 28, 122, 30 + i * 22, C($6A6080));
  end;
  // La calle de adoquines
  Poly([64, 96, 114, 96, SW, 122, 0, 122], C($3C3A44));
  for i := 0 to 60 do
  begin
    Seed(i + 300);
    Pt(10 + Rnd(158), 98 + Rnd(24), C($56525E));
  end;
  // Cables y ropa tendida
  Cable(0, 26, SW, 20, 10, C($0A0A12));
  Cable(0, 40, SW, 46, 8, C($0A0A12));
  Cable(22, 50, 156, 52, 6, C($8A8AA0));
  for i := 0 to 5 do
  begin
    x := 36 + i * 20;
    Bar(x, 53 + (i mod 2), 7, 9, C(IfThen(i mod 3 = 0, $C04040, IfThen(i mod 3 = 1, $E8E8E8, $3A7AC0))));
  end;
  // Panel solar en un balcón
  Poly([140, 62, 168, 56, 168, 66, 140, 72], C($1A3A8A));
  Seg(150, 60, 150, 70, C($4A6AD0));
  Seg(159, 58, 159, 68, C($4A6AD0));
  // El puesto del Socio: bombillo LED colgado de una batería
  Seg(88, 21, 88, 58, C($0A0A12));
  Glow(88, 72, 36, 28, C($A0C0FF), 0.32);
  Oval(88, 60, 2, 2, C($F0F8FF));
  Bar(66, 88, 44, 4, C($5A4030));
  Bar(68, 92, 2, 8, C($3A2818));
  Bar(106, 92, 2, 8, C($3A2818));
  for i := 0 to 4 do
  begin
    Bar(70 + i * 8, 80, 6, 8, C($1A1A1E));
    Bar(70 + i * 8, 80, 6, 2, C(IfThen(i mod 2 = 0, $D04040, $40B050)));
  end;
  // Un almendrón aparcado
  Poly([0, 116, 4, 104, 16, 98, 40, 98, 48, 104, 58, 106, 58, 117, 0, 117], C($7A1A1A));
  Bar(18, 100, 10, 4, C($30384A));
  Bar(30, 100, 10, 4, C($30384A));
  Bar(0, 110, 58, 1, C($C8C8C8));
  Oval(12, 118, 5, 4, C($101010));
  Oval(46, 118, 5, 4, C($101010));
end;

procedure Crane(X, Y, H, Boom: Integer; Col: Byte);
var
  i: Integer;
begin
  Bar(X, Y, 3, H, Col);
  for i := 0 to H div 6 do Seg(X, Y + i * 6, X + 3, Y + i * 6 + 6, Col);
  Seg(X - 10, Y + 2, X + Boom, Y - 4, Col);
  Seg(X - 10, Y + 4, X + Boom, Y - 2, Col);
  for i := 0 to Boom div 8 do Seg(X + i * 8, Y - 2 - i div 3, X + i * 8 + 4, Y + 2 - i div 3, Col);
  Seg(X + Boom - 4, Y - 2, X + Boom - 4, Y + 24, Col);
  Bar(X - 14, Y, 6, 6, Col);
end;

procedure SceneGate;
var
  x, y: Integer;
  fence: Byte;
begin
  Ramp(0, 0, SW, 62, [$06081C, $121436, $1E1C44, $2A2450]);
  Stars(20, 30, 31);
  Crane(30, 14, 46, 64, C($1A1830));
  Crane(140, 20, 40, 34, C($1A1830));
  for x := 0 to 8 do Bar(x * 20, 50, 18, 12, C(Mix($3A2A30, $1A2A40, (x mod 3) / 2)));
  Ramp(0, 62, SW, 60, [$2A2A30, $1C1C22]);
  for x := 0 to 5 do Bar(x * 32, 104, 16, 1, C($A08A30));
  // La valla de tela metálica
  fence := C($6A6A78);
  for y := 40 to 98 do
    for x := 0 to SW - 1 do
      if ((x < 68) or (x > 112)) and (((x + y) mod 6 = 0) or ((x - y + 600) mod 6 = 0)) then Pt(x, y, fence);
  for x := 0 to 5 do
    if (x * 30 < 66) or (x * 30 > 114) then Bar(x * 30, 36, 2, 64, C($4A4A58));
  // El letrero y la barrera
  Bevel(62, 26, 56, 12, C($C8C8C0), C($F0F0E8), C($8A8A84));
  TxtC(90, 26, 'PUERTO', C($1A2A5A));
  Bar(66, 38, 3, 60, C($4A4A58));
  Bar(111, 38, 3, 60, C($4A4A58));
  for x := 0 to 5 do Bar(70 + x * 6, 76, 6, 3, C(IfThen(x mod 2 = 0, $D03030, $F0F0F0)));
  // La garita con su planta eléctrica
  Bar(124, 52, 38, 46, C($8A8A7A));
  Bar(122, 48, 42, 5, C($5A5A50));
  Bar(130, 60, 20, 14, C($FFD870));
  Glow(140, 67, 26, 20, C($FFC860), 0.4);
  Bar(150, 76, 9, 22, C($4A4A40));
  Oval(140, 64, 3, 3, C($2A2018));
  Bar(137, 67, 6, 7, C($2A2018));
  // Reflector
  Bar(14, 20, 2, 80, C($3A3A48));
  Bar(10, 18, 10, 4, C($E8E8D0));
  Glow(15, 24, 20, 12, C($F0F0C0), 0.35);
end;

procedure Container(X, Y, W, H: Integer; Col: LongWord);
var
  i: Integer;
begin
  Bar(X, Y, W, H, C(Col));
  for i := 0 to W div 3 do Bar(X + i * 3, Y + 1, 1, H - 2, C(Mix(Col, $000000, 0.35)));
  Bar(X, Y, W, 1, C(Mix(Col, $FFFFFF, 0.3)));
  Bar(X, Y + H - 1, W, 1, C(Mix(Col, $000000, 0.55)));
end;

procedure SceneCargo;
var
  i, cx: Integer;
begin
  Ramp(0, 0, SW, 50, [$05071A, $0E1030, $1A1A40]);
  Stars(16, 26, 41);
  Crane(96, 4, 50, 70, C($1A1A34));
  Ramp(0, 50, SW, 72, [$2C2C32, $1E1E24, $16161A]);
  Container(2, 44, 40, 20, $9A2A24);
  Container(2, 64, 40, 20, $1E4A8A);
  Container(46, 54, 44, 20, $2A7A3A);
  Container(46, 74, 44, 20, $C0701E);
  Container(122, 48, 54, 22, $2A5A9A);
  Container(122, 70, 54, 22, $8A2420);
  for i := 0 to 5 do Bar(i * 30, 110, 14, 1, C($B09A30));
  // El reflector que barre la zona
  cx := 89 + Round(Sin(Anim * 0.09) * 58);
  Poly([168, 4, cx - 10, 121, cx + 10, 121], C($F0F0D0), 0.3);
  Poly([168, 4, cx - 22, 121, cx + 22, 121], C($E8E8C8), 0.18);
  Glow(cx, 116, 26, 6, C($FFFFE0), 0.5);
  // Los sacos de café
  for i := 0 to 4 do
  begin
    Oval(18 + i * 14, 108 - (i mod 2) * 6, 9, 6, C($C8B088));
    Oval(18 + i * 14, 106 - (i mod 2) * 6, 7, 3, C($D8C49C));
    Seg(12 + i * 14, 108 - (i mod 2) * 6, 24 + i * 14, 108 - (i mod 2) * 6, C($8A7050));
  end;
  Oval(32, 96, 9, 6, C($C8B088));
  Bar(28, 95, 9, 1, C($6A3A20));
  // Un guardia hace la ronda
  if Alert >= 50 then
  begin
    Bar(150, 92, 5, 14, C($1A2018));
    Oval(152, 89, 2, 3, C($1A2018));
    Glow(144, 100, 14, 6, C($FFFFC0), 0.5);
  end;
end;

procedure SceneBox;
var
  i, x: Integer;
begin
  // Interior de un contenedor abierto
  Poly([0, 0, SW, 0, 128, 24, 50, 24], C($4A1A14));
  Poly([0, 0, 50, 24, 50, 92, 0, 122], C($7A3428));
  Poly([SW, 0, 128, 24, 128, 92, SW, 122], C($6E2E24));
  for i := 0 to 11 do
  begin
    x := i * 4;
    Seg(x, Round(x * 24 / 50), x, 122 - Round(x * 30 / 50), C($5A2218));
    Seg(SW - x, Round(x * 24 / 50), SW - x, 122 - Round(x * 30 / 50), C($52201A));
  end;
  Bar(50, 24, 78, 68, C($6A2A20));
  for i := 0 to 19 do Bar(51 + i * 4, 25, 1, 66, C($5A2218));
  Poly([50, 92, 128, 92, SW, 122, 0, 122], C($3A2A22));
  // La mesa y el terminal viejo encendido
  Bar(58, 74, 62, 4, C($5A4A3A));
  Bar(60, 78, 3, 16, C($3A2A1A));
  Bar(114, 78, 3, 16, C($3A2A1A));
  Glow(88, 58, 34, 24, C($2A8A3A), 0.35);
  Bevel(72, 46, 32, 26, C($C8C0A0), C($E8E0C0), C($8A846A));
  Bar(75, 49, 26, 18, C($062A0E));
  for i := 0 to 4 do Bar(77, 51 + i * 3, 6 + ((i * 7) mod 15), 1, C($4AE06A));
  if (Anim div 4) mod 2 = 0 then Bar(77 + 8, 51 + 15, 3, 2, C($8AFF9A));
  Bar(70, 70, 36, 4, C($A8A088));
  // Batería de camión con sus cables
  Bar(100, 100, 20, 11, C($1A1A1E));
  Bar(102, 98, 4, 2, C($C03030));
  Bar(114, 98, 4, 2, C($2A2A2A));
  Cable(104, 98, 96, 72, -6, C($C03030));
  Cable(116, 98, 100, 72, -4, C($101010));
  // Papeles por el suelo
  Bar(64, 104, 8, 5, C($E8E8E0));
  Bar(74, 110, 7, 4, C($D8D8D0));
  // La puerta abierta (primer plano)
  Bar(0, 0, 6, SH, C($8A3A2C));
  Bar(SW - 6, 0, 6, SH, C($7A3226));
end;

procedure SceneShop;
var
  i, y: Integer;
begin
  Ramp(0, 0, SW, 72, [$12302E, $0E2624, $0A1C1A]);
  // Ventana con cables
  Bevel(8, 8, 32, 28, C($2A3A38), C($3A5450), C($0A1A18));
  Ramp(10, 10, 28, 24, [$0A0C26, $1A1A40]);
  Cable(10, 14, 38, 18, 4, C($050508));
  // Estanterías con piezas
  for y := 0 to 1 do
  begin
    Bar(46, 18 + y * 18, 74, 2, C($5A4428));
    for i := 0 to 6 do
      Bar(48 + i * 10, 10 + y * 18, 8, 8, C(IfThen((i + y) mod 3 = 0, $A06A2A, IfThen((i + y) mod 3 = 1, $3A6A8A, $6A6A6A))));
  end;
  // Dos monitores de tubo
  Bevel(56, 44, 30, 24, C($B8B098), C($D8D0B8), C($7A7460));
  Bar(59, 47, 24, 17, C($2A1A04));
  for i := 0 to 4 do Bar(61, 49 + i * 3, 4 + (i * 5) mod 16, 1, C($FFB030));
  Bevel(90, 42, 32, 26, C($B8B098), C($D8D0B8), C($7A7460));
  Bar(93, 45, 26, 19, C($042A0E));
  for i := 0 to 5 do Bar(95, 47 + i * 3, 3 + (i * 9 + Anim) mod 18, 1, C($4AE06A));
  Glow(88, 56, 40, 20, C($3A8A5A), 0.2);
  // Router reprogramado con luces
  Bar(128, 60, 26, 7, C($1A1A1E));
  Seg(131, 60, 127, 46, C($2A2A2E));
  Seg(150, 60, 154, 46, C($2A2A2E));
  for i := 0 to 4 do
    if (Anim + i * 3) mod (3 + i) < 2 then Pt(132 + i * 4, 63, C($4AF06A)) else Pt(132 + i * 4, 63, C($1A4A2A));
  // El banco de trabajo
  Bar(0, 70, SW, 5, C($6A4A2A));
  Ramp(0, 75, SW, 47, [$4A321C, $2E1E10]);
  // Soldador humeando
  Seg(30, 68, 46, 62, C($8A8A8A));
  Bar(28, 68, 4, 2, C($C03030));
  for i := 0 to 4 do Pt(46 + (Anim + i) mod 3 - 1, 60 - ((Anim * 2 + i * 5) mod 18), C($9AA8A8));
  // Baterías en fila
  for i := 0 to 4 do
  begin
    Bar(124 + i * 10, 88, 8, 14, C($1A1A1E));
    Bar(125 + i * 10, 86, 2, 2, C($C03030));
    Bar(129 + i * 10, 86, 2, 2, C($2A2A2A));
  end;
  Cable(128, 86, 150, 67, -6, C($C03030));
  // Herramientas colgadas
  Seg(4, 44, 4, 58, C($9A9A9A));
  Seg(10, 44, 14, 58, C($9A9A9A));
  Oval(22, 50, 3, 3, C($C8A030));
end;

procedure SceneRoof(Dawn: Boolean);
var
  i, h, x, k: Integer;
begin
  if Dawn then Ramp(0, 0, SW, 74, [$3A3A7A, $7A6A9A, $D8987A, $FFD49A])
  else
  begin
    Ramp(0, 0, SW, 74, [$05061A, $10123A, $1C1A4A]);
    Stars(40, 50, 51);
  end;
  // La ciudad: a oscuras, salvo Miramar al oeste (a la derecha)
  Seed(77);
  x := 0;
  while x < SW do
  begin
    h := 8 + Rnd(22);
    Bar(x, 74 - h, 10, h + 16, C(IfThen(Dawn, $4A3A5A, $121226)));
    for k := 0 to 2 do
      if (Rnd(10) < IfThen(x > 120, 7, 1)) or Dawn then
        Pt(x + 2 + Rnd(6), 76 - h + Rnd(h), C(IfThen(Dawn, $8A7A8A, $FFD870)));
    Inc(x, 10);
  end;
  if not Dawn then Glow(150, 64, 40, 16, C($A08A40), 0.25);
  // La azotea
  Ramp(0, 90, SW, 32, [$5A5650, $3E3A36]);
  Bar(0, 88, SW, 3, C($7A766E));
  // Tanques de agua
  for i := 0 to 1 do
  begin
    Bar(14 + i * 26, 60, 18, 28, C($3A3A3E));
    Oval(23 + i * 26, 60, 9, 3, C($5A5A5E));
    Bar(14 + i * 26, 70, 18, 1, C($2A2A2E));
  end;
  // La antena del nodo
  Bar(120, 16, 2, 74, C($6A6A72));
  for i := 0 to 11 do Seg(116, 20 + i * 6, 126, 26 + i * 6, C($4A4A52));
  Oval(112, 34, 5, 7, C($C8C8CC));
  Seg(116, 36, 120, 36, C($6A6A72));
  if (Anim div 5) mod 2 = 0 then
  begin
    Bar(120, 13, 2, 3, C($FF3030));
    Glow(121, 14, 8, 6, C($FF3030), 0.4);
  end;
  Cable(122, 60, 170, 94, 8, C($15151A));
end;

procedure Palm(X, Y: Integer);
var
  i: Integer;
begin
  for i := 0 to 12 do Oval(X + i div 3, Y + 30 - i * 3, 2, 2, C($3A2A1A));
  Seg(X + 4, Y - 6, X - 16, Y + 4, C($1E3A1E));
  Seg(X + 4, Y - 6, X + 24, Y + 2, C($1E3A1E));
  Seg(X + 4, Y - 6, X - 8, Y + 12, C($1E3A1E));
  Seg(X + 4, Y - 6, X + 16, Y + 12, C($1E3A1E));
  Seg(X + 4, Y - 6, X + 2, Y - 18, C($1E3A1E));
  Seg(X + 5, Y - 5, X - 15, Y + 5, C($2A4A2A));
  Seg(X + 5, Y - 5, X + 25, Y + 3, C($2A4A2A));
end;

procedure SceneGarden;
var
  i, j: Integer;
  on: Boolean;
begin
  Ramp(0, 0, SW, 70, [$04061A, $0C1036, $161A46]);
  Stars(30, 40, 61);
  Oval(30, 14, 6, 6, C($F0F0D8));
  // La mansión de Miramar
  Bar(34, 30, 112, 62, C($B8B0A0));
  Dith(34, 30, 112, 62, C($B8B0A0), C($8A8478), 0.25);
  Bar(30, 26, 120, 5, C($D8D0C0));
  Poly([30, 26, 90, 8, 150, 26], C($A8A090));
  // Paneles solares nuevos en el tejado
  Poly([60, 20, 84, 12, 88, 16, 64, 24], C($1A3A8A));
  Poly([96, 12, 120, 20, 116, 24, 92, 16], C($1A3A8A));
  // Ventanas con el brillo azul de los servidores
  for j := 0 to 1 do
    for i := 0 to 4 do
    begin
      on := (Anim + i * 5 + j * 3) mod 11 < 9;
      Bar(42 + i * 21, 38 + j * 22, 10, 14, C(IfThen(on, $4AD0FF, $2A90C0)));
      Glow(47 + i * 21, 45 + j * 22, 10, 9, C($2A80B0), 0.25);
    end;
  for i := 0 to 3 do Bar(50 + i * 26, 82, 4, 10, C($E0D8C8));
  // Palmas y maleza
  Palm(8, 40);
  Palm(156, 44);
  Ramp(0, 92, SW, 30, [$14240F, $0A1608]);
  for i := 0 to 9 do Oval(i * 19 + 6, 96 + (i mod 3) * 5, 10, 6, C(IfThen(i mod 2 = 0, $1E3A18, $284A20)));
  // La verja
  for i := 0 to 22 do Bar(i * 8, 104, 1, 18, C($1A1A1A));
  Bar(0, 106, SW, 1, C($1A1A1A));
end;

procedure SceneServers;
var
  i, j, k, x: Integer;
begin
  Ramp(0, 0, SW, SH, [$05070F, $0A0E1C, $060810]);
  // Ventana del fondo con luz de luna
  Bar(76, 14, 26, 30, C($1A2A4A));
  Bar(88, 14, 2, 30, C($05070F));
  Poly([76, 44, 102, 44, 120, 122, 58, 122], C($0E1428));
  // Racks a los dos lados
  for k := 0 to 2 do
  begin
    x := k * 22;
    Bar(x, 20 + k * 4, 20, 96 - k * 8, C($15181F));
    Bar(SW - 20 - x, 20 + k * 4, 20, 96 - k * 8, C($15181F));
    for j := 0 to 13 do
      for i := 0 to 3 do
      begin
        if (Anim + i * 7 + j * 3 + k * 11) mod (4 + (i + j) mod 5) < 2 then
        begin
          Pt(x + 3 + i * 4, 24 + k * 4 + j * 6, C(IfThen((i + j) mod 3 = 0, $3AF06A, IfThen((i + j) mod 3 = 1, $FFB030, $3A8AFF))));
          Pt(SW - 17 - x + i * 4, 24 + k * 4 + j * 6, C(IfThen((i + j + 1) mod 3 = 0, $3AF06A, $3A8AFF)));
        end;
      end;
  end;
  // Cables colgando del techo
  Cable(20, 0, 160, 0, 14, C($20242E));
  Cable(40, 0, 130, 0, 22, C($262A36));
  // Ramiro en el centro
  Bar(84, 70, 12, 30, C($0A0C12));
  Oval(90, 64, 5, 6, C($0A0C12));
  Bar(87, 63, 7, 2, C($8AC8FF));
end;

procedure SceneOffice;
var
  i, a: Integer;
begin
  Ramp(0, 0, SW, 80, [$C8B890, $B0A078, $988860]);
  // Ventana con persianas: rayas de luz
  Bar(100, 10, 60, 44, C($F0E0B0));
  for i := 0 to 10 do Bar(100, 12 + i * 4, 60, 2, C($8A7A5A));
  Poly([100, 54, 160, 54, 120, 122, 40, 122], C($D8C8A0));
  // Calendario
  Bar(20, 16, 22, 26, C($F0F0F0));
  Bar(20, 16, 22, 6, C($C03030));
  TxtC(31, 25, '2026', C($303030));
  // Ventilador del techo
  Bar(66, 0, 2, 8, C($4A4A4A));
  a := Anim mod 3;
  if a = 0 then Bar(52, 8, 30, 2, C($4A4A4A))
  else if a = 1 then Seg(56, 12, 78, 5, C($4A4A4A))
  else Seg(56, 5, 78, 12, C($4A4A4A));
  // El escritorio con expedientes
  Bar(10, 76, 126, 8, C($6A4A2A));
  Ramp(10, 84, 126, 38, [$5A3E22, $3A2814]);
  for i := 0 to 3 do Bar(18, 66 - i * 3, 24, 3, C(IfThen(i mod 2 = 0, $E8D8A0, $C8B880)));
  // La gorra de Valdés sobre la mesa
  Oval(90, 72, 12, 4, C($1A2A5A));
  Bar(80, 74, 22, 2, C($0A1430));
  Bar(88, 69, 4, 3, C($F0C040));
  // Una taza de café
  Bar(112, 70, 7, 6, C($F0F0F0));
  Bar(119, 72, 2, 3, C($F0F0F0));
end;

procedure DrawScene;
begin
  case Loc of
    lMalecon: SceneMalecon(Ending = 2);
    lPaladar: ScenePaladar;
    lAlley: SceneAlley;
    lGate: SceneGate;
    lCargo: SceneCargo;
    lBox: SceneBox;
    lShop: SceneShop;
    lRoof: SceneRoof(Ending = 1);
    lGarden: SceneGarden;
    lServers: SceneServers;
    lOffice: SceneOffice;
  end;
end;

// ============================================================ retratos
type
  TFace = record
    Bg1, Bg2, Skin, SkinD, Hair, Cloth: LongWord;
    HairStyle, Hat, Glasses, Mouth: Integer;
    Mustache, Beard, Stubble, Chain, Headset, Phone, Badge, Earrings: Boolean;
  end;

function FaceOf(W: TWho): TFace;
begin
  FillChar(Result, SizeOf(Result), 0);
  with Result do
    case W of
      wYari:
        begin
          Bg1 := $1A4A4A; Bg2 := $0A2222; Skin := $8A5434; SkinD := $663C22;
          Hair := $1A1210; Cloth := $3A8A8A; HairStyle := 1; Glasses := 3;
          Headset := True; Earrings := True; Mouth := 1;
        end;
      wSocio:
        begin
          Bg1 := $4A2A5A; Bg2 := $1E1028; Skin := $B07850; SkinD := $8A5838;
          Hair := $1A1414; Cloth := $E8E8E8; Hat := 2; Glasses := 2; Chain := True;
          Stubble := True; Mouth := 1;
        end;
      wValdes:
        begin
          Bg1 := $2A3448; Bg2 := $10141E; Skin := $E0B090; SkinD := $B08868;
          Hair := $A8A8A8; Cloth := $2A3A6A; HairStyle := 3; Hat := 1;
          Mustache := True; Badge := True; Mouth := 2;
        end;
      wFisher:
        begin
          Bg1 := $6A3A4A; Bg2 := $2A1A2A; Skin := $5A3420; SkinD := $40241A;
          Hair := $D8D8D0; Cloth := $C8C0A0; Hat := 3; Stubble := True;
        end;
      wGirl:
        begin
          Bg1 := $1A1A4A; Bg2 := $0A0A1E; Skin := $C08860; SkinD := $9A6A48;
          Hair := $2A1A14; Cloth := $D05A8A; HairStyle := 2; Phone := True;
          Earrings := True;
        end;
      wCook:
        begin
          Bg1 := $5A2A1A; Bg2 := $2A140A; Skin := $6A3E28; SkinD := $4E2C1A;
          Hair := $2A2420; Cloth := $F0F0E8; Hat := 4; Earrings := True; Mouth := 1;
        end;
      wGuard:
        begin
          Bg1 := $2A3020; Bg2 := $10140C; Skin := $D0A080; SkinD := $A88060;
          Hair := $2A2018; Cloth := $4A5A3A; Hat := 5; Mouth := 2;
        end;
      wRamiro:
        begin
          Bg1 := $0E2A4A; Bg2 := $050E1E; Skin := $E8C0A0; SkinD := $C09878;
          Hair := $5A3A2A; Cloth := $8A9AB0; Glasses := 1; Beard := True;
        end;
    else
      begin
        Bg1 := $2A2A4A; Bg2 := $10101E; Skin := $C89270; SkinD := $9A6A4E;
        Hair := $2A2020; Cloth := $5A4A3A; Stubble := True;
      end;
    end;
end;

procedure Portrait(W: TWho);
var
  f: TFace;
  i: Integer;
  dark: Byte;
begin
  f := FaceOf(W);
  dark := C($141010);
  Ramp(0, 0, PW, PH, [f.Bg1, f.Bg2]);
  if W = wRamiro then
    for i := 0 to 8 do
      if (Anim + i * 3) mod 5 < 3 then Pt(4 + i * 6, 6 + (i mod 3) * 4, C($3AF06A));
  // El pelo de detrás
  if f.HairStyle = 1 then Oval(31, 24, 21, 19, C(f.Hair));
  if f.HairStyle = 2 then
  begin
    Oval(31, 28, 17, 20, C(f.Hair));
    Bar(14, 28, 35, 30, C(f.Hair));
  end;
  // Hombros y ropa
  Poly([2, PH, 8, 58, 20, 52, 42, 52, 54, 58, 60, PH], C(f.Cloth));
  Shade(32, 52, 30, 20, C(Mix(f.Cloth, $000000, 0.35)), 0.5);
  if W = wCook then Poly([20, PH, 22, 58, 40, 58, 42, PH], C($C04040));
  // Cuello y cabeza
  Bar(26, 44, 11, 10, C(f.SkinD));
  Oval(18, 33, 2, 4, C(f.SkinD));
  Oval(44, 33, 2, 4, C(f.SkinD));
  Oval(31, 32, 13, 16, C(f.Skin));
  Shade(36, 18, 10, 28, C(f.SkinD), 0.3);
  // Pelo
  case f.HairStyle of
    0:
      begin
        Oval(31, 20, 13, 7, C(f.Hair));
        Bar(18, 18, 4, 10, C(f.Hair));
        Bar(41, 18, 4, 10, C(f.Hair));
      end;
    1: Oval(31, 18, 15, 8, C(f.Hair));
    2:
      begin
        Oval(31, 19, 14, 7, C(f.Hair));
        Bar(17, 20, 4, 24, C(f.Hair));
        Bar(42, 20, 4, 24, C(f.Hair));
      end;
    3:
      begin
        Bar(17, 24, 4, 10, C(f.Hair));
        Bar(42, 24, 4, 10, C(f.Hair));
      end;
  end;
  // Ojos, cejas, nariz y boca
  Bar(23, 31, 6, 3, C($F0F0F0));
  Bar(34, 31, 6, 3, C($F0F0F0));
  Bar(25, 31, 2, 3, dark);
  Bar(36, 31, 2, 3, dark);
  Bar(22, 28, 8, 1, C(Mix(f.Hair, $000000, 0.3)));
  Bar(33, 28, 8, 1, C(Mix(f.Hair, $000000, 0.3)));
  Bar(30, 34, 3, 5, C(f.SkinD));
  Bar(29, 38, 5, 1, C(f.SkinD));
  case f.Mouth of
    1:
      begin
        Bar(27, 42, 10, 1, C($6A2A2A));
        Pt(26, 41, C($6A2A2A));
        Pt(37, 41, C($6A2A2A));
      end;
    2:
      begin
        Bar(27, 42, 10, 1, C($5A2A2A));
        Pt(26, 43, C($5A2A2A));
        Pt(37, 43, C($5A2A2A));
      end;
  else
    Bar(27, 42, 9, 1, C($6A2E2E));
  end;
  if f.Mustache then Bar(25, 39, 13, 3, C(f.Hair));
  if f.Beard then
  begin
    Poly([19, 36, 22, 46, 31, 50, 40, 46, 43, 36, 40, 42, 31, 45, 22, 42], C(f.Hair));
    Bar(26, 40, 11, 2, C(f.Hair));
  end;
  if f.Stubble then Shade(21, 39, 21, 9, C(Mix(f.Hair, f.SkinD, 0.5)), 0.22);
  // Gafas
  case f.Glasses of
    1:
      begin
        Bar(21, 29, 10, 1, dark); Bar(21, 35, 10, 1, dark);
        Bar(21, 29, 1, 7, dark); Bar(30, 29, 1, 7, dark);
        Bar(32, 29, 10, 1, dark); Bar(32, 35, 10, 1, dark);
        Bar(32, 29, 1, 7, dark); Bar(41, 29, 1, 7, dark);
        Bar(30, 31, 3, 1, dark);
      end;
    2:
      begin
        Bar(21, 29, 9, 5, C($101014));
        Bar(32, 29, 9, 5, C($101014));
        Bar(30, 30, 3, 1, C($101014));
        Pt(23, 30, C($8A8AA0));
        Pt(34, 30, C($8A8AA0));
      end;
    3:
      begin
        Bar(18, 19, 27, 5, C($3A4450));
        Oval(25, 21, 3, 2, C($E0A030));
        Oval(37, 21, 3, 2, C($E0A030));
      end;
  end;
  // Sombreros y gorras
  case f.Hat of
    1:
      begin
        Bar(16, 12, 30, 9, C($1A2A5A));
        Bar(14, 20, 34, 3, C($0A1430));
        Bar(29, 13, 4, 4, C($F0C040));
      end;
    2:
      begin
        Oval(31, 18, 14, 6, C($C03030));
        Bar(40, 18, 10, 3, C($8A1A1A));
      end;
    3:
      begin
        Oval(31, 18, 25, 4, C($D8C070));
        Oval(31, 12, 12, 6, C($C8B060));
        Bar(20, 15, 23, 2, C($6A3A20));
      end;
    4:
      begin
        Oval(31, 18, 16, 9, C($C02828));
        for i := 0 to 5 do Pt(22 + i * 4, 16 + (i mod 2) * 3, C($F0F0F0));
        Oval(46, 22, 3, 2, C($C02828));
      end;
    5:
      begin
        Bar(16, 13, 30, 8, C($4A5A3A));
        Bar(15, 20, 32, 2, C($2A3A20));
      end;
  end;
  // Complementos
  if f.Earrings then
  begin
    Pt(18, 38, C($F0C040));
    Pt(44, 38, C($F0C040));
  end;
  if f.Chain then
  begin
    Cable(22, 53, 40, 53, 5, C($F0C040));
    Pt(31, 58, C($FFE070));
  end;
  if f.Headset then
  begin
    Cable(17, 30, 45, 30, -26, C($2A2A2A));
    Oval(17, 32, 2, 3, C($2A2A2A));
    Seg(17, 35, 24, 43, C($2A2A2A));
  end;
  if f.Badge then
  begin
    Bar(42, 58, 6, 6, C($F0C040));
    Pt(44, 60, C($8A6A10));
  end;
  if f.Phone then
  begin
    Shade(18, 36, 26, 14, C($8AC0F0), 0.3);
    Bar(36, 56, 9, 14, C($202028));
    Bar(37, 57, 7, 11, C($B0E0FF));
  end;
end;

// ============================================================ iconos
procedure Icon(I, X, Y: Integer; Col, Dk: Byte);
begin
  case I of
    0:
      begin
        Oval(X + 6, Y + 5, 6, 4, Col);
        Poly([X + 2, Y + 7, X + 6, Y + 8, X + 1, Y + 12], Col);
        Bar(X + 3, Y + 4, 2, 2, Dk);
        Bar(X + 6, Y + 4, 2, 2, Dk);
        Bar(X + 9, Y + 4, 2, 2, Dk);
      end;
    1:
      begin
        Oval(X + 5, Y + 5, 5, 5, Col);
        Oval(X + 5, Y + 5, 3, 3, Dk);
        Seg(X + 8, Y + 8, X + 12, Y + 12, Col);
        Seg(X + 9, Y + 8, X + 12, Y + 11, Col);
      end;
    2:
      begin
        Oval(X + 6, Y + 4, 4, 4, Col);
        Poly([X + 2, Y + 5, X + 10, Y + 5, X + 6, Y + 13], Col);
        Oval(X + 6, Y + 4, 1, 1, Dk);
      end;
  else
    begin
      Bar(X + 2, Y, 9, 12, Col);
      Bar(X + 4, Y + 3, 5, 1, Dk);
      Bar(X + 4, Y + 6, 5, 1, Dk);
      Bar(X + 4, Y + 9, 5, 1, Dk);
      Bar(X + 1, Y + 1, 2, 1, Dk);
      Bar(X + 1, Y + 5, 2, 1, Dk);
      Bar(X + 1, Y + 9, 2, 1, Dk);
    end;
  end;
end;

// ============================================================ la interfaz
const
  K_BG = $0B0E24;
  K_FACE = $16205A;
  K_HI = $4A5FB0;
  K_LO = $05081A;
  K_INK = $E8E8F0;
  K_DIM = $8890B8;
  K_GOLD = $FFD84A;
  K_SEL = $FFD84A;
  K_SELINK = $10143A;

function ButtonLabel(I: Integer): string;
begin
  case I of
    0: Result := tx_B_TALK;
    1: Result := tx_B_LOOK;
    2: Result := tx_B_GO;
  else
    Result := tx_B_NOTES;
  end;
end;

procedure Meter(X, Y, W: Integer; const Name: string; V: Integer; Col: LongWord);
begin
  Txt(X, Y, Name, C(K_DIM));
  Bevel(X, Y + 11, W, 6, C($05081A), C($05081A), C($2A3A7A));
  Bar(X + 1, Y + 12, Round((W - 2) * Max(0, Min(100, V)) / 100), 4, C(Col));
  Txt(X + W + 3, Y + 8, IntToStr(V) + '%', C(K_INK));
end;

function Speaker: TWho;
begin
  if Busy then Result := Lines[LineAt].Who
  else if (Mode = mTalk) and (HoverRow >= 0) and (HoverRow <= High(Rows)) and
    (Rows[HoverRow].Kind = rkTalk) then Result := TWho(Rows[HoverRow].Val)
  else Result := LastWho;
  if Result = wNone then Result := wMikel;
end;

procedure DrawEndCard;
var
  title: string;
  ws: TStringList;
  i: Integer;
begin
  case Ending of
    1: title := tx_END_A_TITLE;
    2: title := tx_END_B_TITLE;
  else
    title := tx_END_C_TITLE;
  end;
  SetClip(0, 0, VW, VH);
  Shade(0, 0, VW, VH, C($000000), 0.55);
  Bevel(50, 46, 260, 118, C(K_FACE), C(K_HI), C(K_LO));
  Bar(52, 48, 256, 14, C($2A1A5A));
  TxtC(180, 49, title, C(K_GOLD), True, C(K_LO));
  TxtC(180, 74, tx_THE_END, C(K_INK), True, C(K_LO));
  ws := Wrap(Fmt(tx_END_STATS, [Clock, IntToStr(ClueCount), IntToStr(ALL_CLUES)]), 230);
  for i := 0 to ws.Count - 1 do TxtC(180, 98 + i * LINE_H, ws[i], C(K_INK));
  TxtC(180, 144, tx_END_AGAIN, C(K_DIM));
end;

procedure RenderAll;
var
  i, j, n, y, shown, len: Integer;
  who: TWho;
  ws: TStringList;
  s, t: string;
  sel, en: Boolean;
begin
  PalN := 0;
  OX := 0;
  OY := 0;
  SetClip(0, 0, VW, VH);
  BuildRows;
  // Fondo
  Bar(0, 0, VW, VH, C(K_BG));
  Dith(0, 12, VW, VH - 12, C(K_BG), C($10143A), 0.2);
  // Cabecera: el acto y la hora
  Bar(0, 0, VW, 12, C($1A1440));
  Bar(0, 12, VW, 1, C(K_HI));
  if Ending > 0 then t := LocName(Loc) else t := ActTitle(Act);
  Txt(4, 0, t, C(K_GOLD), False, C(K_LO));
  Txt(VW - 4 - TextW(Clock), 0, Clock, C(K_INK), False, C(K_LO));
  // El lugar
  Bevel(LIST_X, 14, LIST_W, 15, C($2A1A5A), C($6A4AB0), C(K_LO));
  TxtC(LIST_X + LIST_W div 2, 14, LocName(Loc), C(K_INK), True, C(K_LO));
  // La lista de opciones
  Bevel(LIST_X, LIST_Y, LIST_W, 62, C(K_FACE), C(K_HI), C(K_LO));
  for i := 0 to Min(High(Rows), MAX_ROWS - 1) do
  begin
    y := LIST_Y + 1 + i * ROW_H;
    sel := (i = HoverRow) and not Busy;
    if sel then Bar(LIST_X + 2, y, LIST_W - 4, ROW_H, C(K_SEL));
    s := IntToStr(i + 1) + '  ' + Rows[i].Text;
    if (Rows[i].Kind = rkGo) and (TLoc(Rows[i].Val) = Loc) then s := s + '  ◂ ' + tx_HERE;
    if sel then Txt(LIST_X + 5, y, s, C(K_SELINK))
    else if Rows[i].Kind = rkInfo then Txt(LIST_X + 5, y, Rows[i].Text, C(K_DIM))
    else Txt(LIST_X + 5, y, s, C(IfThen(Busy, K_DIM, K_INK)));
  end;
  // La escena
  Bevel(SCENE_X - 1, SCENE_Y - 1, SW + 2, SH + 2, C(K_LO), C(K_LO), C(K_HI));
  SetClip(SCENE_X, SCENE_Y, SW, SH);
  OX := SCENE_X;
  OY := SCENE_Y;
  DrawScene;
  if Banner > 0 then
  begin
    Shade(0, 38, SW, 40, C($05081A), 0.75);
    s := ActTitle(Act);
    n := Pos('·', s);
    if n > 0 then
    begin
      TxtC(SW div 2, 42, Trim(Copy(s, 1, n - 1)), C(K_GOLD), True, C(K_LO));
      TxtC(SW div 2, 60, Trim(Copy(s, n + Length('·'), MaxInt)), C(K_INK), False, C(K_LO));
    end;
  end;
  OX := 0;
  OY := 0;
  SetClip(0, 0, VW, VH);
  // Retrato y ficha
  who := Speaker;
  Bevel(PORT_X - 2, PORT_Y - 2, PW + 4, PH + 4, C(K_LO), C(K_LO), C(K_HI));
  SetClip(PORT_X, PORT_Y, PW, PH);
  OX := PORT_X;
  OY := PORT_Y;
  Portrait(who);
  OX := 0;
  OY := 0;
  SetClip(0, 0, VW, VH);
  if TextW(WhoName(who), True) <= VW - INFO_X - 4 then
    Txt(INFO_X, 14, WhoName(who), C(K_GOLD), True, C(K_LO))
  else Txt(INFO_X, 15, WhoName(who), C(K_GOLD), False, C(K_LO));
  Txt(INFO_X, 28, WhoRole(who), C(K_DIM));
  Meter(INFO_X, 44, 60, tx_BATTERY, Battery, IfThen(Battery > 30, $5AD65A, $E04040));
  if Act = 2 then Meter(INFO_X, 66, 60, tx_ALERT, Alert, IfThen(Alert < 60, $F0A030, $E04040))
  else if (Act = 3) and not (fDecrypted in Flags) then Meter(INFO_X, 66, 60, tx_SIGNAL, Signal, $5AD6E0);
  // El texto
  Bevel(188, 90, 168, 90, C($0A0C1E), C(K_LO), C(K_HI));
  if Busy then
  begin
    ws := Wrap(Lines[LineAt].Text, TEXT_W);
    shown := Typed;
    for j := 0 to Min(ws.Count, TEXT_LINES) - 1 do
    begin
      len := UTF8Length(ws[j]);
      if shown <= 0 then Break;
      Txt(TEXT_X, TEXT_Y + j * LINE_H, UTF8Copy(ws[j], 1, Min(len, shown)), C(K_INK));
      Dec(shown, len + 1);
    end;
    if (Typed >= UTF8Length(Lines[LineAt].Text)) and ((Anim div 4) mod 2 = 0) then
      Txt(354 - TextW(tx_MORE + ' ▾'), 168, tx_MORE + ' ▾', C(K_GOLD));
  end
  else if not ShowEnd then
  begin
    case Mode of
      mGo: s := tx_H_GO;
      mTalk: s := tx_H_TALK;
      mChoice: s := tx_H_CHOOSE;
    else
      s := tx_H_NOTES;
    end;
    Txt(TEXT_X, TEXT_Y, s, C(K_DIM));
    if (Mode = mChoice) and (Length(Choices) > 0) and (Choices[0].Code = CH_KEY) and (itList in Items) then
      for j := 0 to High(KEYS) do
        Txt(TEXT_X, TEXT_Y + (j + 1) * LINE_H + 2, KEYS[j] + '  ' + KeyPos(j), C($8AE0A0));
  end;
  // Los botones
  en := not Busy and not ShowEnd and (Mode <> mChoice) and (Ending = 0);
  for i := 0 to 3 do
  begin
    sel := (i = HoverBtn) and en;
    if sel then Bevel(BTN_X[i], BTN_Y[i], BTN_W, BTN_H, C($3A4AA0), C($8A9AF0), C(K_LO))
    else if ((i = 0) and (Mode = mTalk)) or ((i = 2) and (Mode = mGo)) or ((i = 3) and (Mode = mNotes)) then
      Bevel(BTN_X[i], BTN_Y[i], BTN_W, BTN_H, C($2A1A5A), C($6A4AB0), C(K_LO))
    else Bevel(BTN_X[i], BTN_Y[i], BTN_W, BTN_H, C(K_FACE), C(K_HI), C(K_LO));
    Icon(i, BTN_X[i] + 4, BTN_Y[i] + 2, C(IfThen(en, K_GOLD, K_DIM)), C(K_FACE));
    Txt(BTN_X[i] + 20, BTN_Y[i] + 2, ButtonLabel(i), C(IfThen(en, K_INK, K_DIM)));
  end;
  if ShowEnd then DrawEndCard;
end;

// La imagen ampliada (BGRA) con la paleta de esta imagen.
function NewImage(W, H: Integer): TLazIntfImage;
var
  d: TRawImageDescription;
begin
  d.Init_BPP32_B8G8R8A8_BIO_TTB(W, H);
  Result := TLazIntfImage.Create(0, 0);
  Result.DataDescription := d;
end;

procedure BuildImage(Img: TLazIntfImage; S: Integer);
var
  x, y, k: Integer;
  row: PLongWord;
  dev: array[0..255] of LongWord;
  c: LongWord;
begin
  for k := 0 to 255 do dev[k] := $FF000000 or PalRGB[k];
  for y := 0 to VH - 1 do
  begin
    row := PLongWord(Img.GetDataLineStart(y * S));
    for x := 0 to VW - 1 do
    begin
      c := dev[Pix[y, x]];
      for k := 0 to S - 1 do row[x * S + k] := c;
    end;
    for k := 1 to S - 1 do
      Move(row^, Img.GetDataLineStart(y * S + k)^, VW * S * 4);
  end;
end;

procedure SavePNG(const FileName: string);
var
  img: TLazIntfImage;
  w: TFPWriterPNG;
begin
  RenderAll;
  img := NewImage(VW * SCALE, VH * SCALE);
  w := TFPWriterPNG.Create;
  try
    BuildImage(img, SCALE);
    w.UseAlpha := False;
    img.SaveToFile(FileName, w);
  finally
    w.Free;
    img.Free;
  end;
end;

// ============================================================ pruebas
procedure Flush;
var
  n: Integer;
begin
  n := 0;
  while Busy and (n < 200) do
  begin
    Typed := MaxInt div 2;
    Advance;
    Inc(n);
  end;
end;

// Sin ventana: DMS_MALECON_SELFTEST=1. Las cuatro actas de principio a fin,
// los tres finales, la alerta del puerto, la señal de la red y el dibujo de
// todas las escenas y retratos.
function SelfTest: Integer;
var
  fails, k, caught: Integer;
  l: TLoc;
  w: TWho;

  procedure Go(L: TLoc);
  begin
    Mode := mGo;
    DoRow(RowIndex(rkGo, Ord(L)));
  end;

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
  NewGame;
  Check(Busy, 'la partida empieza con la introducción');
  Flush;
  Check((Act = 1) and (Loc = lMalecon), 'acto I en el Malecón');
  // El Socio no da el pase sin las dos baterías
  Go(lAlley);
  Check(Loc = lAlley, 'viajar al callejón');
  Mode := mTalk;
  DoRow(RowIndex(rkTalk, Ord(wSocio)));
  Flush;
  Check(Mode = mChoice, 'el Socio da a elegir');
  Check(RowIndex(rkChoice, CH_TRADE) < 0, 'sin baterías no hay trato');
  DoRow(RowIndex(rkChoice, CH_BYE));
  Flush;
  // Las dos baterías
  Go(lMalecon);
  DoButton(1);
  Flush;
  Check(itCell in Items, 'la pila del muro');
  Go(lPaladar);
  Mode := mTalk;
  DoRow(RowIndex(rkTalk, Ord(wCook)));
  Flush;
  DoButton(1);
  Flush;
  Check(itLithium in Items, 'la batería de la paladar');
  Check(Battery = 40, 'examinar a oscuras gasta la linterna');
  Go(lAlley);
  Mode := mTalk;
  DoRow(RowIndex(rkTalk, Ord(wSocio)));
  Flush;
  Check(RowIndex(rkChoice, CH_CHARGE) >= 0, 'el Socio carga la linterna');
  DoRow(RowIndex(rkChoice, CH_TRADE));
  Flush;
  Check((Act = 2) and (Loc = lGate) and (itPass in Items), 'con el pase, acto II en el puerto');
  // Sin hablar con el guardia no se pasa
  Go(lCargo);
  Flush;
  Check(Loc = lGate, 'el guardia corta el paso');
  Mode := mTalk;
  DoRow(RowIndex(rkTalk, Ord(wGuard)));
  Flush;
  Check(fGuardOK in Flags, 'el guardia deja pasar');
  Go(lCargo);
  DoButton(1);
  Flush;
  Check((itUSB in Items) and (Alert > 0), 'la memoria USB entre el café, con alerta');
  // Esconderse baja la alerta
  k := Alert;
  DoRow(RowIndex(rkHide, 0));
  Flush;
  Check(Alert < k, 'esperar en la sombra baja la alerta');
  // Demasiado ruido: te pillan y Valdés te saca
  Battery := 100;
  caught := 0;
  while (caught < 10) and not (fCaught in Flags) do
  begin
    DoButton(1);
    Flush;
    Inc(caught);
  end;
  Check((fCaught in Flags) and (Loc = lGate) and (Alert = 30), 'pillado: de vuelta en la puerta');
  Battery := 100;
  Go(lBox);
  DoButton(1);
  Flush;
  Check(clTerminal in Clues, 'el terminal: nodo Miramar');
  DoButton(1);
  Flush;
  Check((Act = 3) and (Loc = lShop), 'con la memoria y el listado, acto III');
  // La clave: fallos, señal y la azotea
  Mode := mTalk;
  DoRow(RowIndex(rkTalk, Ord(wYari)));
  Flush;
  Check(clOldTown in Clues, 'la pista de la Habana Vieja');
  DoRow(RowIndex(rkChoice, CH_DECRYPT));
  Check(RowIndex(rkChoice, CH_KEY + KEY_OK) >= 0, 'las claves del listado');
  k := Signal;
  DoRow(RowIndex(rkChoice, CH_KEY));
  Flush;
  Check((Signal <= k - 25) and (Tries = 1), 'una clave mala cuesta señal');
  while Signal > 0 do
  begin
    DoRow(RowIndex(rkChoice, CH_DECRYPT));
    DoRow(RowIndex(rkChoice, CH_KEY + 1));
    Flush;
    if Mode <> mChoice then Break;
  end;
  Check(Signal = 0, 'sin señal');
  Battery := 100;
  Go(lRoof);
  DoButton(1);
  Flush;
  Check(Signal = 100, 'reiniciar el nodo en la azotea');
  Go(lShop);
  Mode := mTalk;
  DoRow(RowIndex(rkTalk, Ord(wYari)));
  Flush;
  DoRow(RowIndex(rkChoice, CH_DECRYPT));
  DoRow(RowIndex(rkChoice, CH_KEY + KEY_OK));
  Flush;
  Check((Act = 4) and (fDecrypted in Flags) and (clFraud in Clues), 'la clave buena: acto IV');
  // Los tres finales
  for k := 0 to 2 do
  begin
    NewGame;
    Flush;
    StartAct(4);
    Go(lServers);
    Mode := mTalk;
    DoRow(RowIndex(rkTalk, Ord(wRamiro)));
    Flush;
    BuildRows;
    Check(Length(Rows) = 3, 'tres decisiones');
    DoRow(RowIndex(rkChoice, CH_END + k));
    Flush;
    Check(ShowEnd and (Ending = k + 1), 'final ' + IntToStr(k + 1));
    RenderAll;
  end;
  // Todas las escenas y todos los retratos, con 256 colores como mucho
  for l := Low(TLoc) to High(TLoc) do
    for k := 0 to 2 do
    begin
      NewGame;
      Flush;
      Loc := l;
      Act := 1 + Ord(l) div 3;
      Anim := k * 7;
      RenderAll;
    end;
  for w := Low(TWho) to High(TWho) do
  begin
    LastWho := w;
    RenderAll;
  end;
  // Los textos de la libreta y del listado caben en el recuadro
  for k := 0 to 4 do DescribeItem(TItem(k));
  Check(not PalFull and (PalMax <= 256), 'cada imagen cabe en 256 colores');
  Check(MaxWrap <= TEXT_LINES, 'cada texto cabe en el recuadro (' + IntToStr(MaxWrap) + ' líneas)');
  if fails = 0 then
    WriteLn('selftest ok acts=4 endings=3 colors=', PalMax, ' lines=', MaxWrap)
  else
    WriteLn('selftest FAILED ', fails);
  Result := Ord(fails > 0);
end;

// Capturas sin abrir la ventana: DMS_MALECON_SHOT=<carpeta>.
function Shots(const Dir: string): Integer;
begin
  ForceDirectories(Dir);
  // 1. El Malecón: el pescador
  NewGame;
  Flush;
  Banner := 0;
  Anim := 12;
  Mode := mTalk;
  TalkTo(wFisher);
  Typed := MaxInt div 2;
  HoverRow := -1;
  SavePNG(Dir + '/malecon.png');
  // 2. La paladar: Yari
  NewGame;
  Flush;
  Banner := 0;
  Travel(lPaladar);
  Mode := mTalk;
  TalkTo(wYari);
  Typed := MaxInt div 2;
  Anim := 5;
  SavePNG(Dir + '/paladar.png');
  // 3. El puerto: la memoria USB entre el café, con la alerta subiendo
  NewGame;
  Flush;
  StartAct(2);
  Banner := 0;
  Include(Flags, fGuardOK);
  Travel(lCargo);
  Look;
  Typed := MaxInt div 2;
  Anim := 40;
  SavePNG(Dir + '/puerto.png');
  // 4. El taller: probar una clave del listado
  NewGame;
  Flush;
  StartAct(3);
  Banner := 0;
  Items := [itUSB, itList];
  Clues := [clBoat, clTerminal, clBirds];
  TalkTo(wYari);
  Flush;
  Choose(CH_DECRYPT);
  LastWho := wYari;
  Anim := 8;
  SavePNG(Dir + '/taller.png');
  // 5. Miramar: la decisión
  NewGame;
  Flush;
  StartAct(4);
  Banner := 0;
  Loc := lServers;
  TalkTo(wRamiro);
  Typed := MaxInt div 2;
  Anim := 3;
  SavePNG(Dir + '/miramar.png');
  WriteLn('shots ok ', Dir);
  Result := 0;
end;

// ============================================================ la ventana
var
  OutImg: TLazIntfImage = nil;
  OutBmp: TBitmap = nil;

procedure TForm1.form_create;
begin
  StageHint.Visible := False;
  Stage.BevelOuter := bvNone;
  Stage.DoubleBuffered := True;
  DoubleBuffered := True;
  if GetEnvironmentVariable('DMS_MALECON_SELFTEST') <> '' then Halt(SelfTest);
  if GetEnvironmentVariable('DMS_MALECON_SHOT') <> '' then
    Halt(Shots(GetEnvironmentVariable('DMS_MALECON_SHOT')));
  Box := TPaintBox.Create(Self);
  Box.Parent := Stage;
  Box.Align := alClient;
  Box.OnPaint := @BoxPaint;
  Box.OnMouseDown := @BoxMouseDown;
  Box.OnMouseMove := @BoxMouseMove;
  OutImg := NewImage(VW * SCALE, VH * SCALE);
  OutBmp := TBitmap.Create;
  NewGame;
  Redraw;
end;

procedure TForm1.form_close;
begin
end;

procedure TForm1.Redraw;
begin
  RenderAll;
  BuildImage(OutImg, SCALE);
  OutBmp.LoadFromIntfImage(OutImg);
  if Box <> nil then Box.Invalidate;
end;

procedure TForm1.BoxPaint(Sender: TObject);
var
  x, y: Integer;
begin
  Box.Canvas.Brush.Color := clBlack;
  Box.Canvas.FillRect(0, 0, Box.Width, Box.Height);
  if OutBmp = nil then Exit;
  x := (Box.Width - OutBmp.Width) div 2;
  y := (Box.Height - OutBmp.Height) div 2;
  Box.Canvas.Draw(x, y, OutBmp);
end;

function TForm1.ToVirtual(X, Y: Integer; out VX, VY: Integer): Boolean;
begin
  VX := (X - (Box.Width - VW * SCALE) div 2) div SCALE;
  VY := (Y - (Box.Height - VH * SCALE) div 2) div SCALE;
  Result := (VX >= 0) and (VY >= 0) and (VX < VW) and (VY < VH);
end;

function RowAt(VX, VY: Integer): Integer;
begin
  Result := -1;
  if (VX >= LIST_X) and (VX < LIST_X + LIST_W) and (VY > LIST_Y) then
  begin
    Result := (VY - LIST_Y - 1) div ROW_H;
    if (Result < 0) or (Result >= MAX_ROWS) or (Result > High(Rows)) then Result := -1;
  end;
end;

function ButtonAt(VX, VY: Integer): Integer;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (VX >= BTN_X[i]) and (VX < BTN_X[i] + BTN_W) and (VY >= BTN_Y[i]) and (VY < BTN_Y[i] + BTN_H) then
      Exit(i);
  Result := -1;
end;

procedure TForm1.BoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  vx, vy, r, b: Integer;
begin
  if not ToVirtual(X, Y, vx, vy) then Exit;
  if ShowEnd then
  begin
    NewGame;
    Redraw;
    Exit;
  end;
  if Busy then
  begin
    Advance;
    Redraw;
    Exit;
  end;
  r := RowAt(vx, vy);
  b := ButtonAt(vx, vy);
  if r >= 0 then DoRow(r)
  else if b >= 0 then DoButton(b);
  Redraw;
end;

procedure TForm1.BoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  vx, vy, r, b: Integer;
begin
  r := -1;
  b := -1;
  if ToVirtual(X, Y, vx, vy) then
  begin
    r := RowAt(vx, vy);
    b := ButtonAt(vx, vy);
  end;
  if (r <> HoverRow) or (b <> HoverBtn) then
  begin
    HoverRow := r;
    HoverBtn := b;
    Redraw;
  end;
end;

// Teclado: 1–6 eligen, Intro o espacio siguen, Esc vuelve a «Viajar» y la
// primera letra de cada botón lo pulsa.
procedure TForm1.form_key;
var
  k: Char;
  i: Integer;
begin
  k := LastKey;
  if ShowEnd and (k in [#13, ' ']) then NewGame
  else if Busy and (k in [#13, ' ']) then Advance
  else if k in ['1'..'6'] then DoRow(Ord(k) - Ord('1'))
  else if (k = #27) and (Mode <> mChoice) then Mode := mGo
  else
    for i := 0 to 3 do
      if UTF8LowerCase(UTF8Copy(ButtonLabel(i), 1, 1)) = LowerCase(k) then DoButton(i);
  Redraw;
end;

// El reloj del diseño, cada 100 ms: el texto que se escribe y lo que se mueve.
procedure TForm1.Tick_timer;
begin
  Inc(Anim);
  if Banner > 0 then Dec(Banner);
  if Busy then Inc(Typed, 4);
  Redraw;
end;

procedure TForm1.Menu1_click(const Item: string);
begin
  if Item = tx_MP_NEW then
  begin
    NewGame;
    Redraw;
  end
  else if Item = tx_MP_QUIT then Close
  else if Item = tx_MP_HOWTO then MessageDlg(tx_L_HOWTO, tx_HOWTO_TEXT, mtInformation, [mbOK], 0)
  else if Item = tx_MP_ABOUT then MessageDlg(tx_L_ABOUT, tx_ABOUT_TEXT, mtInformation, [mbOK], 0);
end;

end.
''';
