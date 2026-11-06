program main;

// score is var (the caller's own variable); bonus is just a copy.
procedure AddBonus(var score: Integer; bonus: Integer);
begin
  score := score + bonus;
  bonus := 0;
end;

// var parameters let a procedure hand back several results.
procedure SplitTime(total: Integer; var mins, secs: Integer);
begin
  mins := total div 60;
  secs := total mod 60;
end;

// const: read-only, and the string is not copied.
procedure Show(const player: String; score: Integer);
begin
  WriteLn(player, ': ', score, ' points');
end;

var
  score, bonus, mins, secs: Integer;
begin
  score := 120;
  bonus := 30;
  AddBonus(score, bonus);
  Show('Ana', score);
  WriteLn('Bonus after the call: ', bonus);
  SplitTime(197, mins, secs);
  WriteLn('Lap time: ', mins, ' min ', secs, ' s');
end.
