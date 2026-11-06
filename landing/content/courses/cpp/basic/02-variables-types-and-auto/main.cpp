#include <iostream>
#include <string>

int main() {
    // Each variable has a type, a name and (always, better) a value.
    int age = 34;
    double height = 1.78;
    char grade = 'A';
    bool member = true;
    std::string name = "Lucia";

    std::cout << name << " is " << age << " years old\n";
    std::cout << "Height: " << height << " m, grade " << grade << '\n';
    std::cout << "Member: " << member << '\n';  // a bool prints 1 or 0

    // A variable can change its value, but never its type.
    age = age + 1;
    std::cout << "Next year: " << age << '\n';

    // const: a value that must not change.
    const double vat = 0.21;

    // auto: the compiler deduces the type from the value.
    auto price = 49.90;  // double
    auto units = 3;      // int
    auto total = price * units * (1 + vat);
    std::cout << "Total with VAT: " << total << '\n';

    // sizeof tells how many bytes a type takes in memory.
    std::cout << "int: " << sizeof(int) << " bytes, double: " << sizeof(double) << " bytes\n";
    return 0;
}
