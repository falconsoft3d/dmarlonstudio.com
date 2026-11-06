#include <stdio.h>

int main(void) {
    int items = 3;
    double total = 42.75;
    char size = 'M';

    // %d int, %f double, %c char, %s text
    printf("%d items, size %c, %s\n", items, size, "paid");

    // .2 means two decimals; .0 rounds to a whole number.
    printf("Total: %.2f euros\n", total);
    printf("Total: %.0f euros (rounded)\n", total);

    // A width pads the value: right-aligned by default, - aligns left.
    printf("[%5d] [%-5d] [%05d]\n", 42, 42, 42);

    // A small receipt in columns.
    printf("%-10s %4s %8s\n", "Product", "Qty", "Price");
    printf("%-10s %4d %8.2f\n", "T-shirt", 2, 15.0);
    printf("%-10s %4d %8.2f\n", "Cap", 1, 12.5);
    printf("%-10s %4d %8.2f\n", "Socks", 3, 4.99);

    // %% writes a percent sign.
    printf("Discount: %d%%\n", 15);
    // %x shows hexadecimal, %e scientific notation.
    printf("255 in hex: %x, big number: %e\n", 255, 123456.0);
    return 0;
}
