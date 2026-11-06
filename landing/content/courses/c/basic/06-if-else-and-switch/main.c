#include <stdio.h>

int main(void) {
    // if runs its block only when the condition is true.
    int temperature = 31;
    if (temperature > 30)  // one statement: braces are optional
        printf("%d degrees: it is hot, drink water.\n", temperature);

    // else if and else choose one path among several.
    int score = 68;
    if (score >= 90) {
        printf("Score %d: excellent\n", score);
    } else if (score >= 60) {
        printf("Score %d: passed\n", score);
    } else {
        printf("Score %d: try again\n", score);
    }

    // switch compares one whole value with fixed cases.
    int day = 6;
    switch (day) {
        case 1: case 2: case 3: case 4: case 5:
            printf("Day %d: the shop opens at 9:00\n", day);
            break;  // without break, the next case would run too
        case 6: case 7:
            printf("Day %d: weekend, the shop opens at 10:00\n", day);
            break;
        default:
            printf("Day %d does not exist\n", day);
    }
    return 0;
}
