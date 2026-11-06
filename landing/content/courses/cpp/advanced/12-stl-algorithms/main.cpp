#include <algorithm>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>

struct Sale { std::string product; double amount; };

int main() {
    std::vector<Sale> sales = {{"Keyboard", 45}, {"Monitor", 189}, {"Refund", -45},
                               {"Mouse", 19.5}, {"Laptop", 899}, {"Cable", 7.5}};

    // remove_if moves the unwanted items to the end; erase cuts them off.
    auto isRefund = [](const Sale& s) { return s.amount < 0; };
    sales.erase(std::remove_if(sales.begin(), sales.end(), isRefund), sales.end());

    // transform: one new value per element (the price with 21% VAT).
    std::vector<double> withVat(sales.size());
    std::transform(sales.begin(), sales.end(), withVat.begin(), [](const Sale& s) { return s.amount * 1.21; });

    // accumulate: folds every element into one value, starting from 0.0.
    double net = std::accumulate(sales.begin(), sales.end(), 0.0,
                                 [](double sum, const Sale& s) { return sum + s.amount; });
    double gross = std::accumulate(withVat.begin(), withVat.end(), 0.0);

    auto big = std::count_if(sales.begin(), sales.end(), [](const Sale& s) { return s.amount >= 100; });
    auto cheap = std::find_if(sales.begin(), sales.end(), [](const Sale& s) { return s.amount < 10; });

    std::cout << "Sales kept: " << sales.size() << " (first: " << sales.front().product << ")\n";
    std::cout << "Mouse with VAT: " << withVat[2] << " EUR\n";
    std::cout << "Net: " << net << " EUR, with VAT: " << gross << " EUR\n";
    std::cout << "Sales of 100 EUR or more: " << big << "\n";
    if (cheap != sales.end()) std::cout << "First under 10 EUR: " << cheap->product << "\n";
}
