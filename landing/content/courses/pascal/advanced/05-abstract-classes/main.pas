program main;
type
  TPayment = class
    function Fee(amount: Double): Double; virtual; abstract;  // no body here
    procedure Charge(amount: Double);
  end;
  TCard = class(TPayment)
    function Fee(amount: Double): Double; override;
  end;
  TTransfer = class(TPayment)
    function Fee(amount: Double): Double; override;
  end;

procedure TPayment.Charge(amount: Double);
begin  // the same steps for every method; only Fee changes
  WriteLn(Copy(ClassName, 2, 9):8, amount:8:2, ' + fee', Fee(amount):5:2, ' =', amount + Fee(amount):7:2);
end;
function TCard.Fee(amount: Double): Double;
begin
  Result := amount * 0.015;  // 1.5 % of the amount
end;
function TTransfer.Fee(amount: Double): Double;
begin
  Result := 0.35;  // flat fee
end;
var method: TPayment;
begin
  for method in [TCard.Create, TTransfer.Create] do
  begin
    method.Charge(20);
    method.Charge(250);
    method.Free;
  end;
end.
