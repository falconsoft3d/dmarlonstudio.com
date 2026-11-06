#include <stdio.h>

// With a pointer, a function can change the caller's variable.
void add_points(int *score, int points) {
    *score += points;
}

void swap(int *a, int *b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

int main(void) {
    int score = 50;
    int *p = &score;  // & gives the address; p stores it

    // The address changes from run to run, so we only compare it.
    printf("p points to score: %s\n", p == &score ? "yes" : "no");
    printf("score = %d, *p = %d\n", score, *p);

    *p = 75;  // * follows the address and changes the value there
    printf("after *p = 75, score = %d\n", score);

    add_points(&score, 25);
    printf("after add_points, score = %d\n", score);

    int gold = 3, silver = 8;
    swap(&gold, &silver);
    printf("after swap: gold = %d, silver = %d\n", gold, silver);
    int *nowhere = NULL;  // NULL: points to nothing, check before use
    if (nowhere == NULL) printf("nowhere is NULL\n");
    return 0;
}
