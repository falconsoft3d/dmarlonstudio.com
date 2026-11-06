program main;
uses SysUtils;

type
  TLine = record
    Product: String;
    Qty: Integer;
    Price: Double;
  end;

const
  VatRate = 0.21;
  Invoice: array[1..4] of TLine = (
    (Product: 'Keyboard'; Qty: 1; Price: 24.90), (Product: 'Mouse'; Qty: 2; Price: 12.50),
    (Product: 'USB cable'; Qty: 3; Price: 4.99), (Product: 'Monitor'; Qty: 1; Price: 139.00));

procedure Row(const caption: String; amount: Double);
begin
  WriteLn(Format('%-26s%9.2f', [caption, amount]));
end;

var
  line: TLine;
  subtotal: Double = 0;
begin
  for line in Invoice do
  begin
    Row(Format('%-10s %2d x %6.2f', [line.Product, line.Qty, line.Price]), line.Qty * line.Price);
    subtotal := subtotal + line.Qty * line.Price;
  end;
  Row('Subtotal', subtotal);
  Row('VAT 21%', subtotal * VatRate);
  Row('TOTAL', subtotal * (1 + VatRate));
end.
