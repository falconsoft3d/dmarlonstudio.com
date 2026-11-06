#include <stdio.h>

int main(void) {
    // int: whole numbers
    int apples = 12;
    int pears = 7;
    // double: numbers with decimals
    double price = 1.35;
    // char: a single character, between single quotes
    char grade = 'A';

    printf("Apples: %d\n", apples);
    printf("Pears: %d\n", pears);
    printf("Price per kilo: %f\n", price);
    printf("Quality grade: %c\n", grade);

    // A variable can change its value.
    apples = apples - 3;
    printf("Apples after selling 3: %d\n", apples);

    // A new variable can be calculated from others.
    int total = apples + pears;
    printf("Pieces of fruit: %d\n", total);

    // const: a value that cannot change.
    const double vat = 0.21;
    printf("Price with VAT: %f\n", price + price * vat);

    // sizeof tells how many bytes each type uses.
    printf("int: %zu bytes, double: %zu, char: %zu\n",
           sizeof(int), sizeof(double), sizeof(char));
    return 0;
}
