program main;

uses
  SysUtils;

var
  price: Double;

begin
  price := 3.456;
  // With no format, a real number comes out in scientific notation.
  WriteLn(price);
  // :0:2 means as wide as needed, with two decimals.
  WriteLn(price:0:2);
  // :8:2 fills up to 8 characters, aligned to the right.
  WriteLn('[', price:8:2, ']');
  WriteLn('[', 42:6, ']', '[', 'tea':6, ']');

  // Format, from SysUtils, builds a string from a pattern.
  WriteLn(Format('%-10s%4s%9s', ['Item', 'Qty', 'Euros']));
  WriteLn(Format('%-10s%4d%9.2f', ['Coffee', 2, 2.40]));
  WriteLn(Format('%-10s%4d%9.2f', ['Croissant', 3, 4.65]));
  WriteLn(Format('%-10s%4d%9.2f', ['Juice', 1, 2.10]));
  WriteLn(Format('%-14s%9.2f', ['Total', 9.15]));
  WriteLn(Format('VAT included: %d%%', [10]));
end.
