program main;
uses Generics.Collections;
type
  TCityList = specialize TList<String>;
  TSales = specialize TDictionary<String, Integer>;
const
  Orders: array[0..6] of String = ('Madrid', 'Sevilla', 'Madrid', 'Bilbao',
    'Sevilla', 'Madrid', 'Valencia');
var
  sales: TSales;
  cities: TCityList;
  city: String;
  count: Integer;
begin
  sales := TSales.Create;
  cities := TCityList.Create;
  try
    for city in Orders do
      if sales.TryGetValue(city, count) then
        sales[city] := count + 1
      else
        sales.Add(city, 1);
    // A dictionary has no fixed order: copy the keys and sort them
    cities.AddRange(sales.Keys);
    cities.Sort;
    for city in cities do
      WriteLn(city:9, sales[city]:3);
    WriteLn('Cities: ', sales.Count, ', any in Malaga: ', sales.ContainsKey('Malaga'));
  finally
    cities.Free;
    sales.Free;
  end;
end.
