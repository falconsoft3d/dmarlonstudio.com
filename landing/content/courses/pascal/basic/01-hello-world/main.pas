program main;

{ The program runs from begin to the final end with a full stop. }
begin
  WriteLn('Hello, world!');
  WriteLn('Welcome to Pascal.');

  // Write stays on the same line; WriteLn moves to the next one.
  Write('Two plus three is ');
  WriteLn(2 + 3);

  // Several values, separated by commas, in one WriteLn.
  WriteLn('A week has ', 7 * 24, ' hours.');
  WriteLn;
  WriteLn('Goodbye!');
end.
