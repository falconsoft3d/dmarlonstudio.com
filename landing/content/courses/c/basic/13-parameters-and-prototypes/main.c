#include <stdio.h>

// Prototypes announce the functions; their bodies come after main.
double apply_discount(double price, int percent);
int is_leap(int year);

int main(void) {
    // Arguments go in the same order as the parameters.
    printf("Headphones: %.2f\n", apply_discount(59.90, 20));
    printf("Keyboard:   %.2f\n", apply_discount(45.00, 15));

    // Parameters are copies: the function cannot change price here.
    double price = 10.0;
    apply_discount(price, 50);
    printf("price is still %.2f\n", price);
    price = apply_discount(price, 50);  // keep the returned value
    printf("now price is %.2f\n", price);

    int years[] = {1900, 2000, 2024, 2026};
    for (int i = 0; i < 4; i++)
        printf("%d: %s\n", years[i], is_leap(years[i]) ? "leap" : "normal");
    return 0;
}

double apply_discount(double price, int percent) {
    price = price * (100 - percent) / 100;  // changes only the copy
    return price;
}

int is_leap(int year) {
    if (year % 400 == 0) return 1;  // return ends the function at once
    if (year % 100 == 0) return 0;
    return year % 4 == 0;
}
