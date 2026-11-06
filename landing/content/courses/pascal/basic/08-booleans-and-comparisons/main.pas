program main;

var
  age, height: Integer;
  hasTicket, isMember, canRide, discount: Boolean;

begin
  age := 12;
  height := 145;
  hasTicket := True;
  isMember := False;

  // = compares (:= assigns) and <> means "not equal".
  WriteLn('Is the age 12? ', age = 12);
  WriteLn('Is the age not 18? ', age <> 18);
  WriteLn('Taller than 1.50 m? ', height > 150);

  // With and/or, each comparison goes in its own brackets.
  canRide := (height >= 140) and hasTicket;
  WriteLn('Can ride the roller coaster? ', canRide);

  discount := (age < 14) or (age >= 65) or isMember;
  WriteLn('Gets a discount? ', discount);
  WriteLn('Pays full price? ', not discount);

  // xor is true when exactly one side is true.
  WriteLn('Ticket or card, but not both? ', hasTicket xor isMember);

  if (age >= 10) and (age <= 12) then
    WriteLn('Category: junior');
end.
