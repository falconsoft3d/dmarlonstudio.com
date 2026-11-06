program main;
uses SysUtils, fpjson, jsonparser;
const
  Incoming = '{"id": 1042, "customer": {"name": "Lucia Romero", "city": "Malaga"},' +
    ' "lines": [{"sku": "MUG-01", "qty": 2, "cents": 850},' +
    ' {"sku": "TEA-12", "qty": 1, "cents": 1295}]}';
var
  order, line, reply: TJSONObject;
  item: TJSONEnum;
  total: Integer = 0;
begin
  order := GetJSON(Incoming) as TJSONObject;  // parse the text into objects
  try
    WriteLn('Order ', order.Integers['id'], ' for ', order.FindPath('customer.name').AsString);
    for item in order.Arrays['lines'] do
    begin
      line := item.Value as TJSONObject;
      WriteLn('  ', line.Strings['sku'], ' x', line.Integers['qty']);
      total := total + line.Integers['qty'] * line.Integers['cents'];
    end;
    reply := TJSONObject.Create(['order', order.Integers['id'], 'status', 'confirmed']);
    try
      reply.Add('total_cents', total);
      reply.Add('tags', TJSONArray.Create(['paid', 'gift']));  // reply owns it now
      WriteLn(reply.AsJSON);
    finally
      reply.Free;  // frees everything inside too
    end;
  finally
    order.Free;
  end;
end.
