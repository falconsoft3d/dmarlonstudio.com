part of 'tk_examples.dart';

// El código en Pascal de OpenD++ (tk_showcase_pascal_opend.dart): la unidad
// Form1.pas entera; el estudio pone los textos en «// @TEXTS».
const _openDCode = r'''
// @TITLE
unit Form1;

{$mode objfpc}{$H+}
{$IFDEF DARWIN}{$modeswitch objectivec1}{$ENDIF}

interface

uses
  {$IFDEF DARWIN}CocoaAll, CocoaGDIObjects,{$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Menus, dms, design, Math, LCLIntf, LCLType,
  IntfGraphics, GraphType, FPImage, FPWritePNG, LazUTF8, Clipbrd, base64, fpjson, jsonparser;

type
  TForm1 = class(TFormDesign)
  private
    Box: TPaintBox;
    procedure BoxPaint(Sender: TObject);
    procedure BoxDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BoxMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BoxUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BoxWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure KeyDownH(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KeyUpH(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Utf8H(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure PopupPick(Sender: TObject);
    procedure SetShortcuts;
  public
    procedure form_create; override;
    procedure form_close; override;
    procedure Tick_timer; override;
    procedure Menu1_click(const Item: string); override;
  end;

implementation

// Los textos (los traduce el estudio con el resto del ejemplo).
const
  // @TEXTS
  // ---- fin de los textos

const
  FILE_HEAD = 'OPEND++ 1';
  CLIP_HEAD = 'OPEND++CLIP 1';

// ================================================================ geometría
type
  TPt = record
    X, Y: Double;
  end;
  TPoly = array of TPt;
  TPolys = array of TPoly;

  { Una transformación afín: x' = A·x + C·y + E;  y' = B·x + D·y + F. }
  TMat = record
    A, B, C, D, E, F: Double;
  end;

  TRectF = record
    L, T, R, B: Double;
  end;

function P2(X, Y: Double): TPt; inline;
begin
  Result.X := X;
  Result.Y := Y;
end;

function RF(L, T, R, B: Double): TRectF;
begin
  Result.L := L;
  Result.T := T;
  Result.R := R;
  Result.B := B;
end;

function MatId: TMat;
begin
  Result.A := 1; Result.B := 0; Result.C := 0;
  Result.D := 1; Result.E := 0; Result.F := 0;
end;

{ M ∘ N: primero N, luego M. }
function MatMul(const M, N: TMat): TMat;
begin
  Result.A := M.A * N.A + M.C * N.B;
  Result.B := M.B * N.A + M.D * N.B;
  Result.C := M.A * N.C + M.C * N.D;
  Result.D := M.B * N.C + M.D * N.D;
  Result.E := M.A * N.E + M.C * N.F + M.E;
  Result.F := M.B * N.E + M.D * N.F + M.F;
end;

function MatT(X, Y: Double): TMat;
begin
  Result := MatId;
  Result.E := X;
  Result.F := Y;
end;

function MatS(SX, SY: Double): TMat;
begin
  Result := MatId;
  Result.A := SX;
  Result.D := SY;
end;

{ Girar [Deg] grados en sentido antihorario (como se ve en pantalla). }
function MatR(Deg: Double): TMat;
var
  a: Double;
begin
  a := -Deg * Pi / 180;
  Result := MatId;
  Result.A := Cos(a); Result.B := Sin(a);
  Result.C := -Sin(a); Result.D := Cos(a);
end;

function MatInv(const M: TMat): TMat;
var
  det: Double;
begin
  det := M.A * M.D - M.B * M.C;
  if Abs(det) < 1e-12 then Exit(MatId);
  Result.A := M.D / det;
  Result.B := -M.B / det;
  Result.C := -M.C / det;
  Result.D := M.A / det;
  Result.E := (M.C * M.F - M.D * M.E) / det;
  Result.F := (M.B * M.E - M.A * M.F) / det;
end;

function MatAp(const M: TMat; const P: TPt): TPt; inline;
begin
  Result.X := M.A * P.X + M.C * P.Y + M.E;
  Result.Y := M.B * P.X + M.D * P.Y + M.F;
end;

{ Cuánto escala la matriz (la media de los dos ejes). }
function MatScale(const M: TMat): Double;
begin
  Result := (Sqrt(M.A * M.A + M.B * M.B) + Sqrt(M.C * M.C + M.D * M.D)) / 2;
end;

function MatRotated(const M: TMat): Boolean;
begin
  Result := (Abs(M.B) > 1e-9) or (Abs(M.C) > 1e-9);
end;

procedure AddPt(var P: TPoly; X, Y: Double); inline;
begin
  SetLength(P, Length(P) + 1);
  P[High(P)].X := X;
  P[High(P)].Y := Y;
end;

procedure AddPoly(var PP: TPolys; const P: TPoly);
begin
  if Length(P) < 2 then Exit;
  SetLength(PP, Length(PP) + 1);
  PP[High(PP)] := P;
end;

procedure AppendPolys(var PP: TPolys; const Q: TPolys);
var
  i: Integer;
begin
  for i := 0 to High(Q) do AddPoly(PP, Q[i]);
end;

function XfPoly(const P: TPoly; const M: TMat): TPoly;
var
  i: Integer;
begin
  SetLength(Result, Length(P));
  for i := 0 to High(P) do Result[i] := MatAp(M, P[i]);
end;

function XfPolys(const PP: TPolys; const M: TMat): TPolys;
var
  i: Integer;
begin
  SetLength(Result, Length(PP));
  for i := 0 to High(PP) do Result[i] := XfPoly(PP[i], M);
end;

function PolyArea(const P: TPoly): Double;
var
  i, j: Integer;
begin
  Result := 0;
  for i := 0 to High(P) do
  begin
    j := (i + 1) mod Length(P);
    Result := Result + P[i].X * P[j].Y - P[j].X * P[i].Y;
  end;
  Result := Result / 2;
end;

function RevPoly(const P: TPoly): TPoly;
var
  i: Integer;
begin
  SetLength(Result, Length(P));
  for i := 0 to High(P) do Result[i] := P[High(P) - i];
end;

function PolysBounds(const PP: TPolys): TRectF;
var
  i, j: Integer;
begin
  Result := RF(1e30, 1e30, -1e30, -1e30);
  for i := 0 to High(PP) do
    for j := 0 to High(PP[i]) do
    begin
      Result.L := Min(Result.L, PP[i][j].X);
      Result.T := Min(Result.T, PP[i][j].Y);
      Result.R := Max(Result.R, PP[i][j].X);
      Result.B := Max(Result.B, PP[i][j].Y);
    end;
end;

function RectPoly(X, Y, W, H: Double): TPoly;
begin
  SetLength(Result, 4);
  Result[0] := P2(X, Y);
  Result[1] := P2(X + W, Y);
  Result[2] := P2(X + W, Y + H);
  Result[3] := P2(X, Y + H);
end;

function ArcSteps(R: Double): Integer;
begin
  Result := EnsureRange(Round(Sqrt(Max(R, 0)) * 3), 4, 64);
end;

{ Un rectángulo redondeado; R se mide en las mismas unidades que W y H. }
function RRectPoly(X, Y, W, H, R: Double; Steps: Integer = 0): TPoly;
var
  k, n: Integer;
  procedure Corner(CX, CY, A0: Double);
  var
    i: Integer;
    a: Double;
  begin
    for i := 0 to n do
    begin
      a := (A0 + 90 * i / n) * Pi / 180;
      AddPt(Result, CX + R * Cos(a), CY + R * Sin(a));
    end;
  end;
begin
  Result := nil;
  R := Min(R, Min(Abs(W), Abs(H)) / 2);
  if R <= 0.01 then Exit(RectPoly(X, Y, W, H));
  n := Steps;
  if n <= 0 then n := ArcSteps(R);
  k := 0;
  Corner(X + W - R, Y + R, -90);
  Corner(X + W - R, Y + H - R, 0);
  Corner(X + R, Y + H - R, 90);
  Corner(X + R, Y + R, 180);
  if k <> 0 then;
end;

function EllipsePoly(CX, CY, RX, RY: Double; Steps: Integer = 0): TPoly;
var
  i, n: Integer;
  a: Double;
begin
  n := Steps;
  if n <= 0 then n := EnsureRange(Round(Sqrt(Max(Abs(RX), Abs(RY))) * 6), 16, 256);
  SetLength(Result, n);
  for i := 0 to n - 1 do
  begin
    a := 2 * Pi * i / n;
    Result[i] := P2(CX + RX * Cos(a), CY + RY * Sin(a));
  end;
end;

{ Desplaza un contorno cerrado (con área positiva) D unidades hacia fuera
  (D < 0: hacia dentro), con las esquinas en inglete. }
function OffsetPoly(const P: TPoly; D: Double): TPoly;
var
  i, n: Integer;
  a, b, c: TPt;
  n1x, n1y, n2x, n2y, mx, my, l, dt: Double;
begin
  n := Length(P);
  SetLength(Result, n);
  for i := 0 to n - 1 do
  begin
    a := P[(i + n - 1) mod n];
    b := P[i];
    c := P[(i + 1) mod n];
    n1x := b.Y - a.Y; n1y := -(b.X - a.X);
    l := Sqrt(n1x * n1x + n1y * n1y);
    if l > 1e-9 then begin n1x := n1x / l; n1y := n1y / l; end;
    n2x := c.Y - b.Y; n2y := -(c.X - b.X);
    l := Sqrt(n2x * n2x + n2y * n2y);
    if l > 1e-9 then begin n2x := n2x / l; n2y := n2y / l; end;
    mx := n1x + n2x; my := n1y + n2y;
    l := Sqrt(mx * mx + my * my);
    if l < 1e-6 then begin mx := n1x; my := n1y; end
    else begin mx := mx / l; my := my / l; end;
    dt := mx * n1x + my * n1y;
    if dt < 0.25 then dt := 0.25;
    Result[i] := P2(b.X + mx * D / dt, b.Y + my * D / dt);
  end;
end;

{ El trazo de un contorno cerrado: de Inner (dentro) a Outer (fuera). }
function StrokeClosed(const P: TPoly; Outer, Inner: Double): TPolys;
var
  Q: TPoly;
begin
  Result := nil;
  if Length(P) < 3 then Exit;
  Q := P;
  if PolyArea(Q) < 0 then Q := RevPoly(Q);
  AddPoly(Result, OffsetPoly(Q, Outer));
  AddPoly(Result, RevPoly(OffsetPoly(Q, -Inner)));
end;

{ El trazo de una línea abierta de grosor W: un cuadrilátero por tramo y un
  círculo en cada unión (y en los extremos si Round). }
function StrokeOpen(const P: TPoly; W: Double; RoundCaps: Boolean): TPolys;
var
  i: Integer;
  dx, dy, l, nx, ny: Double;
  Q: TPoly;
begin
  Result := nil;
  for i := 0 to High(P) - 1 do
  begin
    dx := P[i + 1].X - P[i].X;
    dy := P[i + 1].Y - P[i].Y;
    l := Sqrt(dx * dx + dy * dy);
    if l < 1e-9 then Continue;
    nx := dy / l * W / 2;
    ny := -dx / l * W / 2;
    SetLength(Q, 4);
    Q[0] := P2(P[i].X + nx, P[i].Y + ny);
    Q[1] := P2(P[i + 1].X + nx, P[i + 1].Y + ny);
    Q[2] := P2(P[i + 1].X - nx, P[i + 1].Y - ny);
    Q[3] := P2(P[i].X - nx, P[i].Y - ny);
    if PolyArea(Q) < 0 then Q := RevPoly(Q);
    AddPoly(Result, Q);
    Q := nil;
  end;
  for i := 0 to High(P) do
    if RoundCaps or ((i > 0) and (i < High(P))) then
      AddPoly(Result, EllipsePoly(P[i].X, P[i].Y, W / 2, W / 2, EnsureRange(Round(W * 2), 8, 48)));
end;

{ Parte una línea en trazos de Dash con huecos de Gap. }
function DashPolys(const P: TPoly; Closed: Boolean; Dash, Gap: Double): TPolys;
var
  i, n: Integer;
  a, b: TPt;
  segL, pos, t0, t1, cyc, phase: Double;
  Cur: TPoly;
  procedure Flush;
  begin
    AddPoly(Result, Cur);
    Cur := nil;
  end;
begin
  Result := nil;
  Cur := nil;
  n := Length(P);
  if n < 2 then Exit;
  Dash := Max(Dash, 0.5);
  Gap := Max(Gap, 0.5);
  cyc := Dash + Gap;
  pos := 0;
  for i := 0 to n - 1 do
  begin
    if (i = n - 1) and not Closed then Break;
    a := P[i];
    b := P[(i + 1) mod n];
    segL := Sqrt(Sqr(b.X - a.X) + Sqr(b.Y - a.Y));
    if segL < 1e-9 then Continue;
    t0 := 0;
    while t0 < segL do
    begin
      phase := pos - Floor(pos / cyc) * cyc;
      if phase < Dash - 1e-7 then
      begin
        t1 := Min(segL, t0 + Max(Dash - phase, 1e-6));
        if Length(Cur) = 0 then AddPt(Cur, a.X + (b.X - a.X) * t0 / segL, a.Y + (b.Y - a.Y) * t0 / segL);
        AddPt(Cur, a.X + (b.X - a.X) * t1 / segL, a.Y + (b.Y - a.Y) * t1 / segL);
        if t1 < segL then Flush;
      end
      else
      begin
        t1 := Min(segL, t0 + Max(cyc - phase, 1e-6));
        if Length(Cur) > 0 then Flush;
      end;
      pos := pos + (t1 - t0);
      t0 := t1;
    end;
  end;
  Flush;
end;

function Bez(const A, B, C, D: TPt; T: Double): TPt;
var
  u: Double;
begin
  u := 1 - T;
  Result.X := u * u * u * A.X + 3 * u * u * T * B.X + 3 * u * T * T * C.X + T * T * T * D.X;
  Result.Y := u * u * u * A.Y + 3 * u * u * T * B.Y + 3 * u * T * T * C.Y + T * T * T * D.Y;
end;

// ================================================================== colores
{ Los colores van como $AARRGGBB, sin premultiplicar. }
function ARGB(A, R, G, B: Integer): LongWord; inline;
begin
  Result := (LongWord(EnsureRange(A, 0, 255)) shl 24) or (LongWord(EnsureRange(R, 0, 255)) shl 16) or
    (LongWord(EnsureRange(G, 0, 255)) shl 8) or LongWord(EnsureRange(B, 0, 255));
end;

function CA(C: LongWord): Integer; inline;
begin
  Result := C shr 24;
end;

function CR(C: LongWord): Integer; inline;
begin
  Result := (C shr 16) and $FF;
end;

function CG(C: LongWord): Integer; inline;
begin
  Result := (C shr 8) and $FF;
end;

function CB(C: LongWord): Integer; inline;
begin
  Result := C and $FF;
end;

{ '#rrggbb' o '#rrggbbaa'. }
function HexC(const S: string): LongWord;
var
  h: string;
begin
  h := StringReplace(Trim(S), '#', '', []);
  if Length(h) = 3 then h := h[1] + h[1] + h[2] + h[2] + h[3] + h[3];
  if Length(h) = 6 then
    Result := $FF000000 or LongWord(StrToIntDef('$' + h, 0))
  else if Length(h) = 8 then
    Result := (LongWord(StrToIntDef('$' + Copy(h, 7, 2), 255)) shl 24) or LongWord(StrToIntDef('$' + Copy(h, 1, 6), 0))
  else
    Result := $FF000000;
end;

function HexOf(C: LongWord): string;
begin
  Result := IntToHex(C and $FFFFFF, 6);
end;

function WithA(C: LongWord; A: Double): LongWord;
begin
  Result := (C and $FFFFFF) or (LongWord(EnsureRange(Round(CA(C) * A), 0, 255)) shl 24);
end;

function SetA(C: LongWord; A: Integer): LongWord;
begin
  Result := (C and $FFFFFF) or (LongWord(EnsureRange(A, 0, 255)) shl 24);
end;

function Mix(C1, C2: LongWord; T: Double): LongWord;
begin
  Result := ARGB(Round(CA(C1) + (CA(C2) - CA(C1)) * T), Round(CR(C1) + (CR(C2) - CR(C1)) * T),
    Round(CG(C1) + (CG(C2) - CG(C1)) * T), Round(CB(C1) + (CB(C2) - CB(C1)) * T));
end;

function Lum(C: LongWord): Double;
begin
  Result := (0.299 * CR(C) + 0.587 * CG(C) + 0.114 * CB(C)) / 255;
end;

procedure ToHSV(C: LongWord; out H, S, V: Double);
var
  r, g, b, mx, mn, d: Double;
begin
  r := CR(C) / 255; g := CG(C) / 255; b := CB(C) / 255;
  mx := Max(r, Max(g, b)); mn := Min(r, Min(g, b));
  d := mx - mn;
  V := mx;
  if mx > 0 then S := d / mx else S := 0;
  if d = 0 then H := 0
  else if mx = r then H := 60 * (((g - b) / d) - 6 * Floor(((g - b) / d) / 6))
  else if mx = g then H := 60 * ((b - r) / d + 2)
  else H := 60 * ((r - g) / d + 4);
  if H < 0 then H := H + 360;
end;

function FromHSV(H, S, V: Double; A: Integer): LongWord;
var
  c, x, m, r, g, b: Double;
  k: Integer;
begin
  H := H - 360 * Floor(H / 360);
  c := V * S;
  x := c * (1 - Abs(Frac(H / 120) * 2 - 1));
  m := V - c;
  k := Trunc(H / 60);
  case k of
    0: begin r := c; g := x; b := 0; end;
    1: begin r := x; g := c; b := 0; end;
    2: begin r := 0; g := c; b := x; end;
    3: begin r := 0; g := x; b := c; end;
    4: begin r := x; g := 0; b := c; end;
  else
    begin r := c; g := 0; b := x; end;
  end;
  Result := ARGB(A, Round((r + m) * 255), Round((g + m) * 255), Round((b + m) * 255));
end;

// ============================================================ la superficie
type
  { Píxeles premultiplicados $AARRGGBB (el mismo orden de bytes que BGRA). }
  TSurface = class
  public
    W, H: Integer;
    P: array of LongWord;
    Clip: TRect;
    constructor Create(AW, AH: Integer);
    procedure Resize(AW, AH: Integer);
    procedure Clear(C: LongWord);
  end;

  TImgData = class
  public
    W, H: Integer;
    P: array of LongWord; // sin premultiplicar
  end;

  TMask = class
  public
    W, H: Integer;
    A: array of Byte;
  end;

  TPaintKind = (pkSolid, pkLinear, pkImage, pkMask);
  TPaintSrc = record
    Kind: TPaintKind;
    C1, C2: LongWord;
    GX, GY, GDX, GDY: Double;
    Img: TImgData;
    Mask: TMask;
    Inv: TMat;
    Clamp: Boolean;
  end;

  { Cuánto cubre la forma cada píxel de su recuadro. }
  TCov = record
    X0, Y0, W, H, Stride: Integer;
    A: array of Single;
  end;

constructor TSurface.Create(AW, AH: Integer);
begin
  inherited Create;
  Resize(AW, AH);
end;

procedure TSurface.Resize(AW, AH: Integer);
begin
  W := Max(1, AW);
  H := Max(1, AH);
  SetLength(P, W * H);
  Clip := Rect(0, 0, W, H);
end;

procedure TSurface.Clear(C: LongWord);
var
  i: Integer;
  pm: LongWord;
  a: Integer;
begin
  a := CA(C);
  pm := (LongWord(a) shl 24) or (LongWord(CR(C) * a div 255) shl 16) or
    (LongWord(CG(C) * a div 255) shl 8) or LongWord(CB(C) * a div 255);
  for i := 0 to W * H - 1 do P[i] := pm;
  Clip := Rect(0, 0, W, H);
end;

var
  Surf: TSurface = nil;

function Solid(C: LongWord): TPaintSrc;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Kind := pkSolid;
  Result.C1 := C;
end;

{ Mezcla el color C (sin premultiplicar) con cobertura A sobre D. }
procedure BlendPx(var D: LongWord; C: LongWord; A: Single); inline;
var
  sa, ia, al, r, g, b: Integer;
begin
  sa := Round(A * (C shr 24));
  if sa <= 0 then Exit;
  if sa >= 255 then
  begin
    D := C or $FF000000;
    Exit;
  end;
  ia := 255 - sa;
  al := sa + ((D shr 24) * ia + 127) div 255;
  r := (((C shr 16) and $FF) * sa + ((D shr 16) and $FF) * ia + 127) div 255;
  g := (((C shr 8) and $FF) * sa + ((D shr 8) and $FF) * ia + 127) div 255;
  b := ((C and $FF) * sa + (D and $FF) * ia + 127) div 255;
  D := (LongWord(al) shl 24) or (LongWord(r) shl 16) or (LongWord(g) shl 8) or LongWord(b);
end;

function ClipOf(const R: TRect): TRect;
begin
  Result.Left := Max(R.Left, Surf.Clip.Left);
  Result.Top := Max(R.Top, Surf.Clip.Top);
  Result.Right := Min(R.Right, Surf.Clip.Right);
  Result.Bottom := Min(R.Bottom, Surf.Clip.Bottom);
end;

{ Un rectángulo en píxeles de la superficie, con los bordes suavizados. }
procedure FillRectD(X0, Y0, X1, Y1: Double; C: LongWord; Alpha: Double = 1);
var
  x, y, ix0, iy0, ix1, iy1: Integer;
  cy, cx, cov: Double;
  R: TRect;
  op: Boolean;
  pc: LongWord;
begin
  if (X1 <= X0) or (Y1 <= Y0) or (CA(C) = 0) or (Alpha <= 0) then Exit;
  ix0 := Floor(X0); iy0 := Floor(Y0); ix1 := Ceil(X1); iy1 := Ceil(Y1);
  R := ClipOf(Rect(ix0, iy0, ix1, iy1));
  op := (CA(C) = 255) and (Alpha >= 1);
  pc := C or $FF000000;
  for y := R.Top to R.Bottom - 1 do
  begin
    cy := Min(Y1, y + 1) - Max(Y0, y);
    for x := R.Left to R.Right - 1 do
    begin
      cx := Min(X1, x + 1) - Max(X0, x);
      cov := cx * cy;
      if op and (cov >= 0.999) then
        Surf.P[y * Surf.W + x] := pc
      else
        BlendPx(Surf.P[y * Surf.W + x], C, cov * Alpha);
    end;
  end;
end;

// ======================================================= el rasterizador
{ Acumula el área con signo de un tramo (como font-rs): al sumar cada fila
  sale la cobertura exacta de cada píxel, con la regla de no-cero. }
procedure AccLine(var C: TCov; X0, Y0, X1, Y1: Double);
var
  dir, dxdy, x, xnext, d, dy, x0f, x1f, s, a0, a1, a2, am, xmf, t, ax0, ax1, tmp: Double;
  y, yEnd, x0i, x1i, xi, ls: Integer;
begin
  if Abs(Y0 - Y1) < 1e-9 then Exit;
  if Y0 < Y1 then dir := 1
  else
  begin
    dir := -1;
    tmp := X0; X0 := X1; X1 := tmp;
    tmp := Y0; Y0 := Y1; Y1 := tmp;
  end;
  dxdy := (X1 - X0) / (Y1 - Y0);
  x := X0;
  if Y0 < 0 then x := x - Y0 * dxdy;
  y := Max(0, Floor(Y0));
  yEnd := Min(C.H, Ceil(Y1));
  while y < yEnd do
  begin
    ls := y * C.Stride;
    dy := Min(y + 1, Y1) - Max(y, Y0);
    xnext := x + dxdy * dy;
    d := dy * dir;
    if x < xnext then begin ax0 := x; ax1 := xnext; end
    else begin ax0 := xnext; ax1 := x; end;
    ax0 := EnsureRange(ax0, 0, C.W);
    ax1 := EnsureRange(ax1, 0, C.W);
    x0f := Floor(ax0);
    x0i := Trunc(x0f);
    x1i := Ceil(ax1);
    if x1i <= x0i + 1 then
    begin
      xmf := EnsureRange(0.5 * (ax0 + ax1) - x0f, 0, 1);
      C.A[ls + x0i] := C.A[ls + x0i] + d - d * xmf;
      C.A[ls + x0i + 1] := C.A[ls + x0i + 1] + d * xmf;
    end
    else
    begin
      s := 1 / (ax1 - ax0);
      t := ax0 - x0f;
      a0 := 0.5 * s * (1 - t) * (1 - t);
      x1f := ax1 - x1i + 1;
      am := 0.5 * s * x1f * x1f;
      C.A[ls + x0i] := C.A[ls + x0i] + d * a0;
      if x1i = x0i + 2 then
        C.A[ls + x0i + 1] := C.A[ls + x0i + 1] + d * (1 - a0 - am)
      else
      begin
        a1 := s * (1.5 - t);
        C.A[ls + x0i + 1] := C.A[ls + x0i + 1] + d * (a1 - a0);
        for xi := x0i + 2 to x1i - 2 do
          C.A[ls + xi] := C.A[ls + xi] + d * s;
        a2 := a1 + (x1i - x0i - 3) * s;
        C.A[ls + x1i - 1] := C.A[ls + x1i - 1] + d * (1 - a2 - am);
      end;
      C.A[ls + x1i] := C.A[ls + x1i] + d * am;
    end;
    x := xnext;
    Inc(y);
  end;
end;

{ Un tramo recortado a los lados: lo que queda fuera, pegado al borde. }
procedure CovSeg(var C: TCov; X0, Y0, X1, Y1: Double);
var
  W, t, ym: Double;
begin
  W := C.W;
  if ((X0 < 0) and (X1 > 0)) or ((X0 > 0) and (X1 < 0)) then
  begin
    t := -X0 / (X1 - X0);
    ym := Y0 + t * (Y1 - Y0);
    CovSeg(C, X0, Y0, 0, ym);
    CovSeg(C, 0, ym, X1, Y1);
    Exit;
  end;
  if ((X0 < W) and (X1 > W)) or ((X0 > W) and (X1 < W)) then
  begin
    t := (W - X0) / (X1 - X0);
    ym := Y0 + t * (Y1 - Y0);
    CovSeg(C, X0, Y0, W, ym);
    CovSeg(C, W, ym, X1, Y1);
    Exit;
  end;
  AccLine(C, EnsureRange(X0, 0, W), Y0, EnsureRange(X1, 0, W), Y1);
end;

function BuildCov(const PP: TPolys; const Clip: TRect; out C: TCov): Boolean;
var
  b: TRectF;
  i, j, k, x, y: Integer;
  acc: Single;
  p, q: TPt;
begin
  C.W := 0; C.H := 0; C.A := nil;
  b := PolysBounds(PP);
  if b.L > b.R then Exit(False);
  C.X0 := Max(Floor(b.L), Clip.Left);
  C.Y0 := Max(Floor(b.T), Clip.Top);
  C.W := Min(Ceil(b.R) + 1, Clip.Right) - C.X0;
  C.H := Min(Ceil(b.B) + 1, Clip.Bottom) - C.Y0;
  if (C.W <= 0) or (C.H <= 0) then Exit(False);
  if Int64(C.W) * C.H > 40000000 then Exit(False);
  C.Stride := C.W + 2;
  SetLength(C.A, C.Stride * C.H + 2);
  for i := 0 to High(PP) do
  begin
    k := Length(PP[i]);
    for j := 0 to k - 1 do
    begin
      p := PP[i][j];
      q := PP[i][(j + 1) mod k];
      CovSeg(C, p.X - C.X0, p.Y - C.Y0, q.X - C.X0, q.Y - C.Y0);
    end;
  end;
  for y := 0 to C.H - 1 do
  begin
    acc := 0;
    for x := 0 to C.W - 1 do
    begin
      acc := acc + C.A[y * C.Stride + x];
      C.A[y * C.Stride + x] := Min(1, Abs(acc));
    end;
  end;
  Result := True;
end;

{ Desenfoque de caja (tres pasadas ≈ gaussiano) que agranda el recuadro. }
procedure BlurCov(var C: TCov; R: Integer);
var
  N: TCov;
  pass, x, y, m, i, lo, hi: Integer;
  sum: Single;
  line, outl: array of Single;
begin
  if (R <= 0) or (C.W <= 0) then Exit;
  m := 3 * R;
  N.X0 := C.X0 - m; N.Y0 := C.Y0 - m;
  N.W := C.W + 2 * m; N.H := C.H + 2 * m;
  N.Stride := N.W + 2;
  SetLength(N.A, N.Stride * N.H + 2);
  for y := 0 to C.H - 1 do
    for x := 0 to C.W - 1 do
      N.A[(y + m) * N.Stride + x + m] := C.A[y * C.Stride + x];
  SetLength(line, Max(N.W, N.H));
  SetLength(outl, Max(N.W, N.H));
  for pass := 1 to 3 do
  begin
    for y := 0 to N.H - 1 do
    begin
      for x := 0 to N.W - 1 do line[x] := N.A[y * N.Stride + x];
      sum := 0;
      for i := 0 to Min(R, N.W - 1) do sum := sum + line[i];
      for x := 0 to N.W - 1 do
      begin
        outl[x] := sum / (2 * R + 1);
        hi := x + R + 1; lo := x - R;
        if hi < N.W then sum := sum + line[hi];
        if lo >= 0 then sum := sum - line[lo];
      end;
      for x := 0 to N.W - 1 do N.A[y * N.Stride + x] := outl[x];
    end;
    for x := 0 to N.W - 1 do
    begin
      for y := 0 to N.H - 1 do line[y] := N.A[y * N.Stride + x];
      sum := 0;
      for i := 0 to Min(R, N.H - 1) do sum := sum + line[i];
      for y := 0 to N.H - 1 do
      begin
        outl[y] := sum / (2 * R + 1);
        hi := y + R + 1; lo := y - R;
        if hi < N.H then sum := sum + line[hi];
        if lo >= 0 then sum := sum - line[lo];
      end;
      for y := 0 to N.H - 1 do N.A[y * N.Stride + x] := outl[y];
    end;
  end;
  C := N;
end;

function SampleImg(Img: TImgData; U, V: Double; Clamp: Boolean): LongWord;
var
  x0, y0, x1, y1: Integer;
  fx, fy: Double;
  c00, c10, c01, c11: LongWord;
  function Ch(Sh: Integer): Integer;
  var
    a, b: Double;
  begin
    a := ((c00 shr Sh) and $FF) * (1 - fx) + ((c10 shr Sh) and $FF) * fx;
    b := ((c01 shr Sh) and $FF) * (1 - fx) + ((c11 shr Sh) and $FF) * fx;
    Result := Round(a * (1 - fy) + b * fy);
  end;
begin
  U := U - 0.5; V := V - 0.5;
  if not Clamp and ((U < -1) or (V < -1) or (U > Img.W) or (V > Img.H)) then Exit(0);
  x0 := Floor(U); y0 := Floor(V);
  fx := U - x0; fy := V - y0;
  x1 := EnsureRange(x0 + 1, 0, Img.W - 1); y1 := EnsureRange(y0 + 1, 0, Img.H - 1);
  x0 := EnsureRange(x0, 0, Img.W - 1); y0 := EnsureRange(y0, 0, Img.H - 1);
  c00 := Img.P[y0 * Img.W + x0]; c10 := Img.P[y0 * Img.W + x1];
  c01 := Img.P[y1 * Img.W + x0]; c11 := Img.P[y1 * Img.W + x1];
  Result := (LongWord(Ch(24)) shl 24) or (LongWord(Ch(16)) shl 16) or (LongWord(Ch(8)) shl 8) or LongWord(Ch(0));
end;

function SampleMask(M: TMask; U, V: Double): Double;
var
  x0, y0: Integer;
  fx, fy, a, b: Double;
  function At(X, Y: Integer): Double;
  begin
    if (X < 0) or (Y < 0) or (X >= M.W) or (Y >= M.H) then Exit(0);
    Result := M.A[Y * M.W + X] / 255;
  end;
begin
  U := U - 0.5; V := V - 0.5;
  x0 := Floor(U); y0 := Floor(V);
  fx := U - x0; fy := V - y0;
  a := At(x0, y0) * (1 - fx) + At(x0 + 1, y0) * fx;
  b := At(x0, y0 + 1) * (1 - fx) + At(x0 + 1, y0 + 1) * fx;
  Result := a * (1 - fy) + b * fy;
end;

{ Pinta la cobertura con la pintura Src (DX, DY: desplazada, las sombras). }
procedure Composite(const C: TCov; const Src: TPaintSrc; Alpha: Double; DX: Integer = 0; DY: Integer = 0);
var
  x, y, px, py: Integer;
  cov, t, m: Double;
  col: LongWord;
  q: TPt;
  R: TRect;
begin
  if (C.W <= 0) or (Alpha <= 0) then Exit;
  R := ClipOf(Rect(C.X0 + DX, C.Y0 + DY, C.X0 + DX + C.W, C.Y0 + DY + C.H));
  col := Src.C1;
  for py := R.Top to R.Bottom - 1 do
  begin
    y := py - C.Y0 - DY;
    for px := R.Left to R.Right - 1 do
    begin
      x := px - C.X0 - DX;
      cov := C.A[y * C.Stride + x];
      if cov < 0.003 then Continue;
      case Src.Kind of
        pkLinear:
          begin
            t := EnsureRange((px + 0.5 - Src.GX) * Src.GDX + (py + 0.5 - Src.GY) * Src.GDY, 0, 1);
            col := Mix(Src.C1, Src.C2, t);
          end;
        pkImage:
          begin
            q := MatAp(Src.Inv, P2(px + 0.5, py + 0.5));
            col := SampleImg(Src.Img, q.X, q.Y, Src.Clamp);
          end;
        pkMask:
          begin
            q := MatAp(Src.Inv, P2(px + 0.5, py + 0.5));
            m := SampleMask(Src.Mask, q.X, q.Y);
            if m <= 0.003 then Continue;
            cov := cov * m;
          end;
      end;
      BlendPx(Surf.P[py * Surf.W + px], col, cov * Alpha);
    end;
  end;
end;

procedure FillPolys(const PP: TPolys; const Src: TPaintSrc; Alpha: Double = 1);
var
  C: TCov;
begin
  if Length(PP) = 0 then Exit;
  if BuildCov(PP, Surf.Clip, C) then Composite(C, Src, Alpha);
end;

procedure FillPoly(const P: TPoly; Col: LongWord; Alpha: Double = 1);
var
  PP: TPolys;
begin
  PP := nil;
  AddPoly(PP, P);
  FillPolys(PP, Solid(Col), Alpha);
end;

{ La sombra de una forma: su cobertura, desenfocada y desplazada. }
procedure ShadowPolys(const PP: TPolys; Col: LongWord; DX, DY, Blur: Double);
var
  C: TCov;
  R: TRect;
  m: Integer;
begin
  m := Ceil(Blur * 1.5) + Ceil(Abs(DX)) + Ceil(Abs(DY)) + 2;
  R := Surf.Clip;
  InflateRect(R, m, m);
  if not BuildCov(PP, R, C) then Exit;
  BlurCov(C, Round(Blur / 2));
  Composite(C, Solid(Col), 1, Round(DX), Round(DY));
end;

procedure LineD(X0, Y0, X1, Y1, W: Double; Col: LongWord; Alpha: Double = 1);
var
  P: TPoly;
begin
  P := nil;
  AddPt(P, X0, Y0);
  AddPt(P, X1, Y1);
  FillPolys(StrokeOpen(P, W, False), Solid(Col), Alpha);
end;

// ================================================================ el texto
var
  MaskBmp: TBitmap = nil;
  MaskCache: TStringList = nil;
  WidthCache: TStringList = nil;
  ImgCache: TStringList = nil;
  UIFont: string = 'default';
  DocFont: string = 'Helvetica';

procedure SetMaskFont(const Name: string; Px: Integer; Bold, Italic: Boolean);
var
  st: TFontStyles;
begin
  if MaskBmp = nil then
  begin
    MaskBmp := TBitmap.Create;
    MaskBmp.SetSize(8, 8);
  end;
  MaskBmp.Canvas.Font.Name := Name;
  MaskBmp.Canvas.Font.Height := -Max(1, Px);
  st := [];
  if Bold then Include(st, fsBold);
  if Italic then Include(st, fsItalic);
  MaskBmp.Canvas.Font.Style := st;
  MaskBmp.Canvas.Font.Quality := fqAntialiased;
end;

function FontKey(const Name: string; Px: Integer; Bold, Italic: Boolean): string;
begin
  Result := Name + '|' + IntToStr(Px) + '|' + IntToStr(Ord(Bold)) + IntToStr(Ord(Italic)) + '|';
end;

{ Lo que mide un texto (píxeles) con esa letra. }
function TextPx(const S, Name: string; Px: Integer; Bold, Italic: Boolean): Integer;
var
  k: string;
  i: Integer;
begin
  if S = '' then Exit(0);
  if WidthCache = nil then
  begin
    WidthCache := TStringList.Create;
    WidthCache.Sorted := True;
  end;
  k := FontKey(Name, Px, Bold, Italic) + S;
  i := WidthCache.IndexOf(k);
  if i >= 0 then Exit(PtrInt(WidthCache.Objects[i]));
  SetMaskFont(Name, Px, Bold, Italic);
  Result := MaskBmp.Canvas.TextWidth(S);
  if WidthCache.Count > 20000 then WidthCache.Clear;
  WidthCache.AddObject(k, TObject(PtrInt(Result)));
end;

function LineHPx(const Name: string; Px: Integer; Bold, Italic: Boolean): Integer;
begin
  Result := Round(Px * 1.22);
  if Name = '' then;
  if Bold or Italic then;
end;

{ El texto como máscara de cobertura (blanco sobre negro), guardada. }
function TextMask(const S, Name: string; Px: Integer; Bold, Italic: Boolean): TMask;
var
  k: string;
  i, x, y, w, h: Integer;
  Img: TLazIntfImage;
  c: TFPColor;
begin
  if MaskCache = nil then
  begin
    MaskCache := TStringList.Create;
    MaskCache.Sorted := True;
    MaskCache.OwnsObjects := True;
  end;
  k := FontKey(Name, Px, Bold, Italic) + S;
  i := MaskCache.IndexOf(k);
  if i >= 0 then Exit(TMask(MaskCache.Objects[i]));
  SetMaskFont(Name, Px, Bold, Italic);
  w := Max(1, MaskBmp.Canvas.TextWidth(S) + Px div 3 + 4);
  h := Max(1, LineHPx(Name, Px, Bold, Italic) + Px div 4 + 2);
  MaskBmp.SetSize(w, h);
  MaskBmp.Canvas.Brush.Style := bsSolid;
  MaskBmp.Canvas.Brush.Color := clBlack;
  MaskBmp.Canvas.FillRect(0, 0, w, h);
  MaskBmp.Canvas.Font.Color := clWhite;
  MaskBmp.Canvas.Brush.Style := bsClear;
  MaskBmp.Canvas.TextOut(2, (LineHPx(Name, Px, Bold, Italic) - MaskBmp.Canvas.TextHeight('Ág')) div 2, S);
  Result := TMask.Create;
  Result.W := w;
  Result.H := h;
  SetLength(Result.A, w * h);
  Img := MaskBmp.CreateIntfImage;
  try
    for y := 0 to h - 1 do
      for x := 0 to w - 1 do
      begin
        c := Img.Colors[x, y];
        Result.A[y * w + x] := Max(c.red, Max(c.green, c.blue)) shr 8;
      end;
  finally
    Img.Free;
  end;
  if MaskCache.Count > 3000 then MaskCache.Clear;
  MaskCache.AddObject(k, Result);
end;

{ Pega una máscara en (X, Y) píxeles, sin girar. }
procedure DrawMask(M: TMask; X, Y: Integer; Col: LongWord; Alpha: Double = 1);
var
  R: TRect;
  px, py: Integer;
  a: Byte;
begin
  R := ClipOf(Rect(X, Y, X + M.W, Y + M.H));
  for py := R.Top to R.Bottom - 1 do
    for px := R.Left to R.Right - 1 do
    begin
      a := M.A[(py - Y) * M.W + (px - X)];
      if a > 0 then BlendPx(Surf.P[py * Surf.W + px], Col, a / 255 * Alpha);
    end;
end;

{ Una máscara con cualquier transformación (máscara → superficie). }
procedure DrawMaskXf(M: TMask; const Mt: TMat; Col: LongWord; Alpha: Double = 1);
var
  Src: TPaintSrc;
  PP: TPolys;
begin
  PP := nil;
  AddPoly(PP, XfPoly(RectPoly(0, 0, M.W, M.H), Mt));
  Src := Solid(Col);
  Src.Kind := pkMask;
  Src.Mask := M;
  Src.Inv := MatInv(Mt);
  FillPolys(PP, Src, Alpha);
end;

// =============================================================== imágenes
function LoadImg(const Path: string): TImgData;
var
  i, x, y, sx, sy, f: Integer;
  Pic: TPicture;
  Img: TLazIntfImage;
  c: TFPColor;
begin
  Result := nil;
  if Path = '' then Exit;
  if ImgCache = nil then
  begin
    ImgCache := TStringList.Create;
    ImgCache.Sorted := True;
    ImgCache.OwnsObjects := True;
  end;
  i := ImgCache.IndexOf(Path);
  if i >= 0 then Exit(TImgData(ImgCache.Objects[i]));
  if not FileExists(Path) then Exit;
  Pic := TPicture.Create;
  try
    try
      Pic.LoadFromFile(Path);
      if not (Pic.Graphic is TRasterImage) then Exit;
      Img := TRasterImage(Pic.Graphic).CreateIntfImage;
      try
        f := 1;
        while (Img.Width div f > 2048) or (Img.Height div f > 2048) do Inc(f);
        Result := TImgData.Create;
        Result.W := Max(1, Img.Width div f);
        Result.H := Max(1, Img.Height div f);
        SetLength(Result.P, Result.W * Result.H);
        for y := 0 to Result.H - 1 do
          for x := 0 to Result.W - 1 do
          begin
            sx := x * f; sy := y * f;
            c := Img.Colors[sx, sy];
            Result.P[y * Result.W + x] := ARGB(c.alpha shr 8, c.red shr 8, c.green shr 8, c.blue shr 8);
          end;
      finally
        Img.Free;
      end;
    except
      FreeAndNil(Result);
    end;
  finally
    Pic.Free;
  end;
  if Result <> nil then ImgCache.AddObject(Path, Result);
end;

{ La superficie como PNG (con transparencia). }
procedure SaveSurfPNG(S: TSurface; const FileName: string);
var
  Img: TLazIntfImage;
  d: TRawImageDescription;
  w: TFPWriterPNG;
  y, x, a: Integer;
  row: PLongWord;
  c: LongWord;
begin
  d.Init_BPP32_B8G8R8A8_BIO_TTB(S.W, S.H);
  Img := TLazIntfImage.Create(0, 0);
  w := TFPWriterPNG.Create;
  try
    Img.DataDescription := d;
    for y := 0 to S.H - 1 do
    begin
      row := PLongWord(Img.GetDataLineStart(y));
      for x := 0 to S.W - 1 do
      begin
        c := S.P[y * S.W + x];
        a := CA(c);
        if (a > 0) and (a < 255) then
          c := ARGB(a, CR(c) * 255 div a, CG(c) * 255 div a, CB(c) * 255 div a);
        row[x] := c;
      end;
    end;
    w.UseAlpha := True;
    Img.SaveToFile(FileName, w);
  finally
    w.Free;
    Img.Free;
  end;
end;

// ============================================================ el documento
type
  TKind = (kFrame, kGroup, kRect, kEllipse, kLine, kArrow, kPolygon, kStar,
    kPath, kText, kComponent, kInstance);
  TFillKind = (fkSolid, fkLinear, fkImage);

  { Un relleno o un trazo: color, degradado o imagen. }
  TFill = record
    Vis: Boolean;
    Kind: TFillKind;
    C1, C2: LongWord;
    Angle: Double;
    Img: string;
    Fit: Boolean;
    Style: string; // el estilo de color enlazado ('' = ninguno)
  end;

  { Un punto de un trazado: el ancla y sus dos tiradores (relativos). }
  TVPt = record
    X, Y, IX, IY, OX, OY: Double;
    Curve: Boolean;
  end;

  { Una capa. Las coordenadas son las de su marco (los grupos no mueven). }
  TNode = class
  public
    Id: Integer;
    Kind: TKind;
    Name: string;
    Parent: TNode;
    Kids: TFPList;
    X, Y, W, H, Rot, Radius, Opacity: Double;
    Visible, Locked, Open: Boolean;
    Fill, Stroke: TFill;
    StrokeW: Double;
    StrokePos: Integer; // 0 centro, 1 dentro, 2 fuera
    Dash: Boolean;
    ShOn: Boolean;
    ShX, ShY, ShBlur: Double;
    ShColor: LongWord;
    Sides: Integer;
    Ratio: Double;
    Pts: array of TVPt;
    Closed: Boolean;
    Text, Font: string;
    Size, LineH, Spacing: Double;
    Bold, Italic, AutoW: Boolean;
    Align: Integer;   // 0 izquierda, 1 centro, 2 derecha
    Clip: Boolean;
    Layout: Integer;  // 0 nada, 1 horizontal, 2 vertical
    Gap, Pad: Double;
    Hug: Boolean;
    LAlign: Integer;  // 0 inicio, 1 centro, 2 final
    CompId: Integer;
    Over: TStringList; // instancias: id de la capa del componente → texto
    Link, Anim, Dur: Integer;
    constructor Create(AKind: TKind);
    destructor Destroy; override;
    function Kid(I: Integer): TNode;
    function Count: Integer;
  end;

  TPage = class
  public
    Name: string;
    Root: TNode;
    Bg: LongWord;
    StartId: Integer;
    constructor Create(const AName: string);
    destructor Destroy; override;
  end;

  TComment = class
  public
    Page: Integer;
    X, Y: Double;
    Text, Who, When: string;
    Done: Boolean;
  end;

const
  KindNames: array[TKind] of string = ('frame', 'group', 'rect', 'ellipse',
    'line', 'arrow', 'polygon', 'star', 'path', 'text', 'component', 'instance');

var
  Pages: TFPList = nil;
  PageIx: Integer = 0;
  Comments: TFPList = nil;
  Styles: TStringList = nil; // nombre=AARRGGBB
  NextId: Integer = 1;
  DocName: string = '';
  FileName: string = '';
  Dirty: Boolean = False;
  NameCount: array[TKind] of Integer;
  FS: TFormatSettings;

constructor TNode.Create(AKind: TKind);
begin
  inherited Create;
  Kind := AKind;
  Kids := TFPList.Create;
  Over := TStringList.Create;
  Visible := True;
  Opacity := 1;
  Open := False;
  StrokeW := 1;
  Fill.C1 := $FFD9D9D9;
  Fill.C2 := $FF000000;
  Fill.Angle := 90;
  Stroke.C1 := $FF000000;
  Stroke.C2 := $FFFFFFFF;
  ShColor := $40000000;
  ShY := 4;
  ShBlur := 12;
  Sides := 5;
  Ratio := 0.38;
  Size := 16;
  Font := DocFont;
  Dur := 300;
end;

destructor TNode.Destroy;
var
  i: Integer;
begin
  for i := 0 to Kids.Count - 1 do TNode(Kids[i]).Free;
  Kids.Free;
  Over.Free;
  inherited Destroy;
end;

function TNode.Kid(I: Integer): TNode;
begin
  Result := TNode(Kids[I]);
end;

function TNode.Count: Integer;
begin
  Result := Kids.Count;
end;

constructor TPage.Create(const AName: string);
begin
  inherited Create;
  Name := AName;
  Root := TNode.Create(kGroup);
  Root.Name := AName;
  Bg := 0; // 0: el del tema
end;

destructor TPage.Destroy;
begin
  Root.Free;
  inherited Destroy;
end;

function Page: TPage;
begin
  Result := TPage(Pages[PageIx]);
end;

function PageN(I: Integer): TPage;
begin
  Result := TPage(Pages[I]);
end;

function KindLabel(K: TKind): string;
begin
  case K of
    kFrame: Result := tx_K_FRAME;
    kGroup: Result := tx_K_GROUP;
    kRect: Result := tx_K_RECT;
    kEllipse: Result := tx_K_ELLIPSE;
    kLine: Result := tx_K_LINE;
    kArrow: Result := tx_K_ARROW;
    kPolygon: Result := tx_K_POLYGON;
    kStar: Result := tx_K_STAR;
    kPath: Result := tx_K_PATH;
    kText: Result := tx_K_TEXT;
    kComponent: Result := tx_K_COMPONENT;
  else
    Result := tx_K_INSTANCE;
  end;
end;

function IsBox(N: TNode): Boolean;
begin
  Result := N.Kind in [kFrame, kComponent, kInstance];
end;

function IsContainer(N: TNode): Boolean;
begin
  Result := (N.Parent = nil) or (N.Kind in [kFrame, kComponent, kGroup]);
end;

procedure AddKid(P, N: TNode; Index: Integer = -1);
begin
  N.Parent := P;
  if (Index < 0) or (Index > P.Kids.Count) then P.Kids.Add(N)
  else P.Kids.Insert(Index, N);
end;

procedure Unlink(N: TNode);
begin
  if N.Parent <> nil then N.Parent.Kids.Remove(N);
  N.Parent := nil;
end;

function IndexIn(N: TNode): Integer;
begin
  if N.Parent = nil then Exit(-1);
  Result := N.Parent.Kids.IndexOf(N);
end;

{ La capa y todas las de dentro, en orden. }
procedure Flatten(N: TNode; L: TFPList; WithSelf: Boolean = True);
var
  i: Integer;
begin
  if WithSelf then L.Add(N);
  for i := 0 to N.Count - 1 do Flatten(N.Kid(i), L);
end;

function IsInside(N, Anc: TNode): Boolean;
begin
  while N <> nil do
  begin
    if N = Anc then Exit(True);
    N := N.Parent;
  end;
  Result := False;
end;

function FindIn(N: TNode; Id: Integer): TNode;
var
  i: Integer;
begin
  if N.Id = Id then Exit(N);
  for i := 0 to N.Count - 1 do
  begin
    Result := FindIn(N.Kid(i), Id);
    if Result <> nil then Exit;
  end;
  Result := nil;
end;

function FindNode(Id: Integer): TNode;
var
  i: Integer;
begin
  Result := nil;
  if Id <= 0 then Exit;
  for i := 0 to Pages.Count - 1 do
  begin
    Result := FindIn(PageN(i).Root, Id);
    if Result <> nil then Exit;
  end;
end;

function RootOf(N: TNode): TNode;
begin
  Result := N;
  while Result.Parent <> nil do Result := Result.Parent;
end;

function PageOfNode(N: TNode): Integer;
var
  r: TNode;
  i: Integer;
begin
  r := RootOf(N);
  for i := 0 to Pages.Count - 1 do
    if PageN(i).Root = r then Exit(i);
  Result := -1;
end;

{ El marco de arriba del todo (el del lienzo) que contiene la capa. }
function TopFrame(N: TNode): TNode;
begin
  Result := nil;
  while (N <> nil) and (N.Parent <> nil) do
  begin
    if (N.Parent.Parent = nil) and IsBox(N) then Exit(N);
    N := N.Parent;
  end;
end;

function DefaultFill(K: TKind): TFill;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Vis := True;
  Result.Kind := fkSolid;
  Result.C1 := $FFD9D9D9;
  Result.C2 := $FF12B886;
  Result.Angle := 180;
  case K of
    kFrame, kComponent: Result.C1 := $FFFFFFFF;
    kText: Result.C1 := $FF000000;
    kGroup, kLine, kArrow, kInstance: Result.Vis := False;
  end;
end;

function NewNode(K: TKind; P: TNode; AX, AY, AW, AH: Double): TNode;
begin
  Result := TNode.Create(K);
  Result.Id := NextId;
  Inc(NextId);
  Result.X := AX; Result.Y := AY; Result.W := AW; Result.H := AH;
  Result.Fill := DefaultFill(K);
  Result.Stroke := DefaultFill(kRect);
  Result.Stroke.Vis := K in [kLine, kArrow, kPath];
  Result.Stroke.C1 := $FF000000;
  if K = kPolygon then Result.Sides := 3;
  if K = kFrame then Result.Clip := True;
  if K = kText then Result.AutoW := True;
  Inc(NameCount[K]);
  if K = kText then Result.Name := ''
  else Result.Name := KindLabel(K) + ' ' + IntToStr(NameCount[K]);
  if P <> nil then AddKid(P, Result);
end;

function NodeName(N: TNode): string;
begin
  if N.Name <> '' then Result := N.Name
  else if N.Kind = kText then
  begin
    Result := StringReplace(N.Text, #10, ' ', [rfReplaceAll]);
    if UTF8Length(Result) > 40 then Result := UTF8Copy(Result, 1, 40) + '…';
    if Result = '' then Result := KindLabel(kText);
  end
  else Result := KindLabel(N.Kind);
end;

// ------------------------------------------------------ estilos de color
function StyleColor(const Name: string; Def: LongWord): LongWord;
var
  i: Integer;
begin
  Result := Def;
  if (Name = '') or (Styles = nil) then Exit;
  i := Styles.IndexOfName(Name);
  if i >= 0 then Result := LongWord(StrToInt64Def('$' + Styles.ValueFromIndex[i], Def));
end;

function FillC1(const F: TFill): LongWord;
begin
  Result := StyleColor(F.Style, F.C1);
end;

// ------------------------------------------------------------ los textos
function DocUnits(N: TNode; const S: string): Double;
begin
  Result := TextPx(S, N.Font, Round(N.Size * 4), N.Bold, N.Italic) / 4;
  if N.Spacing <> 0 then Result := Result + N.Spacing * N.Size / 100 * UTF8Length(S);
end;

function LineHOf(N: TNode): Double;
begin
  if N.LineH > 0 then Result := N.Size * N.LineH / 100
  else Result := N.Size * 1.22;
end;

{ Las líneas del texto: las suyas y, con ancho fijo, partidas por palabras. }
function TextLines(N: TNode): TStringList;
var
  raw: TStringList;
  i, j: Integer;
  words: TStringArray;
  cur, tryS: string;
begin
  Result := TStringList.Create;
  raw := TStringList.Create;
  try
    raw.Text := N.Text;
    if (N.Text = '') or (N.Text[Length(N.Text)] = #10) then raw.Add('');
    for i := 0 to raw.Count - 1 do
    begin
      if N.AutoW or (N.W <= 1) then
      begin
        Result.Add(raw[i]);
        Continue;
      end;
      words := raw[i].Split([' ']);
      cur := '';
      for j := 0 to High(words) do
      begin
        if cur = '' then tryS := words[j] else tryS := cur + ' ' + words[j];
        if (cur <> '') and (DocUnits(N, tryS) > N.W + 0.5) then
        begin
          Result.Add(cur);
          cur := words[j];
        end
        else cur := tryS;
      end;
      Result.Add(cur);
    end;
  finally
    raw.Free;
  end;
end;

procedure FitText(N: TNode);
var
  L: TStringList;
  i: Integer;
  mw: Double;
begin
  L := TextLines(N);
  try
    if N.AutoW then
    begin
      mw := 1;
      for i := 0 to L.Count - 1 do mw := Max(mw, DocUnits(N, L[i]));
      N.W := Ceil(mw);
    end;
    N.H := Ceil(L.Count * LineHOf(N));
  finally
    L.Free;
  end;
end;

// ------------------------------------------------------------ geometría
function LocalMat(N: TNode): TMat;
begin
  Result := MatT(N.X, N.Y);
  if N.Rot <> 0 then
    Result := MatMul(Result, MatMul(MatT(N.W / 2, N.H / 2), MatMul(MatR(N.Rot), MatT(-N.W / 2, -N.H / 2))));
end;

function WorldOf(N: TNode): TMat; forward;

{ El sistema de coordenadas de lo que va dentro de N. }
function ChildMat(N: TNode): TMat;
begin
  if (N = nil) or (N.Parent = nil) then Result := MatId
  else if N.Kind = kGroup then Result := ChildMat(N.Parent)
  else Result := WorldOf(N);
end;

function WorldOf(N: TNode): TMat;
begin
  if N.Parent = nil then Result := MatId
  else Result := MatMul(ChildMat(N.Parent), LocalMat(N));
end;

{ El recuadro (sin girar) que ocupa la capa en el espacio de su padre. }
function BoxIn(N: TNode): TRectF;
var
  P: TPoly;
  PP: TPolys;
begin
  P := XfPoly(RectPoly(0, 0, N.W, N.H), LocalMat(N));
  PP := nil;
  AddPoly(PP, P);
  Result := PolysBounds(PP);
end;

function WorldBox(N: TNode): TRectF;
var
  PP: TPolys;
begin
  PP := nil;
  AddPoly(PP, XfPoly(RectPoly(0, 0, N.W, N.H), WorldOf(N)));
  Result := PolysBounds(PP);
end;

function Union(const A, B: TRectF): TRectF;
begin
  Result := RF(Min(A.L, B.L), Min(A.T, B.T), Max(A.R, B.R), Max(A.B, B.B));
end;

function PathPoly(N: TNode; Sc: Double): TPoly;
var
  i, j, k, np, steps: Integer;
  a, b: TVPt;
  pa, pb, pc, pd, q: TPt;
begin
  Result := nil;
  np := Length(N.Pts);
  if np = 0 then Exit;
  AddPt(Result, N.Pts[0].X, N.Pts[0].Y);
  k := np - 1;
  if N.Closed then k := np;
  for i := 0 to k - 1 do
  begin
    a := N.Pts[i];
    b := N.Pts[(i + 1) mod np];
    if a.Curve or b.Curve then
    begin
      pa := P2(a.X, a.Y); pd := P2(b.X, b.Y);
      pb := P2(a.X + a.OX, a.Y + a.OY);
      pc := P2(b.X + b.IX, b.Y + b.IY);
      steps := EnsureRange(Round(Sqrt(Sqr(pd.X - pa.X) + Sqr(pd.Y - pa.Y)) * Sc / 6), 6, 64);
      for j := 1 to steps do
      begin
        q := Bez(pa, pb, pc, pd, j / steps);
        AddPt(Result, q.X, q.Y);
      end;
    end
    else AddPt(Result, b.X, b.Y);
  end;
  if N.Closed and (Length(Result) > 1) then SetLength(Result, Length(Result) - 1);
end;

{ El contorno de la capa en su espacio (0..W, 0..H); Sc: píxeles por unidad. }
function Outline(N: TNode; Sc: Double): TPoly;
var
  i, np: Integer;
  a, r: Double;
begin
  Result := nil;
  case N.Kind of
    kEllipse:
      Result := EllipsePoly(N.W / 2, N.H / 2, N.W / 2, N.H / 2,
        EnsureRange(Round(Sqrt(Max(N.W, N.H) * Sc) * 6), 16, 360));
    kPolygon, kStar:
      begin
        np := Max(3, N.Sides);
        if N.Kind = kStar then np := np * 2;
        for i := 0 to np - 1 do
        begin
          a := (-90 + 360 * i / np) * Pi / 180;
          r := 1;
          if (N.Kind = kStar) and Odd(i) then r := N.Ratio;
          AddPt(Result, N.W / 2 + N.W / 2 * r * Cos(a), N.H / 2 + N.H / 2 * r * Sin(a));
        end;
      end;
    kPath, kLine, kArrow: Result := PathPoly(N, Sc);
    kText, kGroup: Result := RectPoly(0, 0, N.W, N.H);
  else
    Result := RRectPoly(0, 0, N.W, N.H, N.Radius, EnsureRange(ArcSteps(N.Radius * Sc), 4, 64));
  end;
end;

function IsOpenPath(N: TNode): Boolean;
begin
  Result := (N.Kind in [kLine, kArrow]) or ((N.Kind = kPath) and not N.Closed);
end;

procedure ScalePts(N: TNode; SX, SY: Double);
var
  i: Integer;
begin
  for i := 0 to High(N.Pts) do
  begin
    N.Pts[i].X := N.Pts[i].X * SX; N.Pts[i].Y := N.Pts[i].Y * SY;
    N.Pts[i].IX := N.Pts[i].IX * SX; N.Pts[i].IY := N.Pts[i].IY * SY;
    N.Pts[i].OX := N.Pts[i].OX * SX; N.Pts[i].OY := N.Pts[i].OY * SY;
  end;
end;

{ Cambia el tamaño de una capa (y de lo que tenga dentro si es un grupo). }
procedure SetSize(N: TNode; NW, NH: Double);
var
  sx, sy: Double;
begin
  NW := Max(NW, 0); NH := Max(NH, 0);
  if N.Kind in [kPath, kLine, kArrow] then
  begin
    if N.W > 0.001 then sx := NW / N.W else sx := 1;
    if N.H > 0.001 then sy := NH / N.H else sy := 1;
    ScalePts(N, sx, sy);
  end;
  N.W := NW;
  N.H := NH;
  if N.Kind = kText then N.AutoW := False;
end;

procedure MoveNode(N: TNode; DX, DY: Double);
var
  i: Integer;
begin
  if N.Kind = kGroup then
    for i := 0 to N.Count - 1 do MoveNode(N.Kid(i), DX, DY);
  N.X := N.X + DX;
  N.Y := N.Y + DY;
end;

{ Escala la capa respecto a (OX, OY) del espacio de su padre. }
procedure ScaleNode(N: TNode; OX, OY, SX, SY: Double);
var
  i: Integer;
begin
  if N.Kind = kGroup then
    for i := 0 to N.Count - 1 do ScaleNode(N.Kid(i), OX, OY, SX, SY);
  N.X := OX + (N.X - OX) * SX;
  N.Y := OY + (N.Y - OY) * SY;
  if N.Kind <> kGroup then SetSize(N, N.W * SX, N.H * SY);
end;

{ Coloca los hijos de un marco con diseño automático. }
procedure Relayout(F: TNode);
var
  i: Integer;
  k: TNode;
  pos, cross, ext: Double;
begin
  if F.Layout = 0 then Exit;
  pos := F.Pad;
  cross := 0;
  for i := 0 to F.Count - 1 do
  begin
    k := F.Kid(i);
    if not k.Visible then Continue;
    if F.Layout = 1 then
    begin
      MoveNode(k, pos - k.X, 0);
      pos := pos + k.W + F.Gap;
      cross := Max(cross, k.H);
    end
    else
    begin
      MoveNode(k, 0, pos - k.Y);
      pos := pos + k.H + F.Gap;
      cross := Max(cross, k.W);
    end;
  end;
  if pos > F.Pad then pos := pos - F.Gap;
  if F.Hug then
  begin
    if F.Layout = 1 then
    begin
      F.W := pos + F.Pad;
      F.H := cross + 2 * F.Pad;
    end
    else
    begin
      F.H := pos + F.Pad;
      F.W := cross + 2 * F.Pad;
    end;
  end;
  for i := 0 to F.Count - 1 do
  begin
    k := F.Kid(i);
    if F.Layout = 1 then ext := F.H - 2 * F.Pad - k.H
    else ext := F.W - 2 * F.Pad - k.W;
    case F.LAlign of
      0: ext := 0;
      1: ext := ext / 2;
    end;
    if F.Layout = 1 then MoveNode(k, 0, F.Pad + ext - k.Y)
    else MoveNode(k, F.Pad + ext - k.X, 0);
  end;
end;

{ Pone al día lo que se calcula: textos, diseño automático, grupos. }
procedure Normalize(N: TNode);
var
  i: Integer;
  b: TRectF;
  first: Boolean;
  k: TNode;
begin
  for i := N.Count - 1 downto 0 do
  begin
    k := N.Kid(i);
    Normalize(k);
    if (k.Kind = kGroup) and (k.Count = 0) then
    begin
      Unlink(k);
      k.Free;
    end;
  end;
  if N.Parent = nil then Exit;
  case N.Kind of
    kText: FitText(N);
    kGroup:
      begin
        first := True;
        b := RF(0, 0, 0, 0);
        for i := 0 to N.Count - 1 do
          if first then begin b := BoxIn(N.Kid(i)); first := False; end
          else b := Union(b, BoxIn(N.Kid(i)));
        N.X := b.L; N.Y := b.T; N.W := b.R - b.L; N.H := b.B - b.T;
        N.Rot := 0;
      end;
  end;
  if (N.Kind in [kFrame, kComponent]) and (N.Layout <> 0) then Relayout(N);
end;

procedure NormalizeAll;
var
  i: Integer;
begin
  for i := 0 to Pages.Count - 1 do Normalize(PageN(i).Root);
end;

// ------------------------------------------------------ guardar y abrir
function Esc(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
    case S[i] of
      '\': Result := Result + '\\';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #13: ;
    else
      Result := Result + S[i];
    end;
end;

function Unesc(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  i := 1;
  while i <= Length(S) do
  begin
    if (S[i] = '\') and (i < Length(S)) then
    begin
      Inc(i);
      case S[i] of
        't': Result := Result + #9;
        'n': Result := Result + #10;
      else
        Result := Result + S[i];
      end;
    end
    else Result := Result + S[i];
    Inc(i);
  end;
end;

function F2S(D: Double): string;
begin
  if Abs(D - Round(D)) < 1e-6 then Result := IntToStr(Round(D))
  else Result := FloatToStrF(D, ffGeneral, 9, 0, FS);
end;

function S2F(const S: string): Double;
begin
  Result := StrToFloatDef(Trim(StringReplace(S, ',', '.', [])), 0, FS);
end;

function B2S(B: Boolean): string;
begin
  Result := IntToStr(Ord(B));
end;

function KV(const K, V: string): string;
begin
  Result := #9 + K + '=' + Esc(V);
end;

function FillStr(const P: string; const F: TFill): string;
begin
  Result := KV(P + 'v', B2S(F.Vis)) + KV(P + 'k', IntToStr(Ord(F.Kind))) +
    KV(P + '1', IntToHex(F.C1, 8)) + KV(P + '2', IntToHex(F.C2, 8)) +
    KV(P + 'a', F2S(F.Angle)) + KV(P + 'i', F.Img) + KV(P + 'f', B2S(F.Fit)) +
    KV(P + 's', F.Style);
end;

function PtsStr(N: TNode): string;
var
  i: Integer;
  p: TVPt;
begin
  Result := '';
  for i := 0 to High(N.Pts) do
  begin
    p := N.Pts[i];
    if i > 0 then Result := Result + ';';
    Result := Result + F2S(p.X) + ',' + F2S(p.Y) + ',' + F2S(p.IX) + ',' + F2S(p.IY) + ',' +
      F2S(p.OX) + ',' + F2S(p.OY) + ',' + B2S(p.Curve);
  end;
end;

procedure ParsePts(N: TNode; const S: string);
var
  items, f: TStringArray;
  i: Integer;
begin
  N.Pts := nil;
  if S = '' then Exit;
  items := S.Split([';']);
  SetLength(N.Pts, Length(items));
  for i := 0 to High(items) do
  begin
    f := items[i].Split([',']);
    if Length(f) < 7 then Continue;
    N.Pts[i].X := S2F(f[0]); N.Pts[i].Y := S2F(f[1]);
    N.Pts[i].IX := S2F(f[2]); N.Pts[i].IY := S2F(f[3]);
    N.Pts[i].OX := S2F(f[4]); N.Pts[i].OY := S2F(f[5]);
    N.Pts[i].Curve := f[6] = '1';
  end;
end;

function NodeToLine(N: TNode; ParentId: Integer): string;
var
  i: Integer;
begin
  Result := 'node' + KV('id', IntToStr(N.Id)) + KV('p', IntToStr(ParentId)) +
    KV('k', KindNames[N.Kind]) + KV('n', N.Name) +
    KV('x', F2S(N.X)) + KV('y', F2S(N.Y)) + KV('w', F2S(N.W)) + KV('h', F2S(N.H)) +
    KV('r', F2S(N.Rot)) + KV('rad', F2S(N.Radius)) + KV('op', F2S(N.Opacity)) +
    KV('vis', B2S(N.Visible)) + KV('lock', B2S(N.Locked)) + KV('open', B2S(N.Open)) +
    FillStr('f', N.Fill) + FillStr('s', N.Stroke) +
    KV('sw', F2S(N.StrokeW)) + KV('sp', IntToStr(N.StrokePos)) + KV('dash', B2S(N.Dash)) +
    KV('sh', B2S(N.ShOn)) + KV('shx', F2S(N.ShX)) + KV('shy', F2S(N.ShY)) +
    KV('shb', F2S(N.ShBlur)) + KV('shc', IntToHex(N.ShColor, 8)) +
    KV('sides', IntToStr(N.Sides)) + KV('ratio', F2S(N.Ratio)) +
    KV('pts', PtsStr(N)) + KV('cl', B2S(N.Closed)) +
    KV('t', N.Text) + KV('font', N.Font) + KV('size', F2S(N.Size)) +
    KV('b', B2S(N.Bold)) + KV('it', B2S(N.Italic)) + KV('lh', F2S(N.LineH)) +
    KV('ls', F2S(N.Spacing)) + KV('al', IntToStr(N.Align)) + KV('aw', B2S(N.AutoW)) +
    KV('clip', B2S(N.Clip)) + KV('lay', IntToStr(N.Layout)) + KV('gap', F2S(N.Gap)) +
    KV('pad', F2S(N.Pad)) + KV('hug', B2S(N.Hug)) + KV('la', IntToStr(N.LAlign)) +
    KV('comp', IntToStr(N.CompId)) + KV('link', IntToStr(N.Link)) +
    KV('anim', IntToStr(N.Anim)) + KV('dur', IntToStr(N.Dur));
  for i := 0 to N.Over.Count - 1 do
    Result := Result + KV('o' + N.Over.Names[i], N.Over.ValueFromIndex[i]);
end;

procedure ApplyFill(var F: TFill; C: Char; const V: string);
begin
  case C of
    'v': F.Vis := V = '1';
    'k': F.Kind := TFillKind(EnsureRange(StrToIntDef(V, 0), 0, 2));
    '1': F.C1 := LongWord(StrToInt64Def('$' + V, $FF000000));
    '2': F.C2 := LongWord(StrToInt64Def('$' + V, $FF000000));
    'a': F.Angle := S2F(V);
    'i': F.Img := V;
    'f': F.Fit := V = '1';
    's': F.Style := V;
  end;
end;

procedure ApplyField(N: TNode; const K, V: string);
var
  kk: TKind;
begin
  if K = 'n' then N.Name := V
  else if K = 'k' then
  begin
    for kk := Low(TKind) to High(TKind) do
      if KindNames[kk] = V then N.Kind := kk;
  end
  else if K = 'x' then N.X := S2F(V)
  else if K = 'y' then N.Y := S2F(V)
  else if K = 'w' then N.W := S2F(V)
  else if K = 'h' then N.H := S2F(V)
  else if K = 'r' then N.Rot := S2F(V)
  else if K = 'rad' then N.Radius := S2F(V)
  else if K = 'op' then N.Opacity := S2F(V)
  else if K = 'vis' then N.Visible := V = '1'
  else if K = 'lock' then N.Locked := V = '1'
  else if K = 'open' then N.Open := V = '1'
  else if (Length(K) = 2) and (K[1] = 'f') and (K[2] in ['v', 'k', '1', '2', 'a', 'i', 'f', 's']) then ApplyFill(N.Fill, K[2], V)
  else if (Length(K) = 2) and (K[1] = 's') and (K[2] in ['v', 'k', '1', '2', 'a', 'i', 'f', 's']) then ApplyFill(N.Stroke, K[2], V)
  else if K = 'sw' then N.StrokeW := S2F(V)
  else if K = 'sp' then N.StrokePos := StrToIntDef(V, 0)
  else if K = 'dash' then N.Dash := V = '1'
  else if K = 'sh' then N.ShOn := V = '1'
  else if K = 'shx' then N.ShX := S2F(V)
  else if K = 'shy' then N.ShY := S2F(V)
  else if K = 'shb' then N.ShBlur := S2F(V)
  else if K = 'shc' then N.ShColor := LongWord(StrToInt64Def('$' + V, $40000000))
  else if K = 'sides' then N.Sides := StrToIntDef(V, 5)
  else if K = 'ratio' then N.Ratio := S2F(V)
  else if K = 'pts' then ParsePts(N, V)
  else if K = 'cl' then N.Closed := V = '1'
  else if K = 't' then N.Text := V
  else if K = 'font' then N.Font := V
  else if K = 'size' then N.Size := S2F(V)
  else if K = 'b' then N.Bold := V = '1'
  else if K = 'it' then N.Italic := V = '1'
  else if K = 'lh' then N.LineH := S2F(V)
  else if K = 'ls' then N.Spacing := S2F(V)
  else if K = 'al' then N.Align := StrToIntDef(V, 0)
  else if K = 'aw' then N.AutoW := V = '1'
  else if K = 'clip' then N.Clip := V = '1'
  else if K = 'lay' then N.Layout := StrToIntDef(V, 0)
  else if K = 'gap' then N.Gap := S2F(V)
  else if K = 'pad' then N.Pad := S2F(V)
  else if K = 'hug' then N.Hug := V = '1'
  else if K = 'la' then N.LAlign := StrToIntDef(V, 0)
  else if K = 'comp' then N.CompId := StrToIntDef(V, 0)
  else if K = 'link' then N.Link := StrToIntDef(V, 0)
  else if K = 'anim' then N.Anim := StrToIntDef(V, 0)
  else if K = 'dur' then N.Dur := StrToIntDef(V, 300)
  else if (Length(K) > 1) and (K[1] = 'o') then N.Over.Values[Copy(K, 2, MaxInt)] := V;
end;

procedure WriteTree(N: TNode; ParentId: Integer; L: TStrings);
var
  i: Integer;
begin
  L.Add(NodeToLine(N, ParentId));
  for i := 0 to N.Count - 1 do WriteTree(N.Kid(i), N.Id, L);
end;

function DocText: string;
var
  L: TStringList;
  i, j: Integer;
  c: TComment;
begin
  L := TStringList.Create;
  try
    L.Add(FILE_HEAD);
    L.Add('doc' + KV('n', DocName));
    for i := 0 to Styles.Count - 1 do
      L.Add('style' + KV('n', Styles.Names[i]) + KV('c', Styles.ValueFromIndex[i]));
    for i := 0 to Pages.Count - 1 do
    begin
      L.Add('page' + KV('n', PageN(i).Name) + KV('bg', IntToHex(PageN(i).Bg, 8)) +
        KV('start', IntToStr(PageN(i).StartId)));
      for j := 0 to PageN(i).Root.Count - 1 do WriteTree(PageN(i).Root.Kid(j), 0, L);
    end;
    for i := 0 to Comments.Count - 1 do
    begin
      c := TComment(Comments[i]);
      L.Add('comment' + KV('pg', IntToStr(c.Page)) + KV('x', F2S(c.X)) + KV('y', F2S(c.Y)) +
        KV('t', c.Text) + KV('who', c.Who) + KV('when', c.When) + KV('done', B2S(c.Done)));
    end;
    Result := L.Text;
  finally
    L.Free;
  end;
end;

procedure ClearDoc;
var
  i: Integer;
  k: TKind;
begin
  if Pages <> nil then
    for i := 0 to Pages.Count - 1 do PageN(i).Free
  else
    Pages := TFPList.Create;
  Pages.Clear;
  if Comments <> nil then
    for i := 0 to Comments.Count - 1 do TComment(Comments[i]).Free
  else
    Comments := TFPList.Create;
  Comments.Clear;
  if Styles = nil then Styles := TStringList.Create;
  Styles.Clear;
  NextId := 1;
  PageIx := 0;
  for k := Low(TKind) to High(TKind) do NameCount[k] := 0;
end;

{ Parte una línea «tipo\tclave=valor…» en sus campos. }
function SplitFields(const Line: string; out Kind: string): TStringList;
var
  f: TStringArray;
  i, e: Integer;
begin
  Result := TStringList.Create;
  f := Line.Split([#9]);
  Kind := '';
  if Length(f) = 0 then Exit;
  Kind := f[0];
  for i := 1 to High(f) do
  begin
    e := Pos('=', f[i]);
    if e > 0 then Result.Add(Copy(f[i], 1, e - 1) + '=' + Unesc(Copy(f[i], e + 1, MaxInt)));
  end;
end;

function FieldsNode(F: TStringList): TNode;
var
  i: Integer;
begin
  Result := TNode.Create(kRect);
  Result.Fill.Vis := False;
  for i := 0 to F.Count - 1 do ApplyField(Result, F.Names[i], F.ValueFromIndex[i]);
  Result.Id := StrToIntDef(F.Values['id'], 0);
end;

{ Lee un documento; False si no lo es. }
function LoadDocText(const S: string): Boolean;
var
  L, F: TStringList;
  i, pid: Integer;
  kind: string;
  pg: TPage;
  N, P: TNode;
  map: TStringList;
  c: TComment;
begin
  Result := False;
  L := TStringList.Create;
  map := TStringList.Create;
  try
    L.Text := S;
    if (L.Count = 0) or (Trim(L[0]) <> FILE_HEAD) then Exit;
    ClearDoc;
    pg := nil;
    map.Sorted := True;
    for i := 1 to L.Count - 1 do
    begin
      F := SplitFields(L[i], kind);
      try
        if kind = 'doc' then DocName := F.Values['n']
        else if kind = 'style' then Styles.Add(F.Values['n'] + '=' + F.Values['c'])
        else if kind = 'page' then
        begin
          pg := TPage.Create(F.Values['n']);
          pg.Bg := LongWord(StrToInt64Def('$' + F.Values['bg'], 0));
          pg.StartId := StrToIntDef(F.Values['start'], 0);
          Pages.Add(pg);
        end
        else if (kind = 'node') and (pg <> nil) then
        begin
          N := FieldsNode(F);
          pid := StrToIntDef(F.Values['p'], 0);
          P := pg.Root;
          if (pid > 0) and (map.IndexOf(IntToStr(pid)) >= 0) then
            P := TNode(map.Objects[map.IndexOf(IntToStr(pid))]);
          AddKid(P, N);
          map.AddObject(IntToStr(N.Id), N);
          NextId := Max(NextId, N.Id + 1);
          Inc(NameCount[N.Kind]);
        end
        else if kind = 'comment' then
        begin
          c := TComment.Create;
          c.Page := StrToIntDef(F.Values['pg'], 0);
          c.X := S2F(F.Values['x']);
          c.Y := S2F(F.Values['y']);
          c.Text := F.Values['t'];
          c.Who := F.Values['who'];
          c.When := F.Values['when'];
          c.Done := F.Values['done'] = '1';
          Comments.Add(c);
        end;
      finally
        F.Free;
      end;
    end;
    if Pages.Count = 0 then Pages.Add(TPage.Create(tx_PAGE + ' 1'));
    NormalizeAll;
    Result := True;
  finally
    map.Free;
    L.Free;
  end;
end;

// ============================================================ tema y vista
var
  Dark: Boolean = True;
  // Los colores de la interfaz (los cambia el tema).
  CPanel, CRail, CCanvas, CLine, CText, CMuted, CField, CHover, CSelBg: LongWord;

const
  CAccent = $FF12B886;  // el color de OpenD++
  CAccent2 = $FF0EA472;
  CComp = $FFD946EF;    // componentes e instancias
  CProto = $FF38BDF8;   // conexiones del prototipo
  CGuide = $FFFF4D6D;   // guías inteligentes y medidas
  CWarn = $FFF59E0B;

procedure ApplyTheme;
begin
  if Dark then
  begin
    CPanel := $FF1F2128; CRail := $FF17181D; CCanvas := $FF141519;
    CLine := $FF30333C; CText := $FFE8EAF0; CMuted := $FF9AA0AC;
    CField := $FF2A2D36; CHover := $FF2C2F39; CSelBg := $FF1D3B33;
  end
  else
  begin
    CPanel := $FFFFFFFF; CRail := $FFF6F7F9; CCanvas := $FFEBECEF;
    CLine := $FFE3E5EA; CText := $FF1F2329; CMuted := $FF6B7280;
    CField := $FFF2F3F6; CHover := $FFEEF0F4; CSelBg := $FFD9F5EC;
  end;
end;

const
  TopH = 46;
  RailW = 52;
  InspW = 272;
  RightW = 262;
  StatusH = 26;
  RulerW = 20;

var
  S: Double = 1;           // píxeles de la superficie por punto
  WinW: Double = 1360;
  WinH: Double = 840;
  Zoom: Double = 1;
  PanX: Double = 0;
  PanY: Double = 0;
  CX0, CY0, CX1, CY1: Double; // el lienzo (puntos de la ventana)
  Mode: Integer = 0;        // 0 diseño, 1 prototipo, 2 código
  Rulers: Boolean = True;
  PixGrid: Boolean = True;
  SnapOn: Boolean = True;

procedure LayoutRegions;
begin
  CX0 := RailW + InspW;
  CY0 := TopH;
  CX1 := WinW - RightW;
  CY1 := WinH - StatusH;
  if Rulers then
  begin
    CX0 := CX0 + RulerW;
    CY0 := CY0 + RulerW;
  end;
end;

{ Del documento a la superficie (píxeles). }
function DevMat: TMat;
begin
  Result := MatMul(MatS(S, S), MatMul(MatT(CX0 + PanX, CY0 + PanY), MatS(Zoom, Zoom)));
end;

function W2SX(X: Double): Double;
begin
  Result := CX0 + PanX + X * Zoom;
end;

function W2SY(Y: Double): Double;
begin
  Result := CY0 + PanY + Y * Zoom;
end;

function S2W(X, Y: Double): TPt;
begin
  Result := P2((X - CX0 - PanX) / Zoom, (Y - CY0 - PanY) / Zoom);
end;

function PageBg(Pg: TPage): LongWord;
begin
  if Pg.Bg = 0 then Result := CCanvas else Result := Pg.Bg;
end;

// ======================================================= dibujar las capas
var
  DrawDepth: Integer = 0;

function PaintOf(const F: TFill; const M: TMat; W, H: Double): TPaintSrc;
var
  a, len, vx, vy, l2, s1: Double;
  ps, pe: TPt;
  img: TImgData;
  im: TMat;
begin
  Result := Solid(FillC1(F));
  case F.Kind of
    fkLinear:
      begin
        a := F.Angle * Pi / 180;
        len := Abs(W * Sin(a)) + Abs(H * Cos(a));
        ps := MatAp(M, P2(W / 2 - Sin(a) * len / 2, H / 2 + Cos(a) * len / 2));
        pe := MatAp(M, P2(W / 2 + Sin(a) * len / 2, H / 2 - Cos(a) * len / 2));
        vx := pe.X - ps.X; vy := pe.Y - ps.Y;
        l2 := vx * vx + vy * vy;
        if l2 < 1e-9 then Exit;
        Result.Kind := pkLinear;
        Result.C2 := F.C2;
        Result.GX := ps.X; Result.GY := ps.Y;
        Result.GDX := vx / l2; Result.GDY := vy / l2;
      end;
    fkImage:
      begin
        img := LoadImg(F.Img);
        if img = nil then
        begin
          Result := Solid($FFC9CDD4);
          Exit;
        end;
        if F.Fit then s1 := Min(W / img.W, H / img.H)
        else s1 := Max(W / img.W, H / img.H);
        im := MatMul(M, MatMul(MatT((W - img.W * s1) / 2, (H - img.H * s1) / 2), MatS(s1, s1)));
        Result.Kind := pkImage;
        Result.Img := img;
        Result.Inv := MatInv(im);
        Result.Clamp := not F.Fit;
      end;
  end;
end;

function OverText(N: TNode; Ov: TStringList): string;
var
  i: Integer;
begin
  Result := N.Text;
  if Ov = nil then Exit;
  i := Ov.IndexOfName(IntToStr(N.Id));
  if i >= 0 then Result := Ov.ValueFromIndex[i];
end;

{ Dónde empieza cada línea del texto (unidades de la capa). }
function LineX(N: TNode; const L: string): Double;
begin
  case N.Align of
    1: Result := (N.W - DocUnits(N, L)) / 2;
    2: Result := N.W - DocUnits(N, L);
  else
    Result := 0;
  end;
end;

procedure DrawTextNode(N: TNode; const M: TMat; A: Double; Ov: TStringList);
var
  L: TStringList;
  i, j, px, nc: Integer;
  k, kk, lh, ox, oy, cx: Double;
  col: LongWord;
  mk: TMask;
  p: TPt;
  saved, ch: string;
  fast: Boolean;
begin
  saved := N.Text;
  N.Text := OverText(N, Ov);
  L := TextLines(N);
  try
    k := MatScale(M);
    col := FillC1(N.Fill);
    if not N.Fill.Vis then Exit;
    lh := LineHOf(N);
    px := Round(N.Size * k);
    if px < 3 then
    begin
      // Demasiado pequeño para leerlo: unas barras grises.
      for i := 0 to L.Count - 1 do
        FillPoly(XfPoly(RectPoly(LineX(N, L[i]), i * lh + lh * 0.3, DocUnits(N, L[i]), lh * 0.4), M), col, A * 0.4);
      Exit;
    end;
    px := Min(px, 700);
    kk := px / N.Size;
    fast := not MatRotated(M) and (Abs(kk - k) / k < 0.02);
    for i := 0 to L.Count - 1 do
    begin
      ox := LineX(N, L[i]);
      oy := i * lh + (lh - N.Size * 1.22) / 2;
      if N.Spacing = 0 then
      begin
        if L[i] = '' then Continue;
        mk := TextMask(L[i], N.Font, px, N.Bold, N.Italic);
        if fast then
        begin
          p := MatAp(M, P2(ox, oy));
          DrawMask(mk, Round(p.X) - 2, Round(p.Y), col, A);
        end
        else
          DrawMaskXf(mk, MatMul(M, MatMul(MatT(ox, oy), MatMul(MatS(1 / kk, 1 / kk), MatT(-2, 0)))), col, A);
      end
      else
      begin
        cx := ox;
        nc := UTF8Length(L[i]);
        for j := 1 to nc do
        begin
          ch := UTF8Copy(L[i], j, 1);
          if ch <> ' ' then
          begin
            mk := TextMask(ch, N.Font, px, N.Bold, N.Italic);
            DrawMaskXf(mk, MatMul(M, MatMul(MatT(cx, oy), MatMul(MatS(1 / kk, 1 / kk), MatT(-2, 0)))), col, A);
          end;
          cx := cx + TextPx(ch, N.Font, Round(N.Size * 4), N.Bold, N.Italic) / 4 + N.Spacing * N.Size / 100;
        end;
      end;
    end;
  finally
    L.Free;
    N.Text := saved;
  end;
end;

procedure DrawNodeAt(N: TNode; const PM: TMat; Op: Double; Ov: TStringList); forward;

function ClipRectOf(const PP: TPolys): TRect;
var
  b: TRectF;
begin
  b := PolysBounds(PP);
  Result := ClipOf(Rect(Floor(b.L), Floor(b.T), Ceil(b.R), Ceil(b.B)));
end;

procedure StrokeNode(N, Src: TNode; const P: TPoly; const M: TMat; A: Double);
var
  sc, w, dl, ang, hl: Double;
  PP, D: TPolys;
  i: Integer;
  tip: TPoly;
  pa, pb: TPt;
begin
  if not Src.Stroke.Vis or (Src.StrokeW <= 0) or (Length(P) < 2) then Exit;
  sc := MatScale(M);
  w := Max(Src.StrokeW * sc, 0.6);
  PP := nil;
  if IsOpenPath(N) then
  begin
    if N.Dash then
    begin
      D := DashPolys(P, False, Max(4, Src.StrokeW * 3) * sc, Max(3, Src.StrokeW * 2) * sc);
      for i := 0 to High(D) do AppendPolys(PP, StrokeOpen(D[i], w, False));
    end
    else PP := StrokeOpen(P, w, True);
    if N.Kind = kArrow then
    begin
      pa := P[High(P) - 1];
      pb := P[High(P)];
      ang := ArcTan2(pb.Y - pa.Y, pb.X - pa.X);
      hl := Max(9 * sc, w * 3.2);
      tip := nil;
      AddPt(tip, pb.X + Cos(ang) * w * 0.6, pb.Y + Sin(ang) * w * 0.6);
      AddPt(tip, pb.X - Cos(ang - 0.45) * hl, pb.Y - Sin(ang - 0.45) * hl);
      AddPt(tip, pb.X - Cos(ang + 0.45) * hl, pb.Y - Sin(ang + 0.45) * hl);
      AddPoly(PP, tip);
    end;
  end
  else if N.Dash then
  begin
    dl := Max(4, Src.StrokeW * 3) * sc;
    D := DashPolys(P, True, dl, dl * 0.75);
    for i := 0 to High(D) do AppendPolys(PP, StrokeOpen(D[i], w, False));
  end
  else
    case Src.StrokePos of
      1: PP := StrokeClosed(P, 0, w);
      2: PP := StrokeClosed(P, w, 0);
    else
      PP := StrokeClosed(P, w / 2, w / 2);
    end;
  FillPolys(PP, PaintOf(Src.Stroke, M, N.W, N.H), A);
end;

procedure DrawInstance(N: TNode; const M: TMat; A: Double);
var
  main: TNode;
  i: Integer;
  P: TPoly;
  PP: TPolys;
  old: TRect;
  sc: Double;
  D: TPoly;
begin
  main := FindNode(N.CompId);
  sc := MatScale(M);
  P := XfPoly(RRectPoly(0, 0, N.W, N.H, N.Radius, EnsureRange(ArcSteps(N.Radius * sc), 4, 64)), M);
  PP := nil;
  AddPoly(PP, P);
  if (main = nil) or (main.Kind <> kComponent) or (DrawDepth > 8) then
  begin
    PP := nil;
    for D in DashPolys(P, True, 6 * S, 4 * S) do AppendPolys(PP, StrokeOpen(D, 1.2 * S, False));
    FillPolys(PP, Solid(CComp), A * 0.8);
    Exit;
  end;
  if main.ShOn then ShadowPolys(PP, WithA(main.ShColor, A), main.ShX * sc, main.ShY * sc, main.ShBlur * sc);
  if main.Fill.Vis then FillPolys(PP, PaintOf(main.Fill, M, N.W, N.H), A);
  old := Surf.Clip;
  if main.Clip then Surf.Clip := ClipRectOf(PP);
  Inc(DrawDepth);
  try
    for i := 0 to main.Count - 1 do DrawNodeAt(main.Kid(i), M, A, N.Over);
  finally
    Dec(DrawDepth);
    Surf.Clip := old;
  end;
  StrokeNode(N, main, P, M, A);
end;

procedure DrawNodeAt(N: TNode; const PM: TMat; Op: Double; Ov: TStringList);
var
  M: TMat;
  P: TPoly;
  PP: TPolys;
  a, sc: Double;
  i: Integer;
  old: TRect;
begin
  if not N.Visible then Exit;
  a := Op * N.Opacity;
  if a <= 0.001 then Exit;
  if N.Kind = kGroup then
  begin
    for i := 0 to N.Count - 1 do DrawNodeAt(N.Kid(i), PM, a, Ov);
    Exit;
  end;
  M := MatMul(PM, LocalMat(N));
  if N.Kind = kInstance then
  begin
    DrawInstance(N, M, a);
    Exit;
  end;
  sc := MatScale(M);
  P := XfPoly(Outline(N, sc), M);
  PP := nil;
  AddPoly(PP, P);
  if N.ShOn and not IsOpenPath(N) and (N.Kind <> kText) then
    ShadowPolys(PP, WithA(N.ShColor, a), N.ShX * sc, N.ShY * sc, N.ShBlur * sc);
  if N.Kind = kText then
    DrawTextNode(N, M, a, Ov)
  else if N.Fill.Vis and not IsOpenPath(N) then
    FillPolys(PP, PaintOf(N.Fill, M, N.W, N.H), a);
  if N.Count > 0 then
  begin
    old := Surf.Clip;
    if N.Clip then Surf.Clip := ClipRectOf(PP);
    try
      for i := 0 to N.Count - 1 do DrawNodeAt(N.Kid(i), M, a, Ov);
    finally
      Surf.Clip := old;
    end;
  end;
  StrokeNode(N, N, P, M, a);
end;

{ Dibuja una capa sola, con su recuadro en (X, Y) a escala Sc (píxeles). }
procedure DrawStandalone(N: TNode; X, Y, Sc: Double; Op: Double = 1);
var
  PM: TMat;
begin
  PM := MatMul(MatT(X, Y), MatMul(MatS(Sc, Sc), MatInv(LocalMat(N))));
  if N.Kind = kGroup then PM := MatMul(MatT(X, Y), MatMul(MatS(Sc, Sc), MatT(-N.X, -N.Y)));
  DrawNodeAt(N, PM, Op, nil);
end;

// ================================================== primitivas de la interfaz
procedure URect(X, Y, W, H: Double; C: LongWord; A: Double = 1);
begin
  FillRectD(X * S, Y * S, (X + W) * S, (Y + H) * S, C, A);
end;

procedure URound(X, Y, W, H, R: Double; C: LongWord; A: Double = 1);
begin
  FillPoly(RRectPoly(X * S, Y * S, W * S, H * S, R * S), C, A);
end;

procedure UFrame(X, Y, W, H, R, LW: Double; C: LongWord; A: Double = 1);
begin
  FillPolys(StrokeClosed(RRectPoly(X * S, Y * S, W * S, H * S, R * S), 0, LW * S), Solid(C), A);
end;

procedure ULine(X0, Y0, X1, Y1, LW: Double; C: LongWord; A: Double = 1);
begin
  LineD(X0 * S, Y0 * S, X1 * S, Y1 * S, LW * S, C, A);
end;

procedure UCircle(CX, CY, R: Double; C: LongWord; A: Double = 1);
begin
  FillPoly(EllipsePoly(CX * S, CY * S, R * S, R * S), C, A);
end;

procedure URing(CX, CY, R, LW: Double; C: LongWord; A: Double = 1);
begin
  FillPolys(StrokeClosed(EllipsePoly(CX * S, CY * S, R * S, R * S), LW * S / 2, LW * S / 2), Solid(C), A);
end;

function UTextW(const T: string; Size: Double; Bold: Boolean = False): Double;
begin
  Result := TextPx(T, UIFont, Round(Size * S), Bold, False) / S;
end;

{ Un texto de la interfaz con su esquina en (X, Y); devuelve el ancho. }
function UText(X, Y: Double; const T: string; Size: Double; C: LongWord;
  Bold: Boolean = False; A: Double = 1): Double;
var
  mk: TMask;
begin
  Result := 0;
  if T = '' then Exit;
  mk := TextMask(T, UIFont, Round(Size * S), Bold, False);
  DrawMask(mk, Round(X * S) - 2, Round(Y * S), C, A);
  Result := UTextW(T, Size, Bold);
end;

{ Recorta con «…» para que quepa en W puntos. }
function Ellip(const T: string; Size, W: Double; Bold: Boolean = False): string;
var
  n: Integer;
begin
  Result := T;
  if UTextW(T, Size, Bold) <= W then Exit;
  n := UTF8Length(T);
  while (n > 1) and (UTextW(UTF8Copy(T, 1, n) + '…', Size, Bold) > W) do Dec(n);
  Result := UTF8Copy(T, 1, n) + '…';
end;

{ Texto centrado en vertical en la caja; Al: 0 izquierda, 1 centro, 2 derecha. }
procedure UTextIn(X, Y, W, H: Double; const T: string; Size: Double; C: LongWord;
  Bold: Boolean = False; Al: Integer = 0; A: Double = 1);
var
  s1: string;
  tw, tx: Double;
begin
  s1 := Ellip(T, Size, W, Bold);
  tw := UTextW(s1, Size, Bold);
  case Al of
    1: tx := X + (W - tw) / 2;
    2: tx := X + W - tw;
  else
    tx := X;
  end;
  UText(tx, Y + (H - Size * 1.22) / 2, s1, Size, C, Bold, A);
end;

procedure PushClip(X, Y, W, H: Double; out Old: TRect);
begin
  Old := Surf.Clip;
  Surf.Clip := ClipOf(Rect(Floor(X * S), Floor(Y * S), Ceil((X + W) * S), Ceil((Y + H) * S)));
end;

procedure PopClip(const Old: TRect);
begin
  Surf.Clip := Old;
end;

// --------------------------------------------------------------- iconos
var
  IcX, IcY, IcK: Double;
  IcC: LongWord;

procedure IL(X0, Y0, X1, Y1: Double; W: Double = 1.4);
begin
  ULine(IcX + X0 * IcK, IcY + Y0 * IcK, IcX + X1 * IcK, IcY + Y1 * IcK, W, IcC);
end;

procedure IPoly(const XY: array of Double; Closed: Boolean; Filled: Boolean = False; W: Double = 1.4);
var
  P: TPoly;
  i: Integer;
begin
  P := nil;
  i := 0;
  while i < High(XY) do
  begin
    AddPt(P, (IcX + XY[i] * IcK) * S, (IcY + XY[i + 1] * IcK) * S);
    Inc(i, 2);
  end;
  if Filled then FillPoly(P, IcC)
  else if Closed then FillPolys(StrokeClosed(P, W * S / 2, W * S / 2), Solid(IcC))
  else FillPolys(StrokeOpen(P, W * S, True), Solid(IcC));
end;

procedure IRect(X, Y, W, H, R: Double; Filled: Boolean = False);
begin
  if Filled then URound(IcX + X * IcK, IcY + Y * IcK, W * IcK, H * IcK, R * IcK, IcC)
  else
    FillPolys(StrokeClosed(RRectPoly((IcX + X * IcK) * S, (IcY + Y * IcK) * S, W * IcK * S, H * IcK * S, R * IcK * S), 0.7 * S, 0.7 * S), Solid(IcC));
end;

procedure IEll(CX, CY, R: Double; Filled: Boolean = False; W: Double = 1.4);
begin
  if Filled then UCircle(IcX + CX * IcK, IcY + CY * IcK, R * IcK, IcC)
  else URing(IcX + CX * IcK, IcY + CY * IcK, R * IcK, W, IcC);
end;

{ Un icono de 16×16 centrado en (CX, CY). }
procedure Icon(const Name: string; CX, CY: Double; C: LongWord; Sz: Double = 16);
var
  i: Integer;
begin
  IcK := Sz / 16;
  IcX := CX - Sz / 2;
  IcY := CY - Sz / 2;
  IcC := C;
  if Name = 'move' then IPoly([3, 2, 3, 14, 6.5, 10.5, 9, 15, 11, 14, 8.7, 9.6, 13, 9.4], True, True)
  else if Name = 'hand' then
  begin
    IPoly([4, 9, 4, 4.5], False); IPoly([6.5, 8, 6.5, 2.5], False);
    IPoly([9, 8, 9, 3], False); IPoly([11.5, 8.5, 11.5, 5], False);
    IPoly([4, 8, 4, 11, 6.5, 14, 11, 14, 11.5, 11, 11.5, 8.5], False);
  end
  else if Name = 'frame' then
  begin
    IL(5, 1.5, 5, 14.5); IL(11, 1.5, 11, 14.5); IL(1.5, 5, 14.5, 5); IL(1.5, 11, 14.5, 11);
  end
  else if Name = 'rect' then IRect(2.5, 3.5, 11, 9, 1)
  else if Name = 'ellipse' then IEll(8, 8, 5.6)
  else if Name = 'line' then IL(2.5, 13.5, 13.5, 2.5)
  else if Name = 'arrow' then
  begin
    IL(2.5, 13.5, 13, 3); IPoly([7.5, 3, 13, 3, 13, 8.5], False);
  end
  else if Name = 'polygon' then IPoly([8, 2, 14, 13, 2, 13], True)
  else if Name = 'star' then
    IPoly([8, 1.8, 9.9, 6, 14.3, 6.4, 11, 9.4, 12, 13.8, 8, 11.5, 4, 13.8, 5, 9.4, 1.7, 6.4, 6.1, 6], True)
  else if Name = 'pen' then
  begin
    IPoly([8, 2, 12.5, 9, 10, 14, 6, 14, 3.5, 9], True); IL(8, 2, 8, 8.5); IEll(8, 9.3, 1, True);
  end
  else if Name = 'text' then
  begin
    IL(3, 3, 13, 3, 1.6); IL(8, 3, 8, 14, 1.6); IL(6, 14, 10, 14);
  end
  else if Name = 'image' then
  begin
    IRect(2, 3, 12, 10, 1.5); IPoly([2.5, 12, 6.5, 7.5, 9.5, 10.5, 11, 9, 13.5, 11.5], False);
    IEll(10.5, 6, 1.2, True);
  end
  else if Name = 'comment' then
    IPoly([3, 3, 13, 3, 13, 11, 7, 11, 4, 14, 4, 11, 3, 11], True)
  else if (Name = 'eye') or (Name = 'eyeoff') then
  begin
    IPoly([1.5, 8, 4, 4.8, 8, 3.7, 12, 4.8, 14.5, 8, 12, 11.2, 8, 12.3, 4, 11.2], True, False, 1.2);
    IEll(8, 8, 2, True);
    if Name = 'eyeoff' then IL(3, 13.5, 13, 2.5, 1.4);
  end
  else if (Name = 'lock') or (Name = 'unlock') then
  begin
    IRect(3.5, 7.5, 9, 6.5, 1.2, True);
    if Name = 'lock' then IPoly([5.5, 7.5, 5.5, 5, 8, 2.8, 10.5, 5, 10.5, 7.5], False, False, 1.3)
    else IPoly([5.5, 7.5, 5.5, 5, 8, 2.8, 10.5, 5], False, False, 1.3);
  end
  else if Name = 'plus' then
  begin
    IL(8, 3, 8, 13); IL(3, 8, 13, 8);
  end
  else if Name = 'minus' then IL(3, 8, 13, 8)
  else if Name = 'close' then
  begin
    IL(4, 4, 12, 12); IL(12, 4, 4, 12);
  end
  else if Name = 'play' then IPoly([4.5, 2.5, 13, 8, 4.5, 13.5], True, True)
  else if Name = 'component' then
  begin
    IPoly([8, 1.5, 10.2, 3.7, 8, 5.9, 5.8, 3.7], True, True);
    IPoly([8, 10.1, 10.2, 12.3, 8, 14.5, 5.8, 12.3], True, True);
    IPoly([3.7, 5.8, 5.9, 8, 3.7, 10.2, 1.5, 8], True, True);
    IPoly([12.3, 5.8, 14.5, 8, 12.3, 10.2, 10.1, 8], True, True);
  end
  else if Name = 'instance' then IPoly([8, 2, 14, 8, 8, 14, 2, 8], True)
  else if Name = 'group' then
  begin
    IRect(2.5, 2.5, 11, 11, 1);
    IRect(5, 5, 6, 6, 0.5, True);
  end
  else if Name = 'chev' then IPoly([6, 4, 10, 8, 6, 12], False)
  else if Name = 'chevleft' then IPoly([10, 4, 6, 8, 10, 12], False)
  else if Name = 'chevdown' then IPoly([4, 6, 8, 10, 12, 6], False)
  else if Name = 'grid' then
  begin
    for i := 0 to 2 do
    begin
      IL(2 + i * 6, 2, 2 + i * 6, 14, 1); IL(2, 2 + i * 6, 14, 2 + i * 6, 1);
    end;
  end
  else if Name = 'ruler' then
  begin
    IRect(1.5, 5, 13, 6, 1);
    for i := 1 to 5 do IL(1.5 + i * 2.2, 5, 1.5 + i * 2.2, 5 + 2 + (i mod 2) * 1.5, 1);
  end
  else if Name = 'sun' then
  begin
    IEll(8, 8, 3, True);
    for i := 0 to 7 do
      IL(8 + Cos(i * Pi / 4) * 5, 8 + Sin(i * Pi / 4) * 5, 8 + Cos(i * Pi / 4) * 6.8, 8 + Sin(i * Pi / 4) * 6.8, 1.3);
  end
  else if Name = 'moon' then
    IPoly([10, 2, 7, 3, 5, 5.5, 4.6, 8.8, 6, 11.8, 9, 13.6, 12.4, 13.4, 14, 12, 10.5, 11, 8.3, 8.3, 8.2, 5, 10, 2], True, True)
  else if Name = 'magnet' then
  begin
    IPoly([3, 2.5, 3, 9, 4.8, 12.6, 8, 14, 11.2, 12.6, 13, 9, 13, 2.5], False, False, 1.4);
    IPoly([6, 2.5, 6, 9, 8, 11, 10, 9, 10, 2.5], False, False, 1.4);
  end
  else if Name = 'alignL' then begin IL(2, 2, 2, 14); IRect(4, 4, 9, 3, 0.5, True); IRect(4, 9, 5.5, 3, 0.5, True); end
  else if Name = 'alignCH' then begin IL(8, 2, 8, 14); IRect(3, 4, 10, 3, 0.5, True); IRect(5, 9, 6, 3, 0.5, True); end
  else if Name = 'alignR' then begin IL(14, 2, 14, 14); IRect(3, 4, 9, 3, 0.5, True); IRect(6.5, 9, 5.5, 3, 0.5, True); end
  else if Name = 'alignT' then begin IL(2, 2, 14, 2); IRect(4, 4, 3, 9, 0.5, True); IRect(9, 4, 3, 5.5, 0.5, True); end
  else if Name = 'alignCV' then begin IL(2, 8, 14, 8); IRect(4, 3, 3, 10, 0.5, True); IRect(9, 5, 3, 6, 0.5, True); end
  else if Name = 'alignB' then begin IL(2, 14, 14, 14); IRect(4, 3, 3, 9, 0.5, True); IRect(9, 6.5, 3, 5.5, 0.5, True); end
  else if Name = 'distH' then begin IL(2, 2, 2, 14); IL(14, 2, 14, 14); IRect(6.5, 4, 3, 8, 0.5, True); end
  else if Name = 'distV' then begin IL(2, 2, 14, 2); IL(2, 14, 14, 14); IRect(4, 6.5, 8, 3, 0.5, True); end
  else if Name = 'autoH' then
  begin
    IRect(1.5, 4.5, 4, 7, 1, True); IRect(6.5, 4.5, 4, 7, 1, True); IL(12.5, 4, 12.5, 12);
  end
  else if Name = 'autoV' then
  begin
    IRect(4.5, 1.5, 7, 4, 1, True); IRect(4.5, 6.5, 7, 4, 1, True); IL(4, 12.5, 12, 12.5);
  end
  else if Name = 'link' then
  begin
    IRect(1.5, 5.5, 7, 5, 2.5); IRect(7.5, 5.5, 7, 5, 2.5);
  end
  else if Name = 'code' then
  begin
    IPoly([5.5, 4, 1.8, 8, 5.5, 12], False); IPoly([10.5, 4, 14.2, 8, 10.5, 12], False); IL(9, 3, 7, 13);
  end
  else if Name = 'proto' then
  begin
    IEll(4, 8, 2.2, True); IPoly([6, 8, 10, 8, 10, 4, 13.5, 4], False); IPoly([11.5, 2, 13.8, 4, 11.5, 6], False);
  end
  else if Name = 'design' then
  begin
    IPoly([2.5, 13.5, 3.5, 10, 11, 2.5, 13.5, 5, 6, 12.5], True); IL(9.5, 4, 12, 6.5);
  end
  else if Name = 'trash' then
  begin
    IL(2.5, 4, 13.5, 4); IPoly([4, 4, 5, 14, 11, 14, 12, 4], False); IL(6, 2, 10, 2);
  end
  else if Name = 'export' then
  begin
    IL(8, 2, 8, 10); IPoly([5, 5, 8, 2, 11, 5], False); IPoly([3, 9, 3, 14, 13, 14, 13, 9], False);
  end
  else if Name = 'copy' then
  begin
    IRect(5, 5, 9, 9, 1.5); IPoly([3, 10, 2, 10, 2, 2, 10, 2, 10, 3], False);
  end
  else if Name = 'style' then
  begin
    IEll(5.5, 5.5, 3.3, True); IEll(10.5, 5.5, 3.3); IEll(5.5, 10.5, 3.3); IEll(10.5, 10.5, 3.3, True);
  end
  else if Name = 'sparkle' then
  begin
    IPoly([8, 1.5, 9.4, 6.6, 14.5, 8, 9.4, 9.4, 8, 14.5, 6.6, 9.4, 1.5, 8, 6.6, 6.6], True, True);
  end
  else if Name = 'check' then IPoly([3, 8.5, 6.5, 12, 13, 4.5], False, False, 1.8)
  else if Name = 'dots' then
  begin
    IEll(3.5, 8, 1.3, True); IEll(8, 8, 1.3, True); IEll(12.5, 8, 1.3, True);
  end;
end;

{ El icono de cada tipo de capa (en la lista de capas). }
function KindIcon(N: TNode): string;
begin
  case N.Kind of
    kFrame: Result := 'frame';
    kGroup: Result := 'group';
    kRect: if N.Fill.Kind = fkImage then Result := 'image' else Result := 'rect';
    kEllipse: Result := 'ellipse';
    kLine: Result := 'line';
    kArrow: Result := 'arrow';
    kPolygon: Result := 'polygon';
    kStar: Result := 'star';
    kPath: Result := 'pen';
    kText: Result := 'text';
    kComponent: Result := 'component';
  else
    Result := 'instance';
  end;
end;

// =========================================================== el editor
type
  TTool = (tlMove, tlHand, tlFrame, tlRect, tlEllipse, tlLine, tlArrow, tlPolygon,
    tlStar, tlPen, tlText, tlImage, tlComment);

  THit = record
    X, Y, W, H: Double;
    Act: string;
  end;

  TGuide = record
    X0, Y0, X1, Y1: Double; // en el mundo
    Lbl: string;
  end;

const
  ToolIcons: array[TTool] of string = ('move', 'hand', 'frame', 'rect', 'ellipse',
    'line', 'arrow', 'polygon', 'star', 'pen', 'text', 'image', 'comment');
  ToolKeys: array[TTool] of string = ('V', 'H', 'F', 'R', 'O', 'L', '⇧L', '', '',
    'P', 'T', '⇧⌘K', 'C');

var
  Tool: TTool = tlMove;
  Sel: TFPList = nil;
  HoverNode: TNode = nil;
  UndoL: TStringList = nil;
  RedoL: TStringList = nil;
  Hits: array of THit;
  NHits: Integer = 0;
  HoverAct: string = '';
  MouseX, MouseY: Double;
  // El campo que se está escribiendo ('text': el texto de una capa).
  EditId: string = '';
  EditBuf: string = '';
  ECaret: Integer = 0;
  EAnchor: Integer = 0;
  EditNode: TNode = nil;
  EditOver: TNode = nil;     // la instancia cuyo texto se cambia
  CaretOn: Boolean = True;
  CaretT: QWord = 0;
  InspScroll: Double = 0;
  InspH: Double = 0;
  LayerScroll: Double = 0;
  LayerH: Double = 0;
  RightTab: Integer = 0;     // 0 capas, 1 activos, 2 comentarios
  CodeLang: Integer = 0;     // 0 CSS, 1 Flutter
  ExportScale: Integer = 2;
  Guides: array of TGuide;
  NGuides: Integer = 0;
  PenNode: TNode = nil;      // el trazado que se está dibujando
  VertexNode: TNode = nil;   // el trazado cuyos puntos se editan
  ActiveComment: Integer = -1;
  Toast: string = '';
  ToastT: QWord = 0;
  SpaceDown: Boolean = False;
  AltDown: Boolean = False;
  // El selector de color.
  PickOpen: Boolean = False;
  PickTarget: string = '';
  PickX, PickY: Double;
  PickH, PickS, PickV: Double;
  PickA: Integer = 255;
  // La presentación del prototipo.
  Playing: Boolean = False;

function Now64: QWord;
begin
  Result := GetTickCount64;
end;

procedure Say(const Msg: string);
begin
  Toast := Msg;
  ToastT := Now64;
end;

procedure AddHit(X, Y, W, H: Double; const Act: string);
var
  x1, y1: Double;
begin
  // Solo la parte que se ve (lo recortado no se puede pulsar).
  x1 := Min(X + W, Surf.Clip.Right / S);
  y1 := Min(Y + H, Surf.Clip.Bottom / S);
  X := Max(X, Surf.Clip.Left / S);
  Y := Max(Y, Surf.Clip.Top / S);
  W := x1 - X;
  H := y1 - Y;
  if (W <= 0) or (H <= 0) then Exit;
  if NHits >= Length(Hits) then SetLength(Hits, NHits * 2 + 64);
  Hits[NHits].X := X; Hits[NHits].Y := Y;
  Hits[NHits].W := W; Hits[NHits].H := H;
  Hits[NHits].Act := Act;
  Inc(NHits);
end;

function HitAt(X, Y: Double): string;
var
  i: Integer;
begin
  for i := NHits - 1 downto 0 do
    if (X >= Hits[i].X) and (Y >= Hits[i].Y) and (X < Hits[i].X + Hits[i].W) and (Y < Hits[i].Y + Hits[i].H) then
      Exit(Hits[i].Act);
  Result := '';
end;

function HitRect(const Act: string; out X, Y, W, H: Double): Boolean;
var
  i: Integer;
begin
  for i := NHits - 1 downto 0 do
    if Hits[i].Act = Act then
    begin
      X := Hits[i].X; Y := Hits[i].Y; W := Hits[i].W; H := Hits[i].H;
      Exit(True);
    end;
  Result := False;
end;

function Hov(const Act: string): Boolean;
begin
  Result := HoverAct = Act;
end;

// ------------------------------------------------------------ la selección
function IsSel(N: TNode): Boolean;
begin
  Result := Sel.IndexOf(N) >= 0;
end;

function SelN(I: Integer): TNode;
begin
  Result := TNode(Sel[I]);
end;

procedure ClearSel;
begin
  Sel.Clear;
  VertexNode := nil;
end;

procedure SelectOnly(N: TNode);
begin
  Sel.Clear;
  if N <> nil then Sel.Add(N);
  VertexNode := nil;
end;

procedure ToggleSel(N: TNode);
begin
  if IsSel(N) then Sel.Remove(N) else Sel.Add(N);
end;

function One: TNode;
begin
  if Sel.Count = 1 then Result := SelN(0) else Result := nil;
end;

function SelBox: TRectF;
var
  i: Integer;
begin
  Result := RF(0, 0, 0, 0);
  for i := 0 to Sel.Count - 1 do
    if i = 0 then Result := WorldBox(SelN(i))
    else Result := Union(Result, WorldBox(SelN(i)));
end;

{ Quita de la selección lo que ya no está en la página. }
procedure CleanSel;
var
  i: Integer;
begin
  for i := Sel.Count - 1 downto 0 do
    if (SelN(i).Parent = nil) or (PageOfNode(SelN(i)) <> PageIx) then Sel.Delete(i);
  if (HoverNode <> nil) and ((HoverNode.Parent = nil) or (PageOfNode(HoverNode) <> PageIx)) then
    HoverNode := nil;
end;

// ---------------------------------------------------------- deshacer
function Snapshot: string;
var
  ids: string;
  i: Integer;
begin
  ids := '';
  for i := 0 to Sel.Count - 1 do ids := ids + IntToStr(SelN(i).Id) + ',';
  Result := DocText + 'state' + KV('page', IntToStr(PageIx)) + KV('sel', ids) + LineEnding;
end;

procedure Restore(const St: string);
var
  L, F: TStringList;
  kind: string;
  ids: TStringArray;
  i: Integer;
  n: TNode;
begin
  EditId := '';
  EditNode := nil;
  PenNode := nil;
  VertexNode := nil;
  HoverNode := nil;
  LoadDocText(St);
  Sel.Clear;
  L := TStringList.Create;
  try
    L.Text := St;
    for i := L.Count - 1 downto 0 do
      if Copy(L[i], 1, 5) = 'state' then
      begin
        F := SplitFields(L[i], kind);
        try
          PageIx := EnsureRange(StrToIntDef(F.Values['page'], 0), 0, Pages.Count - 1);
          ids := F.Values['sel'].Split([',']);
        finally
          F.Free;
        end;
        for kind in ids do
        begin
          n := FindNode(StrToIntDef(kind, 0));
          if n <> nil then Sel.Add(n);
        end;
        Break;
      end;
  finally
    L.Free;
  end;
  CleanSel;
end;

{ Antes de cambiar el documento: guarda cómo estaba para Deshacer. }
procedure Snap;
begin
  UndoL.Add(Snapshot);
  while UndoL.Count > 80 do UndoL.Delete(0);
  RedoL.Clear;
  Dirty := True;
end;

procedure DoUndo;
begin
  if UndoL.Count = 0 then Exit;
  RedoL.Add(Snapshot);
  Restore(UndoL[UndoL.Count - 1]);
  UndoL.Delete(UndoL.Count - 1);
  Dirty := True;
  Say(tx_UNDONE);
end;

procedure DoRedo;
begin
  if RedoL.Count = 0 then Exit;
  UndoL.Add(Snapshot);
  Restore(RedoL[RedoL.Count - 1]);
  RedoL.Delete(RedoL.Count - 1);
  Dirty := True;
  Say(tx_REDONE);
end;

// ---------------------------------------------------- campos que se escriben
procedure ApplyEdit(const Id, V: string); forward;

procedure BeginEdit(const Id, Val: string);
begin
  EditId := Id;
  EditBuf := Val;
  EAnchor := 0;
  ECaret := UTF8Length(Val);
  CaretOn := True;
  CaretT := Now64;
end;

procedure CommitEdit;
var
  id: string;
begin
  if EditId = '' then Exit;
  id := EditId;
  EditId := '';
  if id = 'text' then
  begin
    EditNode := nil;
    EditOver := nil;
    Exit;
  end;
  ApplyEdit(id, EditBuf);
end;

procedure CancelEdit;
begin
  if EditId = 'text' then
  begin
    CommitEdit;
    Exit;
  end;
  EditId := '';
end;

function SelLo: Integer;
begin
  Result := Min(ECaret, EAnchor);
end;

function SelHi: Integer;
begin
  Result := Max(ECaret, EAnchor);
end;

procedure SyncTextEdit;
begin
  if (EditId = 'text') and (EditNode <> nil) then
  begin
    if EditOver <> nil then EditOver.Over.Values[IntToStr(EditNode.Id)] := EditBuf
    else EditNode.Text := EditBuf;
    NormalizeAll;
    Dirty := True;
  end;
  CaretOn := True;
  CaretT := Now64;
end;

procedure EdInsert(const T: string);
var
  lo: Integer;
begin
  lo := SelLo;
  EditBuf := UTF8Copy(EditBuf, 1, lo) + T + UTF8Copy(EditBuf, SelHi + 1, MaxInt);
  ECaret := lo + UTF8Length(T);
  EAnchor := ECaret;
  SyncTextEdit;
end;

procedure EdBack(Fwd: Boolean);
begin
  if SelLo = SelHi then
  begin
    if Fwd then ECaret := Min(UTF8Length(EditBuf), ECaret + 1)
    else ECaret := Max(0, ECaret - 1);
  end;
  EdInsert('');
end;

procedure EdMove(D: Integer; Extend: Boolean);
begin
  if (not Extend) and (SelLo <> SelHi) then
  begin
    if D < 0 then ECaret := SelLo else ECaret := SelHi;
  end
  else ECaret := EnsureRange(ECaret + D, 0, UTF8Length(EditBuf));
  if not Extend then EAnchor := ECaret;
  CaretOn := True;
  CaretT := Now64;
end;

procedure EdHomeEnd(Last, Extend: Boolean);
begin
  if Last then ECaret := UTF8Length(EditBuf) else ECaret := 0;
  if not Extend then EAnchor := ECaret;
end;

function EdSelected: string;
begin
  Result := UTF8Copy(EditBuf, SelLo + 1, SelHi - SelLo);
end;

{ Un campo del inspector: etiqueta a la izquierda (se arrastra para cambiar
  el número) y el valor, que se escribe al pulsarlo. }
procedure DrawField(X, Y, W, H: Double; const Id, Lbl, Val: string; Scrub: Boolean = True);
var
  lw, tx, cx, lo, hi: Double;
  editing: Boolean;
  shown: string;
  old: TRect;
begin
  editing := EditId = Id;
  if editing then URound(X, Y, W, H, 5, CField)
  else if Hov('f:' + Id) or Hov('s:' + Id) then URound(X, Y, W, H, 5, CHover)
  else URound(X, Y, W, H, 5, CField);
  if editing then UFrame(X, Y, W, H, 5, 1, CAccent);
  lw := 0;
  if Lbl <> '' then
  begin
    lw := Max(18, UTextW(Lbl, 10.5) + 12);
    UTextIn(X + 7, Y, lw - 8, H, Lbl, 10.5, CMuted);
    if Scrub then AddHit(X, Y, lw, H, 's:' + Id);
  end
  else lw := 4;
  tx := X + lw + 2;
  PushClip(tx - 2, Y, W - lw - 2, H, old);
  if editing then
  begin
    shown := EditBuf;
    lo := tx + UTextW(UTF8Copy(shown, 1, SelLo), 11.5);
    hi := tx + UTextW(UTF8Copy(shown, 1, SelHi), 11.5);
    if hi > lo then URect(lo, Y + 4, hi - lo, H - 8, CAccent, 0.35);
    UText(tx, Y + (H - 11.5 * 1.22) / 2, shown, 11.5, CText);
    if CaretOn then
    begin
      cx := tx + UTextW(UTF8Copy(shown, 1, ECaret), 11.5);
      URect(cx, Y + 5, 1, H - 10, CText);
    end;
  end
  else
    UTextIn(tx, Y, W - lw - 6, H, Val, 11.5, CText);
  PopClip(old);
  AddHit(X + lw, Y, W - lw, H, 'f:' + Id);
end;

{ Un botón con icono (y, si se quiere, texto). }
procedure IconBtn(X, Y, W, H: Double; const Ic, Act: string; On: Boolean = False; Lbl: string = '');
var
  c: LongWord;
begin
  if On then URound(X, Y, W, H, 6, CSelBg)
  else if Hov(Act) then URound(X, Y, W, H, 6, CHover);
  if On then c := CAccent else c := CText;
  if Lbl = '' then Icon(Ic, X + W / 2, Y + H / 2, c, 16)
  else
  begin
    Icon(Ic, X + 14, Y + H / 2, c, 14);
    UTextIn(X + 26, Y, W - 28, H, Lbl, 11.5, c);
  end;
  AddHit(X, Y, W, H, Act);
end;

procedure TextBtn(X, Y, W, H: Double; const T, Act: string; Primary: Boolean = False);
begin
  if Primary then
  begin
    if Hov(Act) then URound(X, Y, W, H, 7, CAccent2) else URound(X, Y, W, H, 7, CAccent);
    UTextIn(X, Y, W, H, T, 12, $FFFFFFFF, True, 1);
  end
  else
  begin
    if Hov(Act) then URound(X, Y, W, H, 7, CHover);
    UFrame(X, Y, W, H, 7, 1, CLine);
    UTextIn(X, Y, W, H, T, 12, CText, False, 1);
  end;
  AddHit(X, Y, W, H, Act);
end;

procedure Toggle(X, Y: Double; On: Boolean; const Act: string);
begin
  if On then URound(X, Y, 28, 16, 8, CAccent) else URound(X, Y, 28, 16, 8, CLine);
  if On then UCircle(X + 20, Y + 8, 6, $FFFFFFFF) else UCircle(X + 8, Y + 8, 6, $FFFFFFFF);
  AddHit(X - 2, Y - 3, 32, 22, Act);
end;

procedure Checker(X, Y, W, H: Double);
var
  i, j: Integer;
  old: TRect;
begin
  PushClip(X, Y, W, H, old);
  URect(X, Y, W, H, $FFFFFFFF);
  for j := 0 to Ceil(H / 4) do
    for i := 0 to Ceil(W / 4) do
      if Odd(i + j) then URect(X + i * 4, Y + j * 4, 4, 4, $FFCCCCCC);
  PopClip(old);
end;

procedure Swatch(X, Y, Sz: Double; C: LongWord; const Act: string);
begin
  Checker(X, Y, Sz, Sz);
  URound(X, Y, Sz, Sz, 3, C);
  UFrame(X, Y, Sz, Sz, 3, 1, CLine);
  if Act <> '' then AddHit(X, Y, Sz, Sz, Act);
end;

procedure SectionHead(X, Y, W: Double; const T: string);
begin
  ULine(X - 12, Y - 6, X + W + 12, Y - 6, 1, CLine);
  UText(X, Y, T, 11.5, CText, True);
end;

// ------------------------------------------------------- barra de arriba
procedure DrawLogo(X, Y, Sz: Double);
begin
  URound(X, Y, Sz, Sz, Sz * 0.26, CAccent);
  FillPoly(RRectPoly((X + Sz * 0.5) * S, Y * S, Sz * 0.5 * S, Sz * 0.5 * S, Sz * 0.2 * S), $FF0B7A5C, 0.55);
  UTextIn(X, Y, Sz, Sz, 'D++', Sz * 0.36, $FFFFFFFF, True, 1);
end;

procedure DrawTopBar;
var
  x, w, rx: Double;
  i: Integer;
  t: string;
  zl: string;
begin
  URect(0, 0, WinW, TopH, CPanel);
  ULine(0, TopH - 0.5, WinW, TopH - 0.5, 1, CLine);
  DrawLogo(12, 10, 26);
  x := 46;
  x := x + UText(x, 10, 'OpenD++', 13.5, CText, True) + 8;
  t := DocName;
  if t = '' then t := tx_UNTITLED;
  if Dirty then t := t + ' •';
  t := Ellip(t, 11.5, 150);
  UText(x, 26, t, 10.5, CMuted);
  UText(x, 11, tx_DRAFT, 10, CAccent, True);
  // Las páginas, como pestañas.
  x := Max(x + UTextW(t, 10.5) + 22, 260);
  for i := 0 to Pages.Count - 1 do
  begin
    if EditId = 'page:' + IntToStr(i) then
    begin
      DrawField(x, 8, 140, 30, 'page:' + IntToStr(i), '', EditBuf, False);
      x := x + 146;
      Continue;
    end;
    w := Min(170, UTextW(PageN(i).Name, 12, i = PageIx) + 30);
    if i = PageIx then URound(x, 8, w, 30, 8, CField)
    else if Hov('page:' + IntToStr(i)) then URound(x, 8, w, 30, 8, CHover);
    if i = PageIx then URect(x + 12, 35, w - 24, 2, CAccent);
    UTextIn(x + 12, 8, w - 24, 30, PageN(i).Name, 12, CText, i = PageIx, 1);
    AddHit(x, 8, w, 30, 'page:' + IntToStr(i));
    x := x + w + 4;
  end;
  IconBtn(x, 11, 24, 24, 'plus', 'pageadd');
  // A la derecha: zoom, modo, presentar y exportar.
  rx := WinW - 12;
  rx := rx - 92;
  TextBtn(rx, 9, 92, 28, tx_EXPORT, 'exportsel');
  rx := rx - 112;
  if Hov('play') then URound(rx, 9, 104, 28, 7, CAccent2) else URound(rx, 9, 104, 28, 7, CAccent);
  Icon('play', rx + 18, 23, $FFFFFFFF, 12);
  UTextIn(rx + 28, 9, 70, 28, tx_PRESENT, 12, $FFFFFFFF, True, 1);
  AddHit(rx, 9, 104, 28, 'play');
  rx := rx - 12 - 3 * 96;
  URound(rx, 8, 3 * 96, 30, 8, CField);
  for i := 0 to 2 do
  begin
    case i of
      0: begin t := tx_MODE_DESIGN; zl := 'design'; end;
      1: begin t := tx_MODE_PROTO; zl := 'proto'; end;
    else
      begin t := tx_MODE_CODE; zl := 'code'; end;
    end;
    if Mode = i then URound(rx + i * 96 + 2, 10, 92, 26, 6, CPanel)
    else if Hov('mode:' + IntToStr(i)) then URound(rx + i * 96 + 2, 10, 92, 26, 6, CHover);
    if Mode = i then
    begin
      Icon(zl, rx + i * 96 + 16, 23, CAccent, 13);
      UTextIn(rx + i * 96 + 26, 10, 66, 26, t, 11.5, CText, True, 1);
    end
    else
    begin
      Icon(zl, rx + i * 96 + 16, 23, CMuted, 13);
      UTextIn(rx + i * 96 + 26, 10, 66, 26, t, 11.5, CMuted, False, 1);
    end;
    AddHit(rx + i * 96, 8, 96, 30, 'mode:' + IntToStr(i));
  end;
  rx := rx - 12 - 70;
  zl := IntToStr(Round(Zoom * 100)) + ' %';
  if Hov('zoommenu') then URound(rx, 9, 70, 28, 7, CHover);
  UTextIn(rx + 8, 9, 44, 28, zl, 12, CText, False, 2);
  Icon('chevdown', rx + 60, 23, CMuted, 11);
  AddHit(rx, 9, 70, 28, 'zoommenu');
end;

// ------------------------------------------------- la columna de herramientas
function ToolLabel(T: TTool): string;
begin
  case T of
    tlMove: Result := tx_T_MOVE;
    tlHand: Result := tx_T_HAND;
    tlFrame: Result := tx_T_FRAME;
    tlRect: Result := tx_T_RECT;
    tlEllipse: Result := tx_T_ELLIPSE;
    tlLine: Result := tx_T_LINE;
    tlArrow: Result := tx_T_ARROW;
    tlPolygon: Result := tx_T_POLYGON;
    tlStar: Result := tx_T_STAR;
    tlPen: Result := tx_T_PEN;
    tlText: Result := tx_T_TEXT;
    tlImage: Result := tx_T_IMAGE;
  else
    Result := tx_T_COMMENT;
  end;
end;

procedure DrawRail;
var
  t: TTool;
  y, ty: Double;
  tip, k: string;
  c: LongWord;
begin
  URect(0, TopH, RailW, WinH - TopH - StatusH, CRail);
  ULine(RailW - 0.5, TopH, RailW - 0.5, WinH - StatusH, 1, CLine);
  y := TopH + 10;
  tip := '';
  ty := 0;
  for t := Low(TTool) to High(TTool) do
  begin
    if Tool = t then
    begin
      URound(8, y, 36, 34, 8, CAccent);
      c := $FFFFFFFF;
    end
    else
    begin
      if Hov('tool:' + IntToStr(Ord(t))) then URound(8, y, 36, 34, 8, CHover);
      c := CText;
    end;
    Icon(ToolIcons[t], 26, y + 17, c, 17);
    AddHit(6, y, 40, 34, 'tool:' + IntToStr(Ord(t)));
    if Hov('tool:' + IntToStr(Ord(t))) then
    begin
      tip := ToolLabel(t);
      k := ToolKeys[t];
      if k <> '' then tip := tip + '   ' + k;
      ty := y;
    end;
    y := y + 38;
    if t in [tlHand, tlFrame, tlStar, tlImage] then
    begin
      ULine(14, y + 1, RailW - 14, y + 1, 1, CLine);
      y := y + 8;
    end;
  end;
  // Abajo: tema, reglas y cuadrícula.
  y := WinH - StatusH - 44;
  if Dark then IconBtn(8, y, 36, 34, 'sun', 'theme') else IconBtn(8, y, 36, 34, 'moon', 'theme');
  IconBtn(8, y - 38, 36, 34, 'ruler', 'rulers', Rulers);
  IconBtn(8, y - 76, 36, 34, 'sparkle', 'aimenu');
  if Hov('theme') then begin tip := tx_THEME_TIP; ty := y; end;
  if Hov('rulers') then begin tip := tx_RULERS; ty := y - 38; end;
  if Hov('aimenu') then begin tip := tx_AI_TIP; ty := y - 76; end;
  if tip <> '' then
  begin
    URound(RailW + 4, ty + 5, UTextW(tip, 11.5) + 18, 24, 6, $FF0F1115, 0.94);
    UText(RailW + 13, ty + 9.5, tip, 11.5, $FFFFFFFF);
  end;
end;

// -------------------------------------------------------- barra de estado
function ToolHint: string;
begin
  if Playing then Exit('');
  if EditId = 'text' then Exit(tx_H_TEXTEDIT);
  if VertexNode <> nil then Exit(tx_H_VERTEX);
  if PenNode <> nil then Exit(tx_H_PENON);
  case Tool of
    tlMove:
      if Mode = 1 then Result := tx_H_PROTO
      else if Mode = 2 then Result := tx_H_CODE
      else Result := tx_H_MOVE;
    tlHand: Result := tx_H_HAND;
    tlFrame: Result := tx_H_FRAME;
    tlRect, tlEllipse, tlPolygon, tlStar: Result := tx_H_SHAPE;
    tlLine, tlArrow: Result := tx_H_LINE;
    tlPen: Result := tx_H_PEN;
    tlText: Result := tx_H_TEXT;
    tlImage: Result := tx_H_IMAGE;
  else
    Result := tx_H_COMMENT;
  end;
end;

procedure DrawStatus;
var
  y, x: Double;
  w: TPt;
  t: string;
  b: TRectF;
begin
  y := WinH - StatusH;
  URect(0, y, WinW, StatusH, CRail);
  ULine(0, y + 0.5, WinW, y + 0.5, 1, CLine);
  if (Toast <> '') and (Now64 - ToastT < 3500) then
  begin
    UCircle(14, y + 13, 4, CAccent);
    UTextIn(24, y, WinW / 2, StatusH, Toast, 11, CText);
  end
  else
    UTextIn(12, y, WinW / 2, StatusH, ToolHint, 11, CMuted);
  x := WinW - 12;
  x := x - 26;
  IconBtn(x, y + 2, 24, 22, 'grid', 'pixgrid', PixGrid);
  x := x - 28;
  IconBtn(x, y + 2, 24, 22, 'magnet', 'snap', SnapOn);
  x := x - 64;
  UTextIn(x, y, 56, StatusH, IntToStr(Round(Zoom * 100)) + ' %', 11, CMuted, False, 2);
  if Sel.Count > 0 then
  begin
    b := SelBox;
    t := F2S(Round((b.R - b.L) * 100) / 100) + ' × ' + F2S(Round((b.B - b.T) * 100) / 100);
    if Sel.Count > 1 then t := IntToStr(Sel.Count) + ' ' + tx_LAYERS_LC + ' · ' + t;
    x := x - UTextW(t, 11) - 20;
    UText(x, y + 6.5, t, 11, CText);
  end;
  if (MouseX >= CX0) and (MouseX < CX1) and (MouseY >= CY0) and (MouseY < CY1) then
  begin
    w := S2W(MouseX, MouseY);
    t := 'X ' + IntToStr(Round(w.X)) + '   Y ' + IntToStr(Round(w.Y));
    x := x - UTextW(t, 11) - 22;
    UText(x, y + 6.5, t, 11, CMuted);
  end;
end;

// ------------------------------------------------------------- las reglas
function RulerStep: Double;
const
  St: array[0..12] of Double = (1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2500);
var
  i: Integer;
begin
  for i := 0 to High(St) do
    if St[i] * Zoom >= 56 then Exit(St[i]);
  Result := 5000;
end;

procedure DrawRulers;
var
  st, w0, w1, v, sx: Double;
  b: TRectF;
  old: TRect;
  k: Integer;
begin
  if not Rulers then Exit;
  URect(CX0 - RulerW, CY0 - RulerW, CX1 - CX0 + RulerW, RulerW, CPanel);
  URect(CX0 - RulerW, CY0, RulerW, CY1 - CY0, CPanel);
  ULine(CX0 - RulerW, CY0 - 0.5, CX1, CY0 - 0.5, 1, CLine);
  ULine(CX0 - 0.5, CY0 - RulerW, CX0 - 0.5, CY1, 1, CLine);
  st := RulerStep;
  if Sel.Count > 0 then
  begin
    b := SelBox;
    URect(Max(CX0, W2SX(b.L)), CY0 - RulerW, Max(0, Min(CX1, W2SX(b.R)) - Max(CX0, W2SX(b.L))), RulerW, CAccent, 0.22);
    URect(CX0 - RulerW, Max(CY0, W2SY(b.T)), RulerW, Max(0, Min(CY1, W2SY(b.B)) - Max(CY0, W2SY(b.T))), CAccent, 0.22);
  end;
  // arriba
  PushClip(CX0, CY0 - RulerW, CX1 - CX0, RulerW, old);
  w0 := S2W(CX0, 0).X;
  w1 := S2W(CX1, 0).X;
  v := Floor(w0 / st) * st;
  while v <= w1 do
  begin
    sx := W2SX(v);
    ULine(sx, CY0 - 7, sx, CY0, 1, CMuted);
    UText(sx + 3, CY0 - RulerW + 2, IntToStr(Round(v)), 9, CMuted);
    for k := 1 to 4 do
      ULine(sx + k * st * Zoom / 5, CY0 - 3, sx + k * st * Zoom / 5, CY0, 1, CMuted, 0.6);
    v := v + st;
  end;
  PopClip(old);
  // izquierda
  PushClip(CX0 - RulerW, CY0, RulerW, CY1 - CY0, old);
  w0 := S2W(0, CY0).Y;
  w1 := S2W(0, CY1).Y;
  v := Floor(w0 / st) * st;
  while v <= w1 do
  begin
    sx := W2SY(v);
    ULine(CX0 - 7, sx, CX0, sx, 1, CMuted);
    for k := 1 to 4 do
      ULine(CX0 - 3, sx + k * st * Zoom / 5, CX0, sx + k * st * Zoom / 5, 1, CMuted, 0.6);
    // Los números de la izquierda, de arriba abajo de uno en uno.
    UText(CX0 - RulerW + 3, sx + 2, Copy(IntToStr(Round(v)), 1, 1), 8.5, CMuted);
    if Length(IntToStr(Round(v))) > 1 then UText(CX0 - RulerW + 3, sx + 11, Copy(IntToStr(Round(v)), 2, 1), 8.5, CMuted);
    if Length(IntToStr(Round(v))) > 2 then UText(CX0 - RulerW + 3, sx + 20, Copy(IntToStr(Round(v)), 3, 2), 8.5, CMuted);
    v := v + st;
  end;
  PopClip(old);
  URect(CX0 - RulerW, CY0 - RulerW, RulerW - 1, RulerW - 1, CPanel);
end;

// ============================================================ el inspector
var
  CodeFont: string = 'Menlo';

procedure RunAct(const Act: string); forward;
procedure ShowPopup(const Caps, Acts: array of string); forward;
function CssOf(N: TNode): string; forward;
function FlutterOf(N: TNode): string; forward;

function NumStr(V: Double): string;
begin
  Result := F2S(Round(V * 100) / 100);
end;

function HasRadius(N: TNode): Boolean;
begin
  Result := N.Kind in [kRect, kFrame, kComponent, kInstance];
end;

function GetNum(N: TNode; const Id: string): Double;
begin
  Result := 0;
  if Id = 'x' then Result := N.X
  else if Id = 'y' then Result := N.Y
  else if Id = 'w' then Result := N.W
  else if Id = 'h' then Result := N.H
  else if Id = 'rot' then Result := N.Rot
  else if Id = 'rad' then Result := N.Radius
  else if Id = 'op' then Result := N.Opacity * 100
  else if Id = 'size' then Result := N.Size
  else if Id = 'lh' then Result := N.LineH
  else if Id = 'ls' then Result := N.Spacing
  else if Id = 'sides' then Result := N.Sides
  else if Id = 'ratio' then Result := N.Ratio * 100
  else if Id = 'sw' then Result := N.StrokeW
  else if Id = 'gap' then Result := N.Gap
  else if Id = 'pad' then Result := N.Pad
  else if Id = 'shx' then Result := N.ShX
  else if Id = 'shy' then Result := N.ShY
  else if Id = 'shb' then Result := N.ShBlur
  else if Id = 'sha' then Result := CA(N.ShColor) / 2.55
  else if Id = 'angle' then Result := N.Fill.Angle
  else if Id = 'filla' then Result := CA(N.Fill.C1) / 2.55
  else if Id = 'strokea' then Result := CA(N.Stroke.C1) / 2.55
  else if Id = 'dur' then Result := N.Dur;
end;

procedure SetNum(N: TNode; const Id: string; V: Double);
var
  cx, cy: Double;
begin
  if Id = 'x' then MoveNode(N, V - N.X, 0)
  else if Id = 'y' then MoveNode(N, 0, V - N.Y)
  else if (Id = 'w') or (Id = 'h') then
  begin
    V := Max(V, 0.01);
    if N.Kind = kGroup then
    begin
      if (Id = 'w') and (N.W > 0) then ScaleNode(N, N.X, N.Y, V / N.W, 1)
      else if (Id = 'h') and (N.H > 0) then ScaleNode(N, N.X, N.Y, 1, V / N.H);
    end
    else if Id = 'w' then SetSize(N, V, N.H)
    else SetSize(N, N.W, V);
  end
  else if Id = 'rot' then
  begin
    if N.Kind = kGroup then Exit;
    cx := N.X + N.W / 2; cy := N.Y + N.H / 2;
    N.Rot := V - 360 * Floor((V + 180) / 360);
    N.X := cx - N.W / 2; N.Y := cy - N.H / 2;
  end
  else if Id = 'rad' then N.Radius := Max(0, V)
  else if Id = 'op' then N.Opacity := EnsureRange(V, 0, 100) / 100
  else if Id = 'size' then N.Size := EnsureRange(V, 1, 1000)
  else if Id = 'lh' then N.LineH := Max(0, V)
  else if Id = 'ls' then N.Spacing := EnsureRange(V, -50, 200)
  else if Id = 'sides' then N.Sides := EnsureRange(Round(V), 3, 60)
  else if Id = 'ratio' then N.Ratio := EnsureRange(V, 1, 100) / 100
  else if Id = 'sw' then N.StrokeW := EnsureRange(V, 0, 500)
  else if Id = 'gap' then N.Gap := V
  else if Id = 'pad' then N.Pad := Max(0, V)
  else if Id = 'shx' then N.ShX := V
  else if Id = 'shy' then N.ShY := V
  else if Id = 'shb' then N.ShBlur := EnsureRange(V, 0, 200)
  else if Id = 'sha' then N.ShColor := SetA(N.ShColor, Round(EnsureRange(V, 0, 100) * 2.55))
  else if Id = 'angle' then N.Fill.Angle := V
  else if Id = 'filla' then N.Fill.C1 := SetA(N.Fill.C1, Round(EnsureRange(V, 0, 100) * 2.55))
  else if Id = 'strokea' then N.Stroke.C1 := SetA(N.Stroke.C1, Round(EnsureRange(V, 0, 100) * 2.55))
  else if Id = 'dur' then N.Dur := EnsureRange(Round(V), 0, 5000);
end;

function IsNumId(const Id: string): Boolean;
begin
  Result := Pos(',' + Id + ',', ',x,y,w,h,rot,rad,op,size,lh,ls,sides,ratio,sw,gap,pad,shx,shy,shb,sha,angle,filla,strokea,dur,') > 0;
end;

{ Una cuenta sencilla en un campo: «120+16», «200/2»… }
function EvalNum(const S: string; out V: Double): Boolean;
var
  t: string;
  i: Integer;
  a, b: Double;
  op: Char;
begin
  t := StringReplace(Trim(S), ',', '.', [rfReplaceAll]);
  t := StringReplace(t, '%', '', [rfReplaceAll]);
  t := StringReplace(t, '°', '', [rfReplaceAll]);
  t := StringReplace(t, 'px', '', [rfReplaceAll]);
  Result := TryStrToFloat(t, V, FS);
  if Result then Exit;
  for i := Length(t) downto 2 do
    if t[i] in ['+', '-', '*', '/', 'x'] then
    begin
      op := t[i];
      if not TryStrToFloat(Trim(Copy(t, 1, i - 1)), a, FS) then Continue;
      if not TryStrToFloat(Trim(Copy(t, i + 1, MaxInt)), b, FS) then Continue;
      case op of
        '+': V := a + b;
        '-': V := a - b;
        '*', 'x': V := a * b;
        '/': if b <> 0 then V := a / b else Exit(False);
      end;
      Exit(True);
    end;
end;

procedure PropsChanged;
begin
  NormalizeAll;
  Dirty := True;
end;

procedure ApplyEdit(const Id, V: string);
var
  i, k: Integer;
  n: TNode;
  num: Double;
  c: TComment;
begin
  if Copy(Id, 1, 5) = 'page:' then
  begin
    k := StrToIntDef(Copy(Id, 6, 9), -1);
    if (k >= 0) and (k < Pages.Count) and (Trim(V) <> '') then
    begin
      Snap;
      PageN(k).Name := Trim(V);
    end;
    Exit;
  end;
  if Copy(Id, 1, 5) = 'name:' then
  begin
    n := FindNode(StrToIntDef(Copy(Id, 6, 12), 0));
    if n <> nil then
    begin
      Snap;
      n.Name := V;
    end;
    Exit;
  end;
  if Copy(Id, 1, 8) = 'comment:' then
  begin
    k := StrToIntDef(Copy(Id, 9, 9), -1);
    if (k >= 0) and (k < Comments.Count) then
    begin
      c := TComment(Comments[k]);
      if Trim(V) = '' then
      begin
        Comments.Delete(k);
        c.Free;
        ActiveComment := -1;
      end
      else c.Text := V;
      Dirty := True;
    end;
    Exit;
  end;
  if Copy(Id, 1, 6) = 'sname:' then
  begin
    k := StrToIntDef(Copy(Id, 7, 9), -1);
    if (k >= 0) and (k < Styles.Count) and (Trim(V) <> '') then
    begin
      Snap;
      Styles[k] := Trim(V) + '=' + Styles.ValueFromIndex[k];
    end;
    Exit;
  end;
  if Id = 'pagebg' then
  begin
    Snap;
    Page.Bg := HexC(V);
    Exit;
  end;
  if Id = 'pickhex' then
  begin
    RunAct('pickhex:' + V);
    Exit;
  end;
  if Sel.Count = 0 then Exit;
  if IsNumId(Id) then
  begin
    if not EvalNum(V, num) then Exit;
    Snap;
    for i := 0 to Sel.Count - 1 do SetNum(SelN(i), Id, num);
    PropsChanged;
    Exit;
  end;
  Snap;
  for i := 0 to Sel.Count - 1 do
  begin
    n := SelN(i);
    if Id = 'name' then n.Name := V
    else if Id = 'fillhex' then begin n.Fill.C1 := SetA(HexC(V), CA(n.Fill.C1)); n.Fill.Style := ''; end
    else if Id = 'fill2hex' then n.Fill.C2 := SetA(HexC(V), CA(n.Fill.C2))
    else if Id = 'strokehex' then begin n.Stroke.C1 := SetA(HexC(V), CA(n.Stroke.C1)); n.Stroke.Style := ''; end
    else if Id = 'shhex' then n.ShColor := SetA(HexC(V), CA(n.ShColor));
  end;
  PropsChanged;
end;

// --------------------------------------------------------- selector de color
function TargetColor(const T: string): LongWord;
var
  n: TNode;
  k: Integer;
begin
  Result := $FF000000;
  if T = 'pagebg' then Exit(PageBg(Page));
  if Copy(T, 1, 6) = 'style:' then
  begin
    k := StrToIntDef(Copy(T, 7, 9), -1);
    if (k >= 0) and (k < Styles.Count) then Result := LongWord(StrToInt64Def('$' + Styles.ValueFromIndex[k], 0));
    Exit;
  end;
  if Sel.Count = 0 then Exit;
  n := SelN(0);
  if T = 'fill' then Result := FillC1(n.Fill)
  else if T = 'fill2' then Result := n.Fill.C2
  else if T = 'stroke' then Result := FillC1(n.Stroke)
  else if T = 'shc' then Result := n.ShColor;
end;

procedure SetTargetColor(const T: string; C: LongWord);
var
  i, k: Integer;
  n: TNode;
begin
  if T = 'pagebg' then begin Page.Bg := C or $FF000000; Exit; end;
  if Copy(T, 1, 6) = 'style:' then
  begin
    k := StrToIntDef(Copy(T, 7, 9), -1);
    if (k >= 0) and (k < Styles.Count) then Styles[k] := Styles.Names[k] + '=' + IntToHex(C, 8);
    Exit;
  end;
  for i := 0 to Sel.Count - 1 do
  begin
    n := SelN(i);
    if T = 'fill' then begin n.Fill.C1 := C; n.Fill.Style := ''; n.Fill.Vis := True; end
    else if T = 'fill2' then n.Fill.C2 := C
    else if T = 'stroke' then begin n.Stroke.C1 := C; n.Stroke.Style := ''; n.Stroke.Vis := True; end
    else if T = 'shc' then n.ShColor := C;
  end;
  Dirty := True;
end;

procedure OpenPicker(const T: string; Y: Double);
var
  c: LongWord;
begin
  PickOpen := True;
  PickTarget := T;
  PickX := RailW + InspW + 8;
  PickY := EnsureRange(Y - 40, TopH + 8, WinH - StatusH - 330);
  c := TargetColor(T);
  ToHSV(c, PickH, PickS, PickV);
  PickA := CA(c);
  if EditId <> '' then CommitEdit;
end;

function PickColor: LongWord;
begin
  Result := FromHSV(PickH, PickS, PickV, PickA);
end;

{ Los colores que ya usa el documento (y los estilos), para elegir rápido. }
function DocColors: TStringList;
var
  L: TFPList;
  i: Integer;
  n: TNode;
  procedure Add(C: LongWord);
  var
    h: string;
  begin
    h := IntToHex(C or $FF000000, 8);
    if (Result.IndexOf(h) < 0) and (Result.Count < 16) then Result.Add(h);
  end;
begin
  Result := TStringList.Create;
  for i := 0 to Styles.Count - 1 do Add(LongWord(StrToInt64Def('$' + Styles.ValueFromIndex[i], 0)));
  L := TFPList.Create;
  try
    Flatten(Page.Root, L, False);
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      if n.Fill.Vis and (n.Fill.Kind = fkSolid) then Add(FillC1(n.Fill));
      if n.Stroke.Vis then Add(FillC1(n.Stroke));
    end;
  finally
    L.Free;
  end;
end;

procedure DrawPicker;
var
  x, y, w, sx, sy: Double;
  i, j: Integer;
  cols: TStringList;
  c: LongWord;
  old: TRect;
begin
  if not PickOpen then Exit;
  x := PickX; y := PickY; w := 240;
  FillPoly(RRectPoly((x + 2) * S, (y + 6) * S, w * S, 318 * S, 10 * S), $FF000000, 0.25);
  URound(x, y, w, 318, 10, CPanel);
  UFrame(x, y, w, 318, 10, 1, CLine);
  AddHit(x, y, w, 318, 'pk:none');
  UText(x + 12, y + 10, tx_COLOR, 11.5, CText, True);
  IconBtn(x + w - 30, y + 6, 22, 22, 'close', 'pk:close');
  // El cuadro de saturación y brillo.
  sx := x + 12; sy := y + 34;
  for j := 0 to 37 do
    for i := 0 to 53 do
      URect(sx + i * 4, sy + j * 4, 4.2, 4.2, FromHSV(PickH, i / 53, 1 - j / 37, 255));
  URing(sx + PickS * 216, sy + (1 - PickV) * 152, 6, 2, $FFFFFFFF);
  URing(sx + PickS * 216, sy + (1 - PickV) * 152, 7.5, 1, $FF000000, 0.4);
  AddHit(sx, sy, 216, 152, 'pk:sv');
  // El tono.
  sy := y + 196;
  for i := 0 to 107 do URect(sx + i * 2, sy, 2.2, 12, FromHSV(i / 107 * 360, 1, 1, 255));
  UCircle(sx + PickH / 360 * 216, sy + 6, 7, $FFFFFFFF);
  UCircle(sx + PickH / 360 * 216, sy + 6, 5, FromHSV(PickH, 1, 1, 255));
  AddHit(sx - 4, sy - 4, 224, 20, 'pk:hue');
  // La transparencia.
  sy := y + 218;
  Checker(sx, sy, 216, 12);
  for i := 0 to 107 do URect(sx + i * 2, sy, 2.2, 12, SetA(PickColor, Round(i / 107 * 255)));
  UCircle(sx + PickA / 255 * 216, sy + 6, 7, $FFFFFFFF);
  UCircle(sx + PickA / 255 * 216, sy + 6, 5, PickColor);
  AddHit(sx - 4, sy - 4, 224, 20, 'pk:alpha');
  // Hex y alfa.
  sy := y + 240;
  Swatch(sx, sy + 2, 22, PickColor, '');
  if EditId = 'pickhex' then DrawField(sx + 28, sy, 120, 26, 'pickhex', '#', EditBuf, False)
  else DrawField(sx + 28, sy, 120, 26, 'pickhex', '#', HexOf(PickColor), False);
  UTextIn(sx + 154, sy, 62, 26, IntToStr(Round(PickA / 2.55)) + ' %', 11.5, CMuted, False, 2);
  // Los colores del documento.
  sy := y + 276;
  UText(sx, sy - 1, tx_DOC_COLORS, 9.5, CMuted);
  cols := DocColors;
  try
    PushClip(sx, sy + 12, 216, 22, old);
    for i := 0 to cols.Count - 1 do
    begin
      c := LongWord(StrToInt64Def('$' + cols[i], 0));
      Swatch(sx + i * 22, sy + 14, 18, c, 'pk:sw:' + cols[i]);
    end;
    PopClip(old);
  finally
    cols.Free;
  end;
end;

// ------------------------------------------------------- las secciones
var
  IY: Double;   // dónde va la siguiente fila del inspector
  IX: Double;   // el borde izquierdo de las filas
  IW: Double;   // el ancho de las filas

procedure IGap(H: Double);
begin
  IY := IY + H;
end;

procedure IHead(const T: string; const PlusAct: string = ''; Plus: Boolean = True);
begin
  IGap(10);
  SectionHead(IX, IY, IW, T);
  if PlusAct <> '' then
    if Plus then IconBtn(IX + IW - 22, IY - 4, 22, 22, 'plus', PlusAct)
    else IconBtn(IX + IW - 22, IY - 4, 22, 22, 'minus', PlusAct);
  IGap(24);
end;

procedure INum2(const A, LA, B, LB: string; N: TNode);
var
  hw: Double;
begin
  hw := (IW - 8) / 2;
  DrawField(IX, IY, hw, 26, A, LA, NumStr(GetNum(N, A)));
  DrawField(IX + hw + 8, IY, hw, 26, B, LB, NumStr(GetNum(N, B)));
  IGap(32);
end;

procedure INote(const T: string);
var
  words: TStringArray;
  line, tryS: string;
  i: Integer;
begin
  words := T.Split([' ']);
  line := '';
  for i := 0 to High(words) do
  begin
    if line = '' then tryS := words[i] else tryS := line + ' ' + words[i];
    if UTextW(tryS, 11) > IW then
    begin
      UText(IX, IY, line, 11, CMuted);
      IGap(16);
      line := words[i];
    end
    else line := tryS;
  end;
  if line <> '' then
  begin
    UText(IX, IY, line, 11, CMuted);
    IGap(16);
  end;
end;

procedure IFillRow(N: TNode; const F: TFill; const Pfx, Lbl: string);
var
  c: LongWord;
  t: string;
begin
  c := FillC1(F);
  if F.Kind = fkSolid then Swatch(IX, IY + 3, 20, c, 'pick:' + Pfx)
  else if F.Kind = fkLinear then
  begin
    Swatch(IX, IY + 3, 20, c, 'pick:' + Pfx);
    URect(IX + 10, IY + 3, 10, 20, F.C2);
  end
  else
  begin
    URound(IX, IY + 3, 20, 20, 3, CField);
    Icon('image', IX + 10, IY + 13, CText, 13);
  end;
  if F.Style <> '' then
  begin
    URound(IX + 28, IY, IW - 86, 26, 5, CField);
    Icon('style', IX + 40, IY + 13, CComp, 12);
    UTextIn(IX + 50, IY, IW - 112, 26, F.Style, 11.5, CText);
    IconBtn(IX + IW - 80, IY + 2, 22, 22, 'close', 'unstyle:' + Pfx);
  end
  else if F.Kind = fkImage then
  begin
    t := ExtractFileName(F.Img);
    if t = '' then t := tx_PICK_IMAGE;
    TextBtn(IX + 28, IY, IW - 86, 26, Ellip(t, 12, IW - 100), 'fillimg');
  end
  else
  begin
    DrawField(IX + 28, IY, IW - 124, 26, Pfx + 'hex', '', HexOf(c), False);
    DrawField(IX + IW - 92, IY, 50, 26, Pfx + 'a', '', IntToStr(Round(CA(c) / 2.55)) + '%', False);
  end;
  if Pfx = 'fill' then IconBtn(IX + IW - 50, IY + 2, 22, 22, 'dots', 'filltype')
  else IconBtn(IX + IW - 50, IY + 2, 22, 22, 'style', 'stylemenu:' + Pfx);
  if F.Vis then IconBtn(IX + IW - 26, IY + 2, 22, 22, 'eye', 'vis:' + Pfx)
  else IconBtn(IX + IW - 26, IY + 2, 22, 22, 'eyeoff', 'vis:' + Pfx);
  if Lbl = '' then;
  if N = nil then;
  IGap(32);
end;

procedure InspectDesign(N: TNode);
var
  hw, bw: Double;
  i: Integer;
  t, ic: string;
  main: TNode;
begin
  // La cabecera: el tipo y el nombre.
  if N.Kind in [kComponent, kInstance] then ic := 'component' else ic := KindIcon(N);
  if N.Kind in [kComponent, kInstance] then Icon(KindIcon(N), IX + 8, IY + 13, CComp, 15)
  else Icon(ic, IX + 8, IY + 13, CText, 15);
  if Sel.Count > 1 then
  begin
    UTextIn(IX + 22, IY, IW - 22, 26, IntToStr(Sel.Count) + ' ' + tx_LAYERS_LC, 12.5, CText, True);
    IGap(30);
  end
  else
  begin
    DrawField(IX + 22, IY, IW - 22, 26, 'name', '', NodeName(N), False);
    IGap(30);
    if N.Kind = kInstance then
    begin
      main := FindNode(N.CompId);
      if main <> nil then t := main.Name else t := '?';
      UTextIn(IX, IY, IW - 90, 24, Format(tx_INSTANCE_OF, [t]), 11, CComp);
      TextBtn(IX + IW - 84, IY, 84, 24, tx_DETACH, 'detach');
      IGap(30);
    end
    else if N.Kind = kComponent then
    begin
      UTextIn(IX, IY, IW, 22, tx_MAIN_COMPONENT, 11, CComp);
      IGap(26);
    end;
  end;
  // Alinear y repartir.
  bw := IW / 8;
  IconBtn(IX, IY, bw, 28, 'alignL', 'align:0');
  IconBtn(IX + bw, IY, bw, 28, 'alignCH', 'align:1');
  IconBtn(IX + bw * 2, IY, bw, 28, 'alignR', 'align:2');
  IconBtn(IX + bw * 3, IY, bw, 28, 'alignT', 'align:3');
  IconBtn(IX + bw * 4, IY, bw, 28, 'alignCV', 'align:4');
  IconBtn(IX + bw * 5, IY, bw, 28, 'alignB', 'align:5');
  IconBtn(IX + bw * 6, IY, bw, 28, 'distH', 'dist:0');
  IconBtn(IX + bw * 7, IY, bw, 28, 'distV', 'dist:1');
  IGap(32);
  // Posición y tamaño.
  IHead(tx_POSITION);
  INum2('x', 'X', 'y', 'Y', N);
  INum2('w', 'W', 'h', 'H', N);
  hw := (IW - 8) / 2;
  DrawField(IX, IY, hw, 26, 'rot', '↻', NumStr(N.Rot) + '°');
  if HasRadius(N) then DrawField(IX + hw + 8, IY, hw, 26, 'rad', '◜', NumStr(N.Radius));
  IGap(32);
  if N.Kind in [kPolygon, kStar] then
  begin
    if N.Kind = kStar then INum2('sides', tx_POINTS, 'ratio', tx_RATIO, N)
    else
    begin
      DrawField(IX, IY, hw, 26, 'sides', tx_SIDES, NumStr(N.Sides));
      IGap(32);
    end;
  end;
  // Marco: recortar y diseño automático.
  if N.Kind in [kFrame, kComponent] then
  begin
    UTextIn(IX, IY, IW - 40, 22, tx_CLIP, 11.5, CText);
    Toggle(IX + IW - 30, IY + 3, N.Clip, 'clip');
    IGap(28);
    IHead(tx_AUTOLAYOUT, 'auto', N.Layout = 0);
    if N.Layout <> 0 then
    begin
      IconBtn(IX, IY, 34, 26, 'autoH', 'lay:1', N.Layout = 1);
      IconBtn(IX + 36, IY, 34, 26, 'autoV', 'lay:2', N.Layout = 2);
      if N.Layout = 1 then
      begin
        IconBtn(IX + 84, IY, 30, 26, 'alignT', 'la:0', N.LAlign = 0);
        IconBtn(IX + 116, IY, 30, 26, 'alignCV', 'la:1', N.LAlign = 1);
        IconBtn(IX + 148, IY, 30, 26, 'alignB', 'la:2', N.LAlign = 2);
      end
      else
      begin
        IconBtn(IX + 84, IY, 30, 26, 'alignL', 'la:0', N.LAlign = 0);
        IconBtn(IX + 116, IY, 30, 26, 'alignCH', 'la:1', N.LAlign = 1);
        IconBtn(IX + 148, IY, 30, 26, 'alignR', 'la:2', N.LAlign = 2);
      end;
      IGap(32);
      INum2('gap', tx_GAP, 'pad', tx_PADDING, N);
      UTextIn(IX, IY, IW - 40, 22, tx_HUG, 11.5, CText);
      Toggle(IX + IW - 30, IY + 3, N.Hug, 'hug');
      IGap(28);
    end;
  end;
  // La capa.
  IHead(tx_LAYER);
  DrawField(IX, IY, hw, 26, 'op', '◐', NumStr(N.Opacity * 100) + '%');
  IconBtn(IX + hw + 8, IY, 30, 26, 'eye', 'hide');
  IconBtn(IX + hw + 40, IY, 30, 26, 'lock', 'lock');
  IGap(32);
  // El texto.
  if N.Kind = kText then
  begin
    IHead(tx_TYPOGRAPHY);
    if Hov('fontmenu') then URound(IX, IY, IW, 26, 5, CHover) else URound(IX, IY, IW, 26, 5, CField);
    UTextIn(IX + 8, IY, IW - 30, 26, N.Font, 12, CText);
    Icon('chevdown', IX + IW - 14, IY + 13, CMuted, 11);
    AddHit(IX, IY, IW, 26, 'fontmenu');
    IGap(32);
    DrawField(IX, IY, hw, 26, 'size', 'Aa', NumStr(N.Size));
    if N.Bold then URound(IX + hw + 8, IY, 34, 26, 6, CSelBg)
    else if Hov('bold') then URound(IX + hw + 8, IY, 34, 26, 6, CHover);
    UTextIn(IX + hw + 8, IY, 34, 26, 'B', 13, CText, True, 1);
    AddHit(IX + hw + 8, IY, 34, 26, 'bold');
    if N.Italic then URound(IX + hw + 46, IY, 34, 26, 6, CSelBg)
    else if Hov('italic') then URound(IX + hw + 46, IY, 34, 26, 6, CHover);
    UTextIn(IX + hw + 46, IY, 34, 26, 'I', 13, CText, False, 1);
    AddHit(IX + hw + 46, IY, 34, 26, 'italic');
    IGap(32);
    if N.LineH > 0 then t := NumStr(N.LineH) + '%' else t := tx_AUTO;
    DrawField(IX, IY, hw, 26, 'lh', '↕', t);
    DrawField(IX + hw + 8, IY, hw, 26, 'ls', '↔', NumStr(N.Spacing) + '%');
    IGap(32);
    IconBtn(IX, IY, 30, 26, 'alignL', 'tal:0', N.Align = 0);
    IconBtn(IX + 32, IY, 30, 26, 'alignCH', 'tal:1', N.Align = 1);
    IconBtn(IX + 64, IY, 30, 26, 'alignR', 'tal:2', N.Align = 2);
    UTextIn(IX + 104, IY, IW - 144, 26, tx_AUTOWIDTH, 11, CText, False, 2);
    Toggle(IX + IW - 30, IY + 5, N.AutoW, 'autow');
    IGap(28);
  end;
  // Relleno, trazo y sombra.
  if N.Kind <> kGroup then
  begin
    if not (N.Kind in [kLine, kArrow, kInstance]) then
    begin
      IHead(tx_FILL);
      IFillRow(N, N.Fill, 'fill', '');
      if N.Fill.Kind = fkLinear then
      begin
        Swatch(IX, IY + 3, 20, N.Fill.C2, 'pick:fill2');
        DrawField(IX + 28, IY, IW - 124, 26, 'fill2hex', '', HexOf(N.Fill.C2), False);
        DrawField(IX + IW - 92, IY, 88, 26, 'angle', '∠', NumStr(N.Fill.Angle) + '°');
        IGap(32);
      end
      else if N.Fill.Kind = fkImage then
      begin
        UTextIn(IX, IY, IW - 40, 22, tx_FIT, 11.5, CText);
        Toggle(IX + IW - 30, IY + 3, N.Fill.Fit, 'fillfit');
        IGap(28);
      end;
    end;
    if N.Kind <> kInstance then
    begin
      IHead(tx_STROKE, 'strokeon', not N.Stroke.Vis);
      if N.Stroke.Vis then
      begin
        IFillRow(N, N.Stroke, 'stroke', '');
        DrawField(IX, IY, hw, 26, 'sw', '≡', NumStr(N.StrokeW));
        if not IsOpenPath(N) then
        begin
          case N.StrokePos of
            1: t := tx_INSIDE;
            2: t := tx_OUTSIDE;
          else
            t := tx_CENTER;
          end;
          if Hov('strokepos') then URound(IX + hw + 8, IY, hw - 36, 26, 5, CHover)
          else URound(IX + hw + 8, IY, hw - 36, 26, 5, CField);
          UTextIn(IX + hw + 16, IY, hw - 52, 26, t, 11.5, CText);
          AddHit(IX + hw + 8, IY, hw - 36, 26, 'strokepos');
        end;
        IconBtn(IX + IW - 28, IY, 28, 26, 'dots', 'dash', N.Dash);
        IGap(32);
      end;
      IHead(tx_SHADOW, 'shadow', not N.ShOn);
      if N.ShOn then
      begin
        Swatch(IX, IY + 3, 20, N.ShColor, 'pick:shc');
        DrawField(IX + 28, IY, (IW - 44) / 3, 26, 'shx', 'X', NumStr(N.ShX));
        DrawField(IX + 36 + (IW - 44) / 3, IY, (IW - 44) / 3, 26, 'shy', 'Y', NumStr(N.ShY));
        DrawField(IX + 44 + 2 * (IW - 44) / 3, IY, (IW - 44) / 3, 26, 'shb', '◌', NumStr(N.ShBlur));
        IGap(32);
      end;
    end;
  end;
  // Exportar.
  IHead(tx_EXPORT_SEC);
  for i := 1 to 4 do
  begin
    if ExportScale = i then URound(IX + (i - 1) * 40, IY, 36, 26, 5, CSelBg)
    else if Hov('scale:' + IntToStr(i)) then URound(IX + (i - 1) * 40, IY, 36, 26, 5, CHover)
    else URound(IX + (i - 1) * 40, IY, 36, 26, 5, CField);
    UTextIn(IX + (i - 1) * 40, IY, 36, 26, IntToStr(i) + 'x', 11.5, CText, ExportScale = i, 1);
    AddHit(IX + (i - 1) * 40, IY, 36, 26, 'scale:' + IntToStr(i));
  end;
  IGap(32);
  TextBtn(IX, IY, (IW - 8) / 2, 28, 'PNG', 'exportpng');
  TextBtn(IX + (IW - 8) / 2 + 8, IY, (IW - 8) / 2, 28, 'SVG', 'exportsvg');
  IGap(34);
  TextBtn(IX, IY, IW, 28, tx_AI_COPY_SEL, 'aiexport');
  IGap(34);
end;

procedure InspectPage;
var
  i: Integer;
  c: LongWord;
begin
  IHead(tx_PAGE_SEC);
  Swatch(IX, IY + 3, 20, PageBg(Page), 'pick:pagebg');
  DrawField(IX + 28, IY, IW - 28, 26, 'pagebg', tx_BG, HexOf(PageBg(Page)), False);
  IGap(32);
  IHead(tx_STYLES, 'styleadd');
  if Styles.Count = 0 then INote(tx_STYLES_NONE);
  for i := 0 to Styles.Count - 1 do
  begin
    c := LongWord(StrToInt64Def('$' + Styles.ValueFromIndex[i], 0));
    Swatch(IX, IY + 3, 20, c, 'pick:style:' + IntToStr(i));
    if EditId = 'sname:' + IntToStr(i) then
      DrawField(IX + 28, IY, IW - 60, 26, 'sname:' + IntToStr(i), '', EditBuf, False)
    else
    begin
      if Hov('sname:' + IntToStr(i)) then URound(IX + 28, IY, IW - 60, 26, 5, CHover);
      UTextIn(IX + 34, IY, IW - 120, 26, Styles.Names[i], 12, CText);
      UTextIn(IX + 34, IY, IW - 72, 26, '#' + HexOf(c), 10.5, CMuted, False, 2);
      AddHit(IX + 28, IY, IW - 60, 26, 'sname:' + IntToStr(i));
    end;
    IconBtn(IX + IW - 26, IY + 2, 22, 22, 'minus', 'styledel:' + IntToStr(i));
    IGap(30);
  end;
  IHead(tx_TIPS);
  INote(tx_TIPS_TEXT);
end;

const
  Presets: array[0..15] of string = (
    'P|iPhone 16|393|852', 'P|iPhone 16 Pro Max|440|956', 'P|iPhone 14 Pro Max|430|932',
    'P|iPhone SE|375|667', 'P|Android L|412|915', 'P|Android S|360|640',
    'T|iPad mini|744|1133', 'T|iPad Pro 11"|834|1194', 'T|Surface Pro 8|1440|960',
    'D|MacBook Air|1280|832', 'D|Desktop|1440|1024', 'D|HD 1080p|1920|1080',
    'S|Instagram 1:1|1080|1080', 'S|Story 9:16|1080|1920', 'S|Slide 16:9|1920|1080',
    'S|A4|595|842');

procedure InspectPresets;
var
  i: Integer;
  f: TStringArray;
  g, last: string;
begin
  last := '';
  for i := 0 to High(Presets) do
  begin
    f := Presets[i].Split(['|']);
    g := f[0];
    if g <> last then
    begin
      case g[1] of
        'P': IHead(tx_PRESET_PHONE);
        'T': IHead(tx_PRESET_TABLET);
        'D': IHead(tx_PRESET_DESKTOP);
      else
        IHead(tx_PRESET_SOCIAL);
      end;
      last := g;
    end;
    if Hov('preset:' + IntToStr(i)) then URound(IX - 4, IY, IW + 8, 26, 5, CHover);
    UTextIn(IX + 4, IY, IW - 90, 26, f[1], 12, CText);
    UTextIn(IX, IY, IW - 4, 26, f[2] + ' × ' + f[3], 11, CMuted, False, 2);
    AddHit(IX - 4, IY, IW + 8, 26, 'preset:' + IntToStr(i));
    IGap(27);
  end;
end;

function AnimName(A: Integer): string;
begin
  case A of
    1: Result := tx_ANIM_DISSOLVE;
    2: Result := tx_ANIM_LEFT;
    3: Result := tx_ANIM_RIGHT;
    4: Result := tx_ANIM_UP;
    5: Result := tx_ANIM_PUSH;
  else
    Result := tx_ANIM_INSTANT;
  end;
end;

procedure Dropdown(const T, Act: string);
begin
  if Hov(Act) then URound(IX, IY, IW, 28, 6, CHover) else URound(IX, IY, IW, 28, 6, CField);
  UTextIn(IX + 10, IY, IW - 34, 28, T, 12, CText);
  Icon('chevdown', IX + IW - 14, IY + 14, CMuted, 11);
  AddHit(IX, IY, IW, 28, Act);
  IGap(34);
end;

procedure InspectProto(N: TNode);
var
  t: TNode;
  s1: string;
begin
  if N = nil then
  begin
    IHead(tx_PROTOTYPE);
    t := FindNode(Page.StartId);
    UText(IX, IY, tx_START_FRAME, 11, CMuted);
    IGap(18);
    if t <> nil then s1 := t.Name else s1 := tx_NONE;
    Dropdown(s1, 'startmenu');
    INote(tx_PROTO_HINT);
    IGap(8);
    TextBtn(IX, IY, IW, 30, tx_PRESENT, 'play', True);
    IGap(36);
    Exit;
  end;
  Icon(KindIcon(N), IX + 8, IY + 13, CText, 15);
  UTextIn(IX + 22, IY, IW - 22, 26, NodeName(N), 12.5, CText, True);
  IGap(30);
  IHead(tx_INTERACTION);
  UText(IX, IY, tx_ON_CLICK, 11, CMuted);
  IGap(18);
  t := FindNode(N.Link);
  if t <> nil then s1 := tx_NAVIGATE_TO + ' ' + t.Name else s1 := tx_NONE;
  Dropdown(s1, 'linkmenu');
  if t <> nil then
  begin
    UText(IX, IY, tx_ANIMATION, 11, CMuted);
    IGap(18);
    Dropdown(AnimName(N.Anim), 'animmenu');
    if N.Anim > 0 then
    begin
      DrawField(IX, IY, IW, 26, 'dur', tx_DURATION, IntToStr(N.Dur) + ' ms');
      IGap(32);
    end;
    TextBtn(IX, IY, IW, 28, tx_UNLINK, 'unlink');
    IGap(34);
  end;
  if TopFrame(N) = N then
  begin
    UTextIn(IX, IY, IW - 40, 22, tx_IS_START, 11.5, CText);
    Toggle(IX + IW - 30, IY + 3, Page.StartId = N.Id, 'setstart');
    IGap(28);
  end;
  INote(tx_PROTO_DRAG);
end;

procedure InspectCode(N: TNode);
var
  L: TStringList;
  i: Integer;
  ln: string;
begin
  if N = nil then
  begin
    IHead(tx_MODE_CODE);
    INote(tx_CODE_HINT);
    Exit;
  end;
  Icon(KindIcon(N), IX + 8, IY + 13, CText, 15);
  UTextIn(IX + 22, IY, IW - 22, 26, NodeName(N), 12.5, CText, True);
  IGap(32);
  URound(IX, IY, IW, 28, 7, CField);
  if CodeLang = 0 then URound(IX + 2, IY + 2, IW / 2 - 2, 24, 6, CPanel);
  if CodeLang = 1 then URound(IX + IW / 2, IY + 2, IW / 2 - 2, 24, 6, CPanel);
  UTextIn(IX, IY, IW / 2, 28, 'CSS', 11.5, CText, CodeLang = 0, 1);
  UTextIn(IX + IW / 2, IY, IW / 2, 28, 'Flutter', 11.5, CText, CodeLang = 1, 1);
  AddHit(IX, IY, IW / 2, 28, 'lang:0');
  AddHit(IX + IW / 2, IY, IW / 2, 28, 'lang:1');
  IGap(36);
  if CodeLang = 0 then ln := CssOf(N) else ln := FlutterOf(N);
  L := TStringList.Create;
  try
    L.Text := ln;
    URound(IX, IY, IW, L.Count * 16 + 16, 8, CField);
    for i := 0 to L.Count - 1 do
    begin
      ln := L[i];
      if Pos(':', ln) > 0 then
      begin
        UText(IX + 10, IY + 8 + i * 16, Copy(ln, 1, Pos(':', ln)), 10.5, CAccent);
        UText(IX + 10 + UTextW(Copy(ln, 1, Pos(':', ln)), 10.5), IY + 8 + i * 16,
          Ellip(Copy(ln, Pos(':', ln) + 1, MaxInt), 10.5, IW - 24 - UTextW(Copy(ln, 1, Pos(':', ln)), 10.5)), 10.5, CText);
      end
      else UText(IX + 10, IY + 8 + i * 16, Ellip(ln, 10.5, IW - 20), 10.5, CMuted);
    end;
    IGap(L.Count * 16 + 24);
  finally
    L.Free;
  end;
  TextBtn(IX, IY, IW, 28, tx_COPY_CODE, 'copycode', True);
  IGap(34);
end;

procedure DrawInspector;
var
  x0, y0, h: Double;
  old: TRect;
  n: TNode;
begin
  x0 := RailW;
  y0 := TopH;
  h := WinH - TopH - StatusH;
  URect(x0, y0, InspW, h, CPanel);
  ULine(x0 + InspW - 0.5, y0, x0 + InspW - 0.5, y0 + h, 1, CLine);
  AddHit(x0, y0, InspW, h, 'insp');
  PushClip(x0, y0, InspW, h, old);
  IX := x0 + 14;
  IW := InspW - 28;
  IY := y0 + 12 - InspScroll;
  if Sel.Count > 0 then n := SelN(0) else n := nil;
  if Mode = 1 then InspectProto(n)
  else if Mode = 2 then InspectCode(n)
  else if (Tool = tlFrame) and (Sel.Count = 0) then InspectPresets
  else if n <> nil then InspectDesign(n)
  else InspectPage;
  InspH := IY + InspScroll - y0 + 20;
  if InspH > h then
    URound(x0 + InspW - 6, y0 + InspScroll / InspH * h, 3, h * h / InspH, 1.5, CMuted, 0.5);
  PopClip(old);
end;

// ===================================================== el panel de la derecha
type
  TLayerRow = record
    Id, Depth: Integer;
    Y: Double;
  end;

var
  LayerRows: array of TLayerRow;
  NLayerRows: Integer = 0;
  LayerDragId: Integer = 0;
  LayerDropY: Double = -1;
  AssetScroll: Double = 0;

procedure LayerRow(N: TNode; Depth: Integer; var Y: Double; X0, W: Double);
var
  i: Integer;
  x, rx: Double;
  c, tc: LongWord;
  sid, nm: string;
  isHov: Boolean;
begin
  sid := IntToStr(N.Id);
  if NLayerRows >= Length(LayerRows) then SetLength(LayerRows, NLayerRows * 2 + 32);
  LayerRows[NLayerRows].Id := N.Id;
  LayerRows[NLayerRows].Depth := Depth;
  LayerRows[NLayerRows].Y := Y + LayerScroll;
  Inc(NLayerRows);
  isHov := Hov('layer:' + sid) or Hov('leye:' + sid) or Hov('llock:' + sid) or Hov('exp:' + sid);
  if IsSel(N) then URect(X0, Y, W, 28, CSelBg)
  else if isHov or (HoverNode = N) then URect(X0, Y, W, 28, CHover);
  AddHit(X0, Y, W, 28, 'layer:' + sid);
  x := X0 + 10 + Depth * 14;
  if (N.Count > 0) and (N.Kind <> kInstance) then
  begin
    if N.Open then Icon('chevdown', x + 5, Y + 14, CMuted, 10)
    else Icon('chev', x + 5, Y + 14, CMuted, 10);
    AddHit(x - 2, Y, 16, 28, 'exp:' + sid);
  end;
  x := x + 14;
  if N.Kind in [kComponent, kInstance] then c := CComp
  else if (N.Parent <> nil) and (N.Parent.Parent = nil) and IsBox(N) then c := CText
  else c := CMuted;
  Icon(KindIcon(N), x + 7, Y + 14, c, 13);
  x := x + 20;
  if N.Kind in [kComponent, kInstance] then tc := CComp
  else if N.Visible then tc := CText
  else tc := CMuted;
  nm := NodeName(N);
  rx := X0 + W - 8;
  if EditId = 'name:' + sid then
    DrawField(x - 4, Y + 2, rx - x - 40, 24, 'name:' + sid, '', EditBuf, False)
  else
    UTextIn(x, Y, rx - x - 46, 28, nm, 12, tc, (N.Parent <> nil) and (N.Parent.Parent = nil) and IsBox(N));
  if isHov or N.Locked or not N.Visible then
  begin
    if N.Locked then Icon('lock', rx - 30, Y + 14, CText, 13)
    else if isHov then Icon('unlock', rx - 30, Y + 14, CMuted, 13);
    AddHit(rx - 40, Y, 20, 28, 'llock:' + sid);
    if N.Visible then Icon('eye', rx - 10, Y + 14, CMuted, 14)
    else Icon('eyeoff', rx - 10, Y + 14, CText, 14);
    AddHit(rx - 20, Y, 20, 28, 'leye:' + sid);
  end;
  Y := Y + 28;
  if N.Open and (N.Kind <> kInstance) then
    for i := N.Count - 1 downto 0 do LayerRow(N.Kid(i), Depth + 1, Y, X0, W);
end;

{ Todos los componentes de todas las páginas. }
function AllComponents: TFPList;
var
  L: TFPList;
  i, p: Integer;
begin
  Result := TFPList.Create;
  L := TFPList.Create;
  try
    for p := 0 to Pages.Count - 1 do
    begin
      L.Clear;
      Flatten(PageN(p).Root, L, False);
      for i := 0 to L.Count - 1 do
        if TNode(L[i]).Kind = kComponent then Result.Add(L[i]);
    end;
  finally
    L.Free;
  end;
end;

function Initials(const Who: string): string;
var
  p: TStringArray;
begin
  p := Trim(Who).Split([' ']);
  Result := '';
  if Length(p) > 0 then Result := UTF8Copy(p[0], 1, 1);
  if Length(p) > 1 then Result := Result + UTF8Copy(p[1], 1, 1);
  Result := UTF8UpperCase(Result);
end;

procedure DrawRight;
var
  x0, y0, w, h, y, tw, sc, tx, ty: Double;
  i, n, open: Integer;
  t: string;
  old: TRect;
  L: TFPList;
  c: TNode;
  cm: TComment;
begin
  x0 := WinW - RightW;
  y0 := TopH;
  w := RightW;
  h := WinH - TopH - StatusH;
  URect(x0, y0, w, h, CPanel);
  ULine(x0 + 0.5, y0, x0 + 0.5, y0 + h, 1, CLine);
  AddHit(x0, y0, w, h, 'right');
  // Las pestañas.
  open := 0;
  for i := 0 to Comments.Count - 1 do
    if not TComment(Comments[i]).Done then Inc(open);
  tw := (w - 16) / 3;
  for i := 0 to 2 do
  begin
    case i of
      0: t := tx_LAYERS;
      1: t := tx_ASSETS;
    else
      t := tx_COMMENTS;
      if open > 0 then t := t + ' ' + IntToStr(open);
    end;
    if RightTab = i then UTextIn(x0 + 8 + i * tw, y0 + 6, tw, 28, t, 12, CText, True, 1)
    else UTextIn(x0 + 8 + i * tw, y0 + 6, tw, 28, t, 12, CMuted, False, 1);
    if RightTab = i then URect(x0 + 8 + i * tw + 14, y0 + 34, tw - 28, 2, CAccent);
    AddHit(x0 + 8 + i * tw, y0 + 4, tw, 32, 'rtab:' + IntToStr(i));
  end;
  ULine(x0, y0 + 38.5, x0 + w, y0 + 38.5, 1, CLine);
  PushClip(x0, y0 + 39, w, h - 39, old);
  y := y0 + 44 - LayerScroll;
  case RightTab of
    0:
      begin
        NLayerRows := 0;
        for i := Page.Root.Count - 1 downto 0 do LayerRow(Page.Root.Kid(i), 0, y, x0 + 4, w - 8);
        if Page.Root.Count = 0 then
        begin
          IX := x0 + 16; IW := w - 32; IY := y + 10;
          INote(tx_NO_LAYERS);
        end;
        LayerH := y + LayerScroll - y0 - 40;
        if (LayerDragId <> 0) and (LayerDropY >= 0) then
          URect(x0 + 8, LayerDropY - 1, w - 16, 2, CAccent);
      end;
    1:
      begin
        y := y0 + 52 - AssetScroll;
        UText(x0 + 14, y, tx_COMPONENTS, 11.5, CText, True);
        y := y + 22;
        L := AllComponents;
        try
          if L.Count = 0 then
          begin
            IX := x0 + 14; IW := w - 28; IY := y;
            INote(tx_NO_COMPONENTS);
            y := IY;
          end;
          for i := 0 to L.Count - 1 do
          begin
            c := TNode(L[i]);
            tx := x0 + 12 + (i mod 2) * ((w - 32) / 2 + 8);
            ty := y + (i div 2) * 124;
            if Hov('asset:' + IntToStr(c.Id)) then URound(tx, ty, (w - 32) / 2, 116, 8, CHover)
            else URound(tx, ty, (w - 32) / 2, 116, 8, CField);
            sc := Min(((w - 32) / 2 - 16) / Max(1, c.W), 76 / Max(1, c.H));
            sc := Min(sc, 2);
            PushClip(tx + 4, ty + 4, (w - 32) / 2 - 8, 84, old);
            DrawStandalone(c, (tx + ((w - 32) / 2 - c.W * sc) / 2) * S, (ty + 8 + (76 - c.H * sc) / 2) * S, sc * S);
            PopClip(old);
            PushClip(x0, y0 + 39, w, h - 39, old);
            Icon('component', tx + 12, ty + 101, CComp, 11);
            UTextIn(tx + 20, ty + 90, (w - 32) / 2 - 24, 22, c.Name, 11, CText);
            AddHit(tx, ty, (w - 32) / 2, 116, 'asset:' + IntToStr(c.Id));
          end;
          y := y + ((L.Count + 1) div 2) * 124 + 8;
        finally
          L.Free;
        end;
        IX := x0 + 14; IW := w - 28; IY := y + 6;
        INote(tx_ASSETS_HINT);
      end;
    2:
      begin
        y := y0 + 48;
        n := 0;
        for i := 0 to Comments.Count - 1 do
        begin
          cm := TComment(Comments[i]);
          if cm.Done then Continue;
          Inc(n);
          if (ActiveComment = i) or Hov('cmt:' + IntToStr(i)) then URound(x0 + 8, y, w - 16, 74, 8, CHover);
          UCircle(x0 + 26, y + 18, 11, CAccent);
          UTextIn(x0 + 15, y + 7, 22, 22, Initials(cm.Who), 9.5, $FFFFFFFF, True, 1);
          UTextIn(x0 + 44, y + 7, w - 110, 22, cm.Who, 12, CText, True);
          UTextIn(x0 + 44, y + 7, w - 64, 22, cm.When, 10, CMuted, False, 2);
          UTextIn(x0 + 44, y + 28, w - 64, 20, cm.Text, 11.5, CText);
          UTextIn(x0 + 44, y + 46, w - 64, 20, PageN(EnsureRange(cm.Page, 0, Pages.Count - 1)).Name, 10, CMuted);
          AddHit(x0 + 8, y, w - 16, 74, 'cmt:' + IntToStr(i));
          IconBtn(x0 + w - 36, y + 44, 22, 22, 'check', 'cmtdone:' + IntToStr(i));
          y := y + 80;
        end;
        if n = 0 then
        begin
          IX := x0 + 16; IW := w - 32; IY := y + 4;
          INote(tx_NO_COMMENTS);
        end;
      end;
  end;
  PopClip(old);
end;

// ================================================ encima del lienzo
function ViewMat: TMat;
begin
  Result := MatMul(MatT(CX0 + PanX, CY0 + PanY), MatS(Zoom, Zoom));
end;

{ De la capa (0..W, 0..H) a la ventana (puntos). }
function ScreenMat(N: TNode): TMat;
begin
  Result := MatMul(ViewMat, WorldOf(N));
end;

procedure OutlineNode(N: TNode; C: LongWord; LW: Double);
var
  M: TMat;
  P: TPoly;
begin
  M := MatMul(MatS(S, S), ScreenMat(N));
  P := XfPoly(Outline(N, MatScale(M)), M);
  if Length(P) < 2 then Exit;
  if IsOpenPath(N) then FillPolys(StrokeOpen(P, LW * S, True), Solid(C))
  else FillPolys(StrokeClosed(P, LW * S / 2, LW * S / 2), Solid(C));
end;

{ Las esquinas y los centros de los lados de la selección (en la ventana). }
function HandlePts: TPoly;
const
  HX: array[0..7] of Double = (0, 0.5, 1, 1, 1, 0.5, 0, 0);
  HY: array[0..7] of Double = (0, 0, 0, 0.5, 1, 1, 1, 0.5);
var
  i: Integer;
  M: TMat;
  b: TRectF;
  n: TNode;
begin
  SetLength(Result, 8);
  n := One;
  if (n <> nil) and (n.Kind <> kGroup) then
  begin
    M := ScreenMat(n);
    for i := 0 to 7 do Result[i] := MatAp(M, P2(HX[i] * n.W, HY[i] * n.H));
  end
  else
  begin
    b := SelBox;
    for i := 0 to 7 do
      Result[i] := P2(W2SX(b.L + HX[i] * (b.R - b.L)), W2SY(b.T + HY[i] * (b.B - b.T)));
  end;
end;

function SelColor: LongWord;
var
  n: TNode;
begin
  Result := CAccent;
  n := One;
  if (n <> nil) and (n.Kind in [kComponent, kInstance]) then Result := CComp;
end;

procedure DrawPill(CX, Y: Double; const T: string; C: LongWord);
var
  w: Double;
begin
  w := UTextW(T, 10.5) + 12;
  URound(CX - w / 2, Y, w, 18, 4, C);
  UTextIn(CX - w / 2, Y, w, 18, T, 10.5, $FFFFFFFF, False, 1);
end;

procedure DrawSelection;
var
  P, Q: TPoly;
  i: Integer;
  c: LongWord;
  n: TNode;
  b: TRectF;
  cx, by: Double;
  t: string;
begin
  if Sel.Count = 0 then Exit;
  c := SelColor;
  for i := 0 to Sel.Count - 1 do OutlineNode(SelN(i), c, 1.5);
  P := HandlePts;
  n := One;
  if (Sel.Count > 1) or ((n <> nil) and (n.Kind = kGroup)) then
  begin
    Q := nil;
    for i := 0 to 3 do AddPt(Q, P[i * 2].X * S, P[i * 2].Y * S);
    FillPolys(StrokeClosed(Q, 0.5 * S, 0.5 * S), Solid(c));
  end;
  if (EditId = 'text') or (VertexNode <> nil) or (Mode <> 0) then Exit;
  for i := 0 to 7 do
  begin
    if ((n <> nil) and IsOpenPath(n)) and Odd(i) then Continue;
    URect(P[i].X - 4, P[i].Y - 4, 8, 8, $FFFFFFFF);
    FillPolys(StrokeClosed(RectPoly((P[i].X - 4) * S, (P[i].Y - 4) * S, 8 * S, 8 * S), 0, 1.2 * S), Solid(c));
  end;
  // Más allá de las esquinas se gira.
  if (n <> nil) and (n.Kind <> kGroup) then
    for i := 0 to 3 do
    begin
      cx := P[i * 2].X + (P[i * 2].X - (P[0].X + P[4].X) / 2) / Max(1, Abs(P[i * 2].X - (P[0].X + P[4].X) / 2)) * 9;
      by := P[i * 2].Y + (P[i * 2].Y - (P[0].Y + P[4].Y) / 2) / Max(1, Abs(P[i * 2].Y - (P[0].Y + P[4].Y) / 2)) * 9;
      AddHit(cx - 9, by - 9, 18, 18, 'rot:' + IntToStr(i));
    end;
  for i := 0 to 7 do AddHit(P[i].X - 6, P[i].Y - 6, 12, 12, 'hdl:' + IntToStr(i));
  b := SelBox;
  if n <> nil then t := NumStr(n.W) + ' × ' + NumStr(n.H)
  else t := NumStr(b.R - b.L) + ' × ' + NumStr(b.B - b.T);
  by := Max(Max(P[4].Y, P[6].Y), Max(P[0].Y, P[2].Y));
  DrawPill((P[0].X + P[4].X) / 2, by + 8, t, c);
end;

procedure DrawGuides;
var
  i: Integer;
  g: TGuide;
  x0, y0, x1, y1: Double;
begin
  for i := 0 to NGuides - 1 do
  begin
    g := Guides[i];
    x0 := W2SX(g.X0); y0 := W2SY(g.Y0); x1 := W2SX(g.X1); y1 := W2SY(g.Y1);
    ULine(x0, y0, x1, y1, 1, CGuide);
    if g.Lbl <> '' then DrawPill((x0 + x1) / 2, (y0 + y1) / 2 - 9, g.Lbl, CGuide);
  end;
end;

{ Las medidas rojas entre la selección y la capa bajo el ratón. }
procedure DrawRedlines(A, B: TRectF);
  procedure Seg(X0, Y0, X1, Y1: Double; const T: string);
  begin
    ULine(W2SX(X0), W2SY(Y0), W2SX(X1), W2SY(Y1), 1, CGuide);
    DrawPill((W2SX(X0) + W2SX(X1)) / 2, (W2SY(Y0) + W2SY(Y1)) / 2 - 9, T, CGuide);
  end;
var
  my, mx: Double;
begin
  FillPolys(StrokeClosed(RectPoly(W2SX(B.L) * S, W2SY(B.T) * S, (B.R - B.L) * Zoom * S, (B.B - B.T) * Zoom * S), 0.5 * S, 0.5 * S), Solid(CGuide));
  my := (Max(A.T, B.T) + Min(A.B, B.B)) / 2;
  if (A.B < B.T) or (A.T > B.B) then my := (A.T + A.B) / 2;
  mx := (Max(A.L, B.L) + Min(A.R, B.R)) / 2;
  if (A.R < B.L) or (A.L > B.R) then mx := (A.L + A.R) / 2;
  if A.R <= B.L then Seg(A.R, my, B.L, my, NumStr(B.L - A.R))
  else if B.R <= A.L then Seg(B.R, my, A.L, my, NumStr(A.L - B.R))
  else
  begin
    if A.L > B.L then Seg(B.L, my, A.L, my, NumStr(A.L - B.L));
    if B.R > A.R then Seg(A.R, my, B.R, my, NumStr(B.R - A.R));
  end;
  if A.B <= B.T then Seg(mx, A.B, mx, B.T, NumStr(B.T - A.B))
  else if B.B <= A.T then Seg(mx, B.B, mx, A.T, NumStr(A.T - B.B))
  else
  begin
    if A.T > B.T then Seg(mx, B.T, mx, A.T, NumStr(A.T - B.T));
    if B.B > A.B then Seg(mx, A.B, mx, B.B, NumStr(B.B - A.B));
  end;
end;

{ La flecha del prototipo: de la capa al marco de destino. }
procedure Noodle(X0, Y0, X1, Y1: Double; C: LongWord; LW: Double; Back: Boolean = False);
var
  P: TPoly;
  i: Integer;
  d, ang: Double;
  q: TPt;
  tip: TPoly;
begin
  P := nil;
  d := Max(40, Abs(X1 - X0) / 2);
  // Hacia atrás: sale por la izquierda y llega por la derecha.
  if Back then d := -d;
  for i := 0 to 32 do
  begin
    q := Bez(P2(X0, Y0), P2(X0 + d, Y0), P2(X1 - d, Y1), P2(X1, Y1), i / 32);
    AddPt(P, q.X * S, q.Y * S);
  end;
  FillPolys(StrokeOpen(P, LW * S, True), Solid(C));
  ang := ArcTan2(P[32].Y - P[30].Y, P[32].X - P[30].X);
  tip := nil;
  AddPt(tip, X1 * S, Y1 * S);
  AddPt(tip, (X1 - Cos(ang - 0.5) * 9) * S, (Y1 - Sin(ang - 0.5) * 9) * S);
  AddPt(tip, (X1 - Cos(ang + 0.5) * 9) * S, (Y1 - Sin(ang + 0.5) * 9) * S);
  FillPoly(tip, C);
  UCircle(X0, Y0, 4, C);
end;

var
  ConnFrom: TNode = nil; // arrastrando una conexión nueva
  ConnX, ConnY: Double;

procedure DrawProtoLinks;
var
  L: TFPList;
  i: Integer;
  n, t: TNode;
  a, b: TRectF;
  x0, y0, x1, y1: Double;
  st: TNode;
begin
  L := TFPList.Create;
  try
    Flatten(Page.Root, L, False);
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      if n.Link = 0 then Continue;
      t := FindNode(n.Link);
      if (t = nil) or (PageOfNode(t) <> PageIx) then Continue;
      a := WorldBox(n);
      b := WorldBox(t);
      y0 := W2SY((a.T + a.B) / 2);
      y1 := W2SY(b.T + Min(60, (b.B - b.T) / 2));
      if b.L >= a.R then
      begin
        x0 := W2SX(a.R); x1 := W2SX(b.L);
        if IsSel(n) then Noodle(x0, y0, x1, y1, CProto, 2.4) else Noodle(x0, y0, x1, y1, CProto, 1.4);
      end
      else
      begin
        x0 := W2SX(a.L); x1 := W2SX(b.R);
        if IsSel(n) then Noodle(x0, y0, x1, y1, CProto, 2.4, True) else Noodle(x0, y0, x1, y1, CProto, 1.4, True);
      end;
    end;
  finally
    L.Free;
  end;
  st := FindNode(Page.StartId);
  if (st <> nil) and (PageOfNode(st) = PageIx) then
  begin
    a := WorldBox(st);
    URound(W2SX(a.L), W2SY(a.T) - 44, UTextW(tx_START, 10.5) + 26, 20, 5, CProto);
    Icon('play', W2SX(a.L) + 10, W2SY(a.T) - 34, $FFFFFFFF, 9);
    UText(W2SX(a.L) + 18, W2SY(a.T) - 41.5, tx_START, 10.5, $FFFFFFFF, True);
  end;
  n := One;
  if n <> nil then
  begin
    a := WorldBox(n);
    x0 := W2SX(a.R); y0 := W2SY((a.T + a.B) / 2);
    UCircle(x0, y0, 8, $FFFFFFFF);
    UCircle(x0, y0, 6, CProto);
    Icon('plus', x0, y0, $FFFFFFFF, 9);
    AddHit(x0 - 10, y0 - 10, 20, 20, 'conn');
  end;
  if ConnFrom <> nil then
  begin
    a := WorldBox(ConnFrom);
    Noodle(W2SX(a.R), W2SY((a.T + a.B) / 2), ConnX, ConnY, CProto, 2.4);
  end;
end;

procedure DrawFrameLabels;
var
  i: Integer;
  n: TNode;
  c: LongWord;
  x, y, w: Double;
  t: string;
begin
  for i := 0 to Page.Root.Count - 1 do
  begin
    n := Page.Root.Kid(i);
    if not IsBox(n) or not n.Visible then Continue;
    x := W2SX(n.X);
    y := W2SY(n.Y) - 18;
    if n.Kind in [kComponent, kInstance] then c := CComp
    else if IsSel(n) then c := CAccent
    else c := CMuted;
    w := Max(30, n.W * Zoom);
    if n.Kind = kComponent then
    begin
      Icon('component', x + 6, y + 8, c, 11);
      t := Ellip(n.Name, 11, w - 16);
      UText(x + 14, y + 1.5, t, 11, c);
    end
    else
    begin
      t := Ellip(n.Name, 11, w);
      UText(x, y + 1.5, t, 11, c);
    end;
    AddHit(x, y, Min(w, UTextW(t, 11) + 16), 16, 'flabel:' + IntToStr(n.Id));
  end;
end;

procedure DrawPixelGrid;
var
  w0, w1: TPt;
  v: Integer;
begin
  if not PixGrid or (Zoom < 6) then Exit;
  w0 := S2W(CX0, CY0);
  w1 := S2W(CX1, CY1);
  for v := Floor(w0.X) to Ceil(w1.X) do URect(W2SX(v), CY0, 1 / S, CY1 - CY0, $FF808080, 0.18);
  for v := Floor(w0.Y) to Ceil(w1.Y) do URect(CX0, W2SY(v), CX1 - CX0, 1 / S, $FF808080, 0.18);
end;

{ Dónde está el cursor del texto (unidades de la capa) para el carácter K. }
procedure CaretPos(N: TNode; K: Integer; out X, Y: Double);
var
  L: TStringList;
  i, used, nc: Integer;
begin
  L := TextLines(N);
  try
    used := 0;
    X := 0; Y := 0;
    for i := 0 to L.Count - 1 do
    begin
      nc := UTF8Length(L[i]);
      if (K <= used + nc) or (i = L.Count - 1) then
      begin
        X := LineX(N, L[i]) + DocUnits(N, UTF8Copy(L[i], 1, K - used));
        Y := i * LineHOf(N);
        Exit;
      end;
      used := used + nc;
      // El salto de línea o el espacio donde se partió también cuenta.
      if used < UTF8Length(EditBuf) then Inc(used);
    end;
  finally
    L.Free;
  end;
end;

procedure DrawTextCaret;
var
  M: TMat;
  x0, y0, x1, y1: Double;
  p, q: TPt;
  saved: string;
  n: TNode;
begin
  if (EditId <> 'text') or (EditNode = nil) then Exit;
  n := EditNode;
  if EditOver <> nil then M := MatMul(ScreenMat(EditOver), LocalMat(n))
  else M := ScreenMat(n);
  saved := n.Text;
  n.Text := EditBuf;
  try
    if SelLo <> SelHi then
    begin
      CaretPos(n, SelLo, x0, y0);
      CaretPos(n, SelHi, x1, y1);
      if Abs(y1 - y0) < 0.1 then
        FillPoly(XfPoly(RectPoly(x0, y0, x1 - x0, LineHOf(n)), MatMul(MatS(S, S), M)), CAccent, 0.3)
      else
        FillPoly(XfPoly(RectPoly(0, y0, n.W, y1 - y0 + LineHOf(n)), MatMul(MatS(S, S), M)), CAccent, 0.3);
    end;
    if CaretOn then
    begin
      CaretPos(n, ECaret, x0, y0);
      p := MatAp(M, P2(x0, y0));
      q := MatAp(M, P2(x0, y0 + LineHOf(n)));
      ULine(p.X, p.Y, q.X, q.Y, 1.5, CAccent);
    end;
  finally
    n.Text := saved;
  end;
  OutlineNode(n, CAccent, 1);
end;

procedure DrawPenOverlay;
var
  n: TNode;
  M: TMat;
  i: Integer;
  p, q: TPt;
begin
  n := PenNode;
  if n = nil then n := VertexNode;
  if n = nil then Exit;
  M := ScreenMat(n);
  OutlineNode(n, CAccent, 1.2);
  for i := 0 to High(n.Pts) do
  begin
    p := MatAp(M, P2(n.Pts[i].X, n.Pts[i].Y));
    if n.Pts[i].Curve and (VertexNode <> nil) then
    begin
      q := MatAp(M, P2(n.Pts[i].X + n.Pts[i].OX, n.Pts[i].Y + n.Pts[i].OY));
      ULine(p.X, p.Y, q.X, q.Y, 1, CAccent);
      UCircle(q.X, q.Y, 3, CAccent);
      AddHit(q.X - 6, q.Y - 6, 12, 12, 'vout:' + IntToStr(i));
      q := MatAp(M, P2(n.Pts[i].X + n.Pts[i].IX, n.Pts[i].Y + n.Pts[i].IY));
      ULine(p.X, p.Y, q.X, q.Y, 1, CAccent);
      UCircle(q.X, q.Y, 3, CAccent);
      AddHit(q.X - 6, q.Y - 6, 12, 12, 'vin:' + IntToStr(i));
    end;
    UCircle(p.X, p.Y, 4.5, CAccent);
    UCircle(p.X, p.Y, 3, $FFFFFFFF);
    AddHit(p.X - 7, p.Y - 7, 14, 14, 'vtx:' + IntToStr(i));
  end;
  if (PenNode <> nil) and (Length(n.Pts) > 0) then
  begin
    p := MatAp(M, P2(n.Pts[High(n.Pts)].X, n.Pts[High(n.Pts)].Y));
    ULine(p.X, p.Y, MouseX, MouseY, 1, CAccent, 0.7);
  end;
end;

procedure DrawPins;
var
  i: Integer;
  c: TComment;
  x, y, w: Double;
begin
  for i := 0 to Comments.Count - 1 do
  begin
    c := TComment(Comments[i]);
    if c.Done or (c.Page <> PageIx) then Continue;
    x := W2SX(c.X); y := W2SY(c.Y);
    FillPoly(RRectPoly((x) * S, (y - 30) * S, 30 * S, 30 * S, 15 * S), $FF000000, 0.2);
    FillPoly(RRectPoly(x * S, (y - 32) * S, 30 * S, 30 * S, 15 * S), CAccent);
    URect(x, y - 16, 15, 16, CAccent);
    UTextIn(x, y - 32, 30, 30, Initials(c.Who), 10.5, $FFFFFFFF, True, 1);
    AddHit(x, y - 32, 30, 32, 'pin:' + IntToStr(i));
    if ActiveComment = i then
    begin
      w := 260;
      FillPoly(RRectPoly((x + 38) * S, (y - 30) * S, w * S, 112 * S, 10 * S), $FF000000, 0.25);
      URound(x + 36, y - 34, w, 112, 10, CPanel);
      UFrame(x + 36, y - 34, w, 112, 10, 1, CLine);
      AddHit(x + 36, y - 34, w, 112, 'card');
      UText(x + 48, y - 24, c.Who, 12, CText, True);
      UText(x + 48 + UTextW(c.Who, 12, True) + 8, y - 23, c.When, 10.5, CMuted);
      if EditId = 'comment:' + IntToStr(i) then
        DrawField(x + 46, y + 2, w - 20, 30, 'comment:' + IntToStr(i), '', EditBuf, False)
      else
      begin
        UTextIn(x + 48, y + 2, w - 24, 30, c.Text, 12, CText);
        AddHit(x + 46, y + 2, w - 20, 30, 'f:comment:' + IntToStr(i));
      end;
      TextBtn(x + 46, y + 42, 110, 26, tx_RESOLVE, 'cmtdone:' + IntToStr(i), True);
      TextBtn(x + 162, y + 42, 80, 26, tx_DELETE, 'cmtdel:' + IntToStr(i));
    end;
  end;
end;

var
  MarqOn: Boolean = False;
  MarqX0, MarqY0: Double;

procedure DrawCanvas;
var
  old: TRect;
  i: Integer;
  dm: TMat;
  n: TNode;
begin
  PushClip(RailW + InspW, TopH, WinW - RightW - RailW - InspW, WinH - TopH - StatusH, old);
  URect(RailW + InspW, TopH, WinW - RightW - RailW - InspW, WinH - TopH - StatusH, PageBg(Page));
  PopClip(old);
  PushClip(CX0, CY0, CX1 - CX0, CY1 - CY0, old);
  dm := DevMat;
  for i := 0 to Page.Root.Count - 1 do DrawNodeAt(Page.Root.Kid(i), dm, 1, nil);
  DrawPixelGrid;
  DrawFrameLabels;
  if (HoverNode <> nil) and not IsSel(HoverNode) and (EditId <> 'text') then
    if HoverNode.Kind in [kComponent, kInstance] then OutlineNode(HoverNode, CComp, 1.5)
    else OutlineNode(HoverNode, CAccent, 1.5);
  if Mode = 1 then
  begin
    for i := 0 to Sel.Count - 1 do OutlineNode(SelN(i), CProto, 1.5);
    DrawProtoLinks;
  end
  else
  begin
    DrawSelection;
    if ((Mode = 2) or AltDown) and (Sel.Count > 0) and (HoverNode <> nil) and not IsSel(HoverNode) then
      DrawRedlines(SelBox, WorldBox(HoverNode))
    else if ((Mode = 2) or AltDown) and (One <> nil) and (One.Parent <> nil) and (One.Parent.Parent <> nil) then
    begin
      n := One.Parent;
      while (n.Kind = kGroup) and (n.Parent <> nil) and (n.Parent.Parent <> nil) do n := n.Parent;
      if n.Kind <> kGroup then DrawRedlines(SelBox, WorldBox(n));
    end;
  end;
  DrawGuides;
  DrawTextCaret;
  DrawPenOverlay;
  if MarqOn then
  begin
    URect(Min(MarqX0, MouseX), Min(MarqY0, MouseY), Abs(MouseX - MarqX0), Abs(MouseY - MarqY0), CAccent, 0.1);
    FillPolys(StrokeClosed(RectPoly(Min(MarqX0, MouseX) * S, Min(MarqY0, MouseY) * S, Abs(MouseX - MarqX0) * S, Abs(MouseY - MarqY0) * S), 0.5 * S, 0.5 * S), Solid(CAccent));
  end;
  DrawPins;
  PopClip(old);
end;

// ========================================================== tocar el lienzo
function PointInPoly(const P: TPoly; X, Y: Double): Boolean;
var
  i, j, w: Integer;
begin
  w := 0;
  j := High(P);
  for i := 0 to High(P) do
  begin
    if (P[j].Y <= Y) then
    begin
      if (P[i].Y > Y) and ((P[i].X - P[j].X) * (Y - P[j].Y) - (X - P[j].X) * (P[i].Y - P[j].Y) > 0) then Inc(w);
    end
    else if (P[i].Y <= Y) and ((P[i].X - P[j].X) * (Y - P[j].Y) - (X - P[j].X) * (P[i].Y - P[j].Y) < 0) then Dec(w);
    j := i;
  end;
  Result := w <> 0;
end;

function DistSeg(const A, B: TPt; X, Y: Double): Double;
var
  dx, dy, t: Double;
begin
  dx := B.X - A.X; dy := B.Y - A.Y;
  if dx * dx + dy * dy < 1e-9 then Exit(Sqrt(Sqr(X - A.X) + Sqr(Y - A.Y)));
  t := EnsureRange(((X - A.X) * dx + (Y - A.Y) * dy) / (dx * dx + dy * dy), 0, 1);
  Result := Sqrt(Sqr(X - A.X - t * dx) + Sqr(Y - A.Y - t * dy));
end;

{ ¿El punto del mundo cae en la capa (sin mirar dentro)? }
function NodeHit(N: TNode; const W: TPt): Boolean;
var
  q: TPt;
  P: TPoly;
  i: Integer;
  tol: Double;
begin
  q := MatAp(MatInv(WorldOf(N)), W);
  if IsOpenPath(N) then
  begin
    P := PathPoly(N, 1);
    tol := Max(5 / Zoom, N.StrokeW / 2 + 1 / Zoom);
    for i := 0 to High(P) - 1 do
      if DistSeg(P[i], P[i + 1], q.X, q.Y) <= tol then Exit(True);
    Exit(False);
  end;
  if N.Kind in [kText, kFrame, kComponent, kInstance, kGroup] then
    Exit((q.X >= 0) and (q.Y >= 0) and (q.X <= Max(N.W, 1)) and (q.Y <= Max(N.H, 1)));
  Result := PointInPoly(Outline(N, 1), q.X, q.Y);
end;

{ La capa más profunda bajo el punto (sin entrar en las instancias). }
function DeepHit(N: TNode; const W: TPt; Skip: TFPList): TNode;
var
  i: Integer;
  inside: Boolean;
begin
  Result := nil;
  if not N.Visible or N.Locked then Exit;
  if (Skip <> nil) and (Skip.IndexOf(N) >= 0) then Exit;
  inside := (N.Parent = nil) or NodeHit(N, W);
  if (N.Parent <> nil) and IsBox(N) and N.Clip and not inside then Exit;
  if N.Kind <> kInstance then
    for i := N.Count - 1 downto 0 do
    begin
      Result := DeepHit(N.Kid(i), W, Skip);
      if Result <> nil then Exit;
    end;
  if (N.Parent <> nil) and (N.Kind <> kGroup) and inside then Result := N;
end;

var
  Scope: TNode = nil; // el contenedor en el que se entró con doble clic

function CanPick(N: TNode): Boolean;
var
  i: Integer;
begin
  if N.Parent = nil then Exit(False);
  if N.Parent = Page.Root then Exit(True);
  if (N.Parent.Parent = Page.Root) and IsBox(N.Parent) then Exit(True);
  if N.Parent = Scope then Exit(True);
  for i := 0 to Sel.Count - 1 do
    if (SelN(i).Parent = N.Parent) or (SelN(i) = N.Parent) then Exit(True);
  Result := False;
end;

{ Lo que se elige al pulsar sobre Leaf: subiendo hasta algo que se puede
  elegir de un clic (Deep: la capa misma, con ⌘). }
function Pickable(Leaf: TNode; Deep: Boolean): TNode;
begin
  Result := Leaf;
  if (Result = nil) or Deep then Exit;
  while (Result.Parent <> nil) and not CanPick(Result) do Result := Result.Parent;
  if Result.Parent = nil then Result := nil;
end;

function LeafAt(const W: TPt): TNode;
begin
  Result := DeepHit(Page.Root, W, nil);
end;

{ El marco (o componente) más profundo bajo el punto; Skip: capas que no. }
function FrameAt(const W: TPt; Skip: TFPList): TNode;
var
  n: TNode;
begin
  n := DeepHit(Page.Root, W, Skip);
  while (n <> nil) and not ((n.Kind in [kFrame, kComponent]) and NodeHit(n, W)) do n := n.Parent;
  if (n = nil) or (n.Parent = nil) then Result := Page.Root else Result := n;
end;

function TopFrameAt(const W: TPt): TNode;
var
  i: Integer;
  n: TNode;
begin
  for i := Page.Root.Count - 1 downto 0 do
  begin
    n := Page.Root.Kid(i);
    if n.Visible and IsBox(n) and NodeHit(n, W) then Exit(n);
  end;
  Result := nil;
end;

{ Un punto del mundo en el espacio de lo que va dentro de P. }
function ToSpace(P: TNode; const W: TPt): TPt;
begin
  Result := MatAp(MatInv(ChildMat(P)), W);
end;

{ Lleva la capa a otro padre sin que se mueva en pantalla. }
procedure Reparent(N, NP: TNode; Index: Integer = -1);
var
  cw, cl: TPt;
begin
  if (N = NP) or IsInside(NP, N) then Exit;
  cw := MatAp(WorldOf(N), P2(N.W / 2, N.H / 2));
  Unlink(N);
  AddKid(NP, N, Index);
  cl := ToSpace(NP, cw);
  MoveNode(N, cl.X - N.W / 2 - N.X, cl.Y - N.H / 2 - N.Y);
end;

{ Las capas elegidas sin las que ya van dentro de otra elegida. }
function TopSel: TFPList;
var
  i, j: Integer;
  inner: Boolean;
begin
  Result := TFPList.Create;
  for i := 0 to Sel.Count - 1 do
  begin
    inner := False;
    for j := 0 to Sel.Count - 1 do
      if (i <> j) and IsInside(SelN(i).Parent, SelN(j)) then inner := True;
    if not inner then Result.Add(Sel[i]);
  end;
end;

// ------------------------------------------------------------ arrastrar
type
  TDrag = (dNone, dPan, dMarquee, dMove, dResize, dRotate, dCreate, dPenHandle,
    dConnect, dLayer, dScrub, dPick, dVertex, dScroll);

var
  Drag: TDrag = dNone;
  DragAct: string = '';
  DragX0, DragY0, DragLX, DragLY: Double;
  DragMoved: Boolean = False;
  DragBase: string = '';
  DragNode: TNode = nil;
  DragPanX, DragPanY: Double;
  CreateKind: TKind;
  CreateP0: TPt;

procedure SetTool(T: TTool);
begin
  if EditId <> '' then CommitEdit;
  Tool := T;
  ConnFrom := nil;
end;

procedure FinishPen;
var
  n: TNode;
  b: TRectF;
  PP: TPolys;
  i: Integer;
begin
  n := PenNode;
  PenNode := nil;
  if n = nil then Exit;
  if Length(n.Pts) < 2 then
  begin
    Unlink(n);
    n.Free;
    ClearSel;
    Exit;
  end;
  PP := nil;
  AddPoly(PP, PathPoly(n, 1));
  b := PolysBounds(PP);
  for i := 0 to High(n.Pts) do
  begin
    n.Pts[i].X := n.Pts[i].X - b.L;
    n.Pts[i].Y := n.Pts[i].Y - b.T;
  end;
  n.X := n.X + b.L; n.Y := n.Y + b.T;
  n.W := b.R - b.L; n.H := b.B - b.T;
  SelectOnly(n);
  Tool := tlMove;
end;

{ Rehace el recuadro de un trazado cuyos puntos se han movido. }
procedure NormalizePath(N: TNode);
var
  b: TRectF;
  PP: TPolys;
  i: Integer;
begin
  if (N = nil) or (Length(N.Pts) = 0) or (N.Rot <> 0) then Exit;
  PP := nil;
  AddPoly(PP, PathPoly(N, 1));
  b := PolysBounds(PP);
  for i := 0 to High(N.Pts) do
  begin
    N.Pts[i].X := N.Pts[i].X - b.L;
    N.Pts[i].Y := N.Pts[i].Y - b.T;
  end;
  N.X := N.X + b.L; N.Y := N.Y + b.T;
  N.W := b.R - b.L; N.H := b.B - b.T;
end;

procedure AddGuide(X0, Y0, X1, Y1: Double; const L: string = '');
begin
  if NGuides >= Length(Guides) then SetLength(Guides, NGuides * 2 + 16);
  Guides[NGuides].X0 := X0; Guides[NGuides].Y0 := Y0;
  Guides[NGuides].X1 := X1; Guides[NGuides].Y1 := Y1;
  Guides[NGuides].Lbl := L;
  Inc(NGuides);
end;

{ Las guías inteligentes: mueve B (dx, dy) para que sus bordes o su centro
  coincidan con los de las capas vecinas y con su marco. }
procedure SmartSnap(const B: TRectF; Movers: TFPList; var DX, DY: Double);
var
  cand: TFPList;
  par: TNode;
  i, a, k: Integer;
  bx, by: array[0..2] of Double;
  best, d, tol, sx, sy: Double;
  r: TRectF;
  rs: array of TRectF;
  hitX, hitY: Double;
  fx, fy: Boolean;
begin
  NGuides := 0;
  if not SnapOn or (Movers.Count = 0) then Exit;
  tol := 5 / Zoom;
  par := TNode(Movers[0]).Parent;
  while (par <> nil) and (par.Kind = kGroup) and (par.Parent <> nil) do par := par.Parent;
  cand := TFPList.Create;
  try
    if par <> nil then
      for i := 0 to par.Count - 1 do
        if (Movers.IndexOf(par.Kid(i)) < 0) and par.Kid(i).Visible then cand.Add(par.Kid(i));
    SetLength(rs, cand.Count + 1);
    for i := 0 to cand.Count - 1 do rs[i] := WorldBox(TNode(cand[i]));
    k := cand.Count;
    if (par <> nil) and (par.Parent <> nil) then
    begin
      rs[k] := WorldBox(par);
      Inc(k);
    end;
    bx[0] := B.L + DX; bx[1] := (B.L + B.R) / 2 + DX; bx[2] := B.R + DX;
    by[0] := B.T + DY; by[1] := (B.T + B.B) / 2 + DY; by[2] := B.B + DY;
    best := tol; sx := 0; fx := False; hitX := 0;
    best := tol; sy := 0; fy := False; hitY := 0;
    for i := 0 to k - 1 do
    begin
      r := rs[i];
      for a := 0 to 2 do
      begin
        d := r.L - bx[a]; if (Abs(d) < tol) and (not fx or (Abs(d) < Abs(sx))) then begin sx := d; fx := True; hitX := r.L; end;
        d := (r.L + r.R) / 2 - bx[a]; if (Abs(d) < tol) and (not fx or (Abs(d) < Abs(sx))) then begin sx := d; fx := True; hitX := (r.L + r.R) / 2; end;
        d := r.R - bx[a]; if (Abs(d) < tol) and (not fx or (Abs(d) < Abs(sx))) then begin sx := d; fx := True; hitX := r.R; end;
        d := r.T - by[a]; if (Abs(d) < tol) and (not fy or (Abs(d) < Abs(sy))) then begin sy := d; fy := True; hitY := r.T; end;
        d := (r.T + r.B) / 2 - by[a]; if (Abs(d) < tol) and (not fy or (Abs(d) < Abs(sy))) then begin sy := d; fy := True; hitY := (r.T + r.B) / 2; end;
        d := r.B - by[a]; if (Abs(d) < tol) and (not fy or (Abs(d) < Abs(sy))) then begin sy := d; fy := True; hitY := r.B; end;
      end;
    end;
    if best = 0 then;
    if fx then DX := DX + sx;
    if fy then DY := DY + sy;
    // Dibuja las guías donde coincide.
    if fx then
      for i := 0 to k - 1 do
      begin
        r := rs[i];
        if (Abs(r.L - hitX) < 0.01) or (Abs(r.R - hitX) < 0.01) or (Abs((r.L + r.R) / 2 - hitX) < 0.01) then
          AddGuide(hitX, Min(r.T, B.T + DY), hitX, Max(r.B, B.B + DY));
      end;
    if fy then
      for i := 0 to k - 1 do
      begin
        r := rs[i];
        if (Abs(r.T - hitY) < 0.01) or (Abs(r.B - hitY) < 0.01) or (Abs((r.T + r.B) / 2 - hitY) < 0.01) then
          AddGuide(Min(r.L, B.L + DX), hitY, Max(r.R, B.R + DX), hitY);
      end;
    // Y la distancia hasta el borde del marco.
    if (par <> nil) and (par.Parent <> nil) then
    begin
      r := WorldBox(par);
      AddGuide(r.L, (B.T + B.B) / 2 + DY, B.L + DX, (B.T + B.B) / 2 + DY, NumStr(B.L + DX - r.L));
      AddGuide((B.L + B.R) / 2 + DX, r.T, (B.L + B.R) / 2 + DX, B.T + DY, NumStr(B.T + DY - r.T));
    end;
  finally
    cand.Free;
  end;
end;

procedure BeginDragBase;
begin
  DragBase := Snapshot;
  DragMoved := False;
end;

{ El primer movimiento de verdad: lo que había queda para Deshacer. }
procedure DragStarted;
begin
  if DragMoved then Exit;
  DragMoved := True;
  UndoL.Add(DragBase);
  RedoL.Clear;
  Dirty := True;
end;

procedure ApplyMove(Shift: TShiftState);
var
  dx, dy: Double;
  L: TFPList;
  i, j, k: Integer;
  n, par: TNode;
  b: TRectF;
  lin: TMat;
  q, w: TPt;
begin
  Restore(DragBase);
  dx := (MouseX - DragX0) / Zoom;
  dy := (MouseY - DragY0) / Zoom;
  if ssShift in Shift then
    if Abs(dx) > Abs(dy) then dy := 0 else dx := 0;
  L := TopSel;
  try
    if L.Count = 0 then Exit;
    // Dentro de un marco con diseño automático: cambia el orden.
    n := TNode(L[0]);
    par := n.Parent;
    if (L.Count = 1) and (par <> nil) and (par.Layout <> 0) then
    begin
      w := S2W(MouseX, MouseY);
      q := ToSpace(par, w);
      k := 0;
      for j := 0 to par.Count - 1 do
        if par.Kid(j) <> n then
          if ((par.Layout = 1) and (q.X > par.Kid(j).X + par.Kid(j).W / 2)) or
            ((par.Layout = 2) and (q.Y > par.Kid(j).Y + par.Kid(j).H / 2)) then Inc(k);
      par.Kids.Remove(n);
      par.Kids.Insert(k, n);
      NormalizeAll;
      NGuides := 0;
      Exit;
    end;
    b := SelBox;
    // Píxeles enteros y guías inteligentes.
    dx := Round(b.L + dx) - b.L;
    dy := Round(b.T + dy) - b.T;
    SmartSnap(b, L, dx, dy);
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      lin := MatInv(ChildMat(n.Parent));
      q := P2(lin.A * dx + lin.C * dy, lin.B * dx + lin.D * dy);
      MoveNode(n, q.X, q.Y);
    end;
    NormalizeAll;
  finally
    L.Free;
  end;
end;

procedure DropIntoFrames;
var
  L, skip: TFPList;
  i: Integer;
  n, t: TNode;
  w: TPt;
begin
  L := TopSel;
  skip := TFPList.Create;
  try
    for i := 0 to L.Count - 1 do skip.Add(L[i]);
    w := S2W(MouseX, MouseY);
    t := FrameAt(w, skip);
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      if (n.Parent = nil) or (n.Parent.Kind = kGroup) or (n.Parent.Layout <> 0) then Continue;
      if not ((n.Parent = Page.Root) or (n.Parent.Kind in [kFrame, kComponent])) then Continue;
      if (t <> n.Parent) and not IsInside(t, n) then Reparent(n, t);
    end;
    NormalizeAll;
  finally
    skip.Free;
    L.Free;
  end;
end;

procedure ApplyResize(Shift: TShiftState);
const
  HX: array[0..7] of Double = (0, 0.5, 1, 1, 1, 0.5, 0, 0);
  HY: array[0..7] of Double = (0, 0, 0, 0.5, 1, 1, 1, 0.5);
var
  h, i: Integer;
  n: TNode;
  w, p, A, v, lv, off: TPt;
  ax, ay, nw, nh, s1, rot, ca, sa, cx, cy, sx, sy, ox, oy: Double;
  M: TMat;
  b: TRectF;
  L: TFPList;
begin
  Restore(DragBase);
  h := StrToIntDef(Copy(DragAct, 5, 2), 0);
  w := S2W(MouseX, MouseY);
  n := One;
  if (n <> nil) and (n.Kind <> kGroup) then
  begin
    p := ToSpace(n.Parent, w);
    if ssAlt in Shift then begin ax := 0.5; ay := 0.5; end
    else begin ax := 1 - HX[h]; ay := 1 - HY[h]; end;
    M := LocalMat(n);
    A := MatAp(M, P2(ax * n.W, ay * n.H));
    v := P2(p.X - A.X, p.Y - A.Y);
    rot := -n.Rot * Pi / 180;
    ca := Cos(rot); sa := Sin(rot);
    // de vuelta a los ejes de la capa
    lv := P2(ca * v.X + sa * v.Y, -sa * v.X + ca * v.Y);
    nw := n.W; nh := n.H;
    if HX[h] <> 0.5 then
    begin
      nw := lv.X * Sign(HX[h] - ax + 1e-9);
      if ssAlt in Shift then nw := Abs(lv.X) * 2;
    end;
    if HY[h] <> 0.5 then
    begin
      nh := lv.Y * Sign(HY[h] - ay + 1e-9);
      if ssAlt in Shift then nh := Abs(lv.Y) * 2;
    end;
    if (ssShift in Shift) and (n.W > 0) and (n.H > 0) then
    begin
      if HX[h] = 0.5 then s1 := nh / n.H
      else if HY[h] = 0.5 then s1 := nw / n.W
      else s1 := Max(nw / n.W, nh / n.H);
      nw := n.W * s1; nh := n.H * s1;
    end;
    nw := Max(1, Round(nw));
    nh := Max(1, Round(nh));
    if IsOpenPath(n) then
    begin
      if n.W < 0.5 then nw := n.W;
      if n.H < 0.5 then nh := n.H;
    end;
    off := P2(nw / 2 - ax * nw, nh / 2 - ay * nh);
    cx := A.X + ca * off.X - sa * off.Y;
    cy := A.Y + sa * off.X + ca * off.Y;
    SetSize(n, nw, nh);
    n.X := cx - nw / 2;
    n.Y := cy - nh / 2;
    NormalizeAll;
    Exit;
  end;
  // Varias capas o un grupo: se escalan con su recuadro.
  b := SelBox;
  if (b.R - b.L < 0.01) or (b.B - b.T < 0.01) then Exit;
  ox := b.L + (1 - HX[h]) * (b.R - b.L);
  oy := b.T + (1 - HY[h]) * (b.B - b.T);
  sx := 1; sy := 1;
  if HX[h] <> 0.5 then sx := Max(0.01, (w.X - ox) / ((b.R - b.L) * Sign(HX[h] - (1 - HX[h]))));
  if HY[h] <> 0.5 then sy := Max(0.01, (w.Y - oy) / ((b.B - b.T) * Sign(HY[h] - (1 - HY[h]))));
  if ssShift in Shift then
  begin
    if HX[h] = 0.5 then sx := sy
    else if HY[h] = 0.5 then sy := sx
    else begin sx := Max(sx, sy); sy := sx; end;
  end;
  L := TopSel;
  try
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      p := ToSpace(n.Parent, P2(ox, oy));
      ScaleNode(n, p.X, p.Y, sx, sy);
    end;
  finally
    L.Free;
  end;
  NormalizeAll;
end;

procedure ApplyRotate(Shift: TShiftState);
var
  n: TNode;
  c: TPt;
  a0, a1, r: Double;
begin
  Restore(DragBase);
  n := One;
  if (n = nil) or (n.Kind = kGroup) then Exit;
  c := MatAp(ScreenMat(n), P2(n.W / 2, n.H / 2));
  a0 := ArcTan2(DragY0 - c.Y, DragX0 - c.X);
  a1 := ArcTan2(MouseY - c.Y, MouseX - c.X);
  r := n.Rot - (a1 - a0) * 180 / Pi;
  if ssShift in Shift then r := Round(r / 15) * 15;
  SetNum(n, 'rot', Round(r * 10) / 10);
end;

procedure ApplyCreate(Shift: TShiftState);
var
  n: TNode;
  p0, p1: TPt;
  x0, y0, w, h: Double;
  ang, len: Double;
begin
  n := DragNode;
  if n = nil then Exit;
  p0 := CreateP0;
  p1 := ToSpace(n.Parent, S2W(MouseX, MouseY));
  p1 := P2(Round(p1.X), Round(p1.Y));
  if n.Kind in [kLine, kArrow] then
  begin
    if ssShift in Shift then
    begin
      ang := Round(ArcTan2(p1.Y - p0.Y, p1.X - p0.X) / (Pi / 4)) * (Pi / 4);
      len := Sqrt(Sqr(p1.X - p0.X) + Sqr(p1.Y - p0.Y));
      p1 := P2(p0.X + Cos(ang) * len, p0.Y + Sin(ang) * len);
    end;
    n.X := Min(p0.X, p1.X); n.Y := Min(p0.Y, p1.Y);
    n.W := Abs(p1.X - p0.X); n.H := Abs(p1.Y - p0.Y);
    SetLength(n.Pts, 2);
    FillChar(n.Pts[0], SizeOf(TVPt) * 2, 0);
    n.Pts[0].X := p0.X - n.X; n.Pts[0].Y := p0.Y - n.Y;
    n.Pts[1].X := p1.X - n.X; n.Pts[1].Y := p1.Y - n.Y;
    Exit;
  end;
  w := p1.X - p0.X; h := p1.Y - p0.Y;
  if ssShift in Shift then
  begin
    len := Max(Abs(w), Abs(h));
    w := len * Sign(w + 1e-9); h := len * Sign(h + 1e-9);
  end;
  if ssAlt in Shift then
  begin
    x0 := p0.X - Abs(w); y0 := p0.Y - Abs(h);
    w := Abs(w) * 2; h := Abs(h) * 2;
  end
  else
  begin
    x0 := Min(p0.X, p0.X + w); y0 := Min(p0.Y, p0.Y + h);
    w := Abs(w); h := Abs(h);
  end;
  n.X := x0; n.Y := y0;
  SetSize(n, w, h);
  if n.Kind = kText then n.AutoW := False;
end;

procedure StartTextEdit(N: TNode; Inst: TNode = nil; SelectAll: Boolean = True);
begin
  if EditId <> '' then CommitEdit;
  Snap;
  EditNode := N;
  EditOver := Inst;
  if Inst <> nil then BeginEdit('text', OverText(N, Inst.Over))
  else BeginEdit('text', N.Text);
  if not SelectAll then EAnchor := ECaret;
end;

{ La capa de texto del componente bajo el punto, dentro de una instancia. }
function InstanceText(Inst: TNode; const W: TPt): TNode;
var
  main: TNode;
  L: TFPList;
  i: Integer;
  n: TNode;
  q: TPt;
  M: TMat;
begin
  Result := nil;
  main := FindNode(Inst.CompId);
  if main = nil then Exit;
  L := TFPList.Create;
  try
    Flatten(main, L, False);
    for i := L.Count - 1 downto 0 do
    begin
      n := TNode(L[i]);
      if n.Kind <> kText then Continue;
      // La capa del componente, puesta donde está la instancia.
      M := MatMul(WorldOf(Inst), MatMul(MatInv(WorldOf(main)), WorldOf(n)));
      q := MatAp(MatInv(M), W);
      if (q.X >= 0) and (q.Y >= 0) and (q.X <= n.W) and (q.Y <= n.H) then Exit(n);
    end;
  finally
    L.Free;
  end;
end;

function NewDefault(K: TKind; P: TNode; const At: TPt): TNode;
begin
  Result := NewNode(K, P, At.X, At.Y, 0, 0);
  case K of
    kText:
      begin
        Result.Text := '';
        Result.Size := 24;
        Result.Font := DocFont;
        if (P = Page.Root) and Dark then Result.Fill.C1 := $FFFFFFFF;
      end;
    kLine, kArrow:
      begin
        Result.Stroke.Vis := True;
        Result.StrokeW := 2;
        if P = Page.Root then Result.Stroke.C1 := CMuted;
      end;
    kFrame: Result.Clip := True;
  end;
end;

procedure CanvasDown(Button: TMouseButton; Shift: TShiftState; Dbl: Boolean);
var
  w, lp: TPt;
  leaf, n, par, t: TNode;
  i: Integer;
  c: TComment;
  k: TKind;
begin
  w := S2W(MouseX, MouseY);
  if (Button = mbMiddle) or SpaceDown or (Tool = tlHand) then
  begin
    Drag := dPan;
    DragPanX := PanX; DragPanY := PanY;
    Exit;
  end;
  if EditId <> '' then
  begin
    // Pulsar dentro del texto que se escribe: el cursor va ahí.
    if (EditId = 'text') and (EditNode <> nil) and (EditOver = nil) and NodeHit(EditNode, w) then Exit;
    CommitEdit;
  end;
  ActiveComment := -1;
  case Tool of
    tlFrame, tlRect, tlEllipse, tlLine, tlArrow, tlPolygon, tlStar, tlText:
      begin
        Snap;
        case Tool of
          tlFrame: k := kFrame;
          tlRect: k := kRect;
          tlEllipse: k := kEllipse;
          tlLine: k := kLine;
          tlArrow: k := kArrow;
          tlPolygon: k := kPolygon;
          tlStar: k := kStar;
        else
          k := kText;
        end;
        par := FrameAt(w, nil);
        if (par.Kind = kInstance) or (par.Layout <> 0) then par := Page.Root;
        lp := ToSpace(par, w);
        lp := P2(Round(lp.X), Round(lp.Y));
        DragNode := NewDefault(k, par, lp);
        CreateP0 := lp;
        CreateKind := k;
        SelectOnly(DragNode);
        Drag := dCreate;
        DragMoved := False;
        Exit;
      end;
    tlPen:
      begin
        if PenNode = nil then
        begin
          Snap;
          par := FrameAt(w, nil);
          if par.Kind = kInstance then par := Page.Root;
          lp := ToSpace(par, w);
          PenNode := NewNode(kPath, par, lp.X, lp.Y, 0, 0);
          PenNode.Fill.Vis := False;
          PenNode.Stroke.Vis := True;
          PenNode.StrokeW := 2;
          if par = Page.Root then PenNode.Stroke.C1 := CText;
          SetLength(PenNode.Pts, 1);
          FillChar(PenNode.Pts[0], SizeOf(TVPt), 0);
          SelectOnly(PenNode);
        end
        else
        begin
          lp := ToSpace(PenNode.Parent, w);
          lp := P2(lp.X - PenNode.X, lp.Y - PenNode.Y);
          if (Length(PenNode.Pts) >= 2) and
            (Sqrt(Sqr(lp.X - PenNode.Pts[0].X) + Sqr(lp.Y - PenNode.Pts[0].Y)) * Zoom < 9) then
          begin
            PenNode.Closed := True;
            PenNode.Fill.Vis := True;
            PenNode.Fill.C1 := $FFD9D9D9;
            FinishPen;
            Exit;
          end;
          SetLength(PenNode.Pts, Length(PenNode.Pts) + 1);
          FillChar(PenNode.Pts[High(PenNode.Pts)], SizeOf(TVPt), 0);
          PenNode.Pts[High(PenNode.Pts)].X := lp.X;
          PenNode.Pts[High(PenNode.Pts)].Y := lp.Y;
        end;
        Drag := dPenHandle;
        Exit;
      end;
    tlImage:
      begin
        RunAct('import');
        SetTool(tlMove);
        Exit;
      end;
    tlComment:
      begin
        c := TComment.Create;
        c.Page := PageIx;
        c.X := w.X; c.Y := w.Y;
        c.Who := tx_YOU;
        c.When := FormatDateTime('d/m hh:nn', Now);
        Comments.Add(c);
        ActiveComment := Comments.Count - 1;
        BeginEdit('comment:' + IntToStr(ActiveComment), '');
        RightTab := 2;
        SetTool(tlMove);
        Dirty := True;
        Exit;
      end;
  end;
  // La flecha: elegir, mover, entrar con doble clic.
  leaf := LeafAt(w);
  if Dbl then
  begin
    if (One <> nil) and (One.Kind = kInstance) and (leaf = One) then
    begin
      t := InstanceText(One, w);
      if t <> nil then
      begin
        StartTextEdit(t, One);
        Exit;
      end;
    end;
    if leaf <> nil then
    begin
      n := leaf;
      if (One <> nil) and IsInside(leaf, One) and (leaf <> One) then
      begin
        while n.Parent <> One do n := n.Parent;
        Scope := One;
      end
      else n := Pickable(leaf, False);
      if n <> nil then
      begin
        SelectOnly(n);
        if n.Kind = kText then StartTextEdit(n)
        else if (n.Kind in [kPath, kLine, kArrow]) and (One = n) and (n = leaf) then VertexNode := n;
      end;
    end;
    Exit;
  end;
  n := Pickable(leaf, (ssMeta in Shift) or (ssCtrl in Shift));
  if (n <> nil) and (n.Parent = Page.Root) and IsBox(n) and (n.Count > 0) and (n.Kind <> kInstance) and
    (leaf = n) and not IsSel(n) then n := nil;
  if n = nil then
  begin
    if not (ssShift in Shift) then ClearSel;
    Scope := nil;
    Drag := dMarquee;
    MarqOn := True;
    MarqX0 := MouseX;
    MarqY0 := MouseY;
    Exit;
  end;
  if ssShift in Shift then
  begin
    ToggleSel(n);
    Exit;
  end;
  if not IsSel(n) then SelectOnly(n);
  if (VertexNode <> nil) and (VertexNode <> n) then VertexNode := nil;
  if ssAlt in Shift then RunAct('dupinplace');
  for i := 0 to Sel.Count - 1 do
    if SelN(i).Locked then Exit;
  BeginDragBase;
  Drag := dMove;
end;

procedure MarqueeSelect;
var
  x0, y0, x1, y1: TPt;
  box, b: TRectF;
  cont: TNode;
  i: Integer;
  n: TNode;
begin
  x0 := S2W(Min(MarqX0, MouseX), Min(MarqY0, MouseY));
  y0 := S2W(Max(MarqX0, MouseX), Max(MarqY0, MouseY));
  x1 := x0; y1 := y0;
  box := RF(x1.X, x1.Y, y1.X, y1.Y);
  cont := TopFrameAt(S2W(MarqX0, MarqY0));
  if (cont = nil) or (cont.Kind = kInstance) then cont := Page.Root;
  for i := 0 to cont.Count - 1 do
  begin
    n := cont.Kid(i);
    if not n.Visible or n.Locked then Continue;
    b := WorldBox(n);
    if (b.L < box.R) and (b.R > box.L) and (b.T < box.B) and (b.B > box.T) then
    begin
      // Un marco de arriba entra solo si queda dentro entero.
      if (cont = Page.Root) and IsBox(n) and not ((b.L >= box.L) and (b.R <= box.R) and (b.T >= box.T) and (b.B <= box.B)) then
        Continue;
      if not IsSel(n) then Sel.Add(n);
    end;
  end;
end;

procedure LayerDropAt(Y: Double; out Target: TNode; out Inside, Above: Boolean);
var
  i: Integer;
  r: TLayerRow;
  ry: Double;
begin
  Target := nil;
  Inside := False;
  Above := False;
  LayerDropY := -1;
  for i := 0 to NLayerRows - 1 do
  begin
    r := LayerRows[i];
    ry := r.Y - LayerScroll;
    if (Y >= ry) and (Y < ry + 28) then
    begin
      Target := FindNode(r.Id);
      if Target = nil then Exit;
      if (Target.Kind in [kFrame, kGroup, kComponent]) and (Y > ry + 8) and (Y < ry + 20) then
      begin
        Inside := True;
        LayerDropY := ry + 28;
      end
      else if Y < ry + 14 then
      begin
        Above := True;
        LayerDropY := ry;
      end
      else LayerDropY := ry + 28;
      Exit;
    end;
  end;
end;

procedure FinishLayerDrag;
var
  t, n: TNode;
  inside, above: Boolean;
  k: Integer;
begin
  n := FindNode(LayerDragId);
  LayerDropAt(MouseY, t, inside, above);
  LayerDragId := 0;
  LayerDropY := -1;
  if (n = nil) or (t = nil) or (t = n) or IsInside(t, n) then Exit;
  Snap;
  if inside then Reparent(n, t)
  else
  begin
    Unlink(n);
    k := IndexIn(t);
    if above then Inc(k);
    Reparent(n, t.Parent, k);
  end;
  NormalizeAll;
  SelectOnly(n);
end;

{ El color elegido arrastrando en el selector. }
procedure PickDrag;
var
  sx, sy: Double;
begin
  sx := PickX + 12;
  if DragAct = 'pk:sv' then
  begin
    sy := PickY + 34;
    PickS := EnsureRange((MouseX - sx) / 216, 0, 1);
    PickV := 1 - EnsureRange((MouseY - sy) / 152, 0, 1);
  end
  else if DragAct = 'pk:hue' then PickH := EnsureRange((MouseX - sx) / 216 * 360, 0, 359.9)
  else if DragAct = 'pk:alpha' then PickA := Round(EnsureRange((MouseX - sx) / 216, 0, 1) * 255);
  SetTargetColor(PickTarget, PickColor);
end;

procedure VertexDrag;
var
  n: TNode;
  i: Integer;
  q: TPt;
begin
  n := VertexNode;
  if n = nil then Exit;
  i := StrToIntDef(Copy(DragAct, Pos(':', DragAct) + 1, 9), -1);
  if (i < 0) or (i > High(n.Pts)) then Exit;
  q := MatAp(MatInv(ScreenMat(n)), P2(MouseX, MouseY));
  if Copy(DragAct, 1, 4) = 'vtx:' then
  begin
    n.Pts[i].X := q.X;
    n.Pts[i].Y := q.Y;
  end
  else if Copy(DragAct, 1, 5) = 'vout:' then
  begin
    n.Pts[i].OX := q.X - n.Pts[i].X; n.Pts[i].OY := q.Y - n.Pts[i].Y;
    n.Pts[i].IX := -n.Pts[i].OX; n.Pts[i].IY := -n.Pts[i].OY;
  end
  else
  begin
    n.Pts[i].IX := q.X - n.Pts[i].X; n.Pts[i].IY := q.Y - n.Pts[i].Y;
    n.Pts[i].OX := -n.Pts[i].IX; n.Pts[i].OY := -n.Pts[i].IY;
  end;
end;

procedure ScrubDrag(Shift: TShiftState);
var
  id: string;
  d: Double;
  i: Integer;
  n: TNode;
begin
  id := Copy(DragAct, 3, MaxInt);
  d := Round(MouseX - DragX0);
  if ssShift in Shift then d := d * 10;
  if (id = 'op') or (id = 'filla') or (id = 'strokea') or (id = 'sha') then d := d / 2;
  Restore(DragBase);
  for i := 0 to Sel.Count - 1 do
  begin
    n := SelN(i);
    SetNum(n, id, GetNum(n, id) + d);
  end;
  NormalizeAll;
end;

procedure MouseDownAt(X, Y: Double; Button: TMouseButton; Shift: TShiftState; Dbl: Boolean);
var
  act: string;
  hx, hy, hw, hh: Double;
  i: Integer;
begin
  MouseX := X; MouseY := Y;
  DragX0 := X; DragY0 := Y; DragLX := X; DragLY := Y;
  DragMoved := False;
  Drag := dNone;
  if Playing then
  begin
    RunAct('playclick');
    Exit;
  end;
  act := HitAt(X, Y);
  if PickOpen and (Copy(act, 1, 3) <> 'pk:') and (act <> 'f:pickhex') then
  begin
    PickOpen := False;
    if EditId = 'pickhex' then EditId := '';
  end;
  if Button = mbRight then
  begin
    if (X >= CX0) and (X < CX1) and (Y >= CY0) and (Y < CY1) and (act = '') then
    begin
      if Sel.Count = 0 then SelectOnly(Pickable(LeafAt(S2W(X, Y)), False));
      RunAct('ctxmenu');
    end
    else if Copy(act, 1, 6) = 'layer:' then
    begin
      if not IsSel(FindNode(StrToIntDef(Copy(act, 7, 12), 0))) then RunAct(act);
      RunAct('ctxmenu');
    end;
    Exit;
  end;
  if (act <> '') and (Button = mbLeft) then
  begin
    // Pulsar fuera del campo que se escribe lo confirma.
    if (EditId <> '') and (act <> 'f:' + EditId) then CommitEdit;
    if (Copy(act, 1, 4) = 'hdl:') then
    begin
      BeginDragBase;
      Drag := dResize;
      DragAct := act;
      Exit;
    end;
    if Copy(act, 1, 4) = 'rot:' then
    begin
      BeginDragBase;
      Drag := dRotate;
      DragAct := act;
      Exit;
    end;
    if act = 'conn' then
    begin
      ConnFrom := One;
      ConnX := X; ConnY := Y;
      Drag := dConnect;
      Exit;
    end;
    if (act = 'pk:sv') or (act = 'pk:hue') or (act = 'pk:alpha') then
    begin
      Snap;
      Drag := dPick;
      DragAct := act;
      PickDrag;
      Exit;
    end;
    if (Copy(act, 1, 4) = 'vtx:') or (Copy(act, 1, 4) = 'vin:') or (Copy(act, 1, 5) = 'vout:') then
    begin
      if Dbl and (VertexNode <> nil) and (Copy(act, 1, 4) = 'vtx:') then
      begin
        i := StrToIntDef(Copy(act, 5, 9), 0);
        Snap;
        with VertexNode.Pts[i] do
        begin
          Curve := not Curve;
          if Curve then begin OX := 30; OY := 0; IX := -30; IY := 0; end;
        end;
        Exit;
      end;
      Snap;
      Drag := dVertex;
      DragAct := act;
      Exit;
    end;
    if Copy(act, 1, 2) = 's:' then
    begin
      if Sel.Count = 0 then Exit;
      BeginDragBase;
      Drag := dScrub;
      DragAct := act;
      Exit;
    end;
    if Copy(act, 1, 6) = 'layer:' then
    begin
      if Dbl then
      begin
        RunAct('rename:' + Copy(act, 7, 12));
        Exit;
      end;
      if ssShift in Shift then RunAct('layershift:' + Copy(act, 7, 12))
      else RunAct(act);
      LayerDragId := StrToIntDef(Copy(act, 7, 12), 0);
      Drag := dLayer;
      Exit;
    end;
    if (Copy(act, 1, 7) = 'flabel:') and Dbl then
    begin
      RunAct('rename:' + Copy(act, 8, 12));
      Exit;
    end;
    if Copy(act, 1, 7) = 'flabel:' then
    begin
      RunAct(act);
      if One <> nil then
      begin
        BeginDragBase;
        Drag := dMove;
      end;
      Exit;
    end;
    if (Copy(act, 1, 5) = 'page:') and Dbl then
    begin
      RunAct('pagerename:' + Copy(act, 6, 9));
      Exit;
    end;
    if (act = 'insp') or (act = 'right') then
    begin
      if EditId <> '' then CommitEdit;
      Exit;
    end;
    if (Copy(act, 1, 5) = 'card') or (act = 'pk:none') then Exit;
    if HitRect(act, hx, hy, hw, hh) then;
    RunAct(act);
    Exit;
  end;
  if (X >= CX0) and (X < CX1) and (Y >= CY0) and (Y < CY1) then CanvasDown(Button, Shift, Dbl);
end;

procedure UpdateHover(Shift: TShiftState);
var
  act: string;
  leaf: TNode;
begin
  act := HitAt(MouseX, MouseY);
  HoverAct := act;
  HoverNode := nil;
  if Copy(act, 1, 6) = 'layer:' then HoverNode := FindNode(StrToIntDef(Copy(act, 7, 12), 0))
  else if Copy(act, 1, 7) = 'flabel:' then HoverNode := FindNode(StrToIntDef(Copy(act, 8, 12), 0))
  else if (act = '') and (MouseX >= CX0) and (MouseX < CX1) and (MouseY >= CY0) and (MouseY < CY1) and
    (Tool = tlMove) and not SpaceDown then
  begin
    leaf := LeafAt(S2W(MouseX, MouseY));
    HoverNode := Pickable(leaf, (ssMeta in Shift) or (ssCtrl in Shift));
    if (HoverNode <> nil) and (HoverNode.Parent = Page.Root) and IsBox(HoverNode) and (HoverNode.Count > 0) and
      (leaf = HoverNode) and (HoverNode.Kind <> kInstance) then HoverNode := nil;
  end;
end;

procedure MouseMoveAt(X, Y: Double; Shift: TShiftState);
var
  t: TNode;
  inside, above: Boolean;
  lp: TPt;
begin
  MouseX := X; MouseY := Y;
  AltDown := ssAlt in Shift;
  case Drag of
    dNone: UpdateHover(Shift);
    dPan:
      begin
        PanX := DragPanX + (X - DragX0);
        PanY := DragPanY + (Y - DragY0);
      end;
    dMarquee: ;
    dMove:
      if DragMoved or (Abs(X - DragX0) + Abs(Y - DragY0) > 3) then
      begin
        DragStarted;
        ApplyMove(Shift);
      end;
    dResize: begin DragStarted; ApplyResize(Shift); end;
    dRotate: begin DragStarted; ApplyRotate(Shift); end;
    dCreate:
      begin
        DragMoved := DragMoved or (Abs(X - DragX0) + Abs(Y - DragY0) > 3);
        if DragMoved then ApplyCreate(Shift);
      end;
    dPenHandle:
      if (PenNode <> nil) and (Abs(X - DragX0) + Abs(Y - DragY0) > 3) then
      begin
        lp := P2((X - DragX0) / Zoom, (Y - DragY0) / Zoom);
        with PenNode.Pts[High(PenNode.Pts)] do
        begin
          Curve := True;
          OX := lp.X; OY := lp.Y;
          IX := -lp.X; IY := -lp.Y;
        end;
      end;
    dConnect:
      begin
        ConnX := X; ConnY := Y;
      end;
    dLayer:
      if Abs(Y - DragY0) > 4 then LayerDropAt(Y, t, inside, above);
    dScrub:
      begin
        DragStarted;
        ScrubDrag(Shift);
      end;
    dPick: PickDrag;
    dVertex: VertexDrag;
  end;
  DragLX := X; DragLY := Y;
end;

procedure MouseUpAt(X, Y: Double; Shift: TShiftState);
var
  d: TDrag;
  t: TNode;
  n: TNode;
begin
  MouseX := X; MouseY := Y;
  d := Drag;
  Drag := dNone;
  NGuides := 0;
  case d of
    dMarquee:
      begin
        if (Abs(X - MarqX0) > 2) or (Abs(Y - MarqY0) > 2) then MarqueeSelect;
        MarqOn := False;
      end;
    dMove:
      if DragMoved then DropIntoFrames;
    dCreate:
      begin
        n := DragNode;
        DragNode := nil;
        if n = nil then Exit;
        if not DragMoved then
        begin
          case n.Kind of
            kText: ;
            kLine, kArrow:
              begin
                n.W := 100; n.H := 0;
                SetLength(n.Pts, 2);
                FillChar(n.Pts[0], SizeOf(TVPt) * 2, 0);
                n.Pts[1].X := 100;
              end;
          else
            SetSize(n, 100, 100);
          end;
        end;
        if n.Kind = kText then
        begin
          n.AutoW := not DragMoved;
          SetTool(tlMove);
          StartTextEdit(n, nil, False);
          UndoL.Delete(UndoL.Count - 1);
        end
        else
        begin
          if n.Kind = kFrame then
            // Lo que ya estaba debajo entra en el marco nuevo.
            RunAct('adopt:' + IntToStr(n.Id));
          SetTool(tlMove);
        end;
        NormalizeAll;
      end;
    dConnect:
      begin
        n := ConnFrom;
        ConnFrom := nil;
        if n = nil then Exit;
        t := TopFrameAt(S2W(X, Y));
        Snap;
        if (t <> nil) and (t <> TopFrame(n)) then
        begin
          n.Link := t.Id;
          if n.Anim = 0 then n.Anim := 1;
          if Page.StartId = 0 then
            if TopFrame(n) <> nil then Page.StartId := TopFrame(n).Id;
          Say(Format(tx_LINKED, [t.Name]));
        end
        else n.Link := 0;
      end;
    dLayer:
      if (LayerDragId <> 0) and (Abs(Y - DragY0) > 4) then FinishLayerDrag
      else LayerDragId := 0;
    dVertex:
      begin
        NormalizePath(VertexNode);
        NormalizeAll;
      end;
  end;
  UpdateHover(Shift);
end;

procedure ZoomAt(F, X, Y: Double);
var
  w: TPt;
begin
  w := S2W(X, Y);
  Zoom := EnsureRange(Zoom * F, 0.02, 64);
  PanX := X - CX0 - w.X * Zoom;
  PanY := Y - CY0 - w.Y * Zoom;
end;

procedure ZoomToBox(const B: TRectF; MaxZ: Double = 1);
var
  w, h: Double;
begin
  w := Max(B.R - B.L, 1);
  h := Max(B.B - B.T, 1);
  Zoom := EnsureRange(Min((CX1 - CX0 - 80) / w, (CY1 - CY0 - 80) / h), 0.02, MaxZ);
  PanX := (CX1 - CX0) / 2 - (B.L + w / 2) * Zoom;
  PanY := (CY1 - CY0) / 2 - (B.T + h / 2) * Zoom;
end;

function PageBox: TRectF;
var
  i: Integer;
begin
  Result := RF(0, 0, 400, 300);
  for i := 0 to Page.Root.Count - 1 do
    if i = 0 then Result := WorldBox(Page.Root.Kid(i))
    else Result := Union(Result, WorldBox(Page.Root.Kid(i)));
end;

procedure WheelAt(X, Y: Double; Delta: Integer; Shift: TShiftState);
var
  act: string;
begin
  MouseX := X; MouseY := Y;
  if Playing then Exit;
  act := HitAt(X, Y);
  if (X >= RailW) and (X < RailW + InspW) and (Y > TopH) then
  begin
    InspScroll := EnsureRange(InspScroll - Delta / 3, 0, Max(0, InspH - (WinH - TopH - StatusH)));
    Exit;
  end;
  if (X >= WinW - RightW) and (Y > TopH) then
  begin
    if RightTab = 1 then AssetScroll := Max(0, AssetScroll - Delta / 3)
    else LayerScroll := EnsureRange(LayerScroll - Delta / 3, 0, Max(0, LayerH - (WinH - TopH - StatusH - 60)));
    Exit;
  end;
  if (ssMeta in Shift) or (ssCtrl in Shift) then ZoomAt(Power(1.0015, Delta), X, Y)
  else if ssShift in Shift then PanX := PanX + Delta / 2
  else PanY := PanY + Delta / 2;
  if act = '' then;
end;

// ============================================================ los comandos
{ Una copia de la capa (y de lo de dentro) con números nuevos. }
function CloneNode(N: TNode; Map: TStringList = nil): TNode;
var
  F: TStringList;
  kind: string;
  i: Integer;
begin
  F := SplitFields(NodeToLine(N, 0), kind);
  try
    Result := FieldsNode(F);
  finally
    F.Free;
  end;
  Result.Id := NextId;
  Inc(NextId);
  if Map <> nil then Map.Values[IntToStr(N.Id)] := IntToStr(Result.Id);
  for i := 0 to N.Count - 1 do AddKid(Result, CloneNode(N.Kid(i), Map));
end;

function SortedByZ(L: TFPList): TFPList;
var
  i, j: Integer;
  t: Pointer;
begin
  Result := TFPList.Create;
  for i := 0 to L.Count - 1 do Result.Add(L[i]);
  for i := 0 to Result.Count - 1 do
    for j := i + 1 to Result.Count - 1 do
      if IndexIn(TNode(Result[j])) < IndexIn(TNode(Result[i])) then
      begin
        t := Result[i]; Result[i] := Result[j]; Result[j] := t;
      end;
end;

{ Mete la selección en un contenedor nuevo de tipo K (grupo, marco o componente). }
function WrapSel(K: TKind): TNode;
var
  L, Z: TFPList;
  par, g: TNode;
  i, idx: Integer;
  b: TRectF;
  p0: TPt;
begin
  Result := nil;
  L := TopSel;
  try
    if L.Count = 0 then Exit;
    par := TNode(L[0]).Parent;
    Z := SortedByZ(L);
    try
      idx := 0;
      for i := 0 to Z.Count - 1 do
        if TNode(Z[i]).Parent = par then idx := Max(idx, IndexIn(TNode(Z[i])));
      b := SelBox;
      if K = kGroup then g := NewNode(kGroup, nil, 0, 0, 0, 0)
      else
      begin
        p0 := ToSpace(par, P2(b.L, b.T));
        g := NewNode(K, nil, Round(p0.X), Round(p0.Y), Round(b.R - b.L), Round(b.B - b.T));
        g.Fill.Vis := K = kFrame;
        g.Clip := False;
      end;
      AddKid(par, g, idx + 1);
      for i := 0 to Z.Count - 1 do Reparent(TNode(Z[i]), g);
    finally
      Z.Free;
    end;
  finally
    L.Free;
  end;
  NormalizeAll;
  SelectOnly(g);
  Result := g;
end;

procedure Ungroup;
var
  L: TFPList;
  i, j, idx: Integer;
  g, k: TNode;
begin
  L := TopSel;
  try
    Sel.Clear;
    for i := 0 to L.Count - 1 do
    begin
      g := TNode(L[i]);
      if not (g.Kind in [kGroup, kFrame]) or (g.Parent = nil) then
      begin
        Sel.Add(g);
        Continue;
      end;
      idx := IndexIn(g);
      for j := 0 to g.Count - 1 do
      begin
        k := g.Kid(0);
        Reparent(k, g.Parent, idx + j);
        Sel.Add(k);
      end;
      Unlink(g);
      g.Free;
    end;
  finally
    L.Free;
  end;
  NormalizeAll;
end;

procedure DeleteSel;
var
  L: TFPList;
  i: Integer;
  n: TNode;
begin
  L := TopSel;
  try
    if L.Count = 0 then Exit;
    Snap;
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      if n.Parent = nil then Continue;
      Unlink(n);
      n.Free;
    end;
  finally
    L.Free;
  end;
  Sel.Clear;
  HoverNode := nil;
  Scope := nil;
  VertexNode := nil;
  NormalizeAll;
end;

procedure Duplicate(Offset: Double);
var
  L: TFPList;
  i: Integer;
  n, c: TNode;
begin
  L := TopSel;
  try
    if L.Count = 0 then Exit;
    Sel.Clear;
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      c := CloneNode(n);
      AddKid(n.Parent, c, IndexIn(n) + 1);
      if n.Parent.Layout = 0 then MoveNode(c, Offset, Offset);
      Sel.Add(c);
    end;
  finally
    L.Free;
  end;
  NormalizeAll;
end;

procedure Align(K: Integer);
var
  b, r, ref: TRectF;
  i: Integer;
  n: TNode;
  dx, dy: Double;
  lin: TMat;
begin
  if Sel.Count = 0 then Exit;
  Snap;
  if Sel.Count = 1 then
  begin
    n := SelN(0);
    if (n.Parent = nil) or (n.Parent.Parent = nil) then Exit;
    ref := WorldBox(n.Parent);
    if n.Parent.Kind = kGroup then ref := WorldBox(n.Parent);
  end
  else ref := SelBox;
  for i := 0 to Sel.Count - 1 do
  begin
    n := SelN(i);
    r := WorldBox(n);
    dx := 0; dy := 0;
    case K of
      0: dx := ref.L - r.L;
      1: dx := (ref.L + ref.R) / 2 - (r.L + r.R) / 2;
      2: dx := ref.R - r.R;
      3: dy := ref.T - r.T;
      4: dy := (ref.T + ref.B) / 2 - (r.T + r.B) / 2;
      5: dy := ref.B - r.B;
    end;
    lin := MatInv(ChildMat(n.Parent));
    MoveNode(n, Round(lin.A * dx + lin.C * dy), Round(lin.B * dx + lin.D * dy));
  end;
  b := SelBox;
  if b.L = 0 then;
  NormalizeAll;
end;

procedure Distribute(Vert: Boolean);
var
  Z: TFPList;
  i, j: Integer;
  t: Pointer;
  b: TRectF;
  total, gap, pos: Double;
begin
  if Sel.Count < 3 then Exit;
  Snap;
  Z := TFPList.Create;
  try
    for i := 0 to Sel.Count - 1 do Z.Add(Sel[i]);
    for i := 0 to Z.Count - 1 do
      for j := i + 1 to Z.Count - 1 do
        if (Vert and (WorldBox(TNode(Z[j])).T < WorldBox(TNode(Z[i])).T)) or
          (not Vert and (WorldBox(TNode(Z[j])).L < WorldBox(TNode(Z[i])).L)) then
        begin
          t := Z[i]; Z[i] := Z[j]; Z[j] := t;
        end;
    b := SelBox;
    total := 0;
    for i := 0 to Z.Count - 1 do
      if Vert then total := total + TNode(Z[i]).H else total := total + TNode(Z[i]).W;
    if Vert then gap := (b.B - b.T - total) / (Z.Count - 1) else gap := (b.R - b.L - total) / (Z.Count - 1);
    if Vert then pos := b.T else pos := b.L;
    for i := 0 to Z.Count - 1 do
    begin
      if Vert then
      begin
        MoveNode(TNode(Z[i]), 0, Round(pos - WorldBox(TNode(Z[i])).T));
        pos := pos + TNode(Z[i]).H + gap;
      end
      else
      begin
        MoveNode(TNode(Z[i]), Round(pos - WorldBox(TNode(Z[i])).L), 0);
        pos := pos + TNode(Z[i]).W + gap;
      end;
    end;
  finally
    Z.Free;
  end;
  NormalizeAll;
end;

procedure Restack(K: Integer);
var
  Z: TFPList;
  i, idx: Integer;
  n: TNode;
begin
  if Sel.Count = 0 then Exit;
  Snap;
  Z := SortedByZ(Sel);
  try
    if K in [0, 1] then
      for i := Z.Count - 1 downto 0 do
      begin
        n := TNode(Z[i]);
        idx := IndexIn(n);
        n.Parent.Kids.Delete(idx);
        if K = 0 then n.Parent.Kids.Add(n)
        else n.Parent.Kids.Insert(Min(idx + 1, n.Parent.Kids.Count), n);
      end
    else
      for i := 0 to Z.Count - 1 do
      begin
        n := TNode(Z[i]);
        idx := IndexIn(n);
        n.Parent.Kids.Delete(idx);
        if K = 3 then n.Parent.Kids.Insert(0, n)
        else n.Parent.Kids.Insert(Max(idx - 1, 0), n);
      end;
  finally
    Z.Free;
  end;
  NormalizeAll;
end;

function CompCount: Integer;
var
  L: TFPList;
begin
  L := AllComponents;
  Result := L.Count;
  L.Free;
end;

procedure MakeComponent;
var
  n: TNode;
begin
  if Sel.Count = 0 then Exit;
  Snap;
  n := One;
  if (n <> nil) and (n.Kind = kFrame) then n.Kind := kComponent
  else
  begin
    n := WrapSel(kComponent);
    if n = nil then Exit;
    if (n.Count = 1) then n.Name := n.Kid(0).Name;
  end;
  if Pos(KindLabel(kFrame), n.Name) = 1 then n.Name := KindLabel(kComponent) + ' ' + IntToStr(CompCount);
  SelectOnly(n);
  Say(tx_COMP_MADE);
end;

procedure Detach;
var
  n, main, c, f: TNode;
  i, j: Integer;
  map: TStringList;
  L: TFPList;
  oid: string;
begin
  n := One;
  if (n = nil) or (n.Kind <> kInstance) then Exit;
  main := FindNode(n.CompId);
  if main = nil then Exit;
  Snap;
  f := NewNode(kFrame, nil, n.X, n.Y, n.W, n.H);
  f.Name := n.Name;
  f.Fill := main.Fill;
  f.Stroke := main.Stroke;
  f.StrokeW := main.StrokeW;
  f.Radius := main.Radius;
  f.Clip := main.Clip;
  f.ShOn := main.ShOn; f.ShX := main.ShX; f.ShY := main.ShY; f.ShBlur := main.ShBlur; f.ShColor := main.ShColor;
  f.Link := n.Link; f.Anim := n.Anim; f.Dur := n.Dur;
  f.Rot := n.Rot;
  f.Layout := main.Layout; f.Gap := main.Gap; f.Pad := main.Pad; f.LAlign := main.LAlign;
  map := TStringList.Create;
  L := TFPList.Create;
  try
    for i := 0 to main.Count - 1 do
    begin
      c := CloneNode(main.Kid(i), map);
      AddKid(f, c);
    end;
    // Los textos cambiados en la instancia pasan a la copia.
    for i := 0 to n.Over.Count - 1 do
    begin
      oid := map.Values[n.Over.Names[i]];
      if oid = '' then Continue;
      Flatten(f, L, False);
      for j := 0 to L.Count - 1 do
        if TNode(L[j]).Id = StrToIntDef(oid, 0) then TNode(L[j]).Text := n.Over.ValueFromIndex[i];
      L.Clear;
    end;
  finally
    L.Free;
    map.Free;
  end;
  AddKid(n.Parent, f, IndexIn(n) + 1);
  Unlink(n);
  n.Free;
  NormalizeAll;
  SelectOnly(f);
end;

{ Un sitio libre a la derecha de lo que hay en la página. }
function FreeSpot: TPt;
var
  b: TRectF;
begin
  if Page.Root.Count = 0 then Exit(P2(0, 0));
  b := PageBox;
  Result := P2(Round(b.R + 100), Round(b.T));
end;

function ViewCenter: TPt;
begin
  Result := S2W((CX0 + CX1) / 2, (CY0 + CY1) / 2);
end;

procedure InsertInstance(Main: TNode);
var
  n, par: TNode;
  c, lp: TPt;
begin
  if Main = nil then Exit;
  Snap;
  par := Page.Root;
  if (One <> nil) and (One.Kind in [kFrame, kComponent]) and (One <> Main) and not IsInside(One, Main) then par := One;
  c := ViewCenter;
  if par <> Page.Root then c := MatAp(WorldOf(par), P2(par.W / 2, par.H / 2));
  lp := ToSpace(par, c);
  n := NewNode(kInstance, par, Round(lp.X - Main.W / 2), Round(lp.Y - Main.H / 2), Main.W, Main.H);
  n.CompId := Main.Id;
  n.Name := Main.Name;
  n.Radius := Main.Radius;
  NormalizeAll;
  SelectOnly(n);
end;

procedure PlaceImage(const Path: string);
var
  img: TImgData;
  n, par: TNode;
  w, h, k: Double;
  c, lp: TPt;
begin
  img := LoadImg(Path);
  if img = nil then
  begin
    Say(tx_ERR_IMAGE);
    Exit;
  end;
  Snap;
  w := img.W; h := img.H;
  k := Min(1, 600 / Max(w, h));
  w := Round(w * k); h := Round(h * k);
  par := Page.Root;
  if (One <> nil) and (One.Kind in [kFrame, kComponent]) then par := One;
  c := ViewCenter;
  if par <> Page.Root then c := MatAp(WorldOf(par), P2(par.W / 2, par.H / 2));
  lp := ToSpace(par, c);
  n := NewNode(kRect, par, Round(lp.X - w / 2), Round(lp.Y - h / 2), w, h);
  n.Name := ChangeFileExt(ExtractFileName(Path), '');
  n.Fill.Kind := fkImage;
  n.Fill.Img := Path;
  SelectOnly(n);
end;

{ Un marco nuevo se queda con lo que ya estaba debajo, si cabe entero. }
procedure Adopt(F: TNode);
var
  i: Integer;
  k: TNode;
  b, fb: TRectF;
begin
  if (F = nil) or (F.Parent = nil) then Exit;
  fb := WorldBox(F);
  for i := F.Parent.Count - 1 downto 0 do
  begin
    k := F.Parent.Kid(i);
    if (k = F) or (IndexIn(k) > IndexIn(F)) then Continue;
    b := WorldBox(k);
    if (b.L >= fb.L) and (b.R <= fb.R) and (b.T >= fb.T) and (b.B <= fb.B) and not IsBox(k) then
      Reparent(k, F, 0);
  end;
end;

// ------------------------------------------------------ el portapapeles
procedure KidsTree(T: TNode; L: TStrings);
var
  j: Integer;
begin
  for j := 0 to T.Count - 1 do
  begin
    L.Add(NodeToLine(T.Kid(j), T.Id));
    KidsTree(T.Kid(j), L);
  end;
end;

{ Las capas elegidas como texto (con dónde estaban en el mundo). }
function SelClipText: string;
var
  L: TFPList;
  o: TStringList;
  i: Integer;
  n: TNode;
  cw: TPt;
begin
  L := TopSel;
  o := TStringList.Create;
  try
    o.Add(CLIP_HEAD);
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      cw := MatAp(WorldOf(n), P2(n.W / 2, n.H / 2));
      o.Add(NodeToLine(n, 0) + KV('wx', F2S(cw.X)) + KV('wy', F2S(cw.Y)));
      KidsTree(n, o);
    end;
    Result := o.Text;
  finally
    o.Free;
    L.Free;
  end;
end;

function ImportJson(const Txt: string; out Msg: string): Boolean; forward;

{ Pega lo copiado: capas de OpenD++, un diseño JSON o un texto. }
function PasteText(const T: string): Boolean;
var
  L, F: TStringList;
  map: TStringList;
  tops: TFPList;
  dxs, dys: array of Double;
  i, pid: Integer;
  kind, msg: string;
  n, target, par: TNode;
  c: TPt;
begin
  Result := False;
  if Trim(T) = '' then Exit;
  if Copy(Trim(T), 1, Length(CLIP_HEAD)) <> CLIP_HEAD then
  begin
    if (Pos('{', T) > 0) and ((Pos('"type"', T) > 0) or (Pos('"pages"', T) > 0) or (Pos('"frames"', T) > 0)) then
    begin
      Result := ImportJson(T, msg);
      Say(msg);
      Exit;
    end;
    Snap;
    target := Page.Root;
    if (One <> nil) and (One.Kind in [kFrame, kComponent]) then target := One;
    c := ToSpace(target, ViewCenter);
    n := NewDefault(kText, target, P2(Round(c.X), Round(c.Y)));
    n.Text := T;
    n.Size := 16;
    NormalizeAll;
    SelectOnly(n);
    Exit(True);
  end;
  Snap;
  target := Page.Root;
  if (One <> nil) and (One.Kind in [kFrame, kComponent]) then target := One;
  L := TStringList.Create;
  map := TStringList.Create;
  tops := TFPList.Create;
  try
    L.Text := T;
    Sel.Clear;
    for i := 1 to L.Count - 1 do
    begin
      F := SplitFields(L[i], kind);
      try
        if kind <> 'node' then Continue;
        n := FieldsNode(F);
        map.Values[IntToStr(n.Id)] := IntToStr(NextId);
        n.Id := NextId;
        Inc(NextId);
        pid := StrToIntDef(F.Values['p'], 0);
        if pid = 0 then
        begin
          AddKid(target, n);
          c := ToSpace(target, P2(S2F(F.Values['wx']), S2F(F.Values['wy'])));
          SetLength(dxs, tops.Count + 1);
          SetLength(dys, tops.Count + 1);
          dxs[tops.Count] := c.X - n.W / 2 - n.X;
          dys[tops.Count] := c.Y - n.H / 2 - n.Y;
          tops.Add(n);
          Sel.Add(n);
        end
        else
        begin
          par := FindIn(Page.Root, StrToIntDef(map.Values[IntToStr(pid)], 0));
          if par <> nil then AddKid(par, n) else n.Free;
        end;
      finally
        F.Free;
      end;
    end;
    for i := 0 to tops.Count - 1 do MoveNode(TNode(tops[i]), dxs[i], dys[i]);
    NormalizeAll;
    Result := tops.Count > 0;
  finally
    tops.Free;
    map.Free;
    L.Free;
  end;
end;

// ============================================================== exportar
procedure ExportPNG(const Fn: string; Sc: Double);
var
  b: TRectF;
  tmp, old: TSurface;
  L: TFPList;
  i, w, h: Integer;
  n: TNode;
begin
  if Sel.Count = 0 then Exit;
  b := SelBox;
  w := EnsureRange(Ceil((b.R - b.L) * Sc), 1, 8000);
  h := EnsureRange(Ceil((b.B - b.T) * Sc), 1, 8000);
  tmp := TSurface.Create(w, h);
  old := Surf;
  L := TopSel;
  try
    tmp.Clear(0);
    Surf := tmp;
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      DrawNodeAt(n, MatMul(MatS(Sc, Sc), MatMul(MatT(-b.L, -b.T), ChildMat(n.Parent))), 1, nil);
    end;
    SaveSurfPNG(tmp, Fn);
  finally
    Surf := old;
    L.Free;
    tmp.Free;
  end;
end;

function XmlEsc(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function SvgNum(D: Double): string;
begin
  Result := FloatToStrF(Round(D * 1000) / 1000, ffGeneral, 10, 0, FS);
end;

function SvgColor(C: LongWord; const Attr: string): string;
begin
  Result := ' ' + Attr + '="#' + HexOf(C) + '"';
  if CA(C) < 255 then Result := Result + ' ' + Attr + '-opacity="' + SvgNum(CA(C) / 255) + '"';
end;

var
  SvgIds: Integer = 0;

function SvgPaint(const F: TFill; W, H: Double; const Attr: string; var Defs: string): string;
var
  id: string;
  a: Double;
  img: string;
  st: TFileStream;
  raw: string;
begin
  if not F.Vis then Exit(' ' + Attr + '="none"');
  case F.Kind of
    fkLinear:
      begin
        Inc(SvgIds);
        id := 'g' + IntToStr(SvgIds);
        a := F.Angle * Pi / 180;
        Defs := Defs + '    <linearGradient id="' + id + '" x1="' + SvgNum(0.5 - Sin(a) / 2) + '" y1="' + SvgNum(0.5 + Cos(a) / 2) +
          '" x2="' + SvgNum(0.5 + Sin(a) / 2) + '" y2="' + SvgNum(0.5 - Cos(a) / 2) + '">' + LineEnding +
          '      <stop offset="0"' + StringReplace(SvgColor(FillC1(F), 'stop-color'), 'stop-color-opacity', 'stop-opacity', []) + '/>' + LineEnding +
          '      <stop offset="1"' + StringReplace(SvgColor(F.C2, 'stop-color'), 'stop-color-opacity', 'stop-opacity', []) + '/>' + LineEnding +
          '    </linearGradient>' + LineEnding;
        Result := ' ' + Attr + '="url(#' + id + ')"';
      end;
    fkImage:
      begin
        Inc(SvgIds);
        id := 'p' + IntToStr(SvgIds);
        img := '';
        if FileExists(F.Img) then
        try
          st := TFileStream.Create(F.Img, fmOpenRead or fmShareDenyNone);
          try
            SetLength(raw, st.Size);
            if st.Size > 0 then st.ReadBuffer(raw[1], st.Size);
          finally
            st.Free;
          end;
          img := 'data:image/' + LowerCase(Copy(ExtractFileExt(F.Img), 2, 9)) + ';base64,' + EncodeStringBase64(raw);
        except
          img := '';
        end;
        if F.Fit then raw := 'meet' else raw := 'slice';
        Defs := Defs + '    <pattern id="' + id + '" width="1" height="1" patternContentUnits="userSpaceOnUse">' +
          '<image width="' + SvgNum(W) + '" height="' + SvgNum(H) + '" preserveAspectRatio="xMidYMid ' + raw + '" href="' + img + '"/></pattern>' + LineEnding;
        Result := ' ' + Attr + '="url(#' + id + ')"';
      end;
  else
    Result := SvgColor(FillC1(F), Attr);
  end;
end;

function SvgOf(N: TNode; const PM: TMat; Ov: TStringList; var Defs: string; const Ind: string): string;
var
  M: TMat;
  tr, att, d: string;
  P: TPoly;
  i: Integer;
  L: TStringList;
  lh, y: Double;
  src, main: TNode;
  fid: string;
begin
  Result := '';
  if not N.Visible then Exit;
  if N.Kind = kGroup then
  begin
    Result := Ind + '<g';
    if N.Opacity < 1 then Result := Result + ' opacity="' + SvgNum(N.Opacity) + '"';
    Result := Result + '>' + LineEnding;
    for i := 0 to N.Count - 1 do Result := Result + SvgOf(N.Kid(i), PM, Ov, Defs, Ind + '  ');
    Exit(Result + Ind + '</g>' + LineEnding);
  end;
  M := MatMul(PM, LocalMat(N));
  tr := ' transform="matrix(' + SvgNum(M.A) + ' ' + SvgNum(M.B) + ' ' + SvgNum(M.C) + ' ' + SvgNum(M.D) + ' ' +
    SvgNum(M.E) + ' ' + SvgNum(M.F) + ')"';
  src := N;
  main := nil;
  if N.Kind = kInstance then
  begin
    main := FindNode(N.CompId);
    if main <> nil then src := main;
  end;
  att := '';
  if N.Opacity < 1 then att := att + ' opacity="' + SvgNum(N.Opacity) + '"';
  if src.ShOn then
  begin
    Inc(SvgIds);
    fid := 'f' + IntToStr(SvgIds);
    Defs := Defs + '    <filter id="' + fid + '" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="' + SvgNum(src.ShX) +
      '" dy="' + SvgNum(src.ShY) + '" stdDeviation="' + SvgNum(src.ShBlur / 2) + '" flood-color="#' + HexOf(src.ShColor) +
      '" flood-opacity="' + SvgNum(CA(src.ShColor) / 255) + '"/></filter>' + LineEnding;
    att := att + ' filter="url(#' + fid + ')"';
  end;
  if N.Kind = kText then
  begin
    L := TextLines(N);
    try
      lh := LineHOf(N);
      Result := Ind + '<text' + tr + att + ' font-family="' + XmlEsc(N.Font) + '" font-size="' + SvgNum(N.Size) + '"';
      if N.Bold then Result := Result + ' font-weight="700"';
      if N.Italic then Result := Result + ' font-style="italic"';
      if N.Spacing <> 0 then Result := Result + ' letter-spacing="' + SvgNum(N.Spacing * N.Size / 100) + '"';
      Result := Result + SvgColor(FillC1(N.Fill), 'fill') + '>' + LineEnding;
      for i := 0 to L.Count - 1 do
      begin
        y := i * lh + (lh - N.Size * 1.22) / 2 + N.Size * 0.96;
        Result := Result + Ind + '  <tspan x="' + SvgNum(LineX(N, L[i])) + '" y="' + SvgNum(y) + '">' + XmlEsc(L[i]) + '</tspan>' + LineEnding;
      end;
      Result := Result + Ind + '</text>' + LineEnding;
    finally
      L.Free;
    end;
    Exit;
  end;
  // La forma.
  d := '';
  if N.Kind in [kRect, kFrame, kComponent, kInstance] then
  begin
    d := '<rect width="' + SvgNum(N.W) + '" height="' + SvgNum(N.H) + '"';
    if src.Radius > 0 then d := d + ' rx="' + SvgNum(Min(src.Radius, Min(N.W, N.H) / 2)) + '"';
  end
  else if N.Kind = kEllipse then
    d := '<ellipse cx="' + SvgNum(N.W / 2) + '" cy="' + SvgNum(N.H / 2) + '" rx="' + SvgNum(N.W / 2) + '" ry="' + SvgNum(N.H / 2) + '"'
  else
  begin
    P := Outline(N, 2);
    d := '<path d="';
    for i := 0 to High(P) do
    begin
      if i = 0 then d := d + 'M' else d := d + ' L';
      d := d + SvgNum(P[i].X) + ' ' + SvgNum(P[i].Y);
    end;
    if not IsOpenPath(N) then d := d + ' Z';
    d := d + '"';
  end;
  if IsOpenPath(N) then d := d + ' fill="none"'
  else d := d + SvgPaint(src.Fill, N.W, N.H, 'fill', Defs);
  if src.Stroke.Vis and (src.StrokeW > 0) then
  begin
    d := d + SvgColor(FillC1(src.Stroke), 'stroke') + ' stroke-width="' + SvgNum(src.StrokeW) + '"';
    if N.Dash then d := d + ' stroke-dasharray="' + SvgNum(src.StrokeW * 3) + ' ' + SvgNum(src.StrokeW * 2) + '"';
    if IsOpenPath(N) then d := d + ' stroke-linecap="round"';
    if N.Kind = kArrow then d := d + ' marker-end="url(#arrow)"';
  end;
  if (N.Count = 0) and (main = nil) then
    Exit(Ind + d + tr + att + '/>' + LineEnding);
  Result := Ind + '<g' + att + '>' + LineEnding + Ind + '  ' + d + tr + '/>' + LineEnding;
  if main <> nil then
    for i := 0 to main.Count - 1 do Result := Result + SvgOf(main.Kid(i), M, N.Over, Defs, Ind + '  ')
  else
    for i := 0 to N.Count - 1 do Result := Result + SvgOf(N.Kid(i), M, Ov, Defs, Ind + '  ');
  Result := Result + Ind + '</g>' + LineEnding;
end;

function SvgDoc: string;
var
  b: TRectF;
  L: TFPList;
  i: Integer;
  body, defs: string;
  n: TNode;
begin
  b := SelBox;
  defs := '    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 Z" fill="context-stroke"/></marker>' + LineEnding;
  body := '';
  SvgIds := 0;
  L := TopSel;
  try
    for i := 0 to L.Count - 1 do
    begin
      n := TNode(L[i]);
      body := body + SvgOf(n, MatMul(MatT(-b.L, -b.T), ChildMat(n.Parent)), nil, defs, '  ');
    end;
  finally
    L.Free;
  end;
  Result := '<svg xmlns="http://www.w3.org/2000/svg" width="' + SvgNum(b.R - b.L) + '" height="' + SvgNum(b.B - b.T) +
    '" viewBox="0 0 ' + SvgNum(b.R - b.L) + ' ' + SvgNum(b.B - b.T) + '">' + LineEnding +
    '  <defs>' + LineEnding + defs + '  </defs>' + LineEnding + body + '</svg>' + LineEnding;
end;

// ======================================================== código CSS y Flutter
const
  Q1 = #39; // la comilla simple

function CssColor(C: LongWord): string;
begin
  if CA(C) = 255 then Result := '#' + HexOf(C)
  else Result := 'rgba(' + IntToStr(CR(C)) + ', ' + IntToStr(CG(C)) + ', ' + IntToStr(CB(C)) + ', ' + SvgNum(CA(C) / 255) + ')';
end;

function CssOf(N: TNode): string;
var
  L: TStringList;
  src: TNode;
begin
  L := TStringList.Create;
  try
    L.Add('/* ' + NodeName(N) + ' */');
    src := N;
    if (N.Kind = kInstance) and (FindNode(N.CompId) <> nil) then src := FindNode(N.CompId);
    L.Add('position: absolute;');
    L.Add('left: ' + NumStr(N.X) + 'px;');
    L.Add('top: ' + NumStr(N.Y) + 'px;');
    L.Add('width: ' + NumStr(N.W) + 'px;');
    L.Add('height: ' + NumStr(N.H) + 'px;');
    if N.Kind = kText then
    begin
      L.Add('font-family: ' + Q1 + N.Font + Q1 + ';');
      L.Add('font-size: ' + NumStr(N.Size) + 'px;');
      if N.Bold then L.Add('font-weight: 700;') else L.Add('font-weight: 400;');
      if N.Italic then L.Add('font-style: italic;');
      if N.LineH > 0 then L.Add('line-height: ' + NumStr(N.LineH) + '%;');
      if N.Spacing <> 0 then L.Add('letter-spacing: ' + NumStr(N.Spacing / 100) + 'em;');
      case N.Align of
        1: L.Add('text-align: center;');
        2: L.Add('text-align: right;');
      end;
      L.Add('color: ' + CssColor(FillC1(N.Fill)) + ';');
    end
    else if not IsOpenPath(N) and src.Fill.Vis then
      case src.Fill.Kind of
        fkLinear: L.Add('background: linear-gradient(' + NumStr(src.Fill.Angle) + 'deg, ' + CssColor(FillC1(src.Fill)) +
          ' 0%, ' + CssColor(src.Fill.C2) + ' 100%);');
        fkImage:
          if src.Fill.Fit then L.Add('background: url(' + ExtractFileName(src.Fill.Img) + ') center / contain no-repeat;')
          else L.Add('background: url(' + ExtractFileName(src.Fill.Img) + ') center / cover;');
      else
        L.Add('background: ' + CssColor(FillC1(src.Fill)) + ';');
      end;
    if N.Kind = kEllipse then L.Add('border-radius: 50%;')
    else if src.Radius > 0 then L.Add('border-radius: ' + NumStr(src.Radius) + 'px;');
    if src.Stroke.Vis and (src.StrokeW > 0) then
    begin
      if N.Dash then L.Add('border: ' + NumStr(src.StrokeW) + 'px dashed ' + CssColor(FillC1(src.Stroke)) + ';')
      else if src.StrokePos = 2 then L.Add('outline: ' + NumStr(src.StrokeW) + 'px solid ' + CssColor(FillC1(src.Stroke)) + ';')
      else L.Add('border: ' + NumStr(src.StrokeW) + 'px solid ' + CssColor(FillC1(src.Stroke)) + ';');
    end;
    if src.ShOn then
      L.Add('box-shadow: ' + NumStr(src.ShX) + 'px ' + NumStr(src.ShY) + 'px ' + NumStr(src.ShBlur) + 'px ' + CssColor(src.ShColor) + ';');
    if N.Opacity < 1 then L.Add('opacity: ' + SvgNum(N.Opacity) + ';');
    if N.Rot <> 0 then L.Add('transform: rotate(' + NumStr(-N.Rot) + 'deg);');
    if src.Layout <> 0 then
    begin
      L.Add('display: flex;');
      if src.Layout = 1 then L.Add('flex-direction: row;') else L.Add('flex-direction: column;');
      L.Add('gap: ' + NumStr(src.Gap) + 'px;');
      L.Add('padding: ' + NumStr(src.Pad) + 'px;');
      case src.LAlign of
        1: L.Add('align-items: center;');
        2: L.Add('align-items: flex-end;');
      end;
    end;
    if src.Clip and IsBox(N) then L.Add('overflow: hidden;');
    Result := L.Text;
  finally
    L.Free;
  end;
end;

function FlColor(C: LongWord): string;
begin
  Result := 'Color(0x' + IntToHex(C, 8) + ')';
end;

function FlutterOf(N: TNode): string;
var
  L: TStringList;
  src: TNode;
  t: string;
begin
  L := TStringList.Create;
  try
    src := N;
    if (N.Kind = kInstance) and (FindNode(N.CompId) <> nil) then src := FindNode(N.CompId);
    L.Add('// ' + NodeName(N));
    if N.Kind = kText then
    begin
      t := StringReplace(N.Text, Q1, '\' + Q1, [rfReplaceAll]);
      t := StringReplace(t, #10, '\n', [rfReplaceAll]);
      L.Add('Text(');
      L.Add('  ' + Q1 + t + Q1 + ',');
      case N.Align of
        1: L.Add('  textAlign: TextAlign.center,');
        2: L.Add('  textAlign: TextAlign.right,');
      end;
      L.Add('  style: TextStyle(');
      L.Add('    fontFamily: ' + Q1 + N.Font + Q1 + ',');
      L.Add('    fontSize: ' + NumStr(N.Size) + ',');
      if N.Bold then L.Add('    fontWeight: FontWeight.w700,');
      if N.Italic then L.Add('    fontStyle: FontStyle.italic,');
      if N.LineH > 0 then L.Add('    height: ' + SvgNum(N.LineH / 100) + ',');
      if N.Spacing <> 0 then L.Add('    letterSpacing: ' + SvgNum(N.Spacing * N.Size / 100) + ',');
      L.Add('    color: ' + FlColor(FillC1(N.Fill)) + ',');
      L.Add('  ),');
      L.Add(')');
      Exit(L.Text);
    end;
    if N.Opacity < 1 then L.Add('Opacity(opacity: ' + SvgNum(N.Opacity) + ', child:');
    L.Add('Container(');
    L.Add('  width: ' + NumStr(N.W) + ',');
    L.Add('  height: ' + NumStr(N.H) + ',');
    if src.Layout <> 0 then L.Add('  padding: EdgeInsets.all(' + NumStr(src.Pad) + '),');
    L.Add('  decoration: BoxDecoration(');
    if src.Fill.Vis and not IsOpenPath(N) then
      case src.Fill.Kind of
        fkLinear:
          begin
            L.Add('    gradient: LinearGradient(');
            L.Add('      transform: GradientRotation(' + SvgNum((src.Fill.Angle - 90) * Pi / 180) + '),');
            L.Add('      colors: [' + FlColor(FillC1(src.Fill)) + ', ' + FlColor(src.Fill.C2) + '],');
            L.Add('    ),');
          end;
        fkImage:
          begin
            L.Add('    image: DecorationImage(');
            L.Add('      image: AssetImage(' + Q1 + 'assets/' + ExtractFileName(src.Fill.Img) + Q1 + '),');
            if src.Fill.Fit then L.Add('      fit: BoxFit.contain,') else L.Add('      fit: BoxFit.cover,');
            L.Add('    ),');
          end;
      else
        L.Add('    color: ' + FlColor(FillC1(src.Fill)) + ',');
      end;
    if N.Kind = kEllipse then L.Add('    shape: BoxShape.circle,')
    else if src.Radius > 0 then L.Add('    borderRadius: BorderRadius.circular(' + NumStr(src.Radius) + '),');
    if src.Stroke.Vis and (src.StrokeW > 0) then
      L.Add('    border: Border.all(color: ' + FlColor(FillC1(src.Stroke)) + ', width: ' + NumStr(src.StrokeW) + '),');
    if src.ShOn then
    begin
      L.Add('    boxShadow: [');
      L.Add('      BoxShadow(color: ' + FlColor(src.ShColor) + ', offset: Offset(' + NumStr(src.ShX) + ', ' + NumStr(src.ShY) +
        '), blurRadius: ' + NumStr(src.ShBlur) + '),');
      L.Add('    ],');
    end;
    L.Add('  ),');
    if src.Layout = 1 then L.Add('  child: Row(spacing: ' + NumStr(src.Gap) + ', children: [/* ' + IntToStr(src.Count) + ' */]),')
    else if src.Layout = 2 then L.Add('  child: Column(spacing: ' + NumStr(src.Gap) + ', children: [/* ' + IntToStr(src.Count) + ' */]),')
    else if src.Count > 0 then L.Add('  child: Stack(children: [/* ' + IntToStr(src.Count) + ' */]),');
    L.Add(')');
    if N.Opacity < 1 then L.Add(')');
    if N.Rot <> 0 then L.Insert(1, '// Transform.rotate(angle: ' + SvgNum(-N.Rot * Pi / 180) + ')');
    Result := L.Text;
  finally
    L.Free;
  end;
end;

// =================================================== JSON para la IA
function JHex(C: LongWord): string;
begin
  Result := '#' + HexOf(C);
  if CA(C) < 255 then Result := Result + IntToHex(CA(C), 2);
end;

{ Los textos de la app ya son UTF-8: así fpjson no los convierte otra vez. }
function JStr(const S: string): TJSONStringType;
begin
  Result := S;
end;

function NodeJson(N: TNode; OX, OY: Double): TJSONObject;
var
  o, f: TJSONObject;
  kids, pts: TJSONArray;
  i: Integer;
  t: TNode;
  cx, cy: Double;
begin
  o := TJSONObject.Create;
  case N.Kind of
    kRect: o.Add('type', 'rectangle');
  else
    o.Add('type', KindNames[N.Kind]);
  end;
  o.Add('name', NodeName(N));
  o.Add('x', Round((N.X - OX) * 100) / 100);
  o.Add('y', Round((N.Y - OY) * 100) / 100);
  o.Add('width', Round(N.W * 100) / 100);
  o.Add('height', Round(N.H * 100) / 100);
  if N.Rot <> 0 then o.Add('rotation', N.Rot);
  if N.Opacity < 1 then o.Add('opacity', N.Opacity);
  if HasRadius(N) and (N.Radius > 0) then o.Add('radius', N.Radius);
  if N.Kind in [kPolygon, kStar] then o.Add('sides', N.Sides);
  if N.Kind = kStar then o.Add('ratio', N.Ratio);
  if (N.Kind <> kGroup) and (N.Kind <> kInstance) and not IsOpenPath(N) then
  begin
    if not N.Fill.Vis then o.Add('fill', TJSONNull.Create)
    else
      case N.Fill.Kind of
        fkLinear:
          begin
            f := TJSONObject.Create;
            f.Add('type', 'linear');
            f.Add('from', JHex(FillC1(N.Fill)));
            f.Add('to', JHex(N.Fill.C2));
            f.Add('angle', N.Fill.Angle);
            o.Add('fill', f);
          end;
        fkImage: o.Add('image', N.Fill.Img);
      else
        o.Add('fill', JHex(FillC1(N.Fill)));
      end;
  end;
  if N.Stroke.Vis and (N.StrokeW > 0) and (N.Kind <> kInstance) then
  begin
    f := TJSONObject.Create;
    f.Add('color', JHex(FillC1(N.Stroke)));
    f.Add('width', N.StrokeW);
    case N.StrokePos of
      1: f.Add('position', 'inside');
      2: f.Add('position', 'outside');
    end;
    if N.Dash then f.Add('dashed', True);
    o.Add('stroke', f);
  end;
  if N.ShOn then
  begin
    f := TJSONObject.Create;
    f.Add('x', N.ShX); f.Add('y', N.ShY); f.Add('blur', N.ShBlur);
    f.Add('color', JHex(N.ShColor));
    o.Add('shadow', f);
  end;
  if N.Kind = kText then
  begin
    o.Add('text', N.Text);
    o.Add('fontFamily', N.Font);
    o.Add('fontSize', N.Size);
    if N.Bold then o.Add('fontWeight', 700);
    if N.Italic then o.Add('italic', True);
    case N.Align of
      1: o.Add('textAlign', 'center');
      2: o.Add('textAlign', 'right');
    end;
    if N.LineH > 0 then o.Add('lineHeight', N.LineH);
    if N.Spacing <> 0 then o.Add('letterSpacing', N.Spacing);
    if N.AutoW then o.Add('autoWidth', True);
  end;
  if (N.Kind in [kFrame, kComponent]) and (N.Layout <> 0) then
  begin
    f := TJSONObject.Create;
    if N.Layout = 1 then f.Add('direction', 'horizontal') else f.Add('direction', 'vertical');
    f.Add('gap', N.Gap); f.Add('padding', N.Pad);
    case N.LAlign of
      1: f.Add('align', 'center');
      2: f.Add('align', 'end');
    end;
    if N.Hug then f.Add('hug', True);
    o.Add('layout', f);
  end;
  if (N.Kind in [kFrame, kComponent]) and not N.Clip then o.Add('clip', False);
  if Length(N.Pts) > 0 then
  begin
    pts := TJSONArray.Create;
    for i := 0 to High(N.Pts) do pts.Add(TJSONArray.Create([Round(N.Pts[i].X * 10) / 10, Round(N.Pts[i].Y * 10) / 10]));
    o.Add('points', pts);
    if N.Closed then o.Add('closed', True);
  end;
  if N.Kind = kInstance then
  begin
    t := FindNode(N.CompId);
    if t <> nil then o.Add('component', t.Name);
    if N.Over.Count > 0 then
    begin
      f := TJSONObject.Create;
      for i := 0 to N.Over.Count - 1 do
      begin
        t := FindNode(StrToIntDef(N.Over.Names[i], 0));
        if t <> nil then f.Add(NodeName(t), N.Over.ValueFromIndex[i]);
      end;
      o.Add('overrides', f);
    end;
  end;
  if N.Link > 0 then
  begin
    t := FindNode(N.Link);
    if t <> nil then
    begin
      o.Add('link', t.Name);
      case N.Anim of
        1: o.Add('animation', 'dissolve');
        2: o.Add('animation', 'slide-left');
        3: o.Add('animation', 'slide-right');
        4: o.Add('animation', 'slide-up');
        5: o.Add('animation', 'push');
      end;
    end;
  end;
  if (N.Count > 0) and (N.Kind <> kInstance) then
  begin
    kids := TJSONArray.Create;
    // En un grupo, los hijos van respecto al grupo.
    if N.Kind = kGroup then begin cx := N.X; cy := N.Y; end else begin cx := 0; cy := 0; end;
    for i := 0 to N.Count - 1 do kids.Add(NodeJson(N.Kid(i), cx, cy));
    o.Add('children', kids);
  end;
  Result := o;
end;

function AiTemplate: string;
var
  o, pg, fr, k, k2, lay: TJSONObject;
  jpages, frames, kids, kids2, ref, rules: TJSONArray;
begin
  o := TJSONObject.Create;
  try
    o.Add('_instructions', JStr(tx_AI_PROMPT));
    rules := TJSONArray.Create;
    rules.Add('type: frame | rectangle | ellipse | line | arrow | polygon | star | text | group | path | component | instance');
    rules.Add('x, y, width, height: px; x and y are relative to the parent frame (or group)');
    rules.Add('fill: "#RRGGBB" or "#RRGGBBAA", null for none, or {"type":"linear","from":"#..","to":"#..","angle":180}; image: "file path"');
    rules.Add('stroke: "#RRGGBB" or {"color":"#..","width":1,"position":"inside|center|outside","dashed":false}');
    rules.Add('radius, rotation (degrees, counterclockwise), opacity (0..1), shadow: {"x":0,"y":4,"blur":12,"color":"#00000033"}');
    rules.Add('text: text, fontFamily, fontSize, fontWeight (400|700), italic, textAlign (left|center|right), lineHeight (%), letterSpacing (%), color; without width it grows with the text, with width it wraps');
    rules.Add('layout (frames, like flexbox): {"direction":"horizontal|vertical","gap":12,"padding":16,"align":"start|center|end","hug":true}');
    rules.Add('children: the layers inside a frame, group or component, from back to front');
    rules.Add('component: a reusable piece; instance: {"type":"instance","component":"Component name","overrides":{"Text layer name":"new text"}}');
    rules.Add('link: "Frame name" (prototype: on click, go to that frame); animation: instant | dissolve | slide-left | slide-right | slide-up | push');
    rules.Add('polygon/star: sides, ratio (0..1); path: points [[x,y],...] relative to the layer, closed: true|false');
    o.Add('_format', rules);
    jpages := TJSONArray.Create;
    pg := TJSONObject.Create;
    pg.Add('name', JStr(tx_AIX_PAGE));
    frames := TJSONArray.Create;
    // Un componente: el botón.
    fr := TJSONObject.Create;
    fr.Add('type', 'component');
    fr.Add('name', JStr(tx_AIX_BUTTON));
    fr.Add('x', 0); fr.Add('y', 940); fr.Add('width', 342); fr.Add('height', 52);
    fr.Add('fill', '#12B886'); fr.Add('radius', 12);
    kids := TJSONArray.Create;
    k := TJSONObject.Create;
    k.Add('type', 'text'); k.Add('name', 'Label'); k.Add('text', JStr(tx_AIX_BUTTON));
    k.Add('x', 0); k.Add('y', 15); k.Add('width', 342);
    k.Add('fontSize', 17); k.Add('fontWeight', 700); k.Add('textAlign', 'center'); k.Add('color', '#FFFFFF');
    kids.Add(k);
    fr.Add('children', kids);
    frames.Add(fr);
    // Una pantalla.
    fr := TJSONObject.Create;
    fr.Add('type', 'frame');
    fr.Add('name', JStr(tx_AIX_LOGIN));
    fr.Add('x', 0); fr.Add('y', 0); fr.Add('width', 390); fr.Add('height', 844);
    fr.Add('fill', '#FFFFFF');
    kids := TJSONArray.Create;
    k := TJSONObject.Create;
    k.Add('type', 'text'); k.Add('name', 'Title'); k.Add('text', JStr(tx_AIX_WELCOME));
    k.Add('x', 24); k.Add('y', 120); k.Add('fontSize', 30); k.Add('fontWeight', 700); k.Add('color', '#111827');
    kids.Add(k);
    k := TJSONObject.Create;
    k.Add('type', 'rectangle'); k.Add('name', 'Email');
    k.Add('x', 24); k.Add('y', 200); k.Add('width', 342); k.Add('height', 52);
    k.Add('fill', '#F4F6F9'); k.Add('radius', 12); k.Add('stroke', '#E3E5EA');
    kids.Add(k);
    k := TJSONObject.Create;
    k.Add('type', 'instance'); k.Add('name', JStr(tx_AIX_BUTTON)); k.Add('component', JStr(tx_AIX_BUTTON));
    k.Add('x', 24); k.Add('y', 280);
    k2 := TJSONObject.Create;
    k2.Add('Label', JStr(tx_AIX_ENTER));
    k.Add('overrides', k2);
    k.Add('link', JStr(tx_AIX_HOME)); k.Add('animation', 'slide-left');
    kids.Add(k);
    fr.Add('children', kids);
    frames.Add(fr);
    // Otra con diseño automático.
    fr := TJSONObject.Create;
    fr.Add('type', 'frame');
    fr.Add('name', JStr(tx_AIX_HOME));
    fr.Add('x', 480); fr.Add('y', 0); fr.Add('width', 390); fr.Add('height', 844);
    fr.Add('fill', '#F4F6F9');
    lay := TJSONObject.Create;
    lay.Add('direction', 'vertical'); lay.Add('gap', 16); lay.Add('padding', 24);
    fr.Add('layout', lay);
    kids2 := TJSONArray.Create;
    k := TJSONObject.Create;
    k.Add('type', 'text'); k.Add('text', JStr(tx_AIX_HELLO)); k.Add('fontSize', 24); k.Add('fontWeight', 700); k.Add('color', '#111827');
    kids2.Add(k);
    k := TJSONObject.Create;
    k.Add('type', 'rectangle'); k.Add('name', 'Card'); k.Add('width', 342); k.Add('height', 120); k.Add('radius', 16);
    k2 := TJSONObject.Create;
    k2.Add('type', 'linear'); k2.Add('from', '#12B886'); k2.Add('to', '#0EA5E9'); k2.Add('angle', 135);
    k.Add('fill', k2);
    k2 := TJSONObject.Create;
    k2.Add('x', 0); k2.Add('y', 8); k2.Add('blur', 24); k2.Add('color', '#0000002E');
    k.Add('shadow', k2);
    kids2.Add(k);
    fr.Add('children', kids2);
    frames.Add(fr);
    pg.Add('frames', frames);
    jpages.Add(pg);
    o.Add('jpages', jpages);
    ref := nil;
    if ref = nil then;
    Result := o.FormatJSON([], 2);
  finally
    o.Free;
  end;
end;

// -------------------------------------------------------- leer el JSON
type
  TPending = record
    N: TNode;
    Link, Comp, Anim: string;
    Over: TJSONObject;
  end;

var
  JPend: array of TPending;
  JNames: TStringList = nil;

function JF(O: TJSONObject; const Keys: array of string; Def: Double): Double;
var
  i: Integer;
  d: TJSONData;
begin
  Result := Def;
  for i := 0 to High(Keys) do
  begin
    d := O.Find(Keys[i]);
    if d = nil then Continue;
    case d.JSONType of
      jtNumber: Exit(d.AsFloat);
      jtString: Exit(S2F(StringReplace(StringReplace(d.AsString, 'px', '', []), '%', '', [])));
      jtBoolean: if d.AsBoolean then Exit(1) else Exit(0);
    end;
  end;
end;

function JS(O: TJSONObject; const Keys: array of string; const Def: string): string;
var
  i: Integer;
  d: TJSONData;
begin
  Result := Def;
  for i := 0 to High(Keys) do
  begin
    d := O.Find(Keys[i]);
    if (d <> nil) and (d.JSONType in [jtString, jtNumber]) then Exit(d.AsString);
  end;
end;

function JB(O: TJSONObject; const Key: string; Def: Boolean): Boolean;
var
  d: TJSONData;
begin
  d := O.Find(Key);
  if (d <> nil) and (d.JSONType = jtBoolean) then Result := d.AsBoolean else Result := Def;
end;

function JColorStr(const S: string; Def: LongWord): LongWord;
var
  t: string;
  p: TStringArray;
begin
  t := LowerCase(Trim(S));
  if (t = 'none') or (t = 'transparent') or (t = '') then Exit(0);
  if t = 'white' then Exit($FFFFFFFF);
  if t = 'black' then Exit($FF000000);
  if Copy(t, 1, 4) = 'rgba' then
  begin
    t := Copy(t, Pos('(', t) + 1, MaxInt);
    t := StringReplace(t, ')', '', []);
    p := t.Split([',']);
    if Length(p) >= 4 then Exit(ARGB(Round(S2F(p[3]) * 255), Round(S2F(p[0])), Round(S2F(p[1])), Round(S2F(p[2]))));
  end;
  if Copy(t, 1, 3) = 'rgb' then
  begin
    t := Copy(t, Pos('(', t) + 1, MaxInt);
    t := StringReplace(t, ')', '', []);
    p := t.Split([',']);
    if Length(p) >= 3 then Exit(ARGB(255, Round(S2F(p[0])), Round(S2F(p[1])), Round(S2F(p[2]))));
  end;
  if (Length(t) > 0) and (t[1] = '#') then Exit(HexC(t));
  Result := Def;
end;

{ Un relleno del JSON; False si no lleva. }
function JFill(D: TJSONData; var F: TFill): Boolean;
var
  o: TJSONObject;
  t: string;
  c: LongWord;
begin
  Result := False;
  if (D = nil) or (D.JSONType = jtNull) then begin F.Vis := False; Exit(True); end;
  if D.JSONType = jtString then
  begin
    c := JColorStr(D.AsString, F.C1);
    F.Vis := c <> 0;
    F.Kind := fkSolid;
    if c <> 0 then F.C1 := c;
    Exit(True);
  end;
  if D.JSONType = jtArray then
  begin
    if TJSONArray(D).Count = 0 then begin F.Vis := False; Exit(True); end;
    Exit(JFill(TJSONArray(D)[0], F));
  end;
  if D.JSONType <> jtObject then Exit;
  o := TJSONObject(D);
  t := LowerCase(JS(o, ['type'], 'solid'));
  F.Vis := True;
  if Pos('linear', t) > 0 then
  begin
    F.Kind := fkLinear;
    F.C1 := JColorStr(JS(o, ['from', 'start', 'color'], '#FFFFFF'), $FFFFFFFF);
    F.C2 := JColorStr(JS(o, ['to', 'end'], '#000000'), $FF000000);
    F.Angle := JF(o, ['angle'], 180);
  end
  else if Pos('image', t) > 0 then
  begin
    F.Kind := fkImage;
    F.Img := JS(o, ['src', 'path', 'url'], '');
    F.Fit := LowerCase(JS(o, ['fit', 'mode'], '')) = 'contain';
  end
  else
  begin
    F.Kind := fkSolid;
    F.C1 := JColorStr(JS(o, ['color', 'value'], '#D9D9D9'), $FFD9D9D9);
  end;
  Result := True;
end;

function JKind(const T: string): TKind;
var
  s: string;
begin
  s := LowerCase(T);
  if (s = 'frame') or (s = 'screen') or (s = 'artboard') then Result := kFrame
  else if s = 'group' then Result := kGroup
  else if (s = 'ellipse') or (s = 'circle') or (s = 'oval') then Result := kEllipse
  else if s = 'line' then Result := kLine
  else if s = 'arrow' then Result := kArrow
  else if (s = 'polygon') or (s = 'triangle') then Result := kPolygon
  else if s = 'star' then Result := kStar
  else if (s = 'path') or (s = 'vector') then Result := kPath
  else if (s = 'text') or (s = 'label') then Result := kText
  else if s = 'component' then Result := kComponent
  else if s = 'instance' then Result := kInstance
  else Result := kRect;
end;

function JNode(O: TJSONObject; Par: TNode; OX, OY: Double): TNode;
var
  k: TKind;
  n: TNode;
  d: TJSONData;
  st, lay: TJSONObject;
  arr: TJSONArray;
  i: Integer;
  t, w: string;
  lh, size: Double;
  hasW: Boolean;
begin
  k := JKind(JS(O, ['type', 'kind'], 'rectangle'));
  n := NewNode(k, Par, OX + JF(O, ['x', 'left'], 0), OY + JF(O, ['y', 'top'], 0),
    JF(O, ['width', 'w'], 100), JF(O, ['height', 'h'], 100));
  Result := n;
  hasW := O.Find('width') <> nil;
  t := JS(O, ['name', 'id'], '');
  if t <> '' then n.Name := t;
  n.Rot := JF(O, ['rotation', 'rotate'], 0);
  n.Opacity := EnsureRange(JF(O, ['opacity'], 1), 0, 1);
  n.Radius := JF(O, ['radius', 'cornerRadius', 'borderRadius'], 0);
  n.Visible := JB(O, 'visible', True);
  if k in [kFrame, kComponent] then n.Clip := JB(O, 'clip', JB(O, 'clipContent', True));
  if k in [kPolygon, kStar] then
  begin
    n.Sides := Round(JF(O, ['sides', 'points', 'count'], n.Sides));
    n.Ratio := JF(O, ['ratio', 'innerRadius'], n.Ratio);
    if n.Ratio > 1 then n.Ratio := n.Ratio / 100;
  end;
  // El relleno (los textos: «color»).
  if k = kText then
  begin
    n.Fill.C1 := $FF111827;
    d := O.Find('color');
    if d = nil then d := O.Find('fill');
    if d <> nil then JFill(d, n.Fill);
    n.Fill.Kind := fkSolid;
    n.Fill.Vis := True;
  end
  else
  begin
    d := O.Find('fill');
    if d = nil then d := O.Find('background');
    if d <> nil then JFill(d, n.Fill);
    t := JS(O, ['image', 'src'], '');
    if t <> '' then
    begin
      n.Fill.Vis := True;
      n.Fill.Kind := fkImage;
      n.Fill.Img := t;
    end;
  end;
  // El trazo.
  d := O.Find('stroke');
  if d = nil then d := O.Find('border');
  if d <> nil then
  begin
    if d.JSONType = jtObject then
    begin
      st := TJSONObject(d);
      n.Stroke.C1 := JColorStr(JS(st, ['color'], '#000000'), $FF000000);
      n.Stroke.Vis := n.Stroke.C1 <> 0;
      n.StrokeW := JF(st, ['width', 'weight'], 1);
      t := LowerCase(JS(st, ['position', 'align'], 'center'));
      if t = 'inside' then n.StrokePos := 1 else if t = 'outside' then n.StrokePos := 2;
      n.Dash := JB(st, 'dashed', False);
    end
    else if d.JSONType = jtString then
    begin
      n.Stroke.C1 := JColorStr(d.AsString, $FF000000);
      n.Stroke.Vis := n.Stroke.C1 <> 0;
    end;
  end;
  n.StrokeW := JF(O, ['strokeWidth'], n.StrokeW);
  if k in [kLine, kArrow, kPath] then
  begin
    if d = nil then n.Stroke.Vis := True;
    n.StrokeW := JF(O, ['strokeWidth'], Max(n.StrokeW, 1));
  end;
  // La sombra.
  d := O.Find('shadow');
  if (d <> nil) and (d.JSONType = jtObject) then
  begin
    st := TJSONObject(d);
    n.ShOn := True;
    n.ShX := JF(st, ['x'], 0); n.ShY := JF(st, ['y'], 4); n.ShBlur := JF(st, ['blur'], 12);
    n.ShColor := JColorStr(JS(st, ['color'], '#00000040'), $40000000);
  end
  else if (d <> nil) and (d.JSONType = jtBoolean) then n.ShOn := d.AsBoolean;
  // El texto.
  if k = kText then
  begin
    n.Text := JS(O, ['text', 'content', 'characters', 'value'], '');
    n.Font := JS(O, ['fontFamily', 'font'], DocFont);
    if n.Font = 'Inter' then n.Font := DocFont;
    size := JF(O, ['fontSize', 'size'], 16);
    n.Size := size;
    w := LowerCase(JS(O, ['fontWeight', 'weight'], '400'));
    n.Bold := (Pos('bold', w) > 0) or (StrToIntDef(w, 400) >= 600);
    n.Italic := JB(O, 'italic', False) or (LowerCase(JS(O, ['fontStyle'], '')) = 'italic');
    t := LowerCase(JS(O, ['textAlign', 'align'], 'left'));
    if t = 'center' then n.Align := 1 else if t = 'right' then n.Align := 2;
    lh := JF(O, ['lineHeight'], 0);
    if (lh > 0) and (lh <= 4) then lh := lh * 100
    else if (lh > 4) and (lh < size * 3) and (lh >= size * 0.8) and (lh < 100) then lh := lh / size * 100;
    n.LineH := lh;
    n.Spacing := JF(O, ['letterSpacing'], 0);
    n.AutoW := JB(O, 'autoWidth', not hasW);
  end;
  // El trazado.
  d := O.Find('points');
  if (d <> nil) and (d.JSONType = jtArray) and (k in [kPath, kLine, kArrow, kPolygon]) then
  begin
    arr := TJSONArray(d);
    if k = kPolygon then n.Kind := kPath;
    SetLength(n.Pts, arr.Count);
    for i := 0 to arr.Count - 1 do
    begin
      FillChar(n.Pts[i], SizeOf(TVPt), 0);
      if (arr[i].JSONType = jtArray) and (TJSONArray(arr[i]).Count >= 2) then
      begin
        n.Pts[i].X := TJSONArray(arr[i])[0].AsFloat;
        n.Pts[i].Y := TJSONArray(arr[i])[1].AsFloat;
      end
      else if arr[i].JSONType = jtObject then
      begin
        n.Pts[i].X := JF(TJSONObject(arr[i]), ['x'], 0);
        n.Pts[i].Y := JF(TJSONObject(arr[i]), ['y'], 0);
      end;
    end;
    n.Closed := JB(O, 'closed', False);
    if not n.Closed then n.Fill.Vis := False;
    NormalizePath(n);
  end
  else if k in [kLine, kArrow] then
  begin
    SetLength(n.Pts, 2);
    FillChar(n.Pts[0], SizeOf(TVPt) * 2, 0);
    n.Pts[1].X := n.W;
    n.Pts[1].Y := JF(O, ['height', 'h'], 0);
    n.H := n.Pts[1].Y;
  end;
  // Diseño automático.
  d := O.Find('layout');
  if (d <> nil) and (k in [kFrame, kComponent]) then
  begin
    if d.JSONType = jtObject then
    begin
      lay := TJSONObject(d);
      t := LowerCase(JS(lay, ['direction', 'mode'], 'vertical'));
      if (t = 'horizontal') or (t = 'row') then n.Layout := 1 else n.Layout := 2;
      n.Gap := JF(lay, ['gap', 'spacing', 'itemSpacing'], 0);
      n.Pad := JF(lay, ['padding'], 0);
      t := LowerCase(JS(lay, ['align', 'alignItems'], 'start'));
      if t = 'center' then n.LAlign := 1 else if (t = 'end') or (t = 'flex-end') then n.LAlign := 2;
      n.Hug := JB(lay, 'hug', False);
    end
    else if d.JSONType = jtString then
    begin
      t := LowerCase(d.AsString);
      if (t = 'horizontal') or (t = 'row') then n.Layout := 1
      else if (t = 'vertical') or (t = 'column') then n.Layout := 2;
    end;
  end;
  // Lo que se resuelve al final: enlaces e instancias.
  if (O.Find('link') <> nil) or (O.Find('onClick') <> nil) or (k = kInstance) then
  begin
    SetLength(JPend, Length(JPend) + 1);
    JPend[High(JPend)].N := n;
    JPend[High(JPend)].Link := JS(O, ['link', 'onClick', 'navigate'], '');
    JPend[High(JPend)].Anim := LowerCase(JS(O, ['animation', 'transition'], 'dissolve'));
    JPend[High(JPend)].Comp := JS(O, ['component', 'componentName', 'of'], '');
    d := O.Find('overrides');
    if (d <> nil) and (d.JSONType = jtObject) then JPend[High(JPend)].Over := TJSONObject(d)
    else JPend[High(JPend)].Over := nil;
  end;
  if k in [kFrame, kComponent] then JNames.AddObject(n.Name, n);
  // Los hijos.
  d := O.Find('children');
  if (d <> nil) and (d.JSONType = jtArray) then
  begin
    arr := TJSONArray(d);
    for i := 0 to arr.Count - 1 do
      if arr[i].JSONType = jtObject then
        if k = kGroup then JNode(TJSONObject(arr[i]), Par, n.X, n.Y)
        else JNode(TJSONObject(arr[i]), n, 0, 0);
    if k = kGroup then
    begin
      // Los hijos de un grupo van en el padre del grupo; luego se meten.
      for i := Par.Count - 1 downto 0 do
        if (Par.Kid(i) <> n) and (Par.Kid(i).Id > n.Id) then
        begin
          t := '';
          Reparent(Par.Kid(i), n, 0);
        end;
    end;
  end;
end;

procedure ResolvePending;
var
  i, j, a: Integer;
  p: TPending;
  t, main, kid: TNode;
  L: TFPList;
begin
  for i := 0 to High(JPend) do
  begin
    p := JPend[i];
    if p.N.Kind = kInstance then
    begin
      main := nil;
      j := JNames.IndexOf(p.Comp);
      if j >= 0 then main := TNode(JNames.Objects[j]);
      if (main <> nil) and (main.Kind = kComponent) then
      begin
        p.N.CompId := main.Id;
        p.N.Radius := main.Radius;
        if (p.N.W = 100) and (p.N.H = 100) then
        begin
          p.N.W := main.W;
          p.N.H := main.H;
        end;
        if p.N.Name = KindLabel(kInstance) + ' ' + IntToStr(NameCount[kInstance]) then p.N.Name := main.Name;
        if p.Over <> nil then
        begin
          L := TFPList.Create;
          try
            Flatten(main, L, False);
            for a := 0 to p.Over.Count - 1 do
              for j := 0 to L.Count - 1 do
              begin
                kid := TNode(L[j]);
                if (kid.Kind = kText) and ((kid.Name = p.Over.Names[a]) or (NodeName(kid) = p.Over.Names[a])) then
                  p.N.Over.Values[IntToStr(kid.Id)] := p.Over.Items[a].AsString;
              end;
          finally
            L.Free;
          end;
        end;
      end
      else p.N.Kind := kFrame;
    end;
    if p.Link <> '' then
    begin
      j := JNames.IndexOf(p.Link);
      if j >= 0 then
      begin
        t := TNode(JNames.Objects[j]);
        p.N.Link := t.Id;
        if Pos('dissolve', p.Anim) > 0 then p.N.Anim := 1
        else if Pos('left', p.Anim) > 0 then p.N.Anim := 2
        else if Pos('right', p.Anim) > 0 then p.N.Anim := 3
        else if Pos('up', p.Anim) > 0 then p.N.Anim := 4
        else if Pos('push', p.Anim) > 0 then p.N.Anim := 5
        else p.N.Anim := 0;
      end;
    end;
  end;
end;

{ Lee un diseño en JSON (el de la plantilla, aunque venga con texto alrededor). }
function ImportJson(const Txt: string; out Msg: string): Boolean;
var
  s: string;
  a, b, i, j, n0, made, firstPage: Integer;
  data, d: TJSONData;
  root: TJSONObject;
  jpages, arr: TJSONArray;
  pg: TPage;
  pgO: TJSONObject;
  before: Integer;
  dx, minx: Double;
  tops: TFPList;
  t: string;
begin
  Result := False;
  Msg := tx_AI_BAD;
  s := Txt;
  a := Pos('{', s);
  b := Pos('[', s);
  if (b > 0) and ((a = 0) or (b < a)) then a := b;
  if a = 0 then Exit;
  b := Length(s);
  while (b > a) and not (s[b] in ['}', ']']) do Dec(b);
  s := Copy(s, a, b - a + 1);
  try
    data := GetJSON(s);
  except
    Exit;
  end;
  JNames := TStringList.Create;
  JPend := nil;
  tops := TFPList.Create;
  try
    Snap;
    made := 0;
    firstPage := -1;
    // Los componentes ya existentes también valen para las instancias.
    arr := nil;
    with AllComponents do
    try
      for i := 0 to Count - 1 do JNames.AddObject(TNode(Items[i]).Name, TNode(Items[i]));
    finally
      Free;
    end;
    jpages := nil;
    root := nil;
    if data.JSONType = jtObject then
    begin
      root := TJSONObject(data);
      d := root.Find('jpages');
      if (d <> nil) and (d.JSONType = jtArray) then jpages := TJSONArray(d);
    end;
    if jpages <> nil then
    begin
      for i := 0 to jpages.Count - 1 do
      begin
        if jpages[i].JSONType <> jtObject then Continue;
        pgO := TJSONObject(jpages[i]);
        // Si la página actual está vacía, la primera va en ella.
        if (i = 0) and (Page.Root.Count = 0) then pg := Page
        else
        begin
          pg := TPage.Create(JS(pgO, ['name'], tx_PAGE + ' ' + IntToStr(Pages.Count + 1)));
          Pages.Add(pg);
        end;
        if pg = Page then pg.Name := JS(pgO, ['name'], pg.Name);
        if firstPage < 0 then firstPage := Pages.IndexOf(pg);
        t := JS(pgO, ['background', 'bg'], '');
        if t <> '' then pg.Bg := JColorStr(t, 0);
        d := pgO.Find('frames');
        if d = nil then d := pgO.Find('children');
        if (d <> nil) and (d.JSONType = jtArray) then
        begin
          arr := TJSONArray(d);
          for j := 0 to arr.Count - 1 do
            if arr[j].JSONType = jtObject then
            begin
              JNode(TJSONObject(arr[j]), pg.Root, 0, 0);
              Inc(made);
            end;
        end;
      end;
    end
    else
    begin
      // Unos marcos o una capa sola: en la página actual, a la derecha.
      before := Page.Root.Count;
      dx := 0;
      if before > 0 then dx := FreeSpot.X;
      arr := nil;
      if data.JSONType = jtArray then arr := TJSONArray(data)
      else if root <> nil then
      begin
        d := root.Find('frames');
        if d = nil then d := root.Find('children');
        if (d <> nil) and (d.JSONType = jtArray) then arr := TJSONArray(d);
      end;
      if arr <> nil then
      begin
        for j := 0 to arr.Count - 1 do
          if arr[j].JSONType = jtObject then
          begin
            JNode(TJSONObject(arr[j]), Page.Root, 0, 0);
            Inc(made);
          end;
      end
      else if (root <> nil) and (root.Find('type') <> nil) then
      begin
        JNode(root, Page.Root, 0, 0);
        Inc(made);
      end;
      if dx <> 0 then
      begin
        minx := 1e30;
        for j := before to Page.Root.Count - 1 do minx := Min(minx, Page.Root.Kid(j).X);
        for j := before to Page.Root.Count - 1 do MoveNode(Page.Root.Kid(j), dx - minx, 0);
      end;
      Sel.Clear;
      for j := before to Page.Root.Count - 1 do Sel.Add(Page.Root.Kid(j));
    end;
    ResolvePending;
    NormalizeAll;
    if made = 0 then
    begin
      Msg := tx_AI_EMPTY;
      Exit;
    end;
    if firstPage >= 0 then
    begin
      PageIx := firstPage;
      Sel.Clear;
      n0 := 0;
      for j := 0 to Page.Root.Count - 1 do
        if IsBox(Page.Root.Kid(j)) and (Page.Root.Kid(j).Kind <> kComponent) then
        begin
          if (Page.StartId = 0) and (n0 = 0) then
          begin
            for i := 0 to High(JPend) do
              if (JPend[i].N.Link > 0) and (TopFrame(JPend[i].N) = Page.Root.Kid(j)) then
              begin
                Page.StartId := Page.Root.Kid(j).Id;
                Break;
              end;
          end;
          Inc(n0);
        end;
    end;
    Msg := Format(tx_AI_DONE, [made]);
    Result := True;
  finally
    tops.Free;
    FreeAndNil(JNames);
    JPend := nil;
    data.Free;
  end;
end;

// ======================================================== la presentación
var
  PlayFrame: TNode = nil;
  PlayPrev: TNode = nil;
  PlayAnim: Integer = 0;
  PlayDur: Integer = 300;
  PlayStart: QWord = 0;
  PlayFlash: QWord = 0;
  PlayHist: TFPList = nil;

function FirstFrame: TNode;
var
  i: Integer;
begin
  Result := FindNode(Page.StartId);
  if (Result <> nil) and (PageOfNode(Result) = PageIx) then Exit;
  for i := 0 to Page.Root.Count - 1 do
    if (Page.Root.Kid(i).Kind = kFrame) and Page.Root.Kid(i).Visible then Exit(Page.Root.Kid(i));
  Result := nil;
end;

procedure StartPlay;
begin
  if EditId <> '' then CommitEdit;
  PlayFrame := FirstFrame;
  if PlayFrame = nil then
  begin
    Say(tx_NO_FRAMES);
    Exit;
  end;
  if PlayHist = nil then PlayHist := TFPList.Create;
  PlayHist.Clear;
  PlayPrev := nil;
  Playing := True;
  PickOpen := False;
end;

procedure StopPlay;
begin
  Playing := False;
  PlayPrev := nil;
end;

function PlayProgress: Double;
begin
  if (PlayPrev = nil) or (PlayDur <= 0) then Exit(1);
  Result := EnsureRange((Now64 - PlayStart) / PlayDur, 0, 1);
  // ease-out
  Result := 1 - Power(1 - Result, 3);
end;

procedure GoFrame(T: TNode; Anim, Dur: Integer; Back: Boolean = False);
begin
  if (T = nil) or (T = PlayFrame) then Exit;
  if not Back then PlayHist.Add(PlayFrame);
  PlayPrev := PlayFrame;
  PlayFrame := T;
  PlayAnim := Anim;
  PlayDur := Dur;
  if Anim = 0 then PlayPrev := nil;
  PlayStart := Now64;
end;

function PlayScale(F: TNode): Double;
begin
  Result := Min(Min((WinW - 80) / Max(1, F.W), (WinH - 44 - 50) / Max(1, F.H)), 1);
end;

procedure DrawPlay;
var
  sc, fx, fy, t, ox, px: Double;
  L: TFPList;
  i: Integer;
  n: TNode;
  b, fb: TRectF;
  old: TRect;
  flash: Boolean;
begin
  URect(0, 0, WinW, WinH, $FF0B0C0F);
  // La barra de arriba.
  URect(0, 0, WinW, 44, $FF16181D);
  if Hov('playexit') then URound(10, 8, 150, 28, 7, $FF2C2F39);
  Icon('chevleft', 24, 22, $FFE8EAF0, 12);
  UText(32, 14, tx_BACK_TO_EDITOR, 12, $FFE8EAF0);
  AddHit(10, 8, 150, 28, 'playexit');
  if PlayFrame <> nil then UTextIn(0, 0, WinW, 44, PlayFrame.Name, 12.5, $FFE8EAF0, True, 1);
  if Hov('playrestart') then URound(WinW - 130, 8, 120, 28, 7, $FF2C2F39);
  UTextIn(WinW - 130, 8, 120, 28, tx_RESTART, 12, $FFE8EAF0, False, 1);
  AddHit(WinW - 130, 8, 120, 28, 'playrestart');
  if (PlayHist <> nil) and (PlayHist.Count > 0) then
  begin
    if Hov('playback') then URound(WinW - 230, 8, 92, 28, 7, $FF2C2F39);
    UTextIn(WinW - 230, 8, 92, 28, tx_GO_BACK, 12, $FFE8EAF0, False, 1);
    AddHit(WinW - 230, 8, 92, 28, 'playback');
  end;
  UTextIn(0, WinH - 30, WinW, 24, tx_PLAY_HINT, 11, $FF8A909C, False, 1);
  if PlayFrame = nil then Exit;
  sc := PlayScale(PlayFrame);
  fx := (WinW - PlayFrame.W * sc) / 2;
  fy := 44 + (WinH - 44 - 40 - PlayFrame.H * sc) / 2;
  FillPoly(RRectPoly((fx) * S, (fy + 10) * S, PlayFrame.W * sc * S, PlayFrame.H * sc * S, 6 * S), $FF000000, 0.35);
  PushClip(fx, fy, PlayFrame.W * sc, PlayFrame.H * sc, old);
  t := PlayProgress;
  if (PlayPrev <> nil) and (t < 1) then
  begin
    ox := 0;
    px := 0;
    case PlayAnim of
      2: ox := (1 - t) * PlayFrame.W * sc;
      3: ox := -(1 - t) * PlayFrame.W * sc;
      5: begin ox := (1 - t) * PlayFrame.W * sc; px := -t * PlayFrame.W * sc; end;
    end;
    DrawStandalone(PlayPrev, (fx + px) * S, fy * S, sc * S);
    if PlayAnim = 4 then DrawStandalone(PlayFrame, fx * S, (fy + (1 - t) * PlayFrame.H * sc) * S, sc * S)
    else if PlayAnim = 1 then DrawStandalone(PlayFrame, fx * S, fy * S, sc * S, t)
    else DrawStandalone(PlayFrame, (fx + ox) * S, fy * S, sc * S);
  end
  else
  begin
    PlayPrev := nil;
    DrawStandalone(PlayFrame, fx * S, fy * S, sc * S);
  end;
  // Las zonas activas.
  flash := (PlayFlash > 0) and (Now64 - PlayFlash < 600);
  if PlayPrev = nil then
  begin
    L := TFPList.Create;
    try
      Flatten(PlayFrame, L, True);
      fb := WorldBox(PlayFrame);
      for i := 0 to L.Count - 1 do
      begin
        n := TNode(L[i]);
        if (n.Link = 0) or not n.Visible then Continue;
        b := WorldBox(n);
        if flash then
          URound(fx + (b.L - fb.L) * sc, fy + (b.T - fb.T) * sc, (b.R - b.L) * sc, (b.B - b.T) * sc, 4, CProto, 0.35);
        AddHit(fx + (b.L - fb.L) * sc, fy + (b.T - fb.T) * sc, (b.R - b.L) * sc, (b.B - b.T) * sc, 'hot:' + IntToStr(n.Id));
      end;
    finally
      L.Free;
    end;
  end;
  PopClip(old);
end;

procedure PlayClick;
var
  act: string;
  n: TNode;
begin
  act := HitAt(MouseX, MouseY);
  if act = 'playexit' then StopPlay
  else if act = 'playrestart' then StartPlay
  else if act = 'playback' then
  begin
    if PlayHist.Count > 0 then
    begin
      n := TNode(PlayHist[PlayHist.Count - 1]);
      PlayHist.Delete(PlayHist.Count - 1);
      GoFrame(n, 1, 250, True);
    end;
  end
  else if Copy(act, 1, 4) = 'hot:' then
  begin
    n := FindNode(StrToIntDef(Copy(act, 5, 12), 0));
    if n <> nil then GoFrame(FindNode(n.Link), n.Anim, n.Dur);
  end
  else PlayFlash := Now64;
end;

// ============================================================ las acciones
var
  MainForm: TForm1 = nil;
  Popup: TPopupMenu = nil;

function MenuLabel(const Path: string): string;
var
  i: Integer;
begin
  Result := Path;
  for i := Length(Path) downto 1 do
    if Path[i] = '/' then Exit(Copy(Path, i + 1, MaxInt));
end;

procedure ShowPopup(const Caps, Acts: array of string);
var
  i: Integer;
  it: TMenuItem;
  p: TPoint;
begin
  if (MainForm = nil) or not MainForm.Visible then Exit;
  if Popup = nil then Popup := TPopupMenu.Create(MainForm);
  Popup.Items.Clear;
  for i := 0 to High(Caps) do
  begin
    it := TMenuItem.Create(Popup);
    it.Caption := Caps[i];
    if i <= High(Acts) then it.Hint := Acts[i];
    if Caps[i] <> '-' then it.OnClick := @MainForm.PopupPick;
    Popup.Items.Add(it);
  end;
  p := Mouse.CursorPos;
  Popup.PopUp(p.X, p.Y);
end;

procedure BuildSample; forward;
procedure FitView; forward;

function FieldValue(const Id: string): string;
var
  k: Integer;
  n: TNode;
begin
  Result := '';
  if Copy(Id, 1, 5) = 'page:' then
  begin
    k := StrToIntDef(Copy(Id, 6, 9), 0);
    if k < Pages.Count then Result := PageN(k).Name;
    Exit;
  end;
  if Copy(Id, 1, 8) = 'comment:' then
  begin
    k := StrToIntDef(Copy(Id, 9, 9), 0);
    if k < Comments.Count then Result := TComment(Comments[k]).Text;
    Exit;
  end;
  if Copy(Id, 1, 6) = 'sname:' then
  begin
    k := StrToIntDef(Copy(Id, 7, 9), 0);
    if k < Styles.Count then Result := Styles.Names[k];
    Exit;
  end;
  if Id = 'pagebg' then Exit(HexOf(PageBg(Page)));
  if Id = 'pickhex' then Exit(HexOf(PickColor));
  if Sel.Count = 0 then Exit;
  n := SelN(0);
  if Id = 'name' then Result := NodeName(n)
  else if Id = 'fillhex' then Result := HexOf(FillC1(n.Fill))
  else if Id = 'fill2hex' then Result := HexOf(n.Fill.C2)
  else if Id = 'strokehex' then Result := HexOf(FillC1(n.Stroke))
  else if IsNumId(Id) then Result := NumStr(GetNum(n, Id));
end;

procedure SelToggle(const What: string);
var
  i: Integer;
  n: TNode;
  v: Boolean;
begin
  if Sel.Count = 0 then Exit;
  Snap;
  n := SelN(0);
  if What = 'clip' then v := not n.Clip
  else if What = 'hug' then v := not n.Hug
  else if What = 'autow' then v := not n.AutoW
  else if What = 'bold' then v := not n.Bold
  else if What = 'italic' then v := not n.Italic
  else if What = 'fillfit' then v := not n.Fill.Fit
  else if What = 'dash' then v := not n.Dash
  else if What = 'shadow' then v := not n.ShOn
  else if What = 'strokeon' then v := not n.Stroke.Vis
  else if What = 'vis:fill' then v := not n.Fill.Vis
  else if What = 'vis:stroke' then v := not n.Stroke.Vis
  else if What = 'hide' then v := not n.Visible
  else if What = 'lock' then v := not n.Locked
  else Exit;
  for i := 0 to Sel.Count - 1 do
  begin
    n := SelN(i);
    if What = 'clip' then n.Clip := v
    else if What = 'hug' then n.Hug := v
    else if What = 'autow' then n.AutoW := v
    else if What = 'bold' then n.Bold := v
    else if What = 'italic' then n.Italic := v
    else if What = 'fillfit' then n.Fill.Fit := v
    else if What = 'dash' then n.Dash := v
    else if What = 'shadow' then n.ShOn := v
    else if (What = 'strokeon') or (What = 'vis:stroke') then n.Stroke.Vis := v
    else if What = 'vis:fill' then n.Fill.Vis := v
    else if What = 'hide' then n.Visible := v
    else if What = 'lock' then n.Locked := v;
  end;
  PropsChanged;
end;

procedure ToggleAuto;
var
  n, f: TNode;
  L: TFPList;
  b: TRectF;
  i, j: Integer;
  t: Pointer;
begin
  n := One;
  if (n <> nil) and (n.Kind in [kFrame, kComponent]) then
  begin
    Snap;
    if n.Layout <> 0 then n.Layout := 0
    else
    begin
      b := RF(0, 0, 0, 0);
      if n.Count > 1 then
      begin
        b := RF(1e9, 1e9, -1e9, -1e9);
        for i := 0 to n.Count - 1 do b := Union(b, BoxIn(n.Kid(i)));
      end;
      if (b.R - b.L) >= (b.B - b.T) then n.Layout := 1 else n.Layout := 2;
      n.Gap := 10;
      n.Pad := 16;
      // En el orden en que se ven.
      for i := 0 to n.Count - 1 do
        for j := i + 1 to n.Count - 1 do
          if ((n.Layout = 1) and (n.Kid(j).X < n.Kid(i).X)) or ((n.Layout = 2) and (n.Kid(j).Y < n.Kid(i).Y)) then
          begin
            t := n.Kids[i]; n.Kids[i] := n.Kids[j]; n.Kids[j] := t;
          end;
    end;
    PropsChanged;
    Exit;
  end;
  if Sel.Count = 0 then Exit;
  Snap;
  b := SelBox;
  f := WrapSel(kFrame);
  if f = nil then Exit;
  f.Fill.Vis := False;
  f.Name := tx_AUTOLAYOUT;
  if (b.R - b.L) >= (b.B - b.T) then f.Layout := 1 else f.Layout := 2;
  f.Gap := 10;
  f.Hug := True;
  L := TFPList.Create;
  try
    for i := 0 to f.Count - 1 do
      for j := i + 1 to f.Count - 1 do
        if ((f.Layout = 1) and (f.Kid(j).X < f.Kid(i).X)) or ((f.Layout = 2) and (f.Kid(j).Y < f.Kid(i).Y)) then
        begin
          t := f.Kids[i]; f.Kids[i] := f.Kids[j]; f.Kids[j] := t;
        end;
  finally
    L.Free;
  end;
  PropsChanged;
end;

procedure NewDoc;
begin
  ClearDoc;
  Pages.Add(TPage.Create(tx_PAGE + ' 1'));
  DocName := '';
  FileName := '';
  Dirty := False;
  UndoL.Clear;
  RedoL.Clear;
  Sel.Clear;
  Scope := nil;
  HoverNode := nil;
  EditId := '';
  Zoom := 1;
  PanX := 120;
  PanY := 100;
end;

procedure SaveTo(const Fn: string);
begin
  try
    WriteText(Fn, DocText);
    FileName := Fn;
    DocName := ChangeFileExt(ExtractFileName(Fn), '');
    Dirty := False;
    Say(tx_SAVED);
  except
    on E: Exception do ShowMessage(tx_ERR_SAVE + LineEnding + E.Message);
  end;
end;

function FontChoices: TStringList;
const
  Common: array[0..19] of string = ('Inter', 'Helvetica Neue', 'Helvetica', 'Arial', 'Avenir Next',
    'Futura', 'Gill Sans', 'Georgia', 'Times New Roman', 'Palatino', 'Courier New', 'Menlo',
    'Roboto', 'Open Sans', 'Montserrat', 'Poppins', 'Segoe UI', 'Verdana', 'Trebuchet MS', 'Impact');
var
  i: Integer;
begin
  Result := TStringList.Create;
  for i := 0 to High(Common) do
    if Screen.Fonts.IndexOf(Common[i]) >= 0 then Result.Add(Common[i]);
  if Result.Count = 0 then
    for i := 0 to Min(25, Screen.Fonts.Count - 1) do Result.Add(Screen.Fonts[i]);
end;

procedure ExportWith(Fmt: Integer);
var
  fn: string;
begin
  if Sel.Count = 0 then
  begin
    Say(tx_SELECT_FIRST);
    Exit;
  end;
  if MainForm = nil then Exit;
  if Fmt = 1 then
  begin
    MainForm.DlgExport.FilterIndex := 2;
    MainForm.DlgExport.FileName := NodeName(SelN(0)) + '.svg';
  end
  else
  begin
    MainForm.DlgExport.FilterIndex := 1;
    MainForm.DlgExport.FileName := NodeName(SelN(0)) + '.png';
  end;
  if not MainForm.DlgExport.Execute then Exit;
  fn := MainForm.DlgExport.FileName;
  if ExtractFileExt(fn) = '' then
    if MainForm.DlgExport.FilterIndex = 2 then fn := fn + '.svg' else fn := fn + '.png';
  try
    if LowerCase(ExtractFileExt(fn)) = '.svg' then WriteText(fn, SvgDoc)
    else ExportPNG(fn, ExportScale);
    Say(Format(tx_EXPORTED, [ExtractFileName(fn)]));
  except
    on E: Exception do ShowMessage(tx_ERR_SAVE + LineEnding + E.Message);
  end;
end;

function SelJson: string;
var
  o: TJSONObject;
  arr: TJSONArray;
  L: TFPList;
  i: Integer;
begin
  o := TJSONObject.Create;
  L := TopSel;
  try
    o.Add('_instructions', JStr(tx_AI_EDIT_PROMPT));
    arr := TJSONArray.Create;
    for i := 0 to L.Count - 1 do arr.Add(NodeJson(TNode(L[i]), 0, 0));
    o.Add('frames', arr);
    Result := o.FormatJSON([], 2);
  finally
    L.Free;
    o.Free;
  end;
end;

procedure RunAct(const Act: string);
var
  n, t: TNode;
  i, k: Integer;
  a, b: string;
  caps, acts: array of string;
  L: TStringList;
  FL: TFPList;
  c: LongWord;
  f: TStringArray;
  msg: string;
  cm: TComment;
  function Num(const P: string): Integer;
  begin
    Result := StrToIntDef(Copy(Act, Length(P) + 1, 12), -1);
  end;
  function Starts(const P: string): Boolean;
  begin
    Result := Copy(Act, 1, Length(P)) = P;
  end;
begin
  if Starts('tool:') then
  begin
    if PenNode <> nil then FinishPen;
    if TTool(Num('tool:')) = tlImage then RunAct('import')
    else SetTool(TTool(Num('tool:')));
  end
  else if Starts('mode:') then
  begin
    Mode := Num('mode:');
    SetTool(tlMove);
    InspScroll := 0;
  end
  else if Act = 'm0' then RunAct('mode:0')
  else if Act = 'm1' then RunAct('mode:1')
  else if Act = 'm2' then RunAct('mode:2')
  else if Starts('pagerename:') then BeginEdit('page:' + IntToStr(Num('pagerename:')), PageN(Num('pagerename:')).Name)
  else if Starts('page:') then
  begin
    k := Num('page:');
    if (k >= 0) and (k < Pages.Count) and (k <> PageIx) then
    begin
      PageIx := k;
      ClearSel;
      Scope := nil;
      HoverNode := nil;
      ActiveComment := -1;
      ZoomToBox(PageBox, 1);
    end;
  end
  else if Act = 'pageadd' then
  begin
    Snap;
    Pages.Add(TPage.Create(tx_PAGE + ' ' + IntToStr(Pages.Count + 1)));
    PageIx := Pages.Count - 1;
    ClearSel;
    Zoom := 1; PanX := 120; PanY := 100;
  end
  else if Starts('f:') then
  begin
    a := Copy(Act, 3, MaxInt);
    if (Sel.Count = 0) and (Pos(':', a) = 0) and (a <> 'pagebg') and (a <> 'pickhex') then Exit;
    BeginEdit(a, FieldValue(a));
  end
  else if Starts('rename:') then
  begin
    n := FindNode(Num('rename:'));
    if n <> nil then BeginEdit('name:' + IntToStr(n.Id), NodeName(n));
  end
  else if Starts('layershift:') then
  begin
    n := FindNode(Num('layershift:'));
    if n <> nil then ToggleSel(n);
  end
  else if Starts('layer:') then
  begin
    n := FindNode(Num('layer:'));
    if n <> nil then
    begin
      SelectOnly(n);
      Scope := n.Parent;
    end;
  end
  else if Starts('exp:') then
  begin
    n := FindNode(Num('exp:'));
    if n <> nil then n.Open := not n.Open;
  end
  else if Starts('leye:') or Starts('llock:') then
  begin
    n := FindNode(StrToIntDef(Copy(Act, Pos(':', Act) + 1, 12), 0));
    if n = nil then Exit;
    Snap;
    if Starts('leye:') then n.Visible := not n.Visible else n.Locked := not n.Locked;
    if n.Locked and IsSel(n) then Sel.Remove(n);
  end
  else if Starts('flabel:') then
  begin
    n := FindNode(Num('flabel:'));
    if n <> nil then SelectOnly(n);
  end
  else if Starts('rtab:') then
  begin
    RightTab := Num('rtab:');
    LayerScroll := 0;
  end
  else if Starts('asset:') then InsertInstance(FindNode(Num('asset:')))
  else if Starts('cmt:') then
  begin
    k := Num('cmt:');
    if (k < 0) or (k >= Comments.Count) then Exit;
    cm := TComment(Comments[k]);
    PageIx := EnsureRange(cm.Page, 0, Pages.Count - 1);
    ClearSel;
    ActiveComment := k;
    PanX := (CX1 - CX0) / 2 - cm.X * Zoom;
    PanY := (CY1 - CY0) / 2 - cm.Y * Zoom;
  end
  else if Starts('pin:') then
  begin
    k := Num('pin:');
    if ActiveComment = k then ActiveComment := -1 else ActiveComment := k;
  end
  else if Starts('cmtdone:') then
  begin
    k := Num('cmtdone:');
    if (k >= 0) and (k < Comments.Count) then TComment(Comments[k]).Done := True;
    ActiveComment := -1;
    Dirty := True;
    Say(tx_RESOLVED);
  end
  else if Starts('cmtdel:') then
  begin
    k := Num('cmtdel:');
    if (k >= 0) and (k < Comments.Count) then
    begin
      TComment(Comments[k]).Free;
      Comments.Delete(k);
    end;
    ActiveComment := -1;
    EditId := '';
    Dirty := True;
  end
  else if Starts('align:') then Align(Num('align:'))
  else if Starts('dist:') then Distribute(Num('dist:') = 1)
  else if (Act = 'clip') or (Act = 'hug') or (Act = 'autow') or (Act = 'bold') or (Act = 'italic') or
    (Act = 'fillfit') or (Act = 'dash') or (Act = 'shadow') or (Act = 'strokeon') or (Act = 'vis:fill') or
    (Act = 'vis:stroke') or (Act = 'hide') or (Act = 'lock') then SelToggle(Act)
  else if Starts('lay:') or Starts('la:') or Starts('tal:') then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    k := StrToIntDef(Copy(Act, Pos(':', Act) + 1, 3), 0);
    for i := 0 to Sel.Count - 1 do
      if Starts('lay:') then SelN(i).Layout := k
      else if Starts('la:') then SelN(i).LAlign := k
      else SelN(i).Align := k;
    PropsChanged;
  end
  else if (Act = 'auto') or (Act = 'autolayout') then ToggleAuto
  else if Act = 'filltype' then ShowPopup([tx_SOLID, tx_LINEAR, tx_IMAGE_FILL], ['filltype:0', 'filltype:1', 'filltype:2'])
  else if Starts('filltype:') then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    for i := 0 to Sel.Count - 1 do
    begin
      SelN(i).Fill.Kind := TFillKind(EnsureRange(Num('filltype:'), 0, 2));
      SelN(i).Fill.Vis := True;
    end;
    if Num('filltype:') = 2 then RunAct('fillimg');
    PropsChanged;
  end
  else if Act = 'fillimg' then
  begin
    if (MainForm = nil) or (Sel.Count = 0) or not MainForm.DlgImage.Execute then Exit;
    Snap;
    for i := 0 to Sel.Count - 1 do
    begin
      SelN(i).Fill.Kind := fkImage;
      SelN(i).Fill.Img := MainForm.DlgImage.FileName;
      SelN(i).Fill.Vis := True;
    end;
  end
  else if Act = 'strokepos' then ShowPopup([tx_INSIDE, tx_CENTER, tx_OUTSIDE], ['strokepos:1', 'strokepos:0', 'strokepos:2'])
  else if Starts('strokepos:') then
  begin
    Snap;
    for i := 0 to Sel.Count - 1 do SelN(i).StrokePos := Num('strokepos:');
  end
  else if Starts('unstyle:') then
  begin
    Snap;
    for i := 0 to Sel.Count - 1 do
      if Act = 'unstyle:fill' then
      begin
        SelN(i).Fill.C1 := FillC1(SelN(i).Fill);
        SelN(i).Fill.Style := '';
      end
      else
      begin
        SelN(i).Stroke.C1 := FillC1(SelN(i).Stroke);
        SelN(i).Stroke.Style := '';
      end;
  end
  else if Starts('stylemenu:') then
  begin
    a := Copy(Act, 11, 20);
    SetLength(caps, Styles.Count + 2);
    SetLength(acts, Styles.Count + 2);
    for i := 0 to Styles.Count - 1 do
    begin
      caps[i] := Styles.Names[i] + '   #' + HexOf(LongWord(StrToInt64Def('$' + Styles.ValueFromIndex[i], 0)));
      acts[i] := 'style:' + a + ':' + IntToStr(i);
    end;
    caps[Styles.Count] := '-';
    acts[Styles.Count] := '';
    caps[Styles.Count + 1] := tx_STYLE_NEW;
    acts[Styles.Count + 1] := 'stylenew:' + a;
    ShowPopup(caps, acts);
  end
  else if Starts('style:') then
  begin
    f := Act.Split([':']);
    if (Length(f) < 3) or (Sel.Count = 0) then Exit;
    k := StrToIntDef(f[2], -1);
    if (k < 0) or (k >= Styles.Count) then Exit;
    Snap;
    for i := 0 to Sel.Count - 1 do
      if f[1] = 'fill' then
      begin
        SelN(i).Fill.Style := Styles.Names[k];
        SelN(i).Fill.Kind := fkSolid;
        SelN(i).Fill.Vis := True;
      end
      else
      begin
        SelN(i).Stroke.Style := Styles.Names[k];
        SelN(i).Stroke.Vis := True;
      end;
  end
  else if Starts('stylenew:') then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    a := Copy(Act, 10, 20);
    if a = 'fill' then c := FillC1(SelN(0).Fill) else c := FillC1(SelN(0).Stroke);
    b := tx_STYLE + ' ' + IntToStr(Styles.Count + 1);
    Styles.Add(b + '=' + IntToHex(c, 8));
    for i := 0 to Sel.Count - 1 do
      if a = 'fill' then SelN(i).Fill.Style := b else SelN(i).Stroke.Style := b;
    BeginEdit('sname:' + IntToStr(Styles.Count - 1), b);
    ClearSel;
  end
  else if Act = 'styleadd' then
  begin
    Snap;
    Styles.Add(tx_STYLE + ' ' + IntToStr(Styles.Count + 1) + '=FF12B886');
  end
  else if Starts('styledel:') then
  begin
    k := Num('styledel:');
    if (k < 0) or (k >= Styles.Count) then Exit;
    Snap;
    c := LongWord(StrToInt64Def('$' + Styles.ValueFromIndex[k], 0));
    FL := TFPList.Create;
    try
      for i := 0 to Pages.Count - 1 do Flatten(PageN(i).Root, FL, False);
      for i := 0 to FL.Count - 1 do
      begin
        n := TNode(FL[i]);
        if n.Fill.Style = Styles.Names[k] then begin n.Fill.C1 := c; n.Fill.Style := ''; end;
        if n.Stroke.Style = Styles.Names[k] then begin n.Stroke.C1 := c; n.Stroke.Style := ''; end;
      end;
    finally
      FL.Free;
    end;
    Styles.Delete(k);
  end
  else if Starts('sname:') then BeginEdit(Act, FieldValue(Act))
  else if Starts('pick:') then
  begin
    Snap;
    OpenPicker(Copy(Act, 6, MaxInt), MouseY);
  end
  else if Act = 'pk:close' then PickOpen := False
  else if Starts('pk:sw:') then
  begin
    c := SetA(LongWord(StrToInt64Def('$' + Copy(Act, 7, 8), 0)), PickA);
    SetTargetColor(PickTarget, c);
    ToHSV(c, PickH, PickS, PickV);
  end
  else if Starts('pickhex:') then
  begin
    c := SetA(HexC(Copy(Act, 9, MaxInt)), PickA);
    SetTargetColor(PickTarget, c);
    ToHSV(c, PickH, PickS, PickV);
  end
  else if Starts('preset:') then
  begin
    k := Num('preset:');
    if (k < 0) or (k > High(Presets)) then Exit;
    f := Presets[k].Split(['|']);
    Snap;
    n := NewNode(kFrame, Page.Root, FreeSpot.X, FreeSpot.Y, StrToIntDef(f[2], 100), StrToIntDef(f[3], 100));
    n.Name := f[1];
    SelectOnly(n);
    SetTool(tlMove);
    ZoomToBox(WorldBox(n), Zoom);
  end
  else if Starts('scale:') then ExportScale := Num('scale:')
  else if Act = 'exportpng' then ExportWith(0)
  else if Act = 'exportsvg' then ExportWith(1)
  else if (Act = 'exportsel') or (Act = 'export') then ExportWith(0)
  else if Act = 'startmenu' then
  begin
    caps := nil; acts := nil;
    for i := 0 to Page.Root.Count - 1 do
      if Page.Root.Kid(i).Kind = kFrame then
      begin
        SetLength(caps, Length(caps) + 1); SetLength(acts, Length(acts) + 1);
        caps[High(caps)] := Page.Root.Kid(i).Name;
        acts[High(acts)] := 'start:' + IntToStr(Page.Root.Kid(i).Id);
      end;
    ShowPopup(caps, acts);
  end
  else if Starts('start:') then
  begin
    Snap;
    Page.StartId := Num('start:');
  end
  else if Act = 'linkmenu' then
  begin
    SetLength(caps, 1); SetLength(acts, 1);
    caps[0] := tx_NONE; acts[0] := 'link:0';
    for i := 0 to Page.Root.Count - 1 do
      if IsBox(Page.Root.Kid(i)) and (Page.Root.Kid(i).Kind <> kComponent) then
      begin
        SetLength(caps, Length(caps) + 1); SetLength(acts, Length(acts) + 1);
        caps[High(caps)] := Page.Root.Kid(i).Name;
        acts[High(acts)] := 'link:' + IntToStr(Page.Root.Kid(i).Id);
      end;
    ShowPopup(caps, acts);
  end
  else if Starts('link:') then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    for i := 0 to Sel.Count - 1 do
    begin
      SelN(i).Link := Num('link:');
      if (SelN(i).Link > 0) and (SelN(i).Anim = 0) then SelN(i).Anim := 1;
    end;
  end
  else if Act = 'animmenu' then
    ShowPopup([tx_ANIM_INSTANT, tx_ANIM_DISSOLVE, tx_ANIM_LEFT, tx_ANIM_RIGHT, tx_ANIM_UP, tx_ANIM_PUSH],
      ['anim:0', 'anim:1', 'anim:2', 'anim:3', 'anim:4', 'anim:5'])
  else if Starts('anim:') then
  begin
    Snap;
    for i := 0 to Sel.Count - 1 do SelN(i).Anim := Num('anim:');
  end
  else if Act = 'unlink' then
  begin
    Snap;
    for i := 0 to Sel.Count - 1 do SelN(i).Link := 0;
  end
  else if Act = 'setstart' then
  begin
    if One = nil then Exit;
    Snap;
    if Page.StartId = One.Id then Page.StartId := 0 else Page.StartId := One.Id;
  end
  else if Starts('lang:') then CodeLang := Num('lang:')
  else if Act = 'copycode' then
  begin
    if One = nil then Exit;
    if CodeLang = 0 then Clipboard.AsText := CssOf(One) else Clipboard.AsText := FlutterOf(One);
    Say(tx_CODE_COPIED);
  end
  else if Act = 'fontmenu' then
  begin
    L := FontChoices;
    try
      SetLength(caps, L.Count); SetLength(acts, L.Count);
      for i := 0 to L.Count - 1 do
      begin
        caps[i] := L[i];
        acts[i] := 'font:' + L[i];
      end;
    finally
      L.Free;
    end;
    ShowPopup(caps, acts);
  end
  else if Starts('font:') then
  begin
    Snap;
    for i := 0 to Sel.Count - 1 do
      if SelN(i).Kind = kText then SelN(i).Font := Copy(Act, 6, MaxInt);
    PropsChanged;
  end
  else if Starts('adopt:') then Adopt(FindNode(Num('adopt:')))
  else if Act = 'dupinplace' then
  begin
    Snap;
    Duplicate(0);
  end
  else if Act = 'playclick' then PlayClick
  else if Act = 'play' then StartPlay
  else if Act = 'theme' then
  begin
    Dark := not Dark;
    ApplyTheme;
  end
  else if Act = 'rulers' then Rulers := not Rulers
  else if Act = 'pixgrid' then PixGrid := not PixGrid
  else if Act = 'snap' then SnapOn := not SnapOn
  else if Act = 'zoommenu' then
    ShowPopup([MenuLabel(tx_MP_ZOOM_IN), MenuLabel(tx_MP_ZOOM_OUT), MenuLabel(tx_MP_ZOOM_100),
      MenuLabel(tx_MP_ZOOM_ALL), MenuLabel(tx_MP_ZOOM_SEL)], ['zin', 'zout', 'z100', 'zall', 'zsel'])
  else if Act = 'zin' then ZoomAt(1.25, (CX0 + CX1) / 2, (CY0 + CY1) / 2)
  else if Act = 'zout' then ZoomAt(0.8, (CX0 + CX1) / 2, (CY0 + CY1) / 2)
  else if Act = 'z100' then ZoomAt(1 / Zoom, (CX0 + CX1) / 2, (CY0 + CY1) / 2)
  else if Act = 'zall' then ZoomToBox(PageBox, 1)
  else if Act = 'zsel' then
  begin
    if Sel.Count > 0 then ZoomToBox(SelBox, 8);
  end
  else if Act = 'aimenu' then
    ShowPopup([MenuLabel(tx_MP_AI_SCHEMA), MenuLabel(tx_MP_AI_SAVE), '-', MenuLabel(tx_MP_AI_PASTE),
      MenuLabel(tx_MP_AI_IMPORT), '-', MenuLabel(tx_MP_AI_EXPORT)],
      ['ai_schema', 'ai_save', '', 'ai_paste', 'ai_import', '', 'ai_export'])
  else if Act = 'ai_schema' then
  begin
    Clipboard.AsText := AiTemplate;
    Say(tx_AI_COPIED);
    if MainForm <> nil then ShowMessage(tx_AI_HOWTO);
  end
  else if Act = 'ai_save' then
  begin
    if (MainForm <> nil) and MainForm.DlgJsonSave.Execute then
    begin
      WriteText(MainForm.DlgJsonSave.FileName, AiTemplate);
      Say(Format(tx_EXPORTED, [ExtractFileName(MainForm.DlgJsonSave.FileName)]));
    end;
  end
  else if Act = 'ai_paste' then
  begin
    if ImportJson(Clipboard.AsText, msg) then ZoomToBox(PageBox, 1)
    else if MainForm <> nil then ShowMessage(msg);
    Say(msg);
  end
  else if Act = 'ai_import' then
  begin
    if (MainForm <> nil) and MainForm.DlgJson.Execute then
    begin
      if ImportJson(ReadText(MainForm.DlgJson.FileName), msg) then ZoomToBox(PageBox, 1)
      else ShowMessage(msg);
      Say(msg);
    end;
  end
  else if (Act = 'ai_export') or (Act = 'aiexport') then
  begin
    if Sel.Count = 0 then begin Say(tx_SELECT_FIRST); Exit; end;
    Clipboard.AsText := SelJson;
    Say(tx_AI_SEL_COPIED);
  end
  else if Act = 'ctxmenu' then
  begin
    if Sel.Count = 0 then
      ShowPopup([MenuLabel(tx_MP_PASTE), MenuLabel(tx_MP_ALL), '-', MenuLabel(tx_MP_AI_PASTE)], ['paste', 'all', '', 'ai_paste'])
    else
      ShowPopup([MenuLabel(tx_MP_COPY), MenuLabel(tx_MP_PASTE), MenuLabel(tx_MP_DUP), MenuLabel(tx_MP_DEL), '-',
        MenuLabel(tx_MP_GROUP), MenuLabel(tx_MP_UNGROUP), MenuLabel(tx_MP_FRAME_SEL), MenuLabel(tx_MP_AUTO), '-',
        MenuLabel(tx_MP_COMP), MenuLabel(tx_MP_DETACH), '-',
        MenuLabel(tx_MP_FRONT), MenuLabel(tx_MP_BOTTOM), '-', MenuLabel(tx_MP_HIDE), MenuLabel(tx_MP_LOCK), '-',
        tx_COPY_CSS, MenuLabel(tx_MP_AI_EXPORT), MenuLabel(tx_MP_EXPORT)],
        ['copy', 'paste', 'dup', 'del', '', 'group', 'ungroup', 'framesel', 'autolayout', '', 'comp', 'detach', '',
         'front', 'bottom', '', 'hide', 'lock', '', 'copycss', 'ai_export', 'export']);
  end
  else if Act = 'copycss' then
  begin
    if One <> nil then Clipboard.AsText := CssOf(One);
    Say(tx_CODE_COPIED);
  end
  // ---- los del menú
  else if Act = 'new' then
  begin
    if Dirty and (MainForm <> nil) and not MainForm.Ask(tx_ASK_DISCARD) then Exit;
    NewDoc;
  end
  else if Act = 'open' then
  begin
    if (MainForm = nil) or not MainForm.DlgOpen.Execute then Exit;
    if Dirty and not MainForm.Ask(tx_ASK_DISCARD) then Exit;
    if LoadDocText(ReadText(MainForm.DlgOpen.FileName)) then
    begin
      FileName := MainForm.DlgOpen.FileName;
      if DocName = '' then DocName := ChangeFileExt(ExtractFileName(FileName), '');
      Dirty := False;
      UndoL.Clear; RedoL.Clear; Sel.Clear;
      ZoomToBox(PageBox, 1);
    end
    else ShowMessage(tx_ERR_OPEN);
  end
  else if Act = 'sample' then
  begin
    if Dirty and (MainForm <> nil) and not MainForm.Ask(tx_ASK_DISCARD) then Exit;
    BuildSample;
    FitView;
  end
  else if Act = 'save' then
  begin
    if FileName = '' then RunAct('saveas') else SaveTo(FileName);
  end
  else if Act = 'saveas' then
  begin
    if MainForm = nil then Exit;
    a := DocName;
    if a = '' then a := tx_UNTITLED;
    MainForm.DlgSave.FileName := a + '.opend';
    if not MainForm.DlgSave.Execute then Exit;
    a := MainForm.DlgSave.FileName;
    if ExtractFileExt(a) = '' then a := a + '.opend';
    SaveTo(a);
  end
  else if Act = 'import' then
  begin
    if (MainForm <> nil) and MainForm.DlgImage.Execute then PlaceImage(MainForm.DlgImage.FileName);
  end
  else if Act = 'quit' then
  begin
    if MainForm <> nil then MainForm.Close;
  end
  else if Act = 'undo' then
  begin
    if EditId = 'text' then CommitEdit;
    if EditId = '' then DoUndo;
  end
  else if Act = 'redo' then
  begin
    if EditId = '' then DoRedo;
  end
  else if Act = 'cut' then
  begin
    if EditId <> '' then
    begin
      Clipboard.AsText := EdSelected;
      EdInsert('');
    end
    else if Sel.Count > 0 then
    begin
      Clipboard.AsText := SelClipText;
      DeleteSel;
    end;
  end
  else if Act = 'copy' then
  begin
    if EditId <> '' then Clipboard.AsText := EdSelected
    else if Sel.Count > 0 then
    begin
      Clipboard.AsText := SelClipText;
      Say(tx_COPIED);
    end;
  end
  else if Act = 'paste' then
  begin
    if EditId = 'text' then EdInsert(Clipboard.AsText)
    else if EditId <> '' then EdInsert(StringReplace(Clipboard.AsText, LineEnding, ' ', [rfReplaceAll]))
    else PasteText(Clipboard.AsText);
  end
  else if Act = 'dup' then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    Duplicate(10);
  end
  else if Act = 'del' then
  begin
    if EditId = '' then DeleteSel;
  end
  else if Act = 'all' then
  begin
    if EditId <> '' then
    begin
      EAnchor := 0;
      ECaret := UTF8Length(EditBuf);
      Exit;
    end;
    t := Page.Root;
    if Scope <> nil then t := Scope
    else if (Sel.Count > 0) and (SelN(0).Parent <> nil) then t := SelN(0).Parent;
    Sel.Clear;
    for i := 0 to t.Count - 1 do
      if t.Kid(i).Visible and not t.Kid(i).Locked then Sel.Add(t.Kid(i));
  end
  else if Act = 'group' then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    WrapSel(kGroup);
  end
  else if Act = 'ungroup' then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    Ungroup;
  end
  else if Act = 'framesel' then
  begin
    if Sel.Count = 0 then Exit;
    Snap;
    WrapSel(kFrame);
  end
  else if Act = 'comp' then MakeComponent
  else if Act = 'detach' then Detach
  else if Act = 'front' then Restack(0)
  else if Act = 'fwd' then Restack(1)
  else if Act = 'back' then Restack(2)
  else if Act = 'bottom' then Restack(3)
  else if Act = 'keys' then ShowMessage(tx_KEYS_TEXT)
  else if Act = 'how' then ShowMessage(tx_HOW_TEXT)
  else if Act = 'about' then ShowMessage(tx_ABOUT_TEXT);
end;

// ====================================================== el ejemplo
var
  SFrame: TNode;

function SText(P: TNode; X, Y: Double; const T: string; Size: Double; C: LongWord;
  Bold: Boolean = False; W: Double = 0; Al: Integer = 0): TNode;
begin
  Result := NewNode(kText, P, X, Y, W, 10);
  Result.Text := T;
  Result.Size := Size;
  Result.Fill.C1 := C;
  Result.Bold := Bold;
  Result.Align := Al;
  Result.AutoW := W <= 0;
  if W > 0 then Result.W := W;
  Result.Name := '';
end;

function SRect(P: TNode; X, Y, W, H, R: Double; C: LongWord; K: TKind = kRect): TNode;
begin
  Result := NewNode(K, P, X, Y, W, H);
  Result.Radius := R;
  Result.Fill.C1 := C;
end;

procedure BuildSample;
var
  pg: TPage;
  splash, login, home, btn, inst, days, chip, card, mood, n, av, row: TNode;
  i: Integer;
  dayL, dayH: array[0..4] of string;
  names, roles: array[0..2] of string;
  cols: array[0..2] of LongWord;
  c: TComment;
begin
  ClearDoc;
  DocName := 'OpenAttendance';
  Styles.Add(tx_S_GREEN + '=FF49D27A');
  Styles.Add(tx_S_INK + '=FF111827');
  Styles.Add(tx_S_GREY + '=FF6B7280');
  Styles.Add(tx_S_BG + '=FFF4F6F9');
  pg := TPage.Create(tx_S_PAGE1);
  Pages.Add(pg);
  PageIx := 0;
  // El componente: el botón principal.
  btn := SRect(pg.Root, 0, 1040, 366, 56, 14, $FF49D27A, kComponent);
  btn.Name := tx_S_BUTTON;
  btn.Fill.Style := tx_S_GREEN;
  btn.ShOn := True; btn.ShX := 0; btn.ShY := 6; btn.ShBlur := 16; btn.ShColor := $5549D27A;
  n := SText(btn, 0, 16, tx_S_BUTTON_T, 17, $FFFFFFFF, True, 366, 1);
  n.Name := tx_S_LABEL;
  // 1. La bienvenida (como la captura de su diseño).
  splash := SRect(pg.Root, 0, 0, 430, 932, 0, $FF49D27A, kFrame);
  splash.Name := 'Splash';
  splash.Fill.Style := tx_S_GREEN;
  n := SText(splash, 0, 382, 'OPTT', 82, $FFFFFFFF, False, 430, 1);
  n.Name := 'OPTT';
  SText(splash, 0, 486, 'openattendance.com', 18, $E6FFFFFF, False, 430, 1);
  splash.Link := 0;
  // 2. Iniciar sesión.
  login := SRect(pg.Root, 530, 0, 430, 932, 0, $FFFFFFFF, kFrame);
  login.Name := tx_S_LOGIN;
  splash.Link := login.Id;
  splash.Anim := 1;
  splash.Dur := 450;
  av := SRect(login, 179, 112, 72, 72, 0, $FF49D27A, kEllipse);
  av.Name := tx_S_LOGO;
  av.Fill.Style := tx_S_GREEN;
  SText(login, 179, 128, 'O', 34, $FFFFFFFF, True, 72, 1);
  SText(login, 32, 226, tx_S_WELCOME, 30, $FF111827, True);
  SText(login, 32, 272, tx_S_WELCOME_SUB, 16, $FF6B7280, False, 366);
  SText(login, 32, 344, tx_S_EMAIL, 13, $FF374151, True);
  n := SRect(login, 32, 366, 366, 54, 14, $FFF4F6F9);
  n.Name := tx_S_EMAIL;
  n.Stroke.Vis := True; n.Stroke.C1 := $FFE3E5EA; n.StrokePos := 1;
  SText(login, 50, 383, 'ana@empresa.com', 16, $FF9CA3AF);
  SText(login, 32, 440, tx_S_PASSWORD, 13, $FF374151, True);
  n := SRect(login, 32, 462, 366, 54, 14, $FFF4F6F9);
  n.Name := tx_S_PASSWORD;
  n.Stroke.Vis := True; n.Stroke.C1 := $FFE3E5EA; n.StrokePos := 1;
  SText(login, 50, 478, '••••••••••', 16, $FF111827);
  inst := NewNode(kInstance, login, 32, 556, 366, 56);
  inst.CompId := btn.Id;
  inst.Name := tx_S_BUTTON;
  inst.Radius := 14;
  inst.Over.Values[IntToStr(n.Id)] := '';
  inst.Over.Clear;
  inst.Over.Values[IntToStr(btn.Kid(0).Id)] := tx_S_ENTER;
  SText(login, 32, 636, tx_S_FORGOT, 14, $FF0E9F6E, True, 366, 1);
  SText(login, 32, 860, tx_S_NO_ACCOUNT, 14, $FF6B7280, False, 366, 1);
  // 3. El panel.
  home := SRect(pg.Root, 1060, 0, 430, 932, 0, $FFF4F6F9, kFrame);
  home.Name := tx_S_HOME;
  home.Fill.Style := tx_S_BG;
  inst.Link := home.Id;
  inst.Anim := 2;
  SText(home, 24, 64, tx_S_HELLO, 28, $FF111827, True);
  SText(home, 24, 104, tx_S_DATE, 15, $FF6B7280);
  av := SRect(home, 358, 62, 48, 48, 0, $FF49D27A, kEllipse);
  av.Name := 'Avatar';
  av.Fill.Kind := fkLinear; av.Fill.C1 := $FF49D27A; av.Fill.C2 := $FF0EA5E9; av.Fill.Angle := 135;
  SText(home, 358, 75, 'AL', 16, $FFFFFFFF, True, 48, 1);
  card := SRect(home, 24, 150, 382, 168, 24, $FF49D27A);
  card.Name := tx_S_TODAY;
  card.Fill.Kind := fkLinear; card.Fill.C1 := $FF49D27A; card.Fill.C2 := $FF0F9F7A; card.Fill.Angle := 135;
  card.ShOn := True; card.ShY := 12; card.ShBlur := 28; card.ShColor := $4D0F9F7A;
  SText(home, 48, 174, tx_S_CHECKIN, 14, $D9FFFFFF, True);
  SText(home, 48, 196, '08:58', 46, $FFFFFFFF, True);
  SText(home, 48, 262, tx_S_OFFICE, 14, $E6FFFFFF);
  n := NewNode(kStar, home, 340, 176, 40, 40);
  n.Fill.C1 := $59FFFFFF;
  n.Name := tx_S_BADGE;
  SText(home, 24, 346, tx_S_WEEK, 18, $FF111827, True);
  days := NewNode(kFrame, home, 24, 382, 382, 84);
  days.Name := tx_S_DAYS;
  days.Fill.Vis := False;
  days.Layout := 1; days.Gap := 8; days.Hug := True; days.Clip := False;
  dayL[0] := tx_S_D1; dayL[1] := tx_S_D2; dayL[2] := tx_S_D3; dayL[3] := tx_S_D4; dayL[4] := tx_S_D5;
  dayH[0] := '8h 05'; dayH[1] := '7h 58'; dayH[2] := '8h 12'; dayH[3] := '4h 31'; dayH[4] := '—';
  for i := 0 to 4 do
  begin
    chip := SRect(days, 0, 0, 70, 84, 16, $FFFFFFFF, kFrame);
    chip.Name := dayL[i];
    chip.Stroke.Vis := True; chip.Stroke.C1 := $FFE3E5EA; chip.StrokePos := 1;
    if i = 3 then
    begin
      chip.Fill.C1 := $FF111827;
      chip.Stroke.Vis := False;
      SText(chip, 0, 16, dayL[i], 13, $FF9CA3AF, True, 70, 1);
      SText(chip, 0, 44, dayH[i], 15, $FFFFFFFF, True, 70, 1);
    end
    else
    begin
      SText(chip, 0, 16, dayL[i], 13, $FF9CA3AF, True, 70, 1);
      SText(chip, 0, 44, dayH[i], 15, $FF111827, True, 70, 1);
    end;
  end;
  SText(home, 24, 494, tx_S_TEAM, 18, $FF111827, True);
  names[0] := 'Laura Gómez'; names[1] := 'Diego Martín'; names[2] := 'Sofía Ruiz';
  roles[0] := tx_S_R1; roles[1] := tx_S_R2; roles[2] := tx_S_R3;
  cols[0] := $FFF59E0B; cols[1] := $FF6366F1; cols[2] := $FFEC4899;
  for i := 0 to 2 do
  begin
    row := SRect(home, 24, 530 + i * 72, 382, 62, 16, $FFFFFFFF);
    row.Name := names[i];
    SRect(home, 40, 543 + i * 72, 36, 36, 0, cols[i], kEllipse).Name := 'Avatar';
    SText(home, 40, 551 + i * 72, Initials(names[i]), 13, $FFFFFFFF, True, 36, 1);
    SText(home, 88, 541 + i * 72, names[i], 15, $FF111827, True);
    SText(home, 88, 562 + i * 72, roles[i], 13, $FF6B7280);
    if i < 2 then
    begin
      SRect(home, 318, 548 + i * 72, 74, 26, 13, $FFDCFCE7).Name := tx_S_IN;
      SText(home, 318, 553 + i * 72, tx_S_IN, 12, $FF15803D, True, 74, 1);
    end
    else
    begin
      SRect(home, 318, 548 + i * 72, 74, 26, 13, $FFFEF3C7).Name := tx_S_LATE;
      SText(home, 318, 553 + i * 72, tx_S_LATE, 12, $FFB45309, True, 74, 1);
    end;
  end;
  inst := NewNode(kInstance, home, 32, 812, 366, 56);
  inst.CompId := btn.Id;
  inst.Name := tx_S_BUTTON;
  inst.Radius := 14;
  inst.Over.Values[IntToStr(btn.Kid(0).Id)] := tx_S_CHECKOUT;
  inst.Link := login.Id;
  inst.Anim := 3;
  pg.StartId := splash.Id;
  // El comentario.
  c := TComment.Create;
  c.Page := 0; c.X := 530 + 380; c.Y := 556;
  c.Who := 'Laura Gómez';
  c.When := '12/11 10:24';
  c.Text := tx_S_COMMENT;
  Comments.Add(c);
  // 2. Ideas: formas, trazados, degradados.
  pg := TPage.Create(tx_S_PAGE2);
  Pages.Add(pg);
  mood := SRect(pg.Root, 0, 0, 960, 600, 28, $FFFFFFFF, kFrame);
  mood.Name := 'Moodboard';
  SText(mood, 48, 40, 'Moodboard', 40, $FF111827, True);
  SText(mood, 48, 96, tx_S_MOOD_SUB, 16, $FF6B7280);
  n := SRect(mood, 48, 160, 260, 180, 24, $FF49D27A);
  n.Fill.Kind := fkLinear; n.Fill.C1 := $FF49D27A; n.Fill.C2 := $FF0EA5E9; n.Fill.Angle := 135;
  n.ShOn := True; n.ShY := 16; n.ShBlur := 32; n.ShColor := $400EA5E9;
  n.Name := tx_S_GRADIENT;
  n := SRect(mood, 350, 170, 160, 160, 0, $FFF59E0B, kEllipse);
  n.Name := tx_S_SUN;
  n := NewNode(kStar, mood, 560, 160, 170, 170);
  n.Fill.C1 := $FFEC4899; n.Sides := 5; n.Ratio := 0.45; n.Rot := 12;
  n := NewNode(kPolygon, mood, 770, 170, 150, 140);
  n.Fill.C1 := $FF6366F1; n.Sides := 6;
  n := SRect(mood, 70, 400, 180, 110, 18, $FFFFFFFF);
  n.Stroke.Vis := True; n.Stroke.C1 := $FF111827; n.StrokeW := 2; n.Dash := True;
  n.Name := tx_S_DASHED;
  n := SRect(mood, 300, 395, 140, 140, 20, $FF111827);
  n.Rot := 18;
  n.Name := tx_S_ROTATED;
  n := NewNode(kPath, mood, 0, 0, 0, 0);
  n.Name := tx_S_WAVE;
  n.Fill.Vis := False;
  n.Stroke.Vis := True; n.Stroke.C1 := $FF0EA5E9; n.StrokeW := 6;
  SetLength(n.Pts, 3);
  FillChar(n.Pts[0], SizeOf(TVPt) * 3, 0);
  n.Pts[0].X := 500; n.Pts[0].Y := 470; n.Pts[0].Curve := True; n.Pts[0].OX := 70; n.Pts[0].OY := -110;
  n.Pts[1].X := 680; n.Pts[1].Y := 470; n.Pts[1].Curve := True; n.Pts[1].IX := -70; n.Pts[1].IY := 110; n.Pts[1].OX := 70; n.Pts[1].OY := -110;
  n.Pts[2].X := 860; n.Pts[2].Y := 470; n.Pts[2].Curve := True; n.Pts[2].IX := -70; n.Pts[2].IY := 110;
  NormalizePath(n);
  n := NewNode(kArrow, mood, 500, 550, 360, 0);
  n.Stroke.C1 := $FF111827; n.StrokeW := 2;
  SetLength(n.Pts, 2);
  FillChar(n.Pts[0], SizeOf(TVPt) * 2, 0);
  n.Pts[1].X := 360;
  PageIx := 0;
  NormalizeAll;
  // Centra «OPTT» en la bienvenida.
  SFrame := splash;
  UndoL.Clear;
  RedoL.Clear;
  Sel.Clear;
  Dirty := False;
end;

{ La vista inicial: todo el diseño a la vista. }
procedure FitView;
begin
  LayoutRegions;
  ZoomToBox(PageBox, 1);
end;

// ============================================================ dibujar todo
procedure RenderUI;
begin
  NHits := 0;
  LayoutRegions;
  CleanSel;
  Surf.Clear(CCanvas);
  if Playing then
  begin
    DrawPlay;
    Exit;
  end;
  DrawCanvas;
  DrawRulers;
  DrawInspector;
  DrawRight;
  DrawRail;
  DrawTopBar;
  DrawStatus;
  DrawPicker;
end;

procedure RenderAt(W, H, Scale: Double);
begin
  S := Scale;
  WinW := W;
  WinH := H;
  if (Surf.W <> Round(W * S)) or (Surf.H <> Round(H * S)) then Surf.Resize(Round(W * S), Round(H * S));
  RenderUI;
end;

// ================================================================ pruebas
function CountAll: Integer;
var
  L: TFPList;
  i: Integer;
begin
  L := TFPList.Create;
  try
    for i := 0 to Pages.Count - 1 do Flatten(PageN(i).Root, L, False);
    Result := L.Count;
  finally
    L.Free;
  end;
end;

function FindByName(const Nm: string): TNode;
var
  L: TFPList;
  i, p: Integer;
begin
  Result := nil;
  L := TFPList.Create;
  try
    for p := 0 to Pages.Count - 1 do Flatten(PageN(p).Root, L, False);
    // Primero las capas con ese nombre; luego los textos que lo dicen.
    for i := 0 to L.Count - 1 do
      if TNode(L[i]).Name = Nm then Exit(TNode(L[i]));
    for i := 0 to L.Count - 1 do
      if (TNode(L[i]).Kind = kText) and (TNode(L[i]).Text = Nm) then Exit(TNode(L[i]));
  finally
    L.Free;
  end;
end;

{ Sin ventana: DMS_OPEND_SELFTEST=1. }
function SelfTest: Integer;
var
  fails, i, n0, k: Integer;
  t1, t2, tmpd, msg: string;
  n, m, g, f: TNode;
  b0, b1: TRectF;
  sum: Double;
  px: LongWord;
  mk: TMask;
  dx, dy: Double;
  L: TFPList;

  procedure Check(Ok: Boolean; const What: string);
  begin
    if not Ok then
    begin
      WriteLn('FAIL ', What);
      Inc(fails);
    end;
  end;

  function Near(A, B: Double): Boolean;
  begin
    Result := Abs(A - B) < 0.6;
  end;

begin
  fails := 0;
  tmpd := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'opend-selftest';
  ForceDirectories(tmpd);
  // --- el rasterizador
  Surf.Resize(40, 40);
  Surf.Clear($FFFFFFFF);
  FillPoly(RectPoly(10, 10, 10, 10), $FF000000);
  Check(Surf.P[15 * 40 + 15] = $FF000000, 'un cuadrado negro');
  Check(Surf.P[5 * 40 + 5] = $FFFFFFFF, 'fuera del cuadrado, blanco');
  Surf.Clear($FFFFFFFF);
  FillPoly(RectPoly(10.5, 10, 10, 10), $FF000000);
  px := Surf.P[15 * 40 + 10];
  Check((CR(px) > 110) and (CR(px) < 145), 'medio píxel, gris (' + IntToStr(CR(px)) + ')');
  Surf.Clear(0);
  FillPoly(EllipsePoly(20, 20, 10, 10, 256), $FFFFFFFF);
  sum := 0;
  for i := 0 to 40 * 40 - 1 do sum := sum + CA(Surf.P[i]) / 255;
  Check(Abs(sum - Pi * 100) < 3, 'el área del círculo (' + FloatToStrF(sum, ffFixed, 6, 1) + ')');
  Surf.Clear(0);
  FillPolys(StrokeClosed(RectPoly(5, 5, 30, 30), 1, 1), Solid($FFFFFFFF));
  Check((CA(Surf.P[20 * 40 + 20]) = 0) and (CA(Surf.P[20 * 40 + 5]) > 200), 'el trazo deja el centro vacío');
  mk := TextMask('Hola', UIFont, 20, False, False);
  k := 0;
  for i := 0 to High(mk.A) do if mk.A[i] > 128 then Inc(k);
  Check(k > 20, 'el texto se dibuja');
  // --- el ejemplo, guardar y abrir
  BuildSample;
  n0 := CountAll;
  Check(n0 > 60, 'el ejemplo tiene capas (' + IntToStr(n0) + ')');
  t1 := DocText;
  Check(LoadDocText(t1), 'abrir lo guardado');
  t2 := DocText;
  Check(t1 = t2, 'guardar y abrir no cambia nada');
  Check(CountAll = n0, 'las mismas capas');
  // --- el texto y el diseño automático
  n := FindByName('OPTT');
  Check((n <> nil) and (n.Kind = kText), 'el texto OPTT');
  f := FindByName(tx_S_DAYS);
  Check((f <> nil) and (f.Layout = 1) and (f.Count = 5), 'los días con diseño automático');
  if f <> nil then
  begin
    Check(Near(f.Kid(1).X, f.Kid(0).X + f.Kid(0).W + f.Gap), 'el hueco entre los días');
    Check(Near(f.W, 5 * 70 + 4 * 8), 'el marco abraza su contenido (' + NumStr(f.W) + ')');
  end;
  // --- elegir con el ratón
  RenderAt(1360, 840, 1);
  FitView;
  RenderAt(1360, 840, 1);
  b0 := WorldBox(n);
  MouseDownAt(W2SX((b0.L + b0.R) / 2), W2SY((b0.T + b0.B) / 2), mbLeft, [], False);
  MouseUpAt(W2SX((b0.L + b0.R) / 2), W2SY((b0.T + b0.B) / 2), []);
  Check(One = n, 'un clic elige el texto dentro del marco');
  // mover con el ratón (y deshacer)
  RenderAt(1360, 840, 1);
  MouseDownAt(W2SX((b0.L + b0.R) / 2), W2SY((b0.T + b0.B) / 2), mbLeft, [], False);
  MouseMoveAt(W2SX((b0.L + b0.R) / 2) + 40 * Zoom, W2SY((b0.T + b0.B) / 2) + 20 * Zoom, []);
  MouseUpAt(W2SX((b0.L + b0.R) / 2) + 40 * Zoom, W2SY((b0.T + b0.B) / 2) + 20 * Zoom, []);
  n := FindByName('OPTT');
  Check(Near(WorldBox(n).L, b0.L + 40) or Near(WorldBox(n).T, b0.T + 20), 'arrastrar mueve la capa');
  DoUndo;
  n := FindByName('OPTT');
  Check(Near(WorldBox(n).L, b0.L) and Near(WorldBox(n).T, b0.T), 'deshacer la deja donde estaba');
  DoRedo;
  DoUndo;
  // --- tamaño y giro desde el inspector
  SelectOnly(FindByName(tx_S_EMAIL));
  ApplyEdit('w', '200+20');
  Check(Near(One.W, 220), 'una cuenta en el campo W');
  ApplyEdit('rot', '90');
  b1 := WorldBox(One);
  Check(Near(b1.R - b1.L, 54) and Near(b1.B - b1.T, 220), 'girar 90° cambia el recuadro');
  DoUndo; DoUndo;
  // --- agrupar y desagrupar sin moverse
  L := TFPList.Create;
  try
    n := FindByName(tx_S_WELCOME);
    m := FindByName(tx_S_WELCOME_SUB);
    Sel.Clear; Sel.Add(n); Sel.Add(m);
    b0 := SelBox;
      RunAct('group');
      g := One;
    Check((g <> nil) and (g.Kind = kGroup) and (g.Count = 2), 'agrupar');
    b1 := WorldBox(g);
    Check(Near(b0.L, b1.L) and Near(b0.T, b1.T) and Near(b0.R, b1.R), 'el grupo ocupa lo mismo');
    MoveNode(g, 10, 0);
    Check(Near(WorldBox(n).L, b0.L + 10), 'mover el grupo mueve lo de dentro');
      RunAct('ungroup');
      Check((Sel.Count = 2) and (n.Parent.Kind = kFrame), 'desagrupar');
  finally
    L.Free;
  end;
  // --- componentes e instancias
  m := FindByName(tx_S_BUTTON);
  Check((m <> nil) and (m.Kind in [kComponent, kInstance]), 'el botón');
  L := AllComponents;
  try
    Check(L.Count = 1, 'un componente');
    if L.Count > 0 then
    begin
      m := TNode(L[0]);
      n := nil;
      for i := 0 to PageN(0).Root.Count - 1 do;
      SelectOnly(FindByName(tx_S_LOGIN));
      InsertInstance(m);
      n := One;
      Check((n <> nil) and (n.Kind = kInstance) and (n.CompId = m.Id), 'poner una instancia');
      Surf.Resize(400, 100);
      Surf.Clear($FFFFFFFF);
      DrawStandalone(n, 0, 0, 1);
      Check(Surf.P[28 * 400 + 20] <> $FFFFFFFF, 'la instancia se dibuja como el componente');
      Detach;
      Check((One <> nil) and (One.Kind = kFrame) and (One.Count = m.Count), 'separar la instancia');
    end;
  finally
    L.Free;
  end;
  // --- copiar y pegar
  BuildSample;
  n0 := CountAll;
  SelectOnly(FindByName(tx_S_TODAY));
  t1 := SelClipText;
  Check(PasteText(t1) and (CountAll = n0 + 1), 'copiar y pegar');
  // --- exportar
  SelectOnly(FindByName(tx_S_LOGIN));
  ExportPNG(tmpd + '/login.png', 2);
  Check(FileExists(tmpd + '/login.png'), 'exportar a PNG');
  t1 := SvgDoc;
  Check((Pos('<svg', t1) = 1) and (Pos('<text', t1) > 0) and (Pos('<rect', t1) > 0), 'exportar a SVG');
  Check(Pos('font-size: 30px;', CssOf(FindByName(tx_S_WELCOME))) > 0, 'el CSS del título');
  Check(Pos('Text(', FlutterOf(FindByName(tx_S_WELCOME))) > 0, 'el Flutter del título');
  Check(Pos('linear-gradient(135deg', CssOf(FindByName(tx_S_TODAY))) > 0, 'el CSS del degradado');
  // --- la plantilla JSON de la IA
  t1 := AiTemplate;
  NewDoc;
  Check(ImportJson(t1, msg), 'importar la plantilla: ' + msg);
  n := FindByName(tx_AIX_LOGIN);
  Check(n <> nil, 'la pantalla de la plantilla');
  m := nil;
  L := TFPList.Create;
  try
    if n <> nil then Flatten(n, L, False);
    for i := 0 to L.Count - 1 do
      if TNode(L[i]).Kind = kInstance then m := TNode(L[i]);
  finally
    L.Free;
  end;
  Check((m <> nil) and (FindNode(m.CompId) <> nil), 'la instancia del botón');
  Check((m <> nil) and (m.Link > 0) and (FindNode(m.Link).Name = tx_AIX_HOME), 'el enlace del prototipo');
  Check((m <> nil) and (m.Over.Count = 1), 'el texto cambiado de la instancia');
  f := FindByName(tx_AIX_HOME);
  Check((f <> nil) and (f.Layout = 2) and (f.Count = 2), 'el diseño automático de la plantilla');
  SelectOnly(FindByName(tx_AIX_LOGIN));
  t2 := SelJson;
  NewDoc;
  Check(ImportJson('```json' + LineEnding + t2 + LineEnding + '```', msg), 'importar el JSON de una capa (con ``` alrededor)');
  Check(FindByName(tx_AIX_WELCOME) <> nil, 'el texto vuelve');
  Check(not ImportJson('esto no es json', msg), 'un texto que no es JSON');
  // --- guías inteligentes
  NewDoc;
  n := NewNode(kRect, Page.Root, 0, 0, 100, 100);
  m := NewNode(kRect, Page.Root, 300, 3, 100, 100);
  SelectOnly(m);
  L := TFPList.Create;
  try
    L.Add(m);
    dx := 0; dy := 0;
    SmartSnap(WorldBox(m), L, dx, dy);
    Check(Near(dy, -3), 'la guía alinea el borde de arriba');
  finally
    L.Free;
  end;
  // --- la interfaz entera, en los dos temas y los tres modos, y presentar
  BuildSample;
  for k := 0 to 1 do
  begin
    Dark := k = 0;
    ApplyTheme;
    for i := 0 to 2 do
    begin
      Mode := i;
      SelectOnly(FindByName('OPTT'));
      RenderAt(1360, 840, 1);
      Check(NHits > 25, 'la interfaz se dibuja (tema ' + IntToStr(k) + ', modo ' + IntToStr(i) + ')');
    end;
  end;
  Mode := 0;
  Dark := True;
  ApplyTheme;
  ClearSel;
  RenderAt(1360, 840, 1);
  Tool := tlFrame;
  RenderAt(1360, 840, 1);
  Tool := tlMove;
  StartPlay;
  Check(Playing and (PlayFrame <> nil) and (PlayFrame.Name = 'Splash'), 'presentar empieza en la bienvenida');
  RenderAt(1360, 840, 1);
  MouseX := WinW / 2; MouseY := WinH / 2;
  PlayClick;
  Check((PlayFrame <> nil) and (PlayFrame.Name = tx_S_LOGIN), 'un clic va a la siguiente pantalla');
  RenderAt(1360, 840, 1);
  StopPlay;
  if fails = 0 then
    WriteLn('selftest ok nodes=', n0)
  else
    WriteLn('selftest FAILED ', fails);
  Result := Ord(fails > 0);
end;

{ Las capturas de la web, sin ventana: DMS_OPEND_SHOT=<carpeta>. }
function Shots(const Dir: string): Integer;
const
  SW = 1360; SH = 840; SC = 1.5;
var
  n: TNode;
begin
  ForceDirectories(Dir);
  // 1. Diseñar: «OPTT» elegido, como en la captura de su diseño.
  BuildSample;
  Dark := True;
  ApplyTheme;
  RenderAt(SW, SH, SC);
  LayoutRegions;
  ZoomToBox(RF(-40, -40, 1500, 960), 0.62);
  n := FindByName('OPTT');
  SelectOnly(n);
  RightTab := 0;
  FindByName('Splash').Open := True;
  RenderAt(SW, SH, SC);
  HoverAct := '';
  RenderAt(SW, SH, SC);
  SaveSurfPNG(Surf, Dir + '/editor.png');
  // 2. Prototipo: las conexiones y la interacción del botón.
  Mode := 1;
  n := FindByName(tx_S_LOGIN);
  SelectOnly(n.Kid(n.Count - 3));
  RenderAt(SW, SH, SC);
  SaveSurfPNG(Surf, Dir + '/proto.png');
  // 3. Código: el CSS de la tarjeta, con el tema claro.
  Mode := 2;
  Dark := False;
  ApplyTheme;
  SelectOnly(FindByName(tx_S_TODAY));
  HoverNode := FindByName(tx_S_WEEK);
  RenderAt(SW, SH, SC);
  SaveSurfPNG(Surf, Dir + '/code.png');
  HoverNode := nil;
  // 4. Ideas: formas y el selector de color.
  Mode := 0;
  PageIx := 1;
  ZoomToBox(PageBox, 1);
  SelectOnly(FindByName(tx_S_SUN));
  RenderAt(SW, SH, SC);
  OpenPicker('fill', 300);
  RenderAt(SW, SH, SC);
  SaveSurfPNG(Surf, Dir + '/shapes.png');
  PickOpen := False;
  // 5. Presentar el prototipo.
  Dark := True;
  ApplyTheme;
  PageIx := 0;
  ClearSel;
  StartPlay;
  GoFrame(FindByName(tx_S_HOME), 0, 0);
  RenderAt(SW, SH, SC);
  SaveSurfPNG(Surf, Dir + '/play.png');
  StopPlay;
  WriteLn('shots ok ', Dir);
  Result := 0;
end;

// ============================================================== la ventana
var
  OutImg: TLazIntfImage = nil;
  OutBmp: TBitmap = nil;
  MouseDiv: Double = 1;

function BackingScale: Double;
begin
  {$IFDEF DARWIN}
  Result := NSScreen.mainScreen.backingScaleFactor;
  if Result < 1 then Result := 1;
  {$ELSE}
  Result := Max(1, Screen.PixelsPerInch / 96);
  {$ENDIF}
end;

procedure TForm1.form_create;
begin
  StageHint.Visible := False;
  Stage.BevelOuter := bvNone;
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Sel := TFPList.Create;
  UndoL := TStringList.Create;
  RedoL := TStringList.Create;
  {$IFDEF DARWIN}
  UIFont := 'Helvetica Neue';
  CodeFont := 'Menlo';
  {$ELSE}
  UIFont := 'Segoe UI';
  CodeFont := 'Consolas';
  {$ENDIF}
  if Screen.Fonts.IndexOf('Inter') >= 0 then DocFont := 'Inter' else DocFont := UIFont;
  ApplyTheme;
  Surf := TSurface.Create(64, 64);
  // Sin ventana: un error se escribe (con dónde pasó) y la app termina.
  if (GetEnvironmentVariable('DMS_OPEND_SELFTEST') <> '') or (GetEnvironmentVariable('DMS_OPEND_SHOT') <> '') then
  try
    if GetEnvironmentVariable('DMS_OPEND_SELFTEST') <> '' then Halt(SelfTest);
    Halt(Shots(GetEnvironmentVariable('DMS_OPEND_SHOT')));
  except
    on E: Exception do
    begin
      WriteLn('FAIL ', E.ClassName, ': ', E.Message);
      DumpExceptionBackTrace(Output);
      Halt(2);
    end;
  end;
  MainForm := Self;
  Box := TPaintBox.Create(Self);
  Box.Parent := Stage;
  Box.Align := alClient;
  Box.OnPaint := @BoxPaint;
  Box.OnMouseDown := @BoxDown;
  Box.OnMouseMove := @BoxMove;
  Box.OnMouseUp := @BoxUp;
  Box.OnMouseWheel := @BoxWheel;
  KeyPreview := True;
  OnKeyDown := @KeyDownH;
  OnKeyUp := @KeyUpH;
  OnUTF8KeyPress := @Utf8H;
  SetShortcuts;
  BuildSample;
  WinW := ClientWidth;
  WinH := ClientHeight;
  FitView;
  OutImg := TLazIntfImage.Create(0, 0);
  OutBmp := TBitmap.Create;
end;

procedure TForm1.form_close;
begin
  Tick.Enabled := False;
end;

procedure TForm1.SetShortcuts;
  procedure Walk(M: TMenuItem);
  var
    i: Integer;
    h: string;
    sc: TShortCut;
  begin
    for i := 0 to M.Count - 1 do
    begin
      Walk(M[i]);
      h := M[i].Hint;
      sc := 0;
      if h = tx_MP_NEW then sc := ShortCut(VK_N, [ssModifier])
      else if h = tx_MP_OPEN then sc := ShortCut(VK_O, [ssModifier])
      else if h = tx_MP_SAVE then sc := ShortCut(VK_S, [ssModifier])
      else if h = tx_MP_SAVE_AS then sc := ShortCut(VK_S, [ssModifier, ssShift])
      else if h = tx_MP_IMPORT then sc := ShortCut(VK_K, [ssModifier, ssShift])
      else if h = tx_MP_EXPORT then sc := ShortCut(VK_E, [ssModifier, ssShift])
      else if h = tx_MP_UNDO then sc := ShortCut(VK_Z, [ssModifier])
      else if h = tx_MP_REDO then sc := ShortCut(VK_Z, [ssModifier, ssShift])
      else if h = tx_MP_CUT then sc := ShortCut(VK_X, [ssModifier])
      else if h = tx_MP_COPY then sc := ShortCut(VK_C, [ssModifier])
      else if h = tx_MP_PASTE then sc := ShortCut(VK_V, [ssModifier])
      else if h = tx_MP_DUP then sc := ShortCut(VK_D, [ssModifier])
      else if h = tx_MP_ALL then sc := ShortCut(VK_A, [ssModifier])
      else if h = tx_MP_GROUP then sc := ShortCut(VK_G, [ssModifier])
      else if h = tx_MP_UNGROUP then sc := ShortCut(VK_G, [ssModifier, ssShift])
      else if h = tx_MP_FRAME_SEL then sc := ShortCut(VK_G, [ssModifier, ssAlt])
      else if h = tx_MP_COMP then sc := ShortCut(VK_K, [ssModifier, ssAlt])
      else if h = tx_MP_DETACH then sc := ShortCut(VK_B, [ssModifier, ssAlt])
      else if h = tx_MP_FRONT then sc := ShortCut(VK_OEM_6, [ssModifier, ssAlt])
      else if h = tx_MP_FWD then sc := ShortCut(VK_OEM_6, [ssModifier])
      else if h = tx_MP_BACK then sc := ShortCut(VK_OEM_4, [ssModifier])
      else if h = tx_MP_BOTTOM then sc := ShortCut(VK_OEM_4, [ssModifier, ssAlt])
      else if h = tx_MP_HIDE then sc := ShortCut(VK_H, [ssModifier, ssShift])
      else if h = tx_MP_LOCK then sc := ShortCut(VK_L, [ssModifier, ssShift])
      else if h = tx_MP_ZOOM_IN then sc := ShortCut(VK_OEM_PLUS, [ssModifier])
      else if h = tx_MP_ZOOM_OUT then sc := ShortCut(VK_OEM_MINUS, [ssModifier])
      else if h = tx_MP_ZOOM_100 then sc := ShortCut(VK_0, [ssModifier])
      else if h = tx_MP_ZOOM_ALL then sc := ShortCut(VK_1, [ssModifier])
      else if h = tx_MP_ZOOM_SEL then sc := ShortCut(VK_2, [ssModifier])
      else if h = tx_MP_RULERS then sc := ShortCut(VK_R, [ssModifier, ssShift])
      else if h = tx_MP_PLAY then sc := ShortCut(VK_RETURN, [ssModifier, ssAlt]);
      if sc <> 0 then M[i].ShortCut := sc;
    end;
  end;
begin
  Walk(Menu1.Items);
end;

procedure TForm1.PopupPick(Sender: TObject);
begin
  RunAct(TMenuItem(Sender).Hint);
  Box.Invalidate;
end;

procedure TForm1.Menu1_click(const Item: string);
var
  a: string;
begin
  a := '';
  if Item = tx_MP_NEW then a := 'new'
  else if Item = tx_MP_OPEN then a := 'open'
  else if Item = tx_MP_SAMPLE then a := 'sample'
  else if Item = tx_MP_SAVE then a := 'save'
  else if Item = tx_MP_SAVE_AS then a := 'saveas'
  else if Item = tx_MP_IMPORT then a := 'import'
  else if Item = tx_MP_EXPORT then a := 'export'
  else if Item = tx_MP_QUIT then a := 'quit'
  else if Item = tx_MP_UNDO then a := 'undo'
  else if Item = tx_MP_REDO then a := 'redo'
  else if Item = tx_MP_CUT then a := 'cut'
  else if Item = tx_MP_COPY then a := 'copy'
  else if Item = tx_MP_PASTE then a := 'paste'
  else if Item = tx_MP_DUP then a := 'dup'
  else if Item = tx_MP_DEL then a := 'del'
  else if Item = tx_MP_ALL then a := 'all'
  else if Item = tx_MP_GROUP then a := 'group'
  else if Item = tx_MP_UNGROUP then a := 'ungroup'
  else if Item = tx_MP_FRAME_SEL then a := 'framesel'
  else if Item = tx_MP_AUTO then a := 'autolayout'
  else if Item = tx_MP_COMP then a := 'comp'
  else if Item = tx_MP_DETACH then a := 'detach'
  else if Item = tx_MP_FRONT then a := 'front'
  else if Item = tx_MP_FWD then a := 'fwd'
  else if Item = tx_MP_BACK then a := 'back'
  else if Item = tx_MP_BOTTOM then a := 'bottom'
  else if Item = tx_MP_HIDE then a := 'hide'
  else if Item = tx_MP_LOCK then a := 'lock'
  else if Item = tx_MP_ZOOM_IN then a := 'zin'
  else if Item = tx_MP_ZOOM_OUT then a := 'zout'
  else if Item = tx_MP_ZOOM_100 then a := 'z100'
  else if Item = tx_MP_ZOOM_ALL then a := 'zall'
  else if Item = tx_MP_ZOOM_SEL then a := 'zsel'
  else if Item = tx_MP_RULERS then a := 'rulers'
  else if Item = tx_MP_PIXGRID then a := 'pixgrid'
  else if Item = tx_MP_SNAP then a := 'snap'
  else if Item = tx_MP_THEME then a := 'theme'
  else if Item = tx_MP_MODE_D then a := 'm0'
  else if Item = tx_MP_MODE_P then a := 'm1'
  else if Item = tx_MP_MODE_C then a := 'm2'
  else if Item = tx_MP_PLAY then a := 'play'
  else if Item = tx_MP_AI_SCHEMA then a := 'ai_schema'
  else if Item = tx_MP_AI_SAVE then a := 'ai_save'
  else if Item = tx_MP_AI_PASTE then a := 'ai_paste'
  else if Item = tx_MP_AI_IMPORT then a := 'ai_import'
  else if Item = tx_MP_AI_EXPORT then a := 'ai_export'
  else if Item = tx_MP_KEYS then a := 'keys'
  else if Item = tx_MP_HOW then a := 'how'
  else if Item = tx_MP_ABOUT then a := 'about';
  if a = 'buildsample' then;
  if a = 'sample' then
  begin
    if Dirty and not Ask(tx_ASK_DISCARD) then Exit;
    BuildSample;
    FitView;
  end
  else if a <> '' then RunAct(a);
  Box.Invalidate;
end;

procedure TForm1.BoxPaint(Sender: TObject);
var
  y: Integer;
  d: TRawImageDescription;
begin
  S := BackingScale;
  {$IFDEF DARWIN}
  MouseDiv := 1;
  WinW := Box.Width;
  WinH := Box.Height;
  {$ELSE}
  MouseDiv := S;
  WinW := Box.Width / S;
  WinH := Box.Height / S;
  {$ENDIF}
  RenderAt(WinW, WinH, S);
  if (OutImg.Width <> Surf.W) or (OutImg.Height <> Surf.H) then
  begin
    d.Init_BPP32_B8G8R8A8_BIO_TTB(Surf.W, Surf.H);
    OutImg.DataDescription := d;
  end;
  for y := 0 to Surf.H - 1 do
    Move(Surf.P[y * Surf.W], OutImg.GetDataLineStart(y)^, Surf.W * 4);
  OutBmp.LoadFromIntfImage(OutImg);
  Box.Canvas.StretchDraw(Rect(0, 0, Box.Width, Box.Height), OutBmp);
end;

procedure TForm1.BoxDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MouseDownAt(X / MouseDiv, Y / MouseDiv, Button, Shift, ssDouble in Shift);
  Box.Invalidate;
end;

procedure TForm1.BoxMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  oldAct: string;
  oldHover: TNode;
begin
  oldAct := HoverAct;
  oldHover := HoverNode;
  MouseMoveAt(X / MouseDiv, Y / MouseDiv, Shift);
  if (Drag <> dNone) or (oldAct <> HoverAct) or (oldHover <> HoverNode) or (PenNode <> nil) or
    ((MouseX >= CX0) and (MouseX < CX1)) then
    Box.Invalidate;
  case Drag of
    dPan: Box.Cursor := crSizeAll;
    dNone:
      if SpaceDown or (Tool = tlHand) then Box.Cursor := crHandPoint
      else if Copy(HoverAct, 1, 4) = 'hdl:' then Box.Cursor := crSizeNWSE
      else if Copy(HoverAct, 1, 4) = 'rot:' then Box.Cursor := crCross
      else if Copy(HoverAct, 1, 2) = 's:' then Box.Cursor := crSizeWE
      else if Copy(HoverAct, 1, 2) = 'f:' then Box.Cursor := crIBeam
      else if (HoverAct = '') and (MouseX >= CX0) and (MouseX < CX1) and (MouseY >= CY0) and (MouseY < CY1) and
        (Tool in [tlFrame, tlRect, tlEllipse, tlLine, tlArrow, tlPolygon, tlStar, tlPen, tlComment]) then Box.Cursor := crCross
      else if (HoverAct = '') and (Tool = tlText) then Box.Cursor := crIBeam
      else Box.Cursor := crDefault;
  end;
end;

procedure TForm1.BoxUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  MouseUpAt(X / MouseDiv, Y / MouseDiv, Shift);
  Box.Invalidate;
end;

procedure TForm1.BoxWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
begin
  WheelAt(MousePos.X / MouseDiv, MousePos.Y / MouseDiv, WheelDelta, Shift);
  Handled := True;
  Box.Invalidate;
end;

procedure Nudge(DX, DY: Double);
var
  L: TFPList;
  i: Integer;
begin
  if Sel.Count = 0 then Exit;
  Snap;
  L := TopSel;
  try
    for i := 0 to L.Count - 1 do MoveNode(TNode(L[i]), DX, DY);
  finally
    L.Free;
  end;
  NormalizeAll;
end;

procedure TForm1.KeyDownH(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  cmd, sh: Boolean;
  v: Double;
  n: TNode;
  k: Integer;
begin
  cmd := (ssMeta in Shift) or (ssCtrl in Shift);
  sh := ssShift in Shift;
  AltDown := ssAlt in Shift;
  if Playing then
  begin
    case Key of
      VK_ESCAPE: StopPlay;
      VK_LEFT, VK_BACK:
        if PlayHist.Count > 0 then
        begin
          GoFrame(TNode(PlayHist[PlayHist.Count - 1]), 1, 250, True);
          PlayHist.Delete(PlayHist.Count - 1);
        end;
    end;
    Key := 0;
    Box.Invalidate;
    Exit;
  end;
  if EditId <> '' then
  begin
    if cmd then Exit;
    case Key of
      VK_LEFT: EdMove(-1, sh);
      VK_RIGHT: EdMove(1, sh);
      VK_HOME: EdHomeEnd(False, sh);
      VK_END: EdHomeEnd(True, sh);
      VK_UP, VK_DOWN:
        if IsNumId(EditId) and EvalNum(EditBuf, v) then
        begin
          if sh then v := v + 10 * (Ord(Key = VK_UP) * 2 - 1) else v := v + (Ord(Key = VK_UP) * 2 - 1);
          ApplyEdit(EditId, NumStr(v));
          BeginEdit(EditId, NumStr(v));
        end
        else EdHomeEnd(Key = VK_DOWN, sh);
      VK_BACK: EdBack(False);
      VK_DELETE: EdBack(True);
      VK_RETURN:
        if (EditId = 'text') and not sh then EdInsert(#10)
        else CommitEdit;
      VK_ESCAPE:
        if EditId = 'text' then
        begin
          n := EditNode;
          CommitEdit;
          if (n <> nil) and (n.Kind = kText) and (Trim(n.Text) = '') and (n.Parent <> nil) then
          begin
            Unlink(n);
            n.Free;
            Sel.Clear;
            NormalizeAll;
          end;
        end
        else CancelEdit;
      VK_TAB: CommitEdit;
    else
      Exit;
    end;
    Key := 0;
    Box.Invalidate;
    Exit;
  end;
  if cmd then Exit;
  case Key of
    VK_SPACE: SpaceDown := True;
    VK_ESCAPE:
      if PenNode <> nil then FinishPen
      else if VertexNode <> nil then VertexNode := nil
      else if PickOpen then PickOpen := False
      else if ActiveComment >= 0 then ActiveComment := -1
      else if Tool <> tlMove then SetTool(tlMove)
      else if (One <> nil) and (One.Parent <> nil) and (One.Parent <> Page.Root) then
      begin
        n := One.Parent;
        while (n.Parent <> nil) and (n.Parent <> Page.Root) and not CanPick(n) do n := n.Parent;
        SelectOnly(n);
      end
      else ClearSel;
    VK_RETURN:
      if PenNode <> nil then FinishPen
      else if One <> nil then
      begin
        n := One;
        if n.Kind = kText then StartTextEdit(n)
        else if n.Kind in [kPath, kLine, kArrow] then VertexNode := n
        else if (n.Count > 0) and (n.Kind <> kInstance) then
        begin
          Sel.Clear;
          Scope := n;
          for k := 0 to n.Count - 1 do Sel.Add(n.Kid(k));
        end;
      end;
    VK_DELETE, VK_BACK: if PenNode = nil then DeleteSel;
    VK_LEFT: if sh then Nudge(-10, 0) else Nudge(-1, 0);
    VK_RIGHT: if sh then Nudge(10, 0) else Nudge(1, 0);
    VK_UP: if sh then Nudge(0, -10) else Nudge(0, -1);
    VK_DOWN: if sh then Nudge(0, 10) else Nudge(0, 1);
    VK_TAB:
      if (One <> nil) and (One.Parent <> nil) and (One.Parent.Count > 1) then
      begin
        k := IndexIn(One);
        if sh then k := (k + One.Parent.Count - 1) mod One.Parent.Count
        else k := (k + 1) mod One.Parent.Count;
        SelectOnly(One.Parent.Kid(k));
      end;
    VK_V: SetTool(tlMove);
    VK_H: SetTool(tlHand);
    VK_F: SetTool(tlFrame);
    VK_A: if sh then ToggleAuto else SetTool(tlFrame);
    VK_R: if sh then Rulers := not Rulers else SetTool(tlRect);
    VK_O: SetTool(tlEllipse);
    VK_L: if sh then SetTool(tlArrow) else SetTool(tlLine);
    VK_P: SetTool(tlPen);
    VK_T: SetTool(tlText);
    VK_C: SetTool(tlComment);
    VK_0: if sh then RunAct('z100');
    VK_1: if sh then RunAct('zall');
    VK_2: if sh then RunAct('zsel');
    VK_OEM_PLUS, VK_ADD: RunAct('zin');
    VK_OEM_MINUS, VK_SUBTRACT: RunAct('zout');
  else
    Exit;
  end;
  Key := 0;
  Box.Invalidate;
end;

procedure TForm1.KeyUpH(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then SpaceDown := False;
  AltDown := ssAlt in Shift;
  Box.Invalidate;
end;

procedure TForm1.Utf8H(Sender: TObject; var UTF8Key: TUTF8Char);
begin
  if (EditId <> '') and (Length(UTF8Key) > 0) and (UTF8Key[1] >= ' ') and (UTF8Key <> #127) then
  begin
    EdInsert(UTF8Key);
    UTF8Key := '';
    Box.Invalidate;
  end;
end;

procedure TForm1.Tick_timer;
var
  dirty_: Boolean;
begin
  if Box = nil then Exit;
  dirty_ := False;
  if (EditId <> '') and (Now64 - CaretT > 530) then
  begin
    CaretOn := not CaretOn;
    CaretT := Now64;
    dirty_ := True;
  end;
  if Playing and ((PlayPrev <> nil) or ((PlayFlash > 0) and (Now64 - PlayFlash < 700))) then dirty_ := True;
  if (Toast <> '') and (Now64 - ToastT > 3500) and (Now64 - ToastT < 3600) then dirty_ := True;
  if dirty_ then Box.Invalidate;
end;

end.
''';
