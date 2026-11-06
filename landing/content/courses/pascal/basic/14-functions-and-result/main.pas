program main;

// A function returns a value: whatever is left in Result.
function CelsiusToF(c: Double): Double;
begin
  Result := c * 9 / 5 + 32;
end;

function WithVat(price: Double): Double;
const
  Rate = 0.21;
begin
  Result := price * (1 + Rate);
end;

function IsLeap(year: Integer): Boolean;
begin
  Result := ((year mod 4 = 0) and (year mod 100 <> 0)) or (year mod 400 = 0);
end;

var
  temp: Integer;
begin
  // A function call goes wherever a value can go.
  for temp := 0 to 3 do
    WriteLn(temp * 10:3, ' C = ', CelsiusToF(temp * 10):5:1, ' F');
  WriteLn('A 20-euro shirt with VAT: ', WithVat(20):0:2);
  WriteLn('Two shirts: ', 2 * WithVat(20):0:2);
  WriteLn('2024 is a leap year? ', IsLeap(2024));
  WriteLn('1900 is a leap year? ', IsLeap(1900));
  WriteLn('2000 is a leap year? ', IsLeap(2000));
end.
