#include <iostream>
#include <string>

int main() {
    int age = 16;
    bool withAdult = true;
    double temperature = 31.5;

    // A comparison gives a bool: true or false.
    bool adult = age >= 18;
    std::cout << "adult = " << adult << '\n';  // by default, 0 or 1
    std::cout << std::boolalpha;               // from now on, false or true
    std::cout << "adult = " << adult << '\n';
    std::cout << "age == 16: " << (age == 16) << ", age != 16: " << (age != 16) << '\n';

    // && (and): both must be true. || (or): at least one. ! (not) reverses.
    bool canEnter = adult || withAdult;
    std::cout << "Can see the film: " << canEnter << '\n';
    bool hotDay = temperature > 30 && temperature <= 45;
    std::cout << "Hot day: " << hotDay << ", not hot: " << !hotDay << '\n';

    // Short-circuit: if the left side decides, the right one is not evaluated.
    int boxes = 0, items = 12;
    if (boxes != 0 && items / boxes > 5) std::cout << "The boxes are full\n";
    else std::cout << "No boxes to check (and no division by zero)\n";

    // Strings are compared in alphabetical order.
    std::string a = "apple", b = "banana";
    std::cout << a << " < " << b << ": " << (a < b) << '\n';
    return 0;
}
