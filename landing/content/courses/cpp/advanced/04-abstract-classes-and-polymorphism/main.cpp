#include <iostream>
#include <vector>

struct PaymentMethod {   // abstract: pure virtual functions (= 0), no objects of it
    virtual ~PaymentMethod() = default;
    virtual const char* name() const = 0;
    virtual double fee(double amount) const = 0;
    double total(double amount) const { return amount + fee(amount); }
};
struct Card : PaymentMethod {
    const char* name() const override { return "Card"; }
    double fee(double amount) const override { return amount * 0.015; }
};
struct PayPal : PaymentMethod {
    const char* name() const override { return "PayPal"; }
    double fee(double amount) const override { return 0.35 + amount * 0.029; }
};
struct Transfer : PaymentMethod {
    const char* name() const override { return "Transfer"; }
    double fee(double) const override { return 1.0; }   // flat fee
};

int main() {
    Card card; PayPal paypal; Transfer transfer;
    std::vector<const PaymentMethod*> methods = {&card, &paypal, &transfer};   // pointers to the base
    for (double amount : {20.0, 80.0}) {
        const PaymentMethod* best = methods[0];
        for (const PaymentMethod* m : methods) {
            std::cout << amount << " EUR by " << m->name() << ": " << m->total(amount) << "\n";
            if (m->fee(amount) < best->fee(amount)) best = m;
        }
        std::cout << "  cheapest: " << best->name() << "\n";
    }
}
