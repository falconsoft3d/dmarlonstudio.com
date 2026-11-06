program main;
type
  TProduct = class
  private
    FPrice: Double;
    procedure SetPrice(AValue: Double);
    function GetPriceWithVat: Double;
  public
    Name: String;
    property Price: Double read FPrice write SetPrice;
    property PriceWithVat: Double read GetPriceWithVat;  // computed, read-only
  end;

procedure TProduct.SetPrice(AValue: Double);
begin
  if AValue >= 0 then FPrice := AValue;  // a negative price is ignored
end;

function TProduct.GetPriceWithVat: Double;
begin
  Result := FPrice * 1.21;
end;

var lamp: TProduct;
begin
  lamp := TProduct.Create;
  lamp.Name := 'Desk lamp';
  lamp.Price := 34.90;  // calls SetPrice(34.90)
  WriteLn(lamp.Name, ': ', lamp.Price:0:2, ' EUR, ', lamp.PriceWithVat:0:2, ' with VAT');
  lamp.Price := -5;
  WriteLn('After trying -5: ', lamp.Price:0:2, ' EUR');
  lamp.Free;
end.
