#include <stdio.h>

// A type for "a function that takes a double and returns a double".
typedef double (*PriceRule)(double);

double add_vat(double p)  { return p * 1.21; }
double discount(double p) { return p * 0.90; }
double round_up(double p) { return (int)(p + 0.99); }

// apply_all receives a callback: what to do with each price is up to the caller.
void apply_all(double *prices, int n, PriceRule rule) {
    for (int i = 0; i < n; i++) prices[i] = rule(prices[i]);
}

void print_prices(const char *label, const double *prices, int n) {
    printf("%-12s", label);
    for (int i = 0; i < n; i++) printf(" %7.2f", prices[i]);
    printf("\n");
}

int main(void) {
    double prices[] = {10.00, 24.50, 7.95, 99.00};
    int n = sizeof prices / sizeof prices[0];
    print_prices("Start", prices, n);
    // A table of named rules: an array of function pointers.
    struct { const char *name; PriceRule rule; } steps[] = {
        {"Discount", discount}, {"With VAT", add_vat}, {"Rounded", round_up},
    };
    for (int s = 0; s < 3; s++) {
        apply_all(prices, n, steps[s].rule);
        print_prices(steps[s].name, prices, n);
    }
    return 0;
}
