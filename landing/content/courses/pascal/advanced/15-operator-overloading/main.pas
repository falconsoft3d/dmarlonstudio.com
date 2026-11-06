program main;
{$modeswitch advancedrecords}
type
  TMoney = record
    Cents: Int64;  // whole cents: no rounding surprises
    class operator :=(euros: Double): TMoney;
    class operator +(a, b: TMoney): TMoney;
    class operator *(a: TMoney; qty: Integer): TMoney;
    function ToString: String;
  end;
class operator TMoney.:=(euros: Double): TMoney;
begin
  Result.Cents := Round(euros * 100);
end;
class operator TMoney.+(a, b: TMoney): TMoney;
begin
  Result.Cents := a.Cents + b.Cents;
end;
class operator TMoney.*(a: TMoney; qty: Integer): TMoney;
begin
  Result.Cents := a.Cents * qty;
end;
function TMoney.ToString: String;
begin
  WriteStr(Result, Cents / 100:0:2, ' EUR');  // like WriteLn, into a string
end;

var coffee, bill: TMoney;
begin
  coffee := 1.60;             // := turns a Double into a TMoney
  bill := coffee * 2 + 3.25;  // *, then + (3.25 is converted too)
  WriteLn('Coffee: ', coffee.ToString, ' (', coffee.Cents, ' cents)');
  WriteLn('2 coffees + 1 cake: ', bill.ToString);
end.
