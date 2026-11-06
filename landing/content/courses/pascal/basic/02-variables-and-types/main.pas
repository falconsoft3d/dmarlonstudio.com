program main;

// Every variable is declared in the var block, with its type.
var
  shop: String;
  shirts: Integer;
  price: Double;
  size: Char;
  inStock: Boolean;

begin
  // := gives a variable its value.
  shop := 'Corner Shop';
  shirts := 3;
  price := 12.5;
  size := 'M';
  inStock := True;

  WriteLn('Shop: ', shop);
  WriteLn('T-shirts: ', shirts, ' in size ', size);
  WriteLn('In stock? ', inStock);
  WriteLn('Price: ', price);

  // A variable can change, but always keeps its type.
  shirts := shirts + 2;
  WriteLn('T-shirts after the delivery: ', shirts);
  WriteLn('Value of the stock: ', shirts * price:0:2);
  WriteLn('Largest Integer: ', High(Integer));
end.
