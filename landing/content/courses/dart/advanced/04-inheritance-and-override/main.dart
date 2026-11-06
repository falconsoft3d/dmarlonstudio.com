class Employee {
  final String name;
  final int monthlySalary;
  Employee(this.name, this.monthlySalary);

  int annualCost() => monthlySalary * 14; // 14 payments a year
  String describe() => '$name: ${annualCost()} EUR/year';
}

class Manager extends Employee {
  final int bonus;
  // super.name passes the argument on to the parent constructor.
  Manager(super.name, super.monthlySalary, {required this.bonus});

  @override
  int annualCost() => super.annualCost() + bonus;

  @override
  String describe() => '${super.describe()} (incl. bonus $bonus)';
}

class Intern extends Employee {
  Intern(String name) : super(name, 900);

  @override
  int annualCost() => monthlySalary * 6; // six-month contract
}

void main() {
  final staff = [Employee('Ana', 2400), Manager('Luis', 3800, bonus: 6000), Intern('Marta')];
  for (final person in staff) print(person.describe()); // its own annualCost()
  print('Payroll: ${staff.fold(0, (sum, p) => sum + p.annualCost())} EUR');
  print('${staff[2].runtimeType} is Employee: ${staff[2] is Employee}');
}
