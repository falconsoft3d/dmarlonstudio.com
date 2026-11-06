program main;
uses Classes;
var
  clients, config: TStringList;
  index: Integer;
begin
  clients := TStringList.Create;
  config := TStringList.Create;
  try
    clients.Sorted := True;  // sorts and keeps every Add in its place
    clients.CommaText := 'Ruiz,Alonso,Navarro,Garcia,Blanco';
    WriteLn('Clients: ', clients.CommaText);
    if clients.Find('Navarro', index) then  // binary search
      WriteLn('Navarro is at index ', index);
    clients.Add('Castro');
    WriteLn('With Castro: ', clients.CommaText);

    config.Add('host=localhost');
    config.Add('port=8069');
    config.Add('database=odoo_demo');
    WriteLn('Port: ', config.Values['port']);
    config.Values['port'] := '8070';   // changes an existing name
    config.Values['user'] := 'admin';  // a new name is appended
    WriteLn(config.Names[3], ' = ', config.ValueFromIndex[3]);
    WriteLn('Config: ', config.CommaText);
  finally
    clients.Free;
    config.Free;
  end;
end.
