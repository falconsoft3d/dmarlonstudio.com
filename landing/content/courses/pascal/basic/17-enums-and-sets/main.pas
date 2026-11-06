program main;

type
  TDay = (Mon, Tue, Wed, Thu, Fri, Sat, Sun);  // an enumerated type
  TDays = set of TDay;

var
  day: TDay;
  open: TDays;
  c: Char;
  vowels: Integer;
begin
  day := Wed;
  WriteLn(day, ' is at position ', Ord(day), '; the next day is ', Succ(day));

  // A set holds some of those values, without order or repeats.
  open := [Mon..Fri];
  Include(open, Sat);
  Exclude(open, Wed);
  for day := Mon to Sun do
    if day in open then
      Write(day, ' ');
  WriteLn;
  WriteLn('Open on Sunday? ', Sun in open);
  for day in open * [Sat, Sun] do  // * is the intersection
    WriteLn('Open at the weekend: ', day);

  // Sets of Char make quick character tests.
  vowels := 0;
  for c in 'free pascal compiler' do
    if c in ['a', 'e', 'i', 'o', 'u'] then
      Inc(vowels);
  WriteLn('Vowels: ', vowels);
end.
