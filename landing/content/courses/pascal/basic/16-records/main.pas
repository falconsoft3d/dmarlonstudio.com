program main;

type
  TProduct = record
    Name: String;
    Price: Double;
    Stock: Integer;
  end;

function MakeProduct(const name: String; price: Double; stock: Integer): TProduct;
begin
  Result.Name := name;
  Result.Price := price;
  Result.Stock := stock;
end;

procedure Show(const p: TProduct);
begin
  WriteLn(p.Name:10, p.Price:8:2, p.Stock:5);
end;

var
  pen, book, diary: TProduct;
begin
  pen := MakeProduct('Pen', 1.20, 50);
  book := MakeProduct('Notebook', 3.75, 12);
  // Assigning a record copies every field.
  diary := book;
  diary.Name := 'Diary';
  Show(pen);
  Show(book);
  Show(diary);
  WriteLn('Stock value: ', pen.Price * pen.Stock + book.Price * book.Stock:0:2);
end.
