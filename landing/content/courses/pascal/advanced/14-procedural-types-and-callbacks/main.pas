program main;
type
  TPriceRule = function(price: Double): Double;          // any function of this shape
  TSaleEvent = procedure(price, total: Double) of object;  // a method + its object
  TTill = class
    Name: String;
    procedure ShowSale(price, total: Double);
  end;

procedure TTill.ShowSale(price, total: Double);
begin
  WriteLn('[', Name, '] ', price:0:2, ' -> ', total:0:2);
end;
function Sale(price: Double): Double;
begin
  Result := price * 0.80;
end;
function Clearance(price: Double): Double;
begin
  Result := price * 0.50;
end;
procedure Checkout(price: Double; rule: TPriceRule; onSale: TSaleEvent);
begin
  if Assigned(onSale) then onSale(price, rule(price));  // only if someone listens
end;

var till: TTill;
begin
  till := TTill.Create;
  till.Name := 'Till 1';
  Checkout(59.90, @Sale, @till.ShowSale);
  Checkout(59.90, @Clearance, @till.ShowSale);
  till.Free;
end.
