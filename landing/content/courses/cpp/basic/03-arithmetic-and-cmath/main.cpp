#include <cmath>
#include <iostream>

int main() {
    // With two ints, / is integer division and % gives the remainder.
    int cookies = 17, children = 5;
    std::cout << "Each child gets " << cookies / children << " cookies\n";
    std::cout << "Left over: " << cookies % children << '\n';

    // If one side is a double, the result keeps the decimals.
    std::cout << "Exact share: " << cookies / 5.0 << '\n';
    // static_cast converts a value to another type.
    std::cout << "Average: " << static_cast<double>(cookies) / children << '\n';

    int score = 10;  // compound operators: += -= *= /=, and ++
    score += 5;  // 15
    score *= 2;  // 30
    score++;     // 31
    std::cout << "Score: " << score << '\n';

    // <cmath> brings the maths functions.
    double a = 3.0, b = 4.0;
    std::cout << "Hypotenuse: " << std::sqrt(a * a + b * b) << '\n';
    std::cout << "2 to the 10th: " << std::pow(2, 10) << '\n';
    std::cout << "round(7.5): " << std::round(7.5) << ", floor(7.5): " << std::floor(7.5)
              << ", ceil(7.2): " << std::ceil(7.2) << '\n';
    std::cout << "abs(-12.5): " << std::abs(-12.5) << '\n';

    // Area of a pizza 30 cm across.
    const double pi = 3.14159265358979;
    double radius = 15;
    std::cout << "Pizza area: " << pi * std::pow(radius, 2) << " cm2\n";
    return 0;
}
