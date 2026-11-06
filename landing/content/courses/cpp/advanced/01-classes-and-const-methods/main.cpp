#include <iostream>
#include <string>

// A class groups data (members) with the functions that work on it.
class BankAccount {
public:
    std::string owner;
    double balance;
    // Constructor: runs every time an account is created.
    BankAccount(std::string name, double initial) {
        owner = name;
        balance = initial;
    }
    void deposit(double amount) { balance += amount; }
    bool withdraw(double amount) {
        if (amount > balance) return false;   // not enough money
        balance -= amount;
        return true;
    }
    // const: this method promises not to change the object.
    void print() const { std::cout << owner << ": " << balance << " EUR\n"; }
};

int main() {
    BankAccount ana("Ana", 120.0);
    BankAccount luis("Luis", 40.0);
    ana.deposit(30.5);
    std::cout << "Luis withdraws 60? " << (luis.withdraw(60) ? "yes" : "no") << "\n";
    std::cout << "Luis withdraws 25? " << (luis.withdraw(25) ? "yes" : "no") << "\n";
    ana.print();
    luis.print();
    const BankAccount& view = ana;   // read-only: only const methods are allowed
    view.print();                    // view.deposit(5) would not compile
}
