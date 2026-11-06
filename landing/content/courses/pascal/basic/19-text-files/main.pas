program main;

uses
  SysUtils;

var
  f: TextFile;
  line: String;
  count: Integer;
begin
  // Rewrite creates the file (or empties it) to write in it.
  AssignFile(f, 'shopping.txt');
  Rewrite(f);
  WriteLn(f, 'bread');
  WriteLn(f, 'milk');
  CloseFile(f);

  // Append opens it again and writes at the end.
  Append(f);
  WriteLn(f, 'coffee');
  CloseFile(f);

  // Reset opens it to read, from the first line.
  Reset(f);
  count := 0;
  while not Eof(f) do
  begin
    ReadLn(f, line);
    Inc(count);
    WriteLn(count, '. ', line);
  end;
  CloseFile(f);
  WriteLn('Items: ', count, ' | Is there a notes.txt? ', FileExists('notes.txt'));
end.
