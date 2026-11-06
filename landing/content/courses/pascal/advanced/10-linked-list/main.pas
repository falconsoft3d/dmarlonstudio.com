program main;
type
  PStop = ^TStop;  // the pointer type may come before its record
  TStop = record
    Name: String;
    Next: PStop;
  end;

function NewStop(const name: String; next: PStop): PStop;
begin
  New(Result);
  Result^.Name := name;
  Result^.Next := next;
end;

function ToText(stop: PStop): String;
begin
  if stop = nil then Exit('end');
  Result := stop^.Name + ' > ' + ToText(stop^.Next);  // this stop, then the rest
end;

var route, next: PStop;
begin
  route := NewStop('Sol', NewStop('Gran Via', NewStop('Moncloa', nil)));
  WriteLn(ToText(route));
  route^.Next := NewStop('Callao', route^.Next);  // insert after Sol
  WriteLn(ToText(route));
  while route <> nil do  // free every node, front to back
  begin
    next := route^.Next;
    Dispose(route);
    route := next;
  end;
end.
