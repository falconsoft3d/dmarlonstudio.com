class Employee:
    def __init__(self, name, salary):
        self.name = name
        self.salary = salary

    def monthly_pay(self):
        return self.salary / 12

    def describe(self):
        return f"{self.name:<6} {type(self).__name__:<9} {self.monthly_pay():>8.2f}"

class Manager(Employee):              # Manager is an Employee
    def __init__(self, name, salary, bonus):
        super().__init__(name, salary)    # let the parent set its part
        self.bonus = bonus

    def monthly_pay(self):            # override: same name, new behaviour
        return super().monthly_pay() + self.bonus / 12

class Intern(Employee):
    def monthly_pay(self):
        return 800.0                  # fixed grant

staff = [Employee("Lucia", 30000), Manager("Pablo", 48000, 6000),
         Intern("Iker", 0)]
for person in staff:                  # the same call, the right method
    print(person.describe())

print("Payroll:", round(sum(p.monthly_pay() for p in staff), 2))
print("Pablo is an Employee:", isinstance(staff[1], Employee))
print("Manager subclass of Employee:", issubclass(Manager, Employee))
print("Method order:", [c.__name__ for c in Manager.__mro__])
