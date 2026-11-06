program main;
const
  Invoices: array[0..5] of Integer = (120, 340, 90, 160, 250, 40);
  Payment = 500;
var
  chosen: array[0..5] of Boolean;
  found: Integer = 0;

procedure Search(i, remaining: Integer);
var k: Integer;
begin
  if remaining = 0 then  // a match: print the chosen invoices
  begin
    Inc(found);
    Write('Option ', found, ':');
    for k := 0 to High(Invoices) do
      if chosen[k] then Write(' ', Invoices[k]);
    WriteLn;
    Exit;
  end;
  if (i > High(Invoices)) or (remaining < 0) then Exit;  // dead end: go back
  chosen[i] := True;             // try with invoice i...
  Search(i + 1, remaining - Invoices[i]);
  chosen[i] := False;            // ...undo, and try without it
  Search(i + 1, remaining);
end;

begin
  Search(0, Payment);
  WriteLn(found, ' ways to match a payment of ', Payment);
end.
