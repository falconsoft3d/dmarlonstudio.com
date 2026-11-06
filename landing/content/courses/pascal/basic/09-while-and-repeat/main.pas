program main;

var
  savings, weeks, bounces: Integer;
  height: Double;

begin
  // while checks the condition before each turn.
  savings := 0;
  weeks := 0;
  while savings < 100 do
  begin
    savings := savings + 15;
    weeks := weeks + 1;
  end;
  WriteLn('After ', weeks, ' weeks: ', savings, ' euros saved');

  // repeat runs at least once and stops when until is true.
  height := 8.0;
  bounces := 0;
  repeat
    height := height / 2;
    Inc(bounces);  // the same as bounces := bounces + 1
    WriteLn('Bounce ', bounces, ': ', height:0:2, ' m');
  until height < 1;

  // A while loop whose condition is false never runs.
  while savings < 50 do
    WriteLn('This line never appears.');
  WriteLn('Done.');
end.
