#include <iomanip>
#include <iostream>

// Money kept in cents, so sums never suffer rounding errors.
class Money {
    long cents_;
public:
    explicit Money(long cents = 0) : cents_(cents) {}
    static Money euros(double e) { return Money(static_cast<long>(e * 100 + 0.5)); }
    // Arithmetic operators return a new value; += changes this one.
    Money operator+(const Money& o) const { return Money(cents_ + o.cents_); }
    Money operator*(int qty) const { return Money(cents_ * qty); }
    Money& operator+=(const Money& o) { cents_ += o.cents_; return *this; }
    bool operator==(const Money& o) const { return cents_ == o.cents_; }
    bool operator<(const Money& o) const { return cents_ < o.cents_; }

    // << is a free function (the stream goes on the left); friend lets it see cents_.
    friend std::ostream& operator<<(std::ostream& os, const Money& m) {
        return os << m.cents_ / 100 << '.' << std::setw(2) << std::setfill('0')
                  << m.cents_ % 100 << std::setfill(' ') << " EUR";
    }
};

int main() {
    Money coffee = Money::euros(1.80), croissant = Money::euros(2.25);
    Money order = coffee * 2 + croissant;
    std::cout << "Order: " << order << "\n";
    Money till;
    for (int i = 0; i < 3; ++i) till += order;
    std::cout << "Till after 3 orders: " << till << "\n";
    std::cout << std::boolalpha;
    std::cout << "Coffee < croissant? " << (coffee < croissant) << "\n";
    std::cout << "Two coffees == 3.60? " << (coffee * 2 == Money::euros(3.60)) << "\n";
}
