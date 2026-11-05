import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_codegen.dart';
import 'tk_cpp.dart';
import 'tk_model.dart';
import 'tk_unit.dart';

/// Genera una aplicación de escritorio en Object Pascal con Lazarus (LCL):
/// los componentes son los de siempre (TLabel, TButton, TEdit, TMemo…).
/// design.pas tiene la clase TFormDesign, que crea la ventana; la unidad
/// del usuario (Form1.pas) la hereda y se compila tal cual: sus líneas son
/// las de los errores del compilador.
class TkPascal {
  TkPascal._();

  /// Una cadena de Pascal ('…', con '' para la comilla y #10 para el salto).
  static String str(String v) {
    if (v.isEmpty) return "''";
    final out = StringBuffer();
    final lines = v.replaceAll('\r\n', '\n').split('\n');
    for (final (i, l) in lines.indexed) {
      if (i > 0) out.write('#10');
      if (l.isNotEmpty) out.write("'${l.replaceAll("'", "''")}'");
    }
    return out.toString();
  }

  static String _color(Object? v) => "DmsColor('${TkCodegen.color(v)}')";

  static String _class(String kind) => switch (kind) {
    'Label' => 'TLabel',
    'Button' => 'TButton',
    'Entry' || 'Password' => 'TEdit',
    'Image' => 'TImage',
    'Text' => 'TMemo',
    'Checkbutton' => 'TCheckBox',
    'Radiobutton' => 'TRadioButton',
    'Listbox' => 'TListBox',
    'Combobox' => 'TComboBox',
    'Scale' => 'TTrackBar',
    'Frame' => 'TPanel',
    'Progressbar' => 'TProgressBar',
    'PageControl' => 'TPageControl',
    'StatusBar' => 'TStatusBar',
    'Menu' => 'TMainMenu',
    'Timer' => 'TTimer',
    'OpenDialog' => 'TOpenDialog',
    'SaveDialog' => 'TSaveDialog',
    _ => 'TLabel',
  };

  static int _int(Object? v, int def) => switch (v) {
    final num n => n.round(),
    final String s => num.tryParse(s)?.round() ?? def,
    _ => def,
  };

  /// design.pas: la unidad con la clase TFormDesign.
  static String design(TkDesign d) {
    final problems = d.problems();
    if (problems.isNotEmpty) throw UserError(problems.join('\n'));
    final fields = StringBuffer();
    final build = StringBuffer();
    final wrappers = <String>[]; // declaraciones (privadas)
    final bodies = StringBuffer(); // sus implementaciones
    final locals = <String>[];
    final handlerNames = TkCpp.handlers(d);

    /// Un método privado que recibe el evento de la LCL y llama al del
    /// usuario. [sig]: sus parámetros; [call]: lo que hace.
    String wrap(String name, String sig, String call) {
      wrappers.add('    procedure $name($sig);');
      bodies.writeln(
        'procedure TFormDesign.$name($sig);\nbegin\n  $call\nend;\n',
      );
      return '@$name';
    }

    String notify(TkWidget w, String key, [String? args]) {
      final m = w.events[key];
      if (m == null) return '';
      return wrap('dms_${w.name}_$key', 'Sender: TObject', '$m${args ?? ''};');
    }

    void style(String n, TkWidget w) {
      final bg = w.props['bg'], fg = w.props['fg'];
      if (TkCodegen.color(bg) != null) {
        if (w.kind == 'Label') build.writeln('  $n.Transparent := False;');
        build.writeln('  $n.Color := ${_color(bg)};');
      }
      if (TkCodegen.color(fg) != null) {
        build.writeln('  $n.Font.Color := ${_color(fg)};');
      }
      final size = w.props['font_size'];
      if (size is int && size > 0) build.writeln('  $n.Font.Size := $size;');
      if (w.props['font_bold'] == true) {
        build.writeln('  $n.Font.Style := [fsBold];');
      }
    }

    void menu(TkWidget w) {
      final n = w.name;
      fields.writeln('    $n: TMainMenu;');
      build
        ..writeln('  $n := TMainMenu.Create(Self);')
        ..writeln('  Menu := $n;');
      final m = w.events['command'];
      final handler = m == null
          ? 'nil'
          : wrap(
              'dms_${n}_command',
              'Sender: TObject',
              '$m(TMenuItem(Sender).Hint);',
            );
      var count = 0;
      void add(List<TkMenuItem> items, String parent) {
        for (final i in items) {
          if (i.separator) {
            build.writeln("  DmsMenuAdd($parent, '-', '', nil);");
            continue;
          }
          if (i.items.isEmpty) {
            build.writeln(
              '  DmsMenuAdd($parent, ${str(i.label)}, ${str(i.path)}, $handler);',
            );
            continue;
          }
          final v = 'M${++count}';
          locals.add(v);
          build.writeln(
            '  $v := DmsMenuAdd($parent, ${str(i.label)}, ${str(i.path)}, nil);',
          );
          add(i.items, v);
        }
      }

      add(tkMenuItems(w.text('items')), '$n.Items');
    }

    String parentOf(TkWidget w) {
      final p = w.parent == null ? null : d.byName(w.parent!);
      if (p == null || !w.component.nestable) return 'Self';
      if (p.kind == 'PageControl') return '${p.name}_page${d.pageOf(w)}';
      return p.name;
    }

    void create(TkWidget w) {
      final n = w.name;
      final cls = _class(w.kind);
      switch (w.kind) {
        case 'Menu':
          return menu(w);
        case 'Timer':
          fields.writeln('    $n: TTimer;');
          build
            ..writeln('  $n := TTimer.Create(Self);')
            ..writeln('  $n.Interval := ${TkCodegen.interval(w)};')
            ..writeln('  $n.Enabled := ${w.props['enabled'] != false};');
          final h = notify(w, 'command');
          if (h.isNotEmpty) build.writeln('  $n.OnTimer := $h;');
          return;
        case 'OpenDialog' || 'SaveDialog':
          fields.writeln('    $n: $cls;');
          build.writeln('  $n := $cls.Create(Self);');
          final title = w.text('title');
          if (title.isNotEmpty) build.writeln('  $n.Title := ${str(title)};');
          final filter = _filter(w.text('filter'));
          if (filter.isNotEmpty) {
            build.writeln('  $n.Filter := ${str(filter)};');
          }
          final file = w.text('filename');
          if (file.isNotEmpty) build.writeln('  $n.FileName := ${str(file)};');
          if (w.kind == 'SaveDialog') {
            build.writeln('  $n.Options := $n.Options + [ofOverwritePrompt];');
          }
          final m = w.events['select'];
          if (m != null) {
            final h = wrap(
              'dms_${n}_select',
              'Sender: TObject',
              'if $n.UserChoice = mrOK then $m($n.FileName);',
            );
            build.writeln('  $n.OnClose := $h;');
          }
          return;
      }
      // Un botón con color propio o alto: TDmsButton (los botones del
      // sistema no cambian de color ni de alto en todas partes).
      final klass =
          w.kind == 'Button' &&
              (TkCodegen.color(w.props['bg']) != null || w.height > 32)
          ? 'TDmsButton'
          : cls;
      fields.writeln('    $n: $klass;');
      build
        ..writeln('  $n := $klass.Create(Self);')
        ..writeln('  $n.Parent := ${parentOf(w)};');
      if (w.kind == 'StatusBar') {
        build.writeln('  $n.SimplePanel := True;');
      } else {
        final (x, y) = TkCodegen.placeOf(d, w);
        build.writeln('  $n.SetBounds($x, $y, ${w.width}, ${w.height});');
      }
      final text = w.props['text'];
      final t = text is String ? text : '';
      switch (w.kind) {
        case 'Label':
          build
            ..writeln('  $n.AutoSize := False;')
            ..writeln('  $n.WordWrap := True;')
            ..writeln('  $n.Layout := tlCenter;')
            ..writeln(
              '  $n.Alignment := ${switch (w.text('anchor')) {
                'w' => 'taLeftJustify',
                'e' => 'taRightJustify',
                _ => 'taCenter',
              }};',
            )
            ..writeln('  $n.Caption := ${str(t)};');
        case 'Button' || 'Checkbutton' || 'Radiobutton':
          build.writeln('  $n.Caption := ${str(t)};');
          if (w.kind != 'Button' && w.props['checked'] == true) {
            build.writeln('  $n.Checked := True;');
          }
        case 'StatusBar':
          if (t.isNotEmpty) build.writeln('  $n.SimpleText := ${str(t)};');
        case 'Entry':
          if (t.isNotEmpty) build.writeln('  $n.Text := ${str(t)};');
        case 'Password':
          build.writeln("  $n.PasswordChar := '*';");
        case 'Text':
          build
            ..writeln('  $n.WordWrap := True;')
            ..writeln('  $n.ScrollBars := ssAutoVertical;');
          if (t.isNotEmpty) build.writeln('  $n.Lines.Text := ${str(t)};');
        case 'Image':
          final file = w.text('file');
          build
            ..writeln('  $n.Stretch := True;')
            ..writeln('  $n.Proportional := True;')
            ..writeln('  $n.Center := True;');
          if (file.isNotEmpty) {
            build.writeln('  DmsLoadPicture($n, ${str(file)});');
          }
        case 'Listbox' || 'Combobox':
          if (w.kind == 'Combobox') {
            build.writeln('  $n.Style := csDropDownList;');
          }
          for (final i in TkCodegen.items(w)) {
            build.writeln('  $n.Items.Add(${str(i)});');
          }
          if (w.kind == 'Combobox' && t.isNotEmpty) {
            build.writeln('  $n.ItemIndex := $n.Items.IndexOf(${str(t)});');
          }
        case 'Scale':
          build
            ..writeln(
              '  $n.Orientation := ${w.width >= w.height ? 'trHorizontal' : 'trVertical'};',
            )
            ..writeln('  $n.Min := ${_int(w.props['from'], 0)};')
            ..writeln('  $n.Max := ${_int(w.props['to'], 100)};')
            ..writeln('  $n.Position := ${_int(w.props['value'], 0)};');
        case 'Progressbar':
          build
            ..writeln('  $n.Max := ${_int(w.props['maximum'], 100)};')
            ..writeln('  $n.Position := ${_int(w.props['value'], 0)};');
        case 'Frame':
          build
            ..writeln("  $n.Caption := '';")
            ..writeln('  $n.BevelOuter := bvLowered;');
        case 'PageControl':
          for (final (i, title) in tkPages(w).indexed) {
            fields.writeln('    ${n}_page$i: TTabSheet;');
            build
              ..writeln('  ${n}_page$i := $n.AddTabSheet;')
              ..writeln('  ${n}_page$i.Caption := ${str(title)};');
          }
      }
      if (w.props['state'] == 'disabled') {
        build.writeln('  $n.Enabled := False;');
      }
      style(n, w);
      // Eventos.
      switch (w.kind) {
        case 'Button' || 'Checkbutton' || 'Radiobutton':
          final h = notify(w, 'command');
          if (h.isNotEmpty) build.writeln('  $n.OnClick := $h;');
        case 'Entry' || 'Password':
          final m = w.events['enter_key'];
          if (m != null) {
            final h = wrap(
              'dms_${n}_enter_key',
              'Sender: TObject; var Key: Char',
              'if Key = #13 then begin Key := #0; $m; end;',
            );
            build.writeln('  $n.OnKeyPress := $h;');
          }
        case 'Listbox':
          final sel = notify(w, 'select'), dbl = notify(w, 'double');
          if (sel.isNotEmpty) build.writeln('  $n.OnClick := $sel;');
          if (dbl.isNotEmpty) build.writeln('  $n.OnDblClick := $dbl;');
        case 'Combobox':
          final h = notify(w, 'select');
          if (h.isNotEmpty) build.writeln('  $n.OnSelect := $h;');
        case 'Scale':
          final h = notify(w, 'command', '($n.Position)');
          if (h.isNotEmpty) build.writeln('  $n.OnChange := $h;');
      }
      // Lo que va dentro de un marco o de una página.
      if (w.kind == 'Frame' || w.kind == 'PageControl') {
        for (final c in d.widgets.where((c) => c.parent == n)) {
          create(c);
        }
        final active = d.activePage(w);
        if (w.kind == 'PageControl') {
          build.writeln('  $n.PageIndex := $active;');
        }
      }
    }

    for (final w in d.widgets.where((w) => w.parent == null)) {
      create(w);
    }
    // La ventana.
    final form = StringBuffer()
      ..writeln('  Caption := ${str(d.title)};')
      ..writeln('  ClientWidth := ${d.width};')
      ..writeln('  ClientHeight := ${d.height};')
      ..writeln('  Color := ${_color(d.prop(tkFormBg) ?? '#f0f0f0')};');
    if (d.prop(tkFormResizable) != true) {
      form.writeln('  BorderStyle := bsSingle;');
    }
    if (d.prop(tkFormPosition) == 'manual') {
      form
        ..writeln('  Position := poDesigned;')
        ..writeln('  Left := ${TkPy.integer(d.prop(tkFormLeft))};')
        ..writeln('  Top := ${TkPy.integer(d.prop(tkFormTop))};');
    } else {
      form.writeln('  Position := poScreenCenter;');
    }
    if (d.prop(tkFormTopmost) == true) {
      form.writeln('  FormStyle := fsStayOnTop;');
    }
    if (d.appIcon != null) form.writeln('  DmsIcon(Self, ${str(d.appIcon!)});');
    final close = d.events['close'] ?? 'form_close';
    wrappers.add(
      '    procedure dms_close(Sender: TObject; var CloseAction: TCloseAction);',
    );
    bodies.writeln(
      'procedure TFormDesign.dms_close(Sender: TObject; var CloseAction: TCloseAction);\n'
      'begin\n  $close;\nend;\n',
    );
    final events = StringBuffer('  OnClose := @dms_close;\n');
    if (d.events['key'] case final m?) {
      events
        ..writeln('  KeyPreview := True;')
        ..writeln(
          '  OnKeyPress := ${wrap('dms_key', 'Sender: TObject; var Key: Char', 'LastKey := Key; $m;')};',
        );
    }
    if (d.events['resize'] case final m?) {
      events.writeln(
        '  OnResize := ${wrap('dms_resize', 'Sender: TObject', '$m;')};',
      );
    }
    final virtuals = [
      for (final MapEntry(key: m, value: param) in handlerNames.entries)
        if (m != 'form_create' && m != 'form_close') (m, param),
    ];
    String args(String param) {
      final t = PascalUnit.typed(param);
      return t.isEmpty ? '' : '($t)';
    }

    return '''// Generated by DMarlon Studio from the design. Do not edit.
unit design;

{\$mode objfpc}{\$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, dms;

type
  TFormDesign = class(TDmsForm)
  public
$fields    constructor Create(AOwner: TComponent); override;
${virtuals.map((v) => '    procedure ${v.$1}${args(v.$2)}; virtual;').join('\n')}
  private
${wrappers.join('\n')}
  end;

implementation

constructor TFormDesign.Create(AOwner: TComponent);
${locals.isEmpty ? '' : 'var\n  ${locals.join(', ')}: TMenuItem;\n'}begin
  inherited CreateNew(AOwner);
$form$build$events  ${d.events['create'] ?? 'form_create'};
end;

${virtuals.map((v) => 'procedure TFormDesign.${v.$1}${args(v.$2)};\nbegin\nend;\n').join('\n')}
$bodies
end.
''';
  }

  /// «Texto|*.txt» (una por línea) → «Texto|*.txt|Todo|*.*».
  static String _filter(String text) => [
    for (final line in text.split('\n'))
      if (line.contains('|'))
        line.trim().replaceAll(RegExp(r'[,\s]+(?=\*)'), ';'),
  ].join('|');

  /// app.lpr: el programa, que abre la ventana del usuario.
  static String program(TkDesign d) =>
      '''// Generated by DMarlon Studio. Do not edit.
program app;

{\$mode objfpc}{\$H+}
{\$IFDEF DARWIN}{\$modeswitch objectivec1}{\$ENDIF}

uses
  {\$IFDEF UNIX}cthreads,{\$ENDIF}
  {\$IFDEF DARWIN}CocoaAll,{\$ENDIF}
  Interfaces, Forms, dms, design, ${d.name};

var
  F: T${d.name};

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Title := ${str(d.title)};
  Application.Initialize;
  Application.CreateForm(T${d.name}, F);
  {\$IFDEF DARWIN}
  // Sin paquete .app, macOS la abriría en segundo plano y sin ventana
  // al frente: es una aplicación normal y se pone delante.
  NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular);
  NSApp.activateIgnoringOtherApps(True);
  {\$ENDIF}
  Application.Run;
end.
''';

  /// app.lpi: el proyecto de Lazarus. [options]: opciones del compilador
  /// (en macOS, dónde está el SDK).
  static String project(TkDesign d, {List<String> options = const []}) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;');
    return '''<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <ProjectOptions>
    <Version Value="12"/>
    <General>
      <Flags>
        <MainUnitHasCreateFormStatements Value="False"/>
        <MainUnitHasTitleStatement Value="False"/>
        <MainUnitHasScaledStatement Value="False"/>
      </Flags>
      <SessionStorage Value="None"/>
      <Title Value="${esc(d.title)}"/>
      <UseAppBundle Value="False"/>
    </General>
    <BuildModes>
      <Item Name="Default" Default="True"/>
    </BuildModes>
    <RequiredPackages>
      <Item>
        <PackageName Value="LCL"/>
      </Item>
    </RequiredPackages>
    <Units>
      <Unit>
        <Filename Value="app.lpr"/>
        <IsPartOfProject Value="True"/>
      </Unit>
      <Unit>
        <Filename Value="${d.name}.pas"/>
        <IsPartOfProject Value="True"/>
      </Unit>
    </Units>
  </ProjectOptions>
  <CompilerOptions>
    <Version Value="11"/>
    <Target>
      <Filename Value="app"/>
    </Target>
    <SearchPaths>
      <UnitOutputDirectory Value="lib/\$(TargetCPU)-\$(TargetOS)"/>
    </SearchPaths>
    <Other>
      <CustomOptions Value="${esc(options.join(' '))}"/>
    </Other>
  </CompilerOptions>
</CONFIG>
''';
  }

  /// Todos los archivos (nombre → contenido).
  static Map<String, String> files(
    TkDesign d,
    String code, {
    List<String> options = const [],
  }) {
    final unit = code.replaceAll('\r\n', '\n');
    if (!const PascalUnit().hasClass(unit, d.name)) {
      throw UserError(
        tr('El código debe definir «T{0} = class(TFormDesign)».', [d.name]),
      );
    }
    return {
      'dms.pas': tkPascalRuntime,
      'design.pas': design(d),
      '${d.name}.pas': unit,
      'app.lpr': program(d),
      'app.lpi': project(d, options: options),
    };
  }

  /// Lo que se ve en la pestaña «Pascal generado».
  static String preview(TkDesign d, String code) =>
      '${design(d)}\n// ---- ${d.name}.pas\n\n${code.trimRight()}\n';
}

/// dms.pas: lo que la LCL no trae hecho (la ventana con form_create y
/// form_close, colores #rrggbb, preguntar, leer y escribir archivos…).
const tkPascalRuntime =
    r'''// DMarlon Studio runtime for Lazarus (LCL). Generated: do not edit.
unit dms;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus;

type
  { Un botón que respeta el color, el alto y la fuente del diseño. }
  TDmsButton = class(TPanel)
  private
    FUp: TColor;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { La ventana: form_create al abrir y form_close al cerrar. }
  TDmsForm = class(TForm)
  private
    FShown: Boolean;
    procedure DmsFront(Data: PtrInt);
  protected
    procedure DoShow; override;
  public
    { La última tecla pulsada (en el evento de teclado de la ventana). }
    LastKey: Char;
    procedure form_create; virtual;
    procedure form_close; virtual;
    { Pregunta Sí / No. }
    function Ask(const Question: string): Boolean;
  end;

{ Un color #rrggbb. }
function DmsColor(const Hex: string): TColor;
{ Leer y escribir archivos de texto. }
function ReadText(const Path: string): string;
procedure WriteText(const Path, Text: string);
{ Un número como texto, sin ceros de más. }
function NumToStr(V: Double): string;
procedure DmsLoadPicture(Image: TImage; const Path: string);
procedure DmsIcon(Form: TForm; const Path: string);
function DmsMenuAdd(Parent: TMenuItem; const ACaption, APath: string;
  Handler: TNotifyEvent): TMenuItem;

implementation

constructor TDmsButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentColor := False;
  ParentFont := False;
  Color := $00E1E1E1;
  Font.Color := clBlack;
  Cursor := crHandPoint;
end;

procedure TDmsButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  C: TColor;
begin
  FUp := Color;
  C := ColorToRGB(Color);
  Color := RGBToColor(Red(C) * 4 div 5, Green(C) * 4 div 5, Blue(C) * 4 div 5);
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDmsButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  Color := FUp;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TDmsForm.form_create;
begin
end;

{ Al abrirse, delante de las demás ventanas (ya con el bucle en marcha). }
procedure TDmsForm.DoShow;
begin
  inherited DoShow;
  if FShown then Exit;
  FShown := True;
  Application.QueueAsyncCall(@DmsFront, 0);
end;

procedure TDmsForm.DmsFront(Data: PtrInt);
begin
  Application.BringToFront;
  BringToFront;
end;

procedure TDmsForm.form_close;
begin
end;

function TDmsForm.Ask(const Question: string): Boolean;
begin
  Result := MessageDlg(Question, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

function DmsColor(const Hex: string): TColor;
var
  R, G, B: Integer;
begin
  Result := clDefault;
  if (Length(Hex) <> 7) or (Hex[1] <> '#') then Exit;
  R := StrToIntDef('$' + Copy(Hex, 2, 2), 0);
  G := StrToIntDef('$' + Copy(Hex, 4, 2), 0);
  B := StrToIntDef('$' + Copy(Hex, 6, 2), 0);
  Result := RGBToColor(R, G, B);
end;

function ReadText(const Path: string): string;
var
  S: TStringList;
begin
  S := TStringList.Create;
  try
    S.LoadFromFile(Path);
    Result := S.Text;
  finally
    S.Free;
  end;
end;

procedure WriteText(const Path, Text: string);
var
  S: TStringList;
begin
  S := TStringList.Create;
  try
    S.Text := Text;
    S.SaveToFile(Path);
  finally
    S.Free;
  end;
end;

function NumToStr(V: Double): string;
var
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := '.';
  Result := FloatToStrF(V, ffGeneral, 15, 0, F);
end;

procedure DmsLoadPicture(Image: TImage; const Path: string);
begin
  if FileExists(Path) then
  try
    Image.Picture.LoadFromFile(Path);
  except
  end;
end;

procedure DmsIcon(Form: TForm; const Path: string);
var
  P: TPicture;
begin
  if not FileExists(Path) then Exit;
  P := TPicture.Create;
  try
    try
      P.LoadFromFile(Path);
      Form.Icon.Assign(P.Graphic);
      Application.Icon.Assign(P.Graphic);
    except
    end;
  finally
    P.Free;
  end;
end;

function DmsMenuAdd(Parent: TMenuItem; const ACaption, APath: string;
  Handler: TNotifyEvent): TMenuItem;
begin
  Result := TMenuItem.Create(Parent.Owner);
  Result.Caption := ACaption;
  Result.Hint := APath;
  Result.OnClick := Handler;
  Parent.Add(Result);
end;

end.
''';
