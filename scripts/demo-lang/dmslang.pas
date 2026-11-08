{ Una demo de DMarlon Studio en español y en inglés (scripts/build_demos.py).

  La demo se compila dos veces, una por idioma, y los dos ejecutables van
  juntos. Esta unidad, en el «uses» del programa, abre el del idioma elegido:
  el que se guardó en «DMarlon Studio Demos/lang» (el mismo para todas las
  demos) o, la primera vez, el del sistema. Añade el menú Idioma / Language
  a la ventana principal: al cambiar, la ventana se cierra como siempre y se
  abre el otro ejecutable. build_demos.py cambia @OWN@ y @OTHER@. }
unit dmslang;

{$mode objfpc}{$H+}
{$IFDEF DARWIN}{$modeswitch objectivec1}{$ENDIF}

interface

implementation

uses
  {$IFDEF DARWIN}CocoaAll,{$ENDIF}
  {$IFDEF UNIX}BaseUnix,{$ENDIF}
  {$IFDEF MSWINDOWS}Windows, ShellApi,{$ENDIF}
  Classes, SysUtils, Forms, Menus, Dialogs, Controls;

const
  DmsOwn = '@OWN@';
  DmsOther = '@OTHER@'; // el ejecutable del otro idioma, junto a este

type
  {$IFDEF DARWIN}
  TDmsLangTarget = objcclass(NSObject)
  public
    procedure picked(sender: id); message 'dmsLangPicked:';
  end;
  {$ENDIF}

  TDmsLang = class
    procedure AddMenu(Data: PtrInt);
    procedure Pick(Sender: TObject);
  end;

var
  Helper: TDmsLang;
  Target: string = '';
  {$IFDEF DARWIN}
  CocoaTarget: TDmsLangTarget = nil;
  {$ENDIF}

{$IFDEF MSWINDOWS}
function GetUserDefaultUILanguage: Word; stdcall; external 'kernel32.dll';
{$ENDIF}

{$IFDEF DARWIN}
procedure AddCocoaMenu; forward;
{$ENDIF}

function PrefFile: string;
begin
  {$IFDEF DARWIN}
  Result := GetUserDir + 'Library/Application Support/DMarlon Studio Demos/lang';
  {$ELSE}
  {$IFDEF MSWINDOWS}
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
    'DMarlon Studio Demos\lang';
  {$ELSE}
  Result := GetUserDir + '.config/DMarlon Studio Demos/lang';
  {$ENDIF}
  {$ENDIF}
end;

function SystemLang: string;
{$IFDEF DARWIN}
var
  L: NSArray;
{$ENDIF}
begin
  Result := 'en';
  {$IFDEF DARWIN}
  L := NSLocale.preferredLanguages;
  if (L <> nil) and (L.count > 0) and
    (Pos('es', LowerCase(string(NSString(L.objectAtIndex(0)).UTF8String))) = 1) then
    Result := 'es';
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  if (GetUserDefaultUILanguage and $3FF) = $0A then Result := 'es';
  {$ENDIF}
  {$IFDEF LINUX}
  if Pos('es', LowerCase(GetEnvironmentVariable('LANG'))) = 1 then Result := 'es';
  {$ENDIF}
end;

function Wanted: string;
var
  S: TStringList;
begin
  Result := '';
  if FileExists(PrefFile) then
  try
    S := TStringList.Create;
    try
      S.LoadFromFile(PrefFile);
      if S.Count > 0 then Result := Trim(S[0]);
    finally
      S.Free;
    end;
  except
    Result := '';
  end;
  if (Result <> 'es') and (Result <> 'en') then Result := SystemLang;
end;

function OtherExe: string;
begin
  Result := ExtractFilePath(ExpandFileName(ParamStr(0))) + DmsOther;
end;

{ En macOS y Linux, el otro ejecutable ocupa este proceso; en Windows, se
  abre y este termina. }
procedure Launch(const Exe: string);
{$IFDEF UNIX}
var
  Args: array[0..1] of PChar;
{$ENDIF}
begin
  {$IFDEF UNIX}
  Args[0] := PChar(Exe);
  Args[1] := nil;
  FpExecv(PChar(Exe), @Args[0]);
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(Exe), nil, PChar(ExtractFilePath(Exe)), SW_SHOWNORMAL);
  {$ENDIF}
end;

procedure TDmsLang.AddMenu(Data: PtrInt);
const
  Names: array[0..1] of string = ('Español', 'English');
  Codes: array[0..1] of string = ('es', 'en');
var
  F: TForm;
  M: TMainMenu;
  Root, It: TMenuItem;
  H, I: Integer;
  Fresh: Boolean;
begin
  F := Application.MainForm;
  if F = nil then Exit;
  {$IFDEF DARWIN}
  // Sin menú propio, la ventana usa la barra de menú de la aplicación, que
  // la LCL no cambia: «Idioma» va ahí, detrás del menú de la aplicación.
  if F.Menu = nil then
  begin
    AddCocoaMenu;
    Exit;
  end;
  {$ENDIF}
  H := F.ClientHeight;
  M := F.Menu;
  Fresh := M = nil;
  if Fresh then M := TMainMenu.Create(F);
  Root := TMenuItem.Create(M);
  if DmsOwn = 'es' then Root.Caption := 'Idioma' else Root.Caption := 'Language';
  for I := 0 to 1 do
  begin
    It := TMenuItem.Create(Root);
    It.Caption := Names[I];
    It.Tag := I;
    It.RadioItem := True;
    It.GroupIndex := 1;
    It.Checked := Codes[I] = DmsOwn;
    It.OnClick := @Pick;
    Root.Add(It);
  end;
  M.Items.Add(Root);
  if Fresh then F.Menu := M;
  {$IFNDEF DARWIN}
  // En Windows la barra de menú va dentro de la ventana: que no quite sitio.
  F.ClientHeight := H;
  {$ENDIF}
end;

{ Guarda el idioma elegido y cierra la ventana como siempre: al terminar,
  se abre el ejecutable del otro idioma (finalization). }
procedure Choose(const Code: string);
var
  Msg: string;
  S: TStringList;
begin
  if Code = DmsOwn then Exit;
  if DmsOwn = 'es' then
    Msg := 'La aplicación se volverá a abrir en English. Lo que no esté guardado se perderá.'
  else
    Msg := 'The app will reopen in Español. Anything not saved will be lost.';
  if MessageDlg(Msg, mtConfirmation, [mbOK, mbCancel], 0) <> mrOK then Exit;
  ForceDirectories(ExtractFilePath(PrefFile));
  S := TStringList.Create;
  try
    S.Text := Code;
    S.SaveToFile(PrefFile);
  finally
    S.Free;
  end;
  Target := OtherExe;
  Application.MainForm.Close;
end;

procedure TDmsLang.Pick(Sender: TObject);
begin
  if TMenuItem(Sender).Tag = 0 then Choose('es') else Choose('en');
end;

{$IFDEF DARWIN}
procedure TDmsLangTarget.picked(sender: id);
begin
  if NSMenuItem(sender).tag = 0 then Choose('es') else Choose('en');
end;

procedure AddCocoaMenu;
const
  Names: array[0..1] of string = ('Español', 'English');
  Codes: array[0..1] of string = ('es', 'en');
var
  Bar, Sub: NSMenu;
  Root, It: NSMenuItem;
  Title: NSString;
  I: Integer;
begin
  Bar := NSApp.mainMenu;
  if Bar = nil then Exit;
  CocoaTarget := TDmsLangTarget.alloc.init;
  if DmsOwn = 'es' then Title := NSString.stringWithUTF8String('Idioma')
  else Title := NSString.stringWithUTF8String('Language');
  Sub := NSMenu.alloc.initWithTitle(Title);
  for I := 0 to 1 do
  begin
    It := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
      NSString.stringWithUTF8String(PChar(Names[I])), objcselector('dmsLangPicked:'),
      NSString.stringWithUTF8String(''));
    It.setTarget(CocoaTarget);
    It.setTag(I);
    if Codes[I] = DmsOwn then It.setState(NSOnState);
    Sub.addItem(It);
    It.release;
  end;
  Root := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(Title, nil,
    NSString.stringWithUTF8String(''));
  Root.setSubmenu(Sub);
  Sub.release;
  Bar.addItem(Root);
  Root.release;
end;
{$ENDIF}

initialization
  Helper := TDmsLang.Create;
  if (Wanted <> DmsOwn) and FileExists(OtherExe) then
  begin
    Launch(OtherExe);
    {$IFDEF MSWINDOWS}
    Halt(0);
    {$ENDIF}
  end;
  Application.QueueAsyncCall(@Helper.AddMenu, 0);

finalization
  if Target <> '' then Launch(Target);
  Helper.Free;
end.
