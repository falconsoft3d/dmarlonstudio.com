#include <iomanip>
#include <iostream>
#include <string>
#include <utility>
#include <vector>

int main() {
    std::vector<std::pair<std::string, double>> menu = {
        {"Coffee", 1.5}, {"Croissant", 2.25}, {"Orange juice", 3}, {"Toast", 1.8}};

    // setw sets the width of the NEXT value; left and right align it.
    std::cout << std::left << std::setw(14) << "Item" << std::right << std::setw(8) << "Price" << '\n';
    // setfill changes the character that fills the gap.
    std::cout << std::setfill('-') << std::setw(22) << "" << std::setfill(' ') << '\n';

    // fixed + setprecision(2): always two decimals, until changed.
    std::cout << std::fixed << std::setprecision(2);
    double total = 0;
    for (const auto& [name, price] : menu) {
        std::cout << std::left << std::setw(14) << name << std::right << std::setw(8) << price << '\n';
        total += price;
    }
    std::cout << std::left << std::setw(14) << "TOTAL" << std::right << std::setw(8) << total << '\n';

    // Leading zeros for an order number.
    std::cout << "Order #" << std::setfill('0') << std::setw(5) << 42 << std::setfill(' ') << '\n';

    // Without fixed, setprecision counts significant digits.
    std::cout << std::defaultfloat << std::setprecision(3) << "Pi is about " << 3.14159 << '\n';

    // Integers in other bases.
    std::cout << "255 in hex: " << std::hex << 255 << ", in octal: " << std::oct << 255 << std::dec << '\n';
    return 0;
}
