program main;

type
  TPrices = array of Double;

procedure Add(var list: TPrices; value: Double);
begin
  SetLength(list, Length(list) + 1);
  list[High(list)] := value;
end;

function Sum(const list: TPrices): Double;
var
  x: Double;
begin
  Result := 0;
  for x in list do
    Result := Result + x;
end;

var
  cart: TPrices;
  i: Integer;
begin
  cart := nil;  // nil: an empty dynamic array, with 0 items
  Add(cart, 2.50);
  Add(cart, 0.99);
  Add(cart, 4.75);
  for i := 0 to High(cart) do  // index 0 is the first
    WriteLn('Item ', i, ': ', cart[i]:5:2);
  WriteLn('Total: ', Sum(cart):0:2, ' (', Length(cart), ' items)');
  SetLength(cart, 2);  // shrinking drops the last item
  WriteLn('Without the last one: ', Sum(cart):0:2);
end.
