part of 'tk_examples.dart';

// Ejemplos de Pascal con Lazarus: el mismo diseño, con el código en Object
// Pascal y los componentes de la LCL.

/// Los ejemplos de Pascal.
List<TkExample> tkPascalExamples(String Function(String) t) => [
  _pascalCalculator(t),
  tkUtilPascalOdoo(t),
  tkPascalMalecon(t),
];

TkExample _pascalCalculator(String Function(String) t) {
  final base = _calculator(t);
  final decl = StringBuffer();
  final impl = StringBuffer();
  for (var i = 0; i < 10; i++) {
    decl.writeln('    procedure Btn${i}_click; override;');
    impl.writeln(
      "procedure TForm1.Btn${i}_click;\nbegin\n  Digit('$i');\nend;\n",
    );
  }
  final code =
      '''// ${t(markTr('Calculadora en Pascal con Lazarus: cada botón llama a su método.'))}
unit Form1;

{\$mode objfpc}{\$H+}

interface

uses
  ${PascalUnit.uses};

type
  TForm1 = class(TFormDesign)
  public
    // Estado: lo que se ve, el primer número y la operación pendiente.
    Shown: string;
    First: Double;
    Op: Char;
    Typing: Boolean;
    procedure Clear;
    procedure Refresh;
    procedure Digit(const D: string);
    procedure Dot;
    procedure Compute;
    procedure Operate(O: Char);
    procedure form_create; override;
    procedure form_key; override;
$decl    procedure BtnDot_click; override;
    procedure BtnClear_click; override;
    procedure BtnSign_click; override;
    procedure BtnPercent_click; override;
    procedure BtnAdd_click; override;
    procedure BtnSub_click; override;
    procedure BtnMul_click; override;
    procedure BtnDiv_click; override;
    procedure BtnEquals_click; override;
  end;

implementation

function Num(const S: string): Double;
var
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := '.';
  Result := StrToFloatDef(S, 0, F);
end;

procedure TForm1.form_create;
begin
  Clear;
end;

// ${t(markTr('El teclado también sirve: números, + - * /, Intro y Esc.'))}
procedure TForm1.form_key;
begin
  case LastKey of
    '0'..'9': Digit(LastKey);
    '.', ',': Dot;
    '+', '-', '*', '/': Operate(LastKey);
    #13, '=': Compute;
    #27: Clear;
  end;
end;

procedure TForm1.Clear;
begin
  Shown := '0';
  First := 0;
  Op := #0;
  Typing := False;
  Refresh;
end;

procedure TForm1.Refresh;
begin
  Display.Caption := Shown;
end;

procedure TForm1.Digit(const D: string);
begin
  if Shown = 'Error' then Clear;
  if not Typing or (Shown = '0') then
  begin
    Shown := D;
    Typing := True;
  end
  else if Length(Shown) < 15 then
    Shown := Shown + D;
  Refresh;
end;

procedure TForm1.Dot;
begin
  if Shown = 'Error' then Clear;
  if not Typing then
  begin
    Shown := '0';
    Typing := True;
  end;
  if Pos('.', Shown) = 0 then Shown := Shown + '.';
  Refresh;
end;

procedure TForm1.Compute;
var
  B, R: Double;
begin
  if (Op = #0) or (Shown = 'Error') then Exit;
  B := Num(Shown);
  case Op of
    '+': R := First + B;
    '-': R := First - B;
    '*': R := First * B;
  else
    if B = 0 then R := 0 else R := First / B;
  end;
  if (Op = '/') and (B = 0) then Shown := 'Error' else Shown := NumToStr(R);
  Op := #0;
  Typing := False;
  Refresh;
end;

procedure TForm1.Operate(O: Char);
begin
  if Shown = 'Error' then Exit;
  if Typing and (Op <> #0) then Compute;
  First := Num(Shown);
  Op := O;
  Typing := False;
end;

$impl
procedure TForm1.BtnDot_click;
begin
  Dot;
end;

procedure TForm1.BtnClear_click;
begin
  Clear;
end;

procedure TForm1.BtnSign_click;
begin
  if (Shown = 'Error') or (Shown = '0') then Exit;
  if Shown[1] = '-' then Delete(Shown, 1, 1) else Shown := '-' + Shown;
  Refresh;
end;

procedure TForm1.BtnPercent_click;
begin
  if Shown = 'Error' then Exit;
  Shown := NumToStr(Num(Shown) / 100);
  Typing := False;
  Refresh;
end;

procedure TForm1.BtnAdd_click;
begin
  Operate('+');
end;

procedure TForm1.BtnSub_click;
begin
  Operate('-');
end;

procedure TForm1.BtnMul_click;
begin
  Operate('*');
end;

procedure TForm1.BtnDiv_click;
begin
  Operate('/');
end;

procedure TForm1.BtnEquals_click;
begin
  Compute;
end;

end.
''';
  final design = TkDesign.fromJson({
    ...base.design.toJson(),
    'target': tkTargetPascal,
  });
  return TkExample(
    'pascal_calculator',
    t(markTr('Calculadora (Pascal)')),
    t(
      markTr(
        'La calculadora como aplicación nativa en Pascal con Lazarus: el mismo diseño, con el código en Object Pascal y los componentes de la LCL.',
      ),
    ),
    design,
    code,
  );
}
