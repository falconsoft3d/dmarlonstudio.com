#include <iomanip>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>

const std::map<std::string, double> catalog = {
    {"apple", 0.35}, {"bread", 1.20}, {"cheese", 4.75}, {"milk", 0.99}};

void add(std::map<std::string, int>& cart, const std::string& item, int units = 1) {
    if (catalog.count(item) == 0) throw std::invalid_argument("unknown product " + item);
    if (units <= 0) throw std::invalid_argument("no units of " + item);
    cart[item] += units;
}

int main() {
    std::map<std::string, int> cart;
    std::string item; int units = 0;  // each order: product and units
    while (std::cin >> item >> units) {
        try { add(cart, item, units); }
        catch (const std::exception& e) { std::cout << "Skipped: " << e.what() << '\n'; }
    }
    add(cart, "bread");  // one unit by default
    std::cout << std::fixed << std::setprecision(2);
    double total = 0;
    for (const auto& [name, count] : cart) {
        double price = catalog.at(name);
        total += count * price;
        std::cout << std::left << std::setw(7) << name << std::right << std::setw(3) << count
                  << " x" << std::setw(5) << price << std::setw(7) << count * price << '\n';
    }
    std::cout << "Total " << total << ", to pay " << (total > 5 ? total * 0.90 : total) << '\n';
    return 0;
}
