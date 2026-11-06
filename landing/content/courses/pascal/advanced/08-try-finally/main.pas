program main;
uses SysUtils, Classes;

procedure Import(const rows: array of String);
var
  prices: TStringList;
  row: String;
  total: Double;
begin
  prices := TStringList.Create;
  try
    total := 0;
    for row in rows do
    begin
      total := total + StrToFloat(row);  // may raise EConvertError
      prices.Add(row);
    end;
    WriteLn('Imported ', prices.Count, ' prices, total ', total:0:2);
  finally
    WriteLn('Freeing a list of ', prices.Count);
    prices.Free;  // runs with or without an error
  end;
end;

begin
  Import(['9.95', '24.50', '3.20']);
  try
    Import(['12.00', 'n/a', '7.40']);
    WriteLn('This line is skipped');
  except
    on E: Exception do WriteLn('Import failed: ', E.Message);
  end;
end.
