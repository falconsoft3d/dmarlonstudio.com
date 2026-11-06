program main;
uses SysUtils;
type
  EOutOfStock = class(Exception);  // our own exception class
const
  Stock = 5;
  Requests: array[0..3] of String = ('3', 'ten', '0', '8');

procedure Order(const qtyText: String);
var qty: Integer;
begin
  qty := StrToInt(qtyText);  // raises EConvertError if it is not a number
  if qty <= 0 then
    raise EArgumentException.Create('quantity must be positive');
  if qty > Stock then
    raise EOutOfStock.CreateFmt('only %d left, %d requested', [Stock, qty]);
  WriteLn('Order for ', qty, ' accepted');
end;

var request: String;
begin
  for request in Requests do
    try
      Order(request);
    except
      on E: EOutOfStock do WriteLn('Out of stock: ', E.Message);
      on E: EConvertError do WriteLn('Not a number: ', E.Message);
      on E: Exception do WriteLn(E.ClassName, ': ', E.Message);
    end;
  WriteLn('All requests handled');
end.
