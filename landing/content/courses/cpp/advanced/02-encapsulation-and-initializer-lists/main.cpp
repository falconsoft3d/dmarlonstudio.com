#include <iostream>
#include <string>

class Thermostat {
    // A class is private by default: only its own methods can touch these.
    std::string room_;
    double target_;
    const double min_, max_;      // const members must be set in the list
    int changes_ = 0;             // default member initializer
public:
    // Initializer list: members are built directly, in declaration order.
    Thermostat(std::string room, double target, double min = 15, double max = 28)
        : room_(room), target_(target), min_(min), max_(max) {}
    // The only way to change the target, so it always stays in range.
    void set(double t) {
        target_ = t < min_ ? min_ : (t > max_ ? max_ : t);
        ++changes_;
    }
    double target() const { return target_; }    // read-only access
    void show() const {
        std::cout << room_ << ": " << target_ << " C (changes: " << changes_ << ")\n";
    }
};

int main() {
    Thermostat living("Living room", 21);
    Thermostat office("Office", 20, 18, 24);
    living.show();
    living.set(35);               // too hot: clamped to 28
    office.set(10);               // too cold: clamped to 18
    living.show();
    office.show();
    std::cout << "Average: " << (living.target() + office.target()) / 2 << " C\n";
}
