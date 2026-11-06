program main;
type
  TCustomer = class
    Name: String;
    Orders: Integer;
    constructor Create(const AName: String);
    destructor Destroy; override;
    procedure AddOrder;
  end;

constructor TCustomer.Create(const AName: String);
begin
  Name := AName;  // Orders already starts at 0
  WriteLn('Created ', Name);
end;
destructor TCustomer.Destroy;
begin
  WriteLn('Freed ', Name);
  inherited Destroy;
end;
procedure TCustomer.AddOrder;
begin
  Inc(Orders);
end;

var ana, other: TCustomer;
begin
  ana := TCustomer.Create('Ana Lopez');
  ana.AddOrder;
  other := ana;  // copies the reference: still one single object
  other.AddOrder;
  WriteLn(ana.Name, ' has ', ana.Orders, ' orders');
  ana.Free;      // free it once; other now points to freed memory
end.
