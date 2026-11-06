program main;

uses
  SysUtils;

var
  first, last, full, email, user, domain: String;
  at: Integer;

begin
  first := 'Ada';
  last := 'Lovelace';
  // + joins strings.
  full := first + ' ' + last;
  WriteLn('Full name: ', full, ' (', Length(full), ' characters)');

  // Characters are numbered from 1.
  WriteLn('Initials: ', first[1], last[1]);
  WriteLn('In capitals: ', UpperCase(full));
  WriteLn('In small letters: ', LowerCase(full));

  // Pos finds a piece of text; Copy(s, start, count) cuts one out.
  email := 'ada.lovelace@example.com';
  at := Pos('@', email);
  user := Copy(email, 1, at - 1);
  domain := Copy(email, at + 1, Length(email) - at);
  WriteLn('The @ is at position ', at);
  WriteLn('User: ', user, ' | Domain: ', domain);
  WriteLn('Position of "xyz": ', Pos('xyz', email));

  // IntToStr turns a number into text, ready to join.
  WriteLn('Order ' + IntToStr(1024) + ' for ' + first);
end.
