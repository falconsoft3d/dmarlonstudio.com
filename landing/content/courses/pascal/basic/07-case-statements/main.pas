program main;

var
  day, score: Integer;
  option: Char;

begin
  day := 6;
  case day of
    1..5: WriteLn('Day ', day, ': working day');
    6, 7: WriteLn('Day ', day, ': weekend');
  else
    WriteLn('Day ', day, ': not a day of the week');
  end;

  // Ranges keep a grade table short.
  score := 83;
  case score of
    90..100: WriteLn(score, ' points: A');
    80..89: WriteLn(score, ' points: B');
    70..79: WriteLn(score, ' points: C');
  else
    WriteLn(score, ' points: keep practising');
  end;

  // case also works with Char: a vending machine.
  option := 'b';
  case option of
    'a': WriteLn('Water: 1.00');
    'b': WriteLn('Coffee: 1.50');
    'c': WriteLn('Juice: 2.00');
  end;
end.
