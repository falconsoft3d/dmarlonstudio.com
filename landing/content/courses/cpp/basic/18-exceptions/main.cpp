#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

// throw stops the function and sends an error to whoever called it.
double withdraw(double balance, double amount) {
    if (amount <= 0) throw std::invalid_argument("the amount must be positive");
    if (amount > balance) throw std::runtime_error("not enough money");
    return balance - amount;
}

int main() {
    double balance = 100;
    std::vector<double> requests = {30, -5, 200, 50};
    for (double amount : requests) {
        try {  // try runs the code; the first matching catch handles the error
            balance = withdraw(balance, amount);
            std::cout << "Withdrew " << amount << ", balance " << balance << '\n';
        } catch (const std::invalid_argument& e) {
            std::cout << "Invalid request " << amount << ": " << e.what() << '\n';
        } catch (const std::runtime_error& e) {
            std::cout << "Refused " << amount << ": " << e.what() << '\n';
        }
    }

    // The library throws too: std::stoi with text that is not a number.
    try {
        std::cout << std::stoi("twenty") << '\n';
    } catch (const std::exception&) {  // std::exception catches any standard error
        std::cout << "\"twenty\" is not a number, but the program goes on\n";
    }
    return 0;
}
