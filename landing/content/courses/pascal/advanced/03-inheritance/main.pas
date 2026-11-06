program main;
type
  TEmployee = class
    Name: String;
    Salary: Double;
    constructor Create(const AName: String; ASalary: Double);
    procedure Print;
  end;
  TManager = class(TEmployee)  // inherits Name, Salary and Print
    Team: Integer;
    constructor Create(const AName: String; ASalary: Double; ATeam: Integer);
  end;

constructor TEmployee.Create(const AName: String; ASalary: Double);
begin
  Name := AName; Salary := ASalary;
end;
procedure TEmployee.Print;
begin
  WriteLn(Name, ' earns ', Salary:0:0, ' EUR a month');
end;
constructor TManager.Create(const AName: String; ASalary: Double; ATeam: Integer);
begin
  inherited Create(AName, ASalary);  // the parent fills Name and Salary
  Team := ATeam;
end;

var boss: TManager;
begin
  boss := TManager.Create('Javier Ruiz', 3600, 5);
  boss.Print;  // a TEmployee method
  WriteLn(boss.ClassName, ' leads ', boss.Team, ' people; is a TEmployee: ', boss is TEmployee);
  boss.Free;
end.
