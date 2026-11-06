#include <iostream>

int main() {
    // Shipping cost in an online shop.
    double basket = 42.5;
    if (basket >= 50) {
        std::cout << "Free shipping\n";
    } else if (basket >= 30) {
        std::cout << "Basket " << basket << ": shipping 2.99\n";
    } else {
        std::cout << "Basket " << basket << ": shipping 5.99\n";
    }

    // The first true condition wins; the rest are skipped.
    int score = 78;
    char grade = 'F';
    if (score >= 90) grade = 'A';
    else if (score >= 75) grade = 'B';
    else if (score >= 50) grade = 'C';
    std::cout << "Score " << score << " -> grade " << grade << '\n';

    // switch compares one value with fixed cases; break ends each case.
    switch (grade) {
        case 'A': std::cout << "Excellent!\n"; break;
        case 'B': std::cout << "Very good\n"; break;
        case 'C': std::cout << "Passed\n"; break;
        default:  std::cout << "Try again\n";
    }

    // The ternary operator: condition ? if_true : if_false.
    int stock = 0;
    std::cout << (stock > 0 ? "In stock" : "Sold out") << '\n';
    return 0;
}
