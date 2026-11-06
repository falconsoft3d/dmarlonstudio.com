#include <stdio.h>

int main(void) {
    // while repeats its block as long as the condition is true.
    double coffee = 90.0;
    int minute = 0;
    while (coffee > 60.0) {
        minute++;
        coffee *= 0.9;  // it loses 10% of its heat every minute
        printf("Minute %d: %.1f degrees\n", minute, coffee);
    }
    printf("Ready to drink after %d minutes.\n", minute);

    // A countdown.
    int seconds = 5;
    while (seconds > 0) {
        printf("%d... ", seconds);
        seconds--;
    }
    printf("Lift-off!\n");

    // do-while checks at the end, so the block runs at least once.
    // Counting digits: even 0 has one digit.
    int number = 2026, digits = 0;
    do {
        digits++;
        number /= 10;
    } while (number > 0);
    printf("2026 has %d digits.\n", digits);
    return 0;
}
