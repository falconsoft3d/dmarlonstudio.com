#include <stdio.h>

int main(void) {
    // for (start; condition; step): everything about the counter in one line.
    for (int i = 1; i <= 5; i++) {
        printf("%d x 7 = %d\n", i, i * 7);
    }

    // Counting down in steps of 2.
    for (int n = 10; n > 0; n -= 2) printf("%d ", n);
    printf("\n");

    // Adding up: a bakery sells 20 loaves plus 3 more each day.
    int total = 0;
    for (int day = 1; day <= 7; day++) {
        total += 20 + 3 * day;
    }
    printf("Loaves sold this week: %d\n", total);

    // continue jumps to the next turn; break leaves the loop.
    for (int seat = 1; seat <= 20; seat++) {
        if (seat % 4 == 0) continue;  // every fourth seat is broken
        if (seat > 10) break;         // only the first row is open
        printf("seat %d ", seat);
    }
    printf("\n");

    // A loop inside a loop: rows and columns of a cinema.
    for (int row = 0; row < 3; row++) {
        for (int col = 1; col <= 5; col++) printf("%c%d ", 'A' + row, col);
        printf("\n");
    }
    return 0;
}
