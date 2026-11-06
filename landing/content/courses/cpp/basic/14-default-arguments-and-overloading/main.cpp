#include <iostream>
#include <string>

// Default arguments: used when the call leaves them out.
double withVat(double price, double vat = 0.21) { return price * (1 + vat); }

void greet(const std::string& name, const std::string& word = "Hello", int times = 1) {
    for (int i = 0; i < times; i++) std::cout << word << ", " << name << "! ";
    std::cout << '\n';
}

// Overloading: the same name with different parameters.
double area(double side) { return side * side; }                     // a square
double area(double width, double height) { return width * height; }  // a rectangle

void show(int value) { std::cout << "int: " << value << '\n'; }
void show(double value) { std::cout << "double: " << value << '\n'; }
void show(const std::string& text) { std::cout << "string: \"" << text << "\"\n"; }

int main() {
    std::cout << "Shoes: " << withVat(100) << '\n';        // vat = 0.21
    std::cout << "Book:  " << withVat(100, 0.04) << '\n';  // vat = 0.04

    greet("Carmen");
    greet("Carmen", "Good morning");
    greet("Leo", "Hi", 3);

    // The compiler picks the version that matches the arguments.
    std::cout << "Square 4 m: " << area(4) << " m2, room 3 x 5 m: " << area(3, 5) << " m2\n";
    show(42);
    show(3.5);
    show("ready");
    return 0;
}
