program main;
type
  ITax = interface
    function Apply(net: Double): Double;
  end;
  TVat = class(TInterfacedObject, ITax)
    function Apply(net: Double): Double;
  end;
  TIgic = class(TInterfacedObject, ITax)
    function Apply(net: Double): Double;
  end;

function TVat.Apply(net: Double): Double;
begin
  Result := net * 1.21;  // mainland Spain
end;
function TIgic.Apply(net: Double): Double;
begin
  Result := net * 1.07;  // Canary Islands
end;

procedure Quote(const region: String; tax: ITax; net: Double);
begin
  WriteLn(region:9, ': ', net:7:2, ' net -> ', tax.Apply(net):7:2, ' EUR');
end;

var tax: ITax;
begin
  Quote('Madrid', TVat.Create, 250);     // the object is freed after the call
  Quote('Tenerife', TIgic.Create, 250);
  tax := TIgic.Create;                   // kept alive while tax refers to it
  Quote('La Palma', tax, 19.99);
  tax := nil;                            // last reference gone: freed here
end.
