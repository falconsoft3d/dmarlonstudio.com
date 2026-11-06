program main;
uses SysUtils, fgl;
type
  EBankError = class(Exception);
  TBank = class(specialize TFPGMap<String, Currency>)  // owner -> balance, plus rules
    procedure Withdraw(const owner: String; amount: Currency);
  end;

procedure TBank.Withdraw(const owner: String; amount: Currency);
begin
  if IndexOf(owner) < 0 then
    raise EBankError.CreateFmt('there is no account for %s', [owner]);
  if amount > KeyData[owner] then
    raise EBankError.CreateFmt('%s has only %.2f', [owner, Double(KeyData[owner])]);
  KeyData[owner] := KeyData[owner] - amount;
  WriteLn(owner, ' withdrew ', amount:0:2);
end;
const Requests: array[0..2] of String = ('Elena', 'Pablo', 'Marta');
var
  bank: TBank;
  i: Integer;
begin
  bank := TBank.Create;
  bank['Elena'] := 300;  // adds the key, or changes it if it exists
  bank['Pablo'] := 120;
  for i := 0 to High(Requests) do
    try
      bank.Withdraw(Requests[i], 200);
    except
      on E: EBankError do WriteLn('Refused: ', E.Message);
    end;
  for i := 0 to bank.Count - 1 do WriteLn(bank.Keys[i]:6, bank.Data[i]:8:2);
  bank.Free;
end.
