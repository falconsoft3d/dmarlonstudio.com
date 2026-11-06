program main;

// A constant array: the names of the days.
const
  Days: array[1..7] of String = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');

// A variable array of 7 integers, with initial values.
var
  temps: array[1..7] of Integer = (18, 21, 24, 19, 26, 28, 22);
  i, hottest, total: Integer;

begin
  temps[4] := 20;  // change one element
  total := 0;
  hottest := 1;
  // Low and High give the first and last index.
  for i := Low(temps) to High(temps) do
  begin
    WriteLn(Days[i], ': ', temps[i]:3, ' C');
    total := total + temps[i];
    if temps[i] > temps[hottest] then
      hottest := i;
  end;
  WriteLn('Average: ', total / Length(temps):0:1, ' C');
  WriteLn('Hottest day: ', Days[hottest], ' (', temps[hottest], ' C)');
end.
