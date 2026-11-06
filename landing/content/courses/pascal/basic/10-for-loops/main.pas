program main;

var
  i, total: Integer;
  c: Char;

begin
  // for ... to counts up, one at a time.
  for i := 1 to 5 do
    WriteLn('7 x ', i, ' = ', 7 * i);

  // downto counts down.
  for i := 3 downto 1 do
    Write(i, '... ');
  WriteLn('Lift-off!');

  // Add up the odd numbers from 1 to 99.
  total := 0;
  for i := 1 to 99 do
    if i mod 2 = 1 then
      total := total + i;
  WriteLn('Odd numbers up to 99 add up to ', total);

  // The counter can also be a Char: a grid of cinema seats.
  for i := 1 to 3 do
  begin
    Write('Row ', i, ':');
    for c := 'A' to 'E' do
      Write(' ', i, c);
    WriteLn;
  end;
end.
