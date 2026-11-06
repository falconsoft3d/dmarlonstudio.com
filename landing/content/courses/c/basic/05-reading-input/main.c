#include <stdio.h>

int main(void) {
    char name[30];   // room for a word of up to 29 letters
    int age;
    double price;
    int adults, children;

    // %s reads one word. Text needs no &.
    printf("What is your name? ");
    scanf("%29s", name);
    printf("Nice to meet you, %s!\n", name);

    // For numbers, &age tells scanf where to store the value.
    printf("How old are you? ");
    scanf("%d", &age);
    printf("In 10 years you will be %d.\n", age + 10);

    // %lf reads a double (printf writes it with just %f).
    printf("Price of a cinema ticket? ");
    scanf("%lf", &price);
    printf("One ticket: %.2f euros.\n", price);

    // Two numbers on one line; scanf returns how many it read.
    printf("Adult and child tickets? ");
    int read = scanf("%d %d", &adults, &children);
    printf("(scanf read %d numbers)\n", read);

    // Children pay half price.
    double total = price * adults + price / 2 * children;
    printf("%d tickets cost %.2f euros.\n", adults + children, total);
    return 0;
}
