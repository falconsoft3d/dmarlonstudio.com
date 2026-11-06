program main;
type
  TShipping = class
    function Cost(kg: Double): Double; virtual;
  end;
  TExpress = class(TShipping)
    function Cost(kg: Double): Double; override;
  end;
  TPickup = class(TShipping)
    function Cost(kg: Double): Double; override;
  end;

function TShipping.Cost(kg: Double): Double;
begin
  Result := 4.95 + 0.80 * kg;  // standard rate
end;
function TExpress.Cost(kg: Double): Double;
begin
  Result := inherited Cost(kg) * 2;  // twice the standard rate
end;
function TPickup.Cost(kg: Double): Double;
begin
  Result := 0;  // collected at the shop
end;

var option: TShipping;
begin
  for option in [TShipping.Create, TExpress.Create, TPickup.Create] do
  begin
    WriteLn(option.ClassName:10, ': ', option.Cost(3.5):5:2, ' EUR for 3.5 kg');
    option.Free;
  end;
end.
