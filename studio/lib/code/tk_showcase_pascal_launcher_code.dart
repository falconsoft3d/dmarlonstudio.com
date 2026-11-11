part of 'tk_examples.dart';

// El código en Pascal del «Lanzador de apps» (tk_showcase_pascal_launcher.dart):
// la unidad Form1.pas entera; el estudio pone los textos en «// @TEXTS».
const _launcherCode = r'''
// @TITLE
unit Form1;

{$mode objfpc}{$H+}
{$IFDEF DARWIN}{$modeswitch objectivec1}{$ENDIF}

interface

uses
  {$IFDEF DARWIN}CocoaAll, CocoaGDIObjects, cocoa_extra,{$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Menus, dms, design, Math, LCLIntf, LCLType,
  IntfGraphics, GraphType, FPImage, LazUTF8;

type
  { Lo que se dibuja en el panel y se puede pulsar. }
  THit = record
    R: TRect;
    Act: string;
  end;
  THits = array of THit;

  TForm1 = class(TFormDesign)
  private
    Tray: TTrayIcon;
    TrayMenu: TPopupMenu;
    Box: TPaintBox;
    FQuitting: Boolean;
    FSig, FPending: string;
    FIconSet: Boolean;
    FHover, FScroll, FContentH, FSel: Integer;
    FHits: THits;
    procedure StartUp(Data: PtrInt);
    procedure DoPending(Data: PtrInt);
    procedure ToAccessory(Data: PtrInt);
    procedure TrayItem(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure PanelClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SearchChange(Sender: TObject);
    procedure SearchKey(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BoxPaint(Sender: TObject);
    procedure BoxDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BoxMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BoxWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    function HitAt(X, Y: Integer): Integer;
    function LangMenu: TMenuItem;
    procedure Rescan;
    procedure Rebuild;
    procedure SetIcon;
    procedure ShowPanel;
    procedure Quit;
    procedure Act(const H: string);
  public
    procedure form_create; override;
    procedure Tick_timer; override;
    procedure Search_enter; override;
    procedure Menu1_click(const Item: string); override;
  end;

implementation

// Los textos (los traduce el estudio con el resto del ejemplo).
const
  // @TEXTS
  // ---- fin de los textos

// ================================================================ los datos
type
  { Una aplicación: su nombre (el que enseña el Finder) y dónde está. }
  TApp = record
    Name, Path, Key: string;
  end;
  TAppArray = array of TApp;

const
  MaxRecent = 6;
  MenuIcon = 32;   // píxeles del icono del menú (16 puntos en Retina)
  TileIcon = 128;  // los del panel

var
  Apps: TAppArray;
  Favs, Recent: TStringList;
  Query: string = '';
  Icons: TStringList; // ruta + tamaño → TBitmap
  NameStyle: string = 'finder'; // 'file': el nombre del archivo (capturas)
  // Las pruebas y las capturas cambian dónde se buscan las apps y dónde se
  // guardan las favoritas (si no, DMS_LAUNCHER_DIRS y DMS_LAUNCHER_CONFIG).
  DirsOverride: string = '';
  DirsOverridden: Boolean = False;
  ConfigOverride: string = '';

// {0}, {1}… por los valores.
function Fmt(const S: string; const A: array of string): string;
var
  i: Integer;
begin
  Result := S;
  for i := 0 to High(A) do
    Result := StringReplace(Result, '{' + IntToStr(i) + '}', A[i], [rfReplaceAll]);
end;

{ Para buscar y ordenar: en minúsculas y sin acentos. }
function Fold(const S: string): string;
const
  A: array[0..13] of string = ('á', 'é', 'í', 'ó', 'ú', 'ü', 'ñ', 'à', 'è', 'ì', 'ò', 'ù', 'ç', 'ö');
  B: array[0..13] of string = ('a', 'e', 'i', 'o', 'u', 'u', 'n', 'a', 'e', 'i', 'o', 'u', 'c', 'o');
var
  i: Integer;
begin
  Result := UTF8LowerCase(S);
  for i := 0 to High(A) do
    Result := StringReplace(Result, A[i], B[i], [rfReplaceAll]);
end;

{ La letra del índice: A–Z, o # para lo demás. }
function Letter(const Name: string): string;
var
  F: string;
begin
  F := Fold(Name);
  if (F <> '') and (F[1] in ['a'..'z']) then Result := UpCase(F[1]) else Result := '#';
end;

function ConfigFile: string;
begin
  Result := ConfigOverride;
  if Result = '' then Result := GetEnvironmentVariable('DMS_LAUNCHER_CONFIG');
  if Result <> '' then Exit;
  {$IFDEF MSWINDOWS}
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
    'DMarlon Studio Demos\launcher.txt';
  {$ELSE}
  {$IFDEF DARWIN}
  Result := GetUserDir + 'Library/Application Support/DMarlon Studio Demos/launcher.txt';
  {$ELSE}
  Result := GetUserDir + '.config/DMarlon Studio Demos/launcher.txt';
  {$ENDIF}
  {$ENDIF}
end;

{ Las favoritas y las recientes: «fav=ruta» y «recent=ruta», una por línea. }
procedure LoadConfig;
var
  S: TStringList;
  i: Integer;
begin
  Favs.Clear;
  Recent.Clear;
  if not FileExists(ConfigFile) then Exit;
  S := TStringList.Create;
  try
    try
      S.LoadFromFile(ConfigFile);
    except
      Exit;
    end;
    for i := 0 to S.Count - 1 do
      if Pos('fav=', S[i]) = 1 then Favs.Add(Copy(S[i], 5, MaxInt))
      else if Pos('recent=', S[i]) = 1 then Recent.Add(Copy(S[i], 8, MaxInt));
  finally
    S.Free;
  end;
end;

procedure SaveConfig;
var
  S: TStringList;
  i: Integer;
begin
  S := TStringList.Create;
  try
    for i := 0 to Favs.Count - 1 do S.Add('fav=' + Favs[i]);
    for i := 0 to Recent.Count - 1 do S.Add('recent=' + Recent[i]);
    try
      ForceDirectories(ExtractFilePath(ConfigFile));
      S.SaveToFile(ConfigFile);
    except
    end;
  finally
    S.Free;
  end;
end;

procedure Remember(const Path: string);
var
  i: Integer;
begin
  i := Recent.IndexOf(Path);
  if i >= 0 then Recent.Delete(i);
  Recent.Insert(0, Path);
  while Recent.Count > MaxRecent do Recent.Delete(Recent.Count - 1);
  SaveConfig;
end;

procedure ToggleFav(const Path: string);
var
  i: Integer;
begin
  i := Favs.IndexOf(Path);
  if i >= 0 then Favs.Delete(i) else Favs.Add(Path);
  SaveConfig;
end;

// ============================================================ las apps
{$IFDEF DARWIN}
function NS(const S: string): NSString;
begin
  Result := NSString.stringWithUTF8String(PChar(S));
end;

{ El nombre que enseña el Finder (traducido: «Calculadora»). }
function FinderName(const Path: string): string;
begin
  Result := string(NSFileManager.defaultManager.displayNameAtPath(NS(Path)).UTF8String);
  if LowerCase(ExtractFileExt(Result)) = '.app' then
    Result := ChangeFileExt(Result, '');
end;
{$ENDIF}

function AppName(const Path: string): string;
begin
  Result := ChangeFileExt(ExtractFileName(ExcludeTrailingPathDelimiter(Path)), '');
  {$IFDEF DARWIN}
  if NameStyle = 'finder' then Result := FinderName(Path);
  {$ENDIF}
end;

procedure AddApp(var List: TAppArray; const Path: string);
var
  i: Integer;
  A: TApp;
begin
  for i := 0 to High(List) do
    if List[i].Path = Path then Exit;
  A.Path := Path;
  A.Name := AppName(Path);
  A.Key := Fold(A.Name);
  SetLength(List, Length(List) + 1);
  List[High(List)] := A;
end;

{ Esta app: su paquete .app en macOS (…/Lanzador.app/Contents/MacOS/app) o
  su ejecutable; no se lanza a sí misma. }
function SelfPath: string;
var
  P: string;
begin
  P := ExpandFileName(ParamStr(0));
  Result := P;
  {$IFDEF DARWIN}
  P := ExtractFileDir(ExtractFileDir(ExtractFileDir(P)));
  if LowerCase(ExtractFileExt(P)) = '.app' then Result := P;
  {$ENDIF}
end;

{ La carpeta donde está el lanzador: de ahí salen las apps. }
function HomeDir: string;
begin
  Result := ExtractFileDir(SelfPath);
end;

{ Las apps de [Dir] (y, si [Deep], las de sus carpetas): en macOS, los
  paquetes .app; en Windows, los .exe y los accesos directos (.lnk). }
procedure ScanDir(var List: TAppArray; const Dir: string; Deep: Boolean);
var
  R: TSearchRec;
  D, P, E: string;
begin
  D := IncludeTrailingPathDelimiter(Dir);
  if FindFirst(D + '*', faAnyFile or faDirectory, R) <> 0 then Exit;
  try
    repeat
      if (R.Name = '') or (R.Name[1] = '.') then Continue;
      P := D + R.Name;
      if SameFileName(ExcludeTrailingPathDelimiter(P), SelfPath) then Continue;
      E := LowerCase(ExtractFileExt(R.Name));
      {$IFDEF MSWINDOWS}
      if (R.Attr and faDirectory) <> 0 then
      begin
        if Deep then ScanDir(List, P, False);
      end
      else if ((E = '.exe') or (E = '.lnk')) and
        (Pos('uninst', LowerCase(R.Name)) = 0) then
        AddApp(List, P);
      {$ELSE}
      if E = '.app' then
        AddApp(List, P)
      else if Deep and ((R.Attr and faDirectory) <> 0) then
        ScanDir(List, P, False);
      {$ENDIF}
    until FindNext(R) <> 0;
  finally
    FindClose(R);
  end;
end;

function Before(const A, B: TApp): Boolean;
begin
  Result := UTF8CompareStr(A.Key, B.Key) < 0;
end;

procedure SortApps(var List: TAppArray);
var
  i, j: Integer;
  T: TApp;
begin
  for i := 1 to High(List) do
  begin
    T := List[i];
    j := i - 1;
    while (j >= 0) and Before(T, List[j]) do
    begin
      List[j + 1] := List[j];
      Dec(j);
    end;
    List[j + 1] := T;
  end;
end;

{ Las apps de la carpeta del lanzador (y de sus carpetas), por orden
  alfabético. DMS_LAUNCHER_DIRS (carpetas separadas por «;») cambia dónde
  se buscan (las pruebas y las capturas). }
function ScanApps: TAppArray;
var
  Dirs: TStringList;
  i: Integer;
  Spec: string;
begin
  Result := nil;
  if DirsOverridden then Spec := DirsOverride
  else Spec := GetEnvironmentVariable('DMS_LAUNCHER_DIRS');
  Dirs := TStringList.Create;
  try
    Dirs.Delimiter := ';';
    Dirs.StrictDelimiter := True;
    if Spec <> '' then
      Dirs.DelimitedText := Spec
    else
      Dirs.Add(HomeDir);
    for i := 0 to Dirs.Count - 1 do
      if DirectoryExists(Dirs[i]) then ScanDir(Result, Dirs[i], True);
  finally
    Dirs.Free;
  end;
  SortApps(Result);
end;

function FindApp(const Path: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Apps) do
    if Apps[i].Path = Path then Exit(i);
  Result := -1;
end;

{ Las que coinciden con la búsqueda (todas si está vacía): primero las que
  tienen una palabra que empieza así («ca» → Calculadora, Captura de
  Pantalla) y después las que solo lo contienen (Buscar). }
function Matches: TAppArray;
var
  i, n, pass, k: Integer;
  Q: string;
  Starts: Boolean;
begin
  Result := nil;
  n := 0;
  Q := Fold(Trim(Query));
  for pass := 0 to 1 do
    for i := 0 to High(Apps) do
    begin
      if Q = '' then
        Starts := True
      else
      begin
        k := Pos(Q, Apps[i].Key);
        if k = 0 then Continue;
        Starts := (k = 1) or (Pos(' ' + Q, Apps[i].Key) > 0);
      end;
      if Starts <> (pass = 0) then Continue;
      SetLength(Result, n + 1);
      Result[n] := Apps[i];
      Inc(n);
    end;
end;

function Signature: string;
var
  i: Integer;
begin
  Result := Favs.Text + '|' + Recent.Text + '|';
  for i := 0 to High(Apps) do Result := Result + Apps[i].Path + #10;
end;

procedure OpenApp(const Path: string);
begin
  OpenDocument(Path);
  Remember(Path);
end;

// ============================================================ los iconos
{ El icono de una app de [Size] píxeles, el mismo que enseña el Finder
  (NSWorkspace); nil si no hay (en Windows, el menú va sin iconos). }
function AppIcon(const Path: string; Size: Integer): TBitmap;
{$IFDEF DARWIN}
var
  Pool: NSAutoreleasePool;
  Img: NSImage;
  Rep: NSBitmapImageRep;
  Ctx: NSGraphicsContext;
  Intf: TLazIntfImage;
  d: TRawImageDescription;
  P: PByte;
  x, y, Row, k: Integer;
  a: Byte;
  C: TFPColor;
  Key: string;
{$ENDIF}
begin
  Result := nil;
  {$IFDEF DARWIN}
  Key := IntToStr(Size) + ':' + Path;
  k := Icons.IndexOf(Key);
  if k >= 0 then Exit(TBitmap(Icons.Objects[k]));
  Pool := NSAutoreleasePool.alloc.init;
  try
    Img := NSWorkspace.sharedWorkspace.iconForFile(NS(Path));
    if Img = nil then Exit;
    Rep := NSBitmapImageRep(NSBitmapImageRep.alloc.initWithBitmapDataPlanes_pixelsWide_pixelsHigh__colorSpaceName_bitmapFormat_bytesPerRow_bitsPerPixel(
      nil, Size, Size, 8, 4, True, False, NSDeviceRGBColorSpace, 0, Size * 4, 32));
    try
      Ctx := NSGraphicsContext.graphicsContextWithBitmapImageRep(Rep);
      NSGraphicsContext.classSaveGraphicsState;
      NSGraphicsContext.setCurrentContext(Ctx);
      Img.drawInRect_fromRect_operation_fraction(NSMakeRect(0, 0, Size, Size),
        NSMakeRect(0, 0, 0, 0), NSCompositeSourceOver, 1.0);
      Ctx.flushGraphics;
      NSGraphicsContext.classRestoreGraphicsState;
      // RGBA premultiplicado → la imagen de la LCL.
      P := PByte(Rep.bitmapData);
      Row := Rep.bytesPerRow;
      d.Init_BPP32_B8G8R8A8_BIO_TTB(Size, Size);
      Intf := TLazIntfImage.Create(0, 0);
      try
        Intf.DataDescription := d;
        for y := 0 to Size - 1 do
          for x := 0 to Size - 1 do
          begin
            a := P[y * Row + x * 4 + 3];
            if a = 0 then
            begin
              C.Red := 0; C.Green := 0; C.Blue := 0; C.Alpha := 0;
            end
            else
            begin
              C.Red := Min(255, P[y * Row + x * 4] * 255 div a) * 257;
              C.Green := Min(255, P[y * Row + x * 4 + 1] * 255 div a) * 257;
              C.Blue := Min(255, P[y * Row + x * 4 + 2] * 255 div a) * 257;
              C.Alpha := a * 257;
            end;
            Intf.Colors[x, y] := C;
          end;
        Result := TBitmap.Create;
        Result.LoadFromIntfImage(Intf);
      finally
        Intf.Free;
      end;
    finally
      Rep.release;
    end;
  finally
    Pool.release;
  end;
  if Result <> nil then Icons.AddObject(Key, Result);
  {$ENDIF}
end;

{ El icono de la barra en una rejilla de 22×22: nueve cuadritos redondeados. }
function GlyphAt(X, Y: Double): Boolean;
var
  i, j: Integer;
  cx, cy, dx, dy: Double;
begin
  for j := 0 to 2 do
    for i := 0 to 2 do
    begin
      cx := 4.5 + i * 6.5;
      cy := 4.5 + j * 6.5;
      dx := Max(0, Abs(X - cx) - 1.3);
      dy := Max(0, Abs(Y - cy) - 1.3);
      if dx * dx + dy * dy <= 1.35 * 1.35 then Exit(True);
    end;
  Result := False;
end;

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

{$IFDEF DARWIN}
{ El icono de la barra como plantilla de verdad: macOS solo mira su canal
  alfa y lo pinta del color de la barra. (Al pasar por TIcon se pierde la
  transparencia y se vería un cuadrado lleno.) [Dim]: más tenue. }
procedure TemplateImage(Img: NSImage; Size: Integer; Dim: Boolean);
var
  Rep: NSBitmapImageRep;
  Reps: NSArray;
  P: PByte;
  x, y, Row, i: Integer;
  a: Double;
begin
  Rep := NSBitmapImageRep(NSBitmapImageRep.alloc.initWithBitmapDataPlanes_pixelsWide_pixelsHigh__colorSpaceName_bitmapFormat_bytesPerRow_bitsPerPixel(
    nil, Size, Size, 8, 4, True, False, NSDeviceRGBColorSpace, 0, Size * 4, 32));
  P := PByte(Rep.bitmapData);
  Row := Rep.bytesPerRow;
  for y := 0 to Size - 1 do
    for x := 0 to Size - 1 do
    begin
      a := GlyphCover(x, y, Size);
      if Dim then a := a * 0.4;
      P[y * Row + x * 4] := 0;
      P[y * Row + x * 4 + 1] := 0;
      P[y * Row + x * 4 + 2] := 0;
      P[y * Row + x * 4 + 3] := Round(a * 255);
    end;
  Reps := NSArray.arrayWithArray(Img.representations);
  for i := 0 to Integer(Reps.count) - 1 do
    Img.removeRepresentation(NSImageRep(Reps.objectAtIndex(i)));
  Img.addRepresentation(Rep);
  Rep.release;
  Img.setSize(NSMakeSize(18, 18));
  Img.setTemplate(True);
end;

{ El alfa (0..255) del píxel (X, Y) de la imagen (las pruebas). }
function AlphaAt(Img: NSImage; X, Y: Integer): Integer;
var
  Rep: NSBitmapImageRep;
begin
  Result := -1;
  if Img.representations.count = 0 then Exit;
  Rep := NSBitmapImageRep(Img.representations.objectAtIndex(0));
  Result := PByte(Rep.bitmapData)[Y * Rep.bytesPerRow + X * 4 + 3];
end;
{$ENDIF}

function Glyph(Size: Integer): TBitmap;
var
  Img: TLazIntfImage;
  d: TRawImageDescription;
  x, y: Integer;
  C: TFPColor;
begin
  d.Init_BPP32_B8G8R8A8_BIO_TTB(Size, Size);
  Img := TLazIntfImage.Create(0, 0);
  try
    Img.DataDescription := d;
    for y := 0 to Size - 1 do
      for x := 0 to Size - 1 do
      begin
        {$IFDEF DARWIN}
        C.Red := 0; C.Green := 0; C.Blue := 0;
        {$ELSE}
        C.Red := $5B5B; C.Green := $4040; C.Blue := $E0E0;
        {$ENDIF}
        C.Alpha := Round(GlyphCover(x, y, Size) * $FFFF);
        Img.Colors[x, y] := C;
      end;
    Result := TBitmap.Create;
    Result.LoadFromIntfImage(Img);
  finally
    Img.Free;
  end;
end;

// ============================================================ el menú
function AddItem(Parent: TMenuItem; const Caption, Act: string;
  Handler: TNotifyEvent; Icon: TBitmap = nil): TMenuItem;
begin
  Result := TMenuItem.Create(Parent.Owner);
  Result.Caption := Caption;
  Result.Hint := Act;
  Result.OnClick := Handler;
  Result.Enabled := Act <> '';
  if Icon <> nil then
  begin
    Result.Bitmap := Icon;
    {$IFDEF DARWIN}
    // 32 píxeles en 16 puntos: nítido en Retina.
    if Result.Bitmap.Handle <> 0 then
      TCocoaBitmap(Result.Bitmap.Handle).Image.setSize(NSMakeSize(16, 16));
    {$ENDIF}
  end;
  Parent.Add(Result);
end;

procedure AddSep(Parent: TMenuItem);
begin
  AddItem(Parent, '-', '', nil);
end;

procedure AddApps(Parent: TMenuItem; const Paths: TStrings; H: TNotifyEvent);
var
  i, k: Integer;
begin
  for i := 0 to Paths.Count - 1 do
  begin
    k := FindApp(Paths[i]);
    if k >= 0 then
      AddItem(Parent, Apps[k].Name, 'open'#9 + Apps[k].Path, H, AppIcon(Apps[k].Path, MenuIcon));
  end;
end;

function CountIn(const Paths: TStrings): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Paths.Count - 1 do
    if FindApp(Paths[i]) >= 0 then Inc(Result);
end;

{ El menú del icono: las favoritas, las recientes y todas, por letras.
  [Lang]: el menú Idioma de la ventana (las demos), que se repite aquí. }
procedure BuildTray(Root: TMenuItem; H: TNotifyEvent; Lang: TMenuItem;
  LangH: TNotifyEvent);
var
  i, j: Integer;
  Sub, It: TMenuItem;
  L, Last: string;
begin
  Root.Clear;
  AddItem(Root, Fmt(tx_HEAD, [IntToStr(Length(Apps))]), '', nil);
  AddItem(Root, tx_SEARCH, 'panel', H);
  if CountIn(Favs) > 0 then
  begin
    AddSep(Root);
    AddItem(Root, tx_FAVORITES, '', nil);
    AddApps(Root, Favs, H);
  end;
  if CountIn(Recent) > 0 then
  begin
    AddSep(Root);
    AddItem(Root, tx_RECENT, '', nil);
    AddApps(Root, Recent, H);
  end;
  AddSep(Root);
  if Length(Apps) <= 40 then
    for i := 0 to High(Apps) do
      AddItem(Root, Apps[i].Name, 'open'#9 + Apps[i].Path, H, AppIcon(Apps[i].Path, MenuIcon))
  else
  begin
    // Una opción por letra, con sus apps dentro.
    Last := '';
    Sub := nil;
    for i := 0 to High(Apps) do
    begin
      L := Letter(Apps[i].Name);
      if (Sub = nil) or (L <> Last) then
      begin
        Sub := nil;
        for j := 0 to Root.Count - 1 do
          if (Root[j].Hint = 'sub') and (Root[j].Caption = L) then Sub := Root[j];
        if Sub = nil then Sub := AddItem(Root, L, 'sub', nil);
        Last := L;
      end;
      AddItem(Sub, Apps[i].Name, 'open'#9 + Apps[i].Path, H, AppIcon(Apps[i].Path, MenuIcon));
    end;
  end;
  if Length(Apps) = 0 then AddItem(Root, tx_NO_APPS, '', nil);
  AddSep(Root);
  AddItem(Root, tx_RESCAN, 'rescan', H);
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

{ Las teselas del panel: las favoritas (sin búsqueda) y todas las que
  coinciden. [Sel]: la elegida con el teclado (la primera que coincide). }
procedure PaintPanel(Cv: TCanvas; W, H: Integer; AZoom: Double;
  Scroll, Hover, Sel: Integer; out Hits: THits; out ContentH: Integer);
const
  TW = 132; TH = 128;
var
  List: TAppArray;
  FavList: TAppArray;
  i, k, y, cols, x0, nHits, nTile: Integer;
  Ink, Grey: TColor;

  function AddHit(R: TRect; const A: string): Boolean;
  begin
    SetLength(Hits, nHits + 1);
    Hits[nHits].R := R;
    Hits[nHits].Act := A;
    Result := nHits = Hover;
    Inc(nHits);
  end;

  procedure Tile(const A: TApp; X, Y: Integer);
  var
    R, SR: TRect;
    Hot, Fav, Chosen: Boolean;
    Ic: TBitmap;
    T: string;
    isz: Integer;
  begin
    R := Rect(X, Y, X + S(TW) - S(8), Y + S(TH) - S(8));
    Hot := AddHit(R, 'open'#9 + A.Path);
    Chosen := nTile = Sel;
    Inc(nTile);
    if Chosen then Card(Cv, R, Hex('#dbe7ff'), Hex('#93b4f5'), S(18))
    else if Hot then Card(Cv, R, Hex('#eef2f8'), Hex('#dfe5ee'), S(18));
    isz := S(64);
    Ic := AppIcon(A.Path, TileIcon);
    if Ic <> nil then
      Cv.StretchDraw(Rect((R.Left + R.Right - isz) div 2, R.Top + S(12),
        (R.Left + R.Right + isz) div 2, R.Top + S(12) + isz), Ic)
    else
    begin
      Card(Cv, Rect((R.Left + R.Right - isz) div 2, R.Top + S(12),
        (R.Left + R.Right + isz) div 2, R.Top + S(12) + isz), Hex('#5b40e0'), Hex('#5b40e0'), S(16));
      Pen(Cv, 30, True, clWhite);
      Cv.TextOut((R.Left + R.Right - Cv.TextWidth(Letter(A.Name))) div 2,
        R.Top + S(12) + (isz - Cv.TextHeight('A')) div 2, Letter(A.Name));
    end;
    Pen(Cv, 12.5, Chosen, Ink);
    T := Fit(Cv, A.Name, R.Right - R.Left - S(12));
    Cv.TextOut((R.Left + R.Right - Cv.TextWidth(T)) div 2, R.Top + S(84), T);
    // La estrella: rellena si es favorita; vacía, al pasar por encima.
    Fav := Favs.IndexOf(A.Path) >= 0;
    if Fav or Hot then
    begin
      SR := Rect(R.Right - S(30), R.Top + S(6), R.Right - S(6), R.Top + S(30));
      AddHit(SR, 'fav'#9 + A.Path);
      if Fav then Pen(Cv, 17, True, Hex('#f5a524')) else Pen(Cv, 17, False, Hex('#9aa3b2'));
      if Fav then T := '★' else T := '☆';
      Cv.TextOut((SR.Left + SR.Right - Cv.TextWidth(T)) div 2,
        (SR.Top + SR.Bottom - Cv.TextHeight(T)) div 2, T);
    end;
  end;

  procedure Grid(const L: TAppArray);
  var
    j: Integer;
  begin
    for j := 0 to High(L) do
    begin
      Tile(L[j], x0 + (j mod cols) * S(TW), y + (j div cols) * S(TH));
    end;
    y := y + ((Length(L) + cols - 1) div cols) * S(TH);
  end;

  procedure Section(const T: string);
  begin
    Pen(Cv, 11.5, True, Grey);
    Cv.TextOut(x0 + S(4), y, T);
    y := y + S(26);
  end;

begin
  Z := AZoom;
  nHits := 0;
  nTile := 0;
  Hits := nil;
  Ink := Hex('#1f2937');
  Grey := Hex('#6b7280');
  Cv.Brush.Style := bsSolid;
  Cv.Brush.Color := Hex('#f4f6f9');
  Cv.FillRect(0, 0, W, H);
  cols := Max(1, (W - S(32)) div S(TW));
  x0 := (W - cols * S(TW)) div 2 + S(4);
  y := S(14) - Scroll;
  List := Matches;
  if Trim(Query) = '' then
  begin
    FavList := nil;
    for i := 0 to Favs.Count - 1 do
    begin
      k := FindApp(Favs[i]);
      if k >= 0 then
      begin
        SetLength(FavList, Length(FavList) + 1);
        FavList[High(FavList)] := Apps[k];
      end;
    end;
    if Length(FavList) > 0 then
    begin
      Section(Fmt(tx_SEC_FAV, [IntToStr(Length(FavList))]));
      Grid(FavList);
      y := y + S(10);
    end;
    Section(Fmt(tx_SEC_ALL, [IntToStr(Length(List))]));
  end
  else
    Section(Fmt(tx_SEC_FOUND, [IntToStr(Length(List)), Query]));
  if Length(List) = 0 then
  begin
    Pen(Cv, 14, False, Grey);
    Cv.TextOut(x0 + S(4), y + S(10), tx_NONE_FOUND);
    y := y + S(50);
  end;
  Grid(List);
  ContentH := y + Scroll + S(14);
end;

// ============================================================ las capturas
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
    Result := Mix(Hex('#123a5e'), Hex('#2f6f8f'), Y / (H / 2))
  else
    Result := Mix(Hex('#2f6f8f'), Hex('#e3a35b'), (Y - H / 2) / (H / 2));
end;

{ Un menú como los de macOS, con sus iconos, en (X, Y); [Hi]: la opción
  resaltada. Devuelve el rectángulo de la resaltada. }
function DrawMenu(Cv: TCanvas; X, Y: Integer; Items: TMenuItem; Hi: Integer): TRect;
const
  RowH = 36; SepH = 14; PadL = 40; PadR = 46;
var
  i, w, h, yy, k: Integer;
  R, IR: TRect;
  It: TMenuItem;
  Col: TColor;
  Ic: TBitmap;
begin
  Result := Rect(0, 0, 0, 0);
  Pen(Cv, 17, False, clBlack);
  w := 280;
  h := 12;
  for i := 0 to Items.Count - 1 do
  begin
    w := Max(w, Cv.TextWidth(Items[i].Caption) + PadL + PadR);
    if Items[i].Caption = '-' then Inc(h, SepH) else Inc(h, RowH);
  end;
  R := Rect(X, Y, X + w, Y + h);
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
    if Copy(It.Hint, 1, 5) = 'open'#9 then
    begin
      Ic := AppIcon(Copy(It.Hint, 6, MaxInt), TileIcon);
      if Ic <> nil then Cv.StretchDraw(Rect(X + 10, yy + 5, X + 36, yy + 31), Ic);
    end;
    Pen(Cv, 17, False, Col);
    Cv.TextOut(X + PadL, yy + (RowH - Cv.TextHeight(It.Caption)) div 2, It.Caption);
    if It.Count > 0 then
    begin
      Pen(Cv, 22, False, Col);
      Cv.TextOut(X + w - 28, yy + (RowH - Cv.TextHeight('›')) div 2 - 1, '›');
    end;
    Inc(yy, RowH);
  end;
end;

procedure SavePng(Bmp: TBitmap; const FileName: string);
var
  Png: TPortableNetworkGraphic;
begin
  Png := TPortableNetworkGraphic.Create;
  try
    Png.Assign(Bmp);
    Png.SaveToFile(FileName);
  finally
    Png.Free;
  end;
end;

procedure Desk(const FileName: string; Root: TMenuItem; Open, SubHi: Integer);
const
  W = 1600; H = 1000; BarH = 44;
var
  Bmp: TBitmap;
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
    Pen(Bmp.Canvas, 17, True, Hex('#1d1d1f'));
    T := '17:02';
    Bmp.Canvas.TextOut(W - 30 - Bmp.Canvas.TextWidth(T), (BarH - Bmp.Canvas.TextHeight(T)) div 2, T);
    ix := W - 900;
    gs := 32;
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
    SavePng(Bmp, FileName);
  finally
    Bmp.Free;
  end;
end;

function ItemIndex(Root: TMenuItem; const Caption: string): Integer;
var
  i: Integer;
begin
  for i := 0 to Root.Count - 1 do
    if Root[i].Caption = Caption then Exit(i);
  Result := -1;
end;

{ Unas favoritas y recientes de ejemplo (las primeras que encuentre de
  [AFav] y de [ARec], o las primeras de la lista). }
procedure SampleConfig(const AFav, ARec: array of string);
  procedure Pick(L: TStrings; const Names: array of string; N: Integer);
  var
    i, k: Integer;
  begin
    for k := 0 to High(Names) do
      for i := 0 to High(Apps) do
        if (L.Count < N) and (Pos(Fold(Names[k]), Apps[i].Key) = 1) and
          (Favs.IndexOf(Apps[i].Path) < 0) and (Recent.IndexOf(Apps[i].Path) < 0) then
          L.Add(Apps[i].Path);
    for i := 0 to High(Apps) do
      if (L.Count < N) and (Favs.IndexOf(Apps[i].Path) < 0) and
        (Recent.IndexOf(Apps[i].Path) < 0) then
        L.Add(Apps[i].Path);
  end;
begin
  Favs.Clear;
  Recent.Clear;
  Pick(Favs, AFav, 3);
  Pick(Recent, ARec, 2);
end;

{ El panel como se ve: el buscador (con [AQuery]) y las teselas. }
procedure PanelShot(const FileName, AQuery: string; Sel: Integer);
const
  W = 1600; H = 1000;
var
  Bmp, Body: TBitmap;
  Hits: THits;
  CH, top: Integer;
  R: TRect;
begin
  Z := 1.25;
  Query := AQuery;
  top := S(64);
  Bmp := TBitmap.Create;
  Body := TBitmap.Create;
  try
    Bmp.SetSize(W, H);
    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.Brush.Color := Hex('#f4f6f9');
    Bmp.Canvas.FillRect(0, 0, W, H);
    R := Rect(S(20), S(16), W - S(20), S(16) + S(36));
    Card(Bmp.Canvas, R, clWhite, Hex('#2f6fea'), S(10));
    if AQuery = '' then
    begin
      Pen(Bmp.Canvas, 15, False, Hex('#9aa3b2'));
      Bmp.Canvas.TextOut(R.Left + S(12), R.Top + (S(36) - Bmp.Canvas.TextHeight('Ág')) div 2, tx_SEARCH_HINT);
    end
    else
    begin
      Pen(Bmp.Canvas, 15, False, Hex('#1f2937'));
      Bmp.Canvas.TextOut(R.Left + S(12), R.Top + (S(36) - Bmp.Canvas.TextHeight('Ág')) div 2, AQuery);
    end;
    Body.SetSize(W, H - top);
    PaintPanel(Body.Canvas, W, H - top, 1.25, 0, -1, Sel, Hits, CH);
    Bmp.Canvas.Draw(0, top, Body);
    SavePng(Bmp, FileName);
  finally
    Body.Free;
    Bmp.Free;
  end;
  Query := '';
end;

{ DMS_LAUNCHER_SHOT=carpeta: las capturas de la web, sin ventana, con las
  apps de DMS_LAUNCHER_DIRS (las demos del estudio) o de su carpeta. }
function Shots(const Dir: string): Integer;
var
  M: TPopupMenu;
  k: Integer;
begin
  ForceDirectories(Dir);
  Apps := ScanApps;
  // Como la app de verdad, sin el propio lanzador (aquí, otra copia).
  for k := High(Apps) downto 0 do
    if Pos(Fold(tx_APP), Apps[k].Key) = 1 then Delete(Apps, k, 1);
  SampleConfig(['Docker', 'Calculadora', 'Calculator', 'Consola', 'Console'],
    ['Explorador', 'File Explorer', 'Wifi', 'Home Wi']);
  M := TPopupMenu.Create(nil);
  try
    BuildTray(M.Items, nil, nil, nil);
    Desk(Dir + '/menu.png', M.Items, -1, -1);
    k := ItemIndex(M.Items, Apps[FindApp(Favs[0])].Name);
    Desk(Dir + '/menu-hi.png', M.Items, k, -1);
  finally
    M.Free;
  end;
  PanelShot(Dir + '/panel.png', '', -1);
  PanelShot(Dir + '/search.png', 'co', 0);
  WriteLn('shots ok ', Dir);
  Result := 0;
end;

// ============================================================ las pruebas
{ Sin ventana: DMS_LAUNCHER_SELFTEST=1. Unas apps de mentira en una carpeta
  temporal, la búsqueda, las favoritas y las recientes, el menú (con sus
  iconos de 16 puntos) y el panel; y las apps de verdad del equipo. }
function SelfTest: Integer;
var
  fails, i, CH: Integer;
  Tmp: string;
  M: TPopupMenu;
  Hits: THits;
  Bmp: TBitmap;
  Found: Boolean;
  Ico: TIcon;

  procedure Check(Ok: Boolean; const What: string);
  begin
    if not Ok then
    begin
      WriteLn('FAIL ', What);
      Inc(fails);
    end;
  end;

  procedure MakeApp(const Path: string);
  begin
    {$IFDEF MSWINDOWS}
    ForceDirectories(ExtractFilePath(Path));
    with TStringList.Create do
    try
      SaveToFile(Path);
    finally
      Free;
    end;
    {$ELSE}
    ForceDirectories(Path + '/Contents');
    {$ENDIF}
  end;

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

var
  Ext: string;
begin
  fails := 0;
  Check(Fold('Ánimo Ñandú') = 'animo nandu', 'sin acentos');
  Check(Letter('Él') = 'E', 'letra con acento');
  Check(Letter('1Password') = '#', 'letra de un número');
  // Unas apps de mentira (también dentro de una carpeta y una que no es app).
  {$IFDEF MSWINDOWS}Ext := '.lnk';{$ELSE}Ext := '.app';{$ENDIF}
  Tmp := IncludeTrailingPathDelimiter(GetTempDir) + 'dms_launcher_' + IntToStr(GetProcessID);
  MakeApp(Tmp + '/Zebra' + Ext);
  MakeApp(Tmp + '/Ábaco' + Ext);
  MakeApp(Tmp + '/Calculadora' + Ext);
  MakeApp(Tmp + '/Radio' + Ext);
  MakeApp(Tmp + '/Utilidades/Terminal' + Ext);
  ForceDirectories(Tmp + '/Notas sueltas');
  DirsOverridden := True;
  DirsOverride := Tmp;
  ConfigOverride := Tmp + '/config.txt';
  NameStyle := 'file';
  Apps := ScanApps;
  Check(Length(Apps) = 5, 'cinco apps (' + IntToStr(Length(Apps)) + ')');
  if Length(Apps) = 5 then
    Check((Apps[0].Name = 'Ábaco') and (Apps[1].Name = 'Calculadora') and
      (Apps[2].Name = 'Radio') and (Apps[3].Name = 'Terminal') and
      (Apps[4].Name = 'Zebra'), 'orden alfabético');
  Query := 'ABAC';
  Check((Length(Matches) = 1) and (Matches[0].Name = 'Ábaco'), 'buscar sin acentos');
  Query := 'zz';
  Check(Length(Matches) = 0, 'buscar nada');
  Query := 'ra';
  Check((Length(Matches) = 3) and (Matches[0].Name = 'Radio') and
    (Matches[1].Name = 'Calculadora'), 'primero las que empiezan así');
  Query := '';
  Check(Length(Matches) = 5, 'sin búsqueda, todas');
  // Favoritas y recientes, guardadas.
  LoadConfig;
  ToggleFav(Apps[4].Path);
  Remember(Apps[1].Path);
  Remember(Apps[2].Path);
  Remember(Apps[1].Path);
  LoadConfig;
  Check((Favs.Count = 1) and (Favs[0] = Apps[4].Path), 'favorita guardada');
  Check((Recent.Count = 2) and (Recent[0] = Apps[1].Path), 'recientes en orden');
  for i := 1 to 10 do Remember(Tmp + '/x' + IntToStr(i));
  Check(Recent.Count = MaxRecent, 'como mucho seis recientes');
  Recent.Clear;
  Remember(Apps[2].Path);
  ToggleFav(Apps[4].Path);
  ToggleFav(Apps[4].Path);
  Check(Favs.Count = 1, 'quitar y poner favorita');
  // El menú.
  M := TPopupMenu.Create(nil);
  try
    BuildTray(M.Items, nil, nil, nil);
    Check(Has(M.Items, 'Zebra', 'open'#9 + Apps[4].Path), 'la app en el menú');
    Check(Has(M.Items, tx_FAVORITES, ''), 'favoritas en el menú');
    Check(Has(M.Items, tx_RECENT, ''), 'recientes en el menú');
    Check(Has(M.Items, Fmt(tx_HEAD, ['5']), ''), 'cuántas');
  finally
    M.Free;
  end;
  // El panel.
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(900, 600);
    PaintPanel(Bmp.Canvas, 900, 600, 1, 0, -1, 0, Hits, CH);
    Found := False;
    for i := 0 to High(Hits) do
      if Hits[i].Act = 'open'#9 + Apps[0].Path then Found := True;
    Check(Found, 'el panel abre la app');
    Found := False;
    for i := 0 to High(Hits) do
      if Hits[i].Act = 'fav'#9 + Apps[4].Path then Found := True;
    Check(Found, 'la estrella de la favorita');
  finally
    Bmp.Free;
  end;
  {$IFDEF DARWIN}
  // El icono de una app de verdad.
  Bmp := AppIcon('/System/Applications/Calculator.app', MenuIcon);
  Check((Bmp <> nil) and (Bmp.Width = MenuIcon), 'el icono de la calculadora');
  // En el menú de verdad, los iconos miden 16 puntos.
  M := TPopupMenu.Create(nil);
  try
    M.HandleNeeded;
    BuildTray(M.Items, nil, nil, nil);
    Found := False;
    for i := 0 to M.Items.Count - 1 do
      with M.Items[i] do
        if (Copy(Hint, 1, 5) = 'open'#9) and HandleAllocated and
          (NSMenuItem(Handle).image <> nil) then
        begin
          Found := True;
          Check(Round(NSMenuItem(Handle).image.size.width) = 16, 'icono de 16 puntos (' +
            IntToStr(Round(NSMenuItem(Handle).image.size.width)) + ')');
          Break;
        end;
    Check(Found, 'el menú lleva iconos');
  finally
    M.Free;
  end;
  {$ENDIF}
  // Sin DMS_LAUNCHER_DIRS: las apps de su propia carpeta (y no ella misma).
  DirsOverridden := False;
  Apps := ScanApps;
  WriteLn('carpeta: ', HomeDir, ' · apps: ', Length(Apps));
  for i := 0 to High(Apps) do
    Check(Apps[i].Path <> SelfPath, 'no se lanza a sí misma');
  {$IFDEF DARWIN}
  // El icono de la barra: transparente fuera del dibujo (no un cuadrado).
  Ico := TIcon.Create;
  try
    Bmp := Glyph(44);
    Ico.Assign(Bmp);
    Bmp.Free;
    TemplateImage(TCocoaBitmap(Ico.Handle).Image, 44, False);
    Check(AlphaAt(TCocoaBitmap(Ico.Handle).Image, 0, 0) = 0, 'icono: esquina transparente');
    Check(AlphaAt(TCocoaBitmap(Ico.Handle).Image, 9, 9) > 200, 'icono: el dibujo opaco');
    Check(TCocoaBitmap(Ico.Handle).Image.isTemplate, 'icono: plantilla');
  finally
    Ico.Free;
  end;
  {$ENDIF}
  if fails = 0 then WriteLn('selftest ok');
  if fails = 0 then Result := 0 else Result := 1;
end;

// ============================================================ la ventana
procedure TForm1.form_create;
begin
  StageHint.Visible := False;
  if GetEnvironmentVariable('DMS_LAUNCHER_SELFTEST') <> '' then Halt(SelfTest);
  if GetEnvironmentVariable('DMS_LAUNCHER_SHOT') <> '' then
    Halt(Shots(GetEnvironmentVariable('DMS_LAUNCHER_SHOT')));
  // La app vive en la barra de menús: la ventana (el panel) no se abre sola.
  Application.ShowMainForm := False;
  Stage.BevelOuter := bvNone;
  Stage.DoubleBuffered := True;
  Stage.Anchors := [akLeft, akTop, akRight, akBottom];
  Search.Anchors := [akLeft, akTop, akRight];
  Box := TPaintBox.Create(Self);
  Box.Parent := Stage;
  Box.Align := alClient;
  Box.OnPaint := @BoxPaint;
  Box.OnMouseDown := @BoxDown;
  Box.OnMouseMove := @BoxMove;
  Box.OnMouseWheel := @BoxWheel;
  Search.OnChange := @SearchChange;
  Search.OnKeyDown := @SearchKey;
  Search.TextHint := tx_SEARCH_HINT;
  FHover := -1;
  OnClose := @PanelClose;
  TrayMenu := TPopupMenu.Create(Self);
  Tray := TTrayIcon.Create(Self);
  Tray.PopUpMenu := TrayMenu;
  Tray.OnClick := @TrayClick;
  Tray.Hint := tx_APP;
  Tick.Enabled := False;
  Application.QueueAsyncCall(@StartUp, 0);
end;

procedure TForm1.StartUp(Data: PtrInt);
begin
  {$IFDEF DARWIN}
  NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory);
  {$ENDIF}
  LoadConfig;
  Apps := ScanApps;
  Rebuild;
  SetIcon;
  Tray.Show;
  Tick.Enabled := True;
end;

procedure TForm1.SetIcon;
var
  B: TBitmap;
  I: TIcon;
begin
  if FIconSet then Exit;
  FIconSet := True;
  B := Glyph({$IFDEF DARWIN}44{$ELSE}32{$ENDIF});
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
    TemplateImage(TCocoaBitmap(Tray.Icon.Handle).Image, 44, False);
  Tray.InternalUpdate;
  {$ENDIF}
end;

{ Cada medio minuto: si se instaló o se borró una app, el menú cambia. }
procedure TForm1.Tick_timer;
begin
  Rescan;
end;

procedure TForm1.Rescan;
begin
  Apps := ScanApps;
  Rebuild;
  if Visible then Box.Invalidate;
end;

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
  BuildTray(TrayMenu.Items, @TrayItem, L, @TrayItem);
  Tray.Hint := Fmt(tx_HEAD, [IntToStr(Length(Apps))]);
end;

procedure TForm1.TrayItem(Sender: TObject);
begin
  FPending := TMenuItem(Sender).Hint;
  Application.QueueAsyncCall(@DoPending, 0);
end;

procedure TForm1.DoPending(Data: PtrInt);
begin
  Act(FPending);
end;

procedure TForm1.TrayClick(Sender: TObject);
begin
  ShowPanel;
end;

procedure TForm1.ShowPanel;
begin
  {$IFDEF DARWIN}
  NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular);
  {$ENDIF}
  Show;
  WindowState := wsNormal;
  BringToFront;
  Application.BringToFront;
  {$IFDEF DARWIN}
  NSApp.activateIgnoringOtherApps(True);
  {$ENDIF}
  Search.SelectAll;
  ActiveControl := Search;
  FSel := 0;
  Box.Invalidate;
end;

procedure TForm1.ToAccessory(Data: PtrInt);
begin
  {$IFDEF DARWIN}
  if not Visible then NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory);
  {$ENDIF}
end;

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
  p: Integer;
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
  if K = 'open' then
  begin
    OpenApp(V);
    Rebuild;
    // Abierta desde el panel, la ventana deja paso a la app.
    if Visible then Close;
  end
  else if K = 'fav' then
  begin
    ToggleFav(V);
    Rebuild;
    Box.Invalidate;
  end
  else if K = 'panel' then
    ShowPanel
  else if K = 'rescan' then
    Rescan
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
  if Item = tx_MP_RESCAN then Act('rescan')
  else if Item = tx_MP_HIDE then Act('hide')
  else if Item = tx_MP_QUIT then Act('quit')
  else if Item = tx_MP_HOWTO then Act('howto')
  else if Item = tx_MP_ABOUT then Act('about');
end;

procedure TForm1.SearchChange(Sender: TObject);
begin
  Query := Search.Text;
  FSel := 0;
  FScroll := 0;
  Box.Invalidate;
end;

{ Intro abre la elegida (la primera que coincide). }
procedure TForm1.Search_enter;
var
  L: TAppArray;
begin
  L := Matches;
  if (FSel >= 0) and (FSel < Length(L)) and (Trim(Query) <> '') then
    Act('open'#9 + L[FSel].Path)
  else if Length(L) > 0 then
    Act('open'#9 + L[0].Path);
end;

{ Las flechas eligen entre las que coinciden; Esc borra o cierra. }
procedure TForm1.SearchKey(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  n, cols: Integer;
begin
  n := Length(Matches);
  cols := Max(1, (Box.Width - 32) div 132);
  case Key of
    VK_RIGHT: if Search.SelStart >= UTF8Length(Search.Text) then FSel := Min(n - 1, FSel + 1) else Exit;
    VK_LEFT: if Search.SelStart >= UTF8Length(Search.Text) then FSel := Max(0, FSel - 1) else Exit;
    VK_DOWN: FSel := Min(n - 1, FSel + cols);
    VK_UP: FSel := Max(0, FSel - cols);
    VK_ESCAPE:
      if Search.Text <> '' then Search.Text := '' else Close;
  else
    Exit;
  end;
  Key := 0;
  Box.Invalidate;
end;

procedure TForm1.BoxPaint(Sender: TObject);
var
  Most, Sel: Integer;
begin
  if Trim(Query) = '' then Sel := -1 else Sel := FSel;
  PaintPanel(Box.Canvas, Box.Width, Box.Height, 1, FScroll, FHover, Sel, FHits, FContentH);
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
  // La estrella va encima de su tesela: gana la última.
  for i := High(FHits) downto 0 do
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
  // Al pasar por la estrella, la tesela sigue resaltada.
  if (i >= 0) and (Copy(FHits[i].Act, 1, 4) = 'fav'#9) and (i > 0) then i := i - 1;
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
  Favs := TStringList.Create;
  Recent := TStringList.Create;
  Icons := TStringList.Create;
  Icons.OwnsObjects := True;

finalization
  Icons.Free;
  Recent.Free;
  Favs.Free;
end.
''';
