program main;

var
  temp, grade: Integer;

begin
  temp := 31;
  // The line after then only runs if the condition is true.
  if temp > 30 then
    WriteLn(temp, ' C: it is hot, drink water.');
  if temp < 10 then
    WriteLn('Take a coat.');

  // Several statements go between begin and end.
  // There is never a semicolon just before else.
  grade := 6;
  if grade >= 5 then
  begin
    WriteLn('Grade ', grade, ': passed.');
    WriteLn('See you next year.');
  end
  else
    WriteLn('Grade ', grade, ': failed.');

  // else if checks the conditions in order.
  if grade >= 9 then
    WriteLn('Outstanding')
  else if grade >= 7 then
    WriteLn('Very good')
  else if grade >= 5 then
    WriteLn('Pass')
  else
    WriteLn('Fail');
end.
