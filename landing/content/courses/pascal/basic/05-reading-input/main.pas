program main;

var
  name: String;
  age, tickets, first, second: Integer;
  price: Double;

begin
  Write('What is your name? ');
  ReadLn(name);
  WriteLn('Nice to meet you, ', name, '!');

  // ReadLn turns the text into the type of the variable.
  Write('How old are you? ');
  ReadLn(age);
  WriteLn('In 10 years you will be ', age + 10, '.');

  Write('Price of a cinema ticket? ');
  ReadLn(price);
  Write('How many tickets? ');
  ReadLn(tickets);
  WriteLn(tickets, ' tickets cost ', price * tickets:0:2, ' euros.');

  // Several numbers on the same line, separated by spaces.
  Write('Your two exam marks? ');
  ReadLn(first, second);
  WriteLn('Average mark: ', (first + second) / 2:0:1);
end.
