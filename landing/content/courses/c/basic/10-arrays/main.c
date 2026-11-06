#include <stdio.h>

int main(void) {
    // An array keeps several values of the same type, one after another.
    double temps[7] = {18.5, 21.0, 19.5, 24.0, 26.5, 22.0, 17.5};
    char days[7] = {'M', 'T', 'W', 'T', 'F', 'S', 'S'};
    int count = sizeof(temps) / sizeof(temps[0]);  // 7 elements

    // Positions start at 0: temps[0] is the first, temps[6] the last.
    printf("First: %.1f, last: %.1f\n", temps[0], temps[count - 1]);
    temps[2] = 20.0;  // change one element

    double sum = 0, max = temps[0];
    int hottest = 0;
    for (int i = 0; i < count; i++) {
        printf("%c %5.1f\n", days[i], temps[i]);
        sum += temps[i];
        if (temps[i] > max) {
            max = temps[i];
            hottest = i;
        }
    }
    printf("Average: %.2f\n", sum / count);
    printf("Hottest: day %d (%c), %.1f degrees\n", hottest + 1, days[hottest], max);

    // Elements without a value start at 0.
    int votes[4] = {3, 5};
    votes[3] += 2;
    for (int i = 0; i < 4; i++) printf("Option %d: %d votes\n", i + 1, votes[i]);
    return 0;
}
