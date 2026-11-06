program main;

var
  minutes, slices, friends: Integer;
  share: Double;

begin
  // div divides whole numbers; mod gives the remainder.
  minutes := 135;
  WriteLn(minutes, ' min = ', minutes div 60, ' h ', minutes mod 60, ' min');

  slices := 17;
  friends := 5;
  WriteLn('Each friend gets ', slices div friends, ' slices');
  WriteLn('Slices left over: ', slices mod friends);

  // / always gives a real number, even with two integers.
  share := slices / friends;
  WriteLn('Exact share: ', share:0:2);

  // * and / go before + and -; brackets change the order.
  WriteLn('2 + 3 * 4 = ', 2 + 3 * 4);
  WriteLn('(2 + 3) * 4 = ', (2 + 3) * 4);

  // From real to integer: Trunc cuts, Round rounds.
  WriteLn('Trunc(3.7) = ', Trunc(3.7), ' | Round(3.7) = ', Round(3.7));
  // Round sends .5 to the even number.
  WriteLn('Round(2.5) = ', Round(2.5), ' | Round(3.5) = ', Round(3.5));
  WriteLn('Even? ', 42 mod 2 = 0);
end.
