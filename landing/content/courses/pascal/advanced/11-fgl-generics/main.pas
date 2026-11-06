program main;
uses fgl;
type
  TQtyList = specialize TFPGList<Integer>;
  TStockMap = specialize TFPGMap<String, Integer>;
function Descending(const a, b: Integer): Integer;
begin
  Result := b - a;
end;

var
  orders: TQtyList;
  stock: TStockMap;
  i: Integer;
begin
  orders := TQtyList.Create;
  stock := TStockMap.Create;
  try
    orders.Add(12); orders.Add(5); orders.Add(30); orders.Add(8);
    orders.Sort(@Descending);
    WriteLn('Orders: ', orders.Count, ', largest: ', orders[0], ', smallest: ', orders.Last);
    stock.Sorted := True;  // keys kept in order, found by binary search
    stock['monitor'] := 7;
    stock['keyboard'] := 25;
    stock['mouse'] := 40;
    stock['keyboard'] := stock['keyboard'] - 5;  // 5 keyboards sold
    for i := 0 to stock.Count - 1 do
      WriteLn(stock.Keys[i]:10, stock.Data[i]:4);
    WriteLn('Has webcams: ', stock.IndexOf('webcam') >= 0);
  finally
    orders.Free;
    stock.Free;
  end;
end.
