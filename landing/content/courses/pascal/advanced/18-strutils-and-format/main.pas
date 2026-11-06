program main;
uses SysUtils, StrUtils;
const
  Row = 'Wireless mouse;Peripherals;19.9;48';
  Card = '4532015112830366';
var
  name: String;
  price: Double;
  stock: Integer;
begin
  WriteLn('Fields: ', WordCount(Row, [';']));
  name := ExtractWord(1, Row, [';']);
  price := StrToFloat(ExtractWord(3, Row, [';']));
  stock := StrToInt(ExtractWord(4, Row, [';']));

  WriteLn(Format('|%-16s|%8s|%6s|', ['Product', 'Price', 'Units']));  // - aligns left
  WriteLn(Format('|%-16s|%8.2f|%6d|', [name, price, stock]));
  WriteLn(Format('%s costs %.2f; stock is %s', [name, price, IfThen(stock < 50, 'low', 'fine')]));
  WriteLn('Slug: ', LowerCase(ReplaceStr(name, ' ', '-')));
  WriteLn('Reversed: ', ReverseString(name));
  WriteLn('Mentions MOUSE: ', ContainsText(name, 'MOUSE'), ', starts with "wire": ',
    StartsText('wire', name));
  WriteLn('Card: ', DupeString('*', 12) + RightStr(Card, 4));
  WriteLn('Centred: [', PadCenter('SALE', 12), ']');
  WriteLn(Format('Invoice INV-%.6d, colour #%x', [42, 16744448]));
end.
