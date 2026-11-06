#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

// A family of errors: all of them are AppError, and AppError is a runtime_error.
struct AppError : std::runtime_error { using std::runtime_error::runtime_error; };
struct ValidationError : AppError {
    std::string field;                                  // extra data about the error
    ValidationError(const std::string& f, const std::string& msg) : AppError(msg), field(f) {}
};
struct PaymentError : AppError {
    int code;
    explicit PaymentError(int c) : AppError("payment declined"), code(c) {}
};

void checkout(const std::string& email, double amount) {
    if (email.find('@') == std::string::npos) throw ValidationError("email", "missing @");
    if (amount <= 0) throw AppError("the cart is empty");
    if (amount > 1000) throw PaymentError(51);
    std::cout << "OK: " << amount << " EUR charged to " << email << "\n";
}

int main() {
    std::vector<std::pair<std::string, double>> orders = {
        {"ana@mail.com", 59.9}, {"luis.mail.com", 20}, {"eva@mail.com", 1500}, {"leo@mail.com", 0}};
    for (const auto& [email, amount] : orders) {
        try { checkout(email, amount); }     // the catches go from most to least specific
        catch (const ValidationError& e) { std::cout << "Invalid " << e.field << ": " << e.what() << "\n"; }
        catch (const PaymentError& e) { std::cout << "Bank code " << e.code << ": " << e.what() << "\n"; }
        catch (const AppError& e) { std::cout << "Cannot check out: " << e.what() << "\n"; }
    }
}
