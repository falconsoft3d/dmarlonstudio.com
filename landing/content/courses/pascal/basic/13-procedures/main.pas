program main;

// A procedure is a named block of code that you can call again and again.
procedure PrintLine(width: Integer; symbol: Char);
var
  i: Integer;  // a local variable: it only exists inside
begin
  for i := 1 to width do
    Write(symbol);
  WriteLn;
end;

procedure PrintItem(name: String; qty: Integer; price: Double);
begin
  WriteLn(name:8, qty:3, ' x', price:6:2, qty * price:8:2);
end;

procedure Greet(customer: String);
begin
  WriteLn('Welcome, ', customer, '!');
end;

begin
  Greet('Marta');
  PrintLine(26, '=');
  PrintItem('Bread', 2, 1.20);
  PrintItem('Milk', 3, 0.95);
  PrintItem('Cheese', 1, 4.50);
  PrintLine(26, '-');
  Greet('Luis');
end.
