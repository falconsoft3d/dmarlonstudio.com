#include <iostream>
#include <string>

class Employee {
public:
    Employee(std::string name, double base) : name_(name), base_(base) {}
    virtual ~Employee() = default;
    // virtual: a derived class may replace it with its own version.
    virtual double pay() const { return base_; }
    virtual std::string role() const { return "Employee"; }
    void payslip() const { std::cout << name_ << " (" << role() << "): " << pay() << " EUR\n"; }
protected:                         // visible to derived classes, hidden from the rest
    std::string name_;
    double base_;
};

class Manager : public Employee {      // a Manager is an Employee
    double bonus_;
public:
    Manager(std::string name, double base, double bonus) : Employee(name, base), bonus_(bonus) {}
    double pay() const override { return Employee::pay() + bonus_; }
    std::string role() const override { return "Manager"; }
};

int main() {
    Employee eva("Eva", 2100);
    Manager marc("Marc", 2800, 650);
    eva.payslip();
    marc.payslip();                // payslip() is Employee's, but calls Manager::pay
    const Employee& ref = marc;    // a base reference to a Manager
    std::cout << "Via Employee&: " << ref.pay() << " EUR\n";
    Employee copy = marc;          // slicing: only the Employee part is copied
    copy.payslip();
}
