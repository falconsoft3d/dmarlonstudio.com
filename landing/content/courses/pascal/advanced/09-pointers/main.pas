program main;
type
  TProduct = record
    Name: String;
    Stock: Integer;
  end;
  PProduct = ^TProduct;  // a pointer to a TProduct

procedure Restock(item: PProduct; amount: Integer);
begin
  Inc(item^.Stock, amount);  // changes the record it points to
end;

var
  units: Integer;
  pUnits: PInteger;
  item: PProduct;
begin
  units := 10;
  pUnits := @units;           // the address of an existing variable
  pUnits^ := pUnits^ + 5;     // ^ follows the pointer
  WriteLn('units = ', units);

  item := nil;
  WriteLn('Assigned before New: ', Assigned(item));
  New(item);                  // a new record on the heap
  item^.Name := 'Printer toner';
  item^.Stock := 3;
  Restock(item, 12);
  WriteLn(item^.Name, ': ', item^.Stock, ' in stock');
  Dispose(item);              // give the memory back
  item := nil;                // and forget the old address
  WriteLn('Assigned after Dispose: ', Assigned(item));
end.
