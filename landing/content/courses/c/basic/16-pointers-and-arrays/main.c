#include <stdio.h>

// An array parameter is really a pointer, so pass the length too.
double average(const double *values, int count) {
    double sum = 0;
    for (int i = 0; i < count; i++) sum += values[i];
    return sum / count;
}

// Through the pointer, the function changes the original array.
void add_bonus(int *marks, int count, int bonus) {
    for (int i = 0; i < count; i++) marks[i] += bonus;
}

int main(void) {
    int marks[] = {6, 8, 5, 9, 7};
    int n = sizeof(marks) / sizeof(marks[0]);

    int *p = marks;  // the array name is the address of marks[0]
    printf("*p = %d, *(p + 1) = %d, p[2] = %d\n", *p, *(p + 1), p[2]);

    // p + 1 moves one element forward, not one byte.
    for (int *q = marks; q < marks + n; q++) printf("%d ", *q);
    printf("<- marks\n");

    add_bonus(marks, n, 1);
    for (int i = 0; i < n; i++) printf("%d ", marks[i]);
    printf("<- after the bonus\n");

    double temps[] = {12.5, 15.0, 9.5};
    printf("Average temperature: %.2f\n", average(temps, 3));
    return 0;
}
