#include <stdio.h>

int main(void) {
    int pizzas = 7, people = 3;

    // + - * / work as in maths...
    printf("Slices: %d\n", pizzas * 8);
    // ...but int / int drops the decimals.
    printf("Pizzas each: %d\n", pizzas / people);
    // % gives the remainder of the division.
    printf("Pizzas left over: %d\n", pizzas % people);

    // With a double in the division, the decimals stay.
    double share = (double)pizzas / people;
    printf("Exact share: %f\n", share);

    // Careful: the cast must come before the division.
    double too_late = (double)(pizzas / people);
    printf("Cast too late: %f\n", too_late);

    // Turning a double into an int cuts off the decimals.
    double bill = 47.85;
    int euros = (int)bill;
    int cents = (int)(bill * 100 + 0.5) % 100;
    printf("Bill: %d euros and %d cents\n", euros, cents);

    // Shortcuts that change a variable.
    int score = 10;
    score += 5;   // score = score + 5
    score *= 2;   // score = score * 2
    score++;      // add 1
    printf("Score: %d\n", score);
    return 0;
}
