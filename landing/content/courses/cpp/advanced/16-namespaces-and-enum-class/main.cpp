#include <iostream>
#include <string>

namespace shop {
    // enum class: scoped names that do not turn into int on their own.
    enum class OrderStatus { Pending, Paid, Shipped, Delivered };
    enum class Priority : char { Low = 'L', High = 'H' };    // chosen underlying type

    std::string label(OrderStatus s) {
        switch (s) {
            case OrderStatus::Pending:   return "pending";
            case OrderStatus::Paid:      return "paid";
            case OrderStatus::Shipped:   return "shipped";
            case OrderStatus::Delivered: return "delivered";
        }
        return "unknown";
    }
}

namespace shop::tax {                  // a nested namespace (C++17 syntax)
    constexpr double vat = 0.21;
    double withVat(double net) { return net * (1 + vat); }
}
namespace tx = shop::tax;              // a shorter alias

int main() {
    using shop::OrderStatus;           // bring in just this one name
    OrderStatus status = OrderStatus::Paid;
    std::cout << "Order is " << shop::label(status) << "\n";
    status = static_cast<OrderStatus>(static_cast<int>(status) + 1);    // next step
    std::cout << "Now it is " << shop::label(status) << " (step " << static_cast<int>(status) << ")\n";
    std::cout << "Priority code: " << static_cast<char>(shop::Priority::High) << "\n";
    std::cout << "120 EUR + VAT = " << tx::withVat(120) << " EUR\n";
}
