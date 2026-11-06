#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int students = 10;  // known only at run time in a real program

    // malloc: room for 10 ints. Its contents are garbage until we write them.
    int *marks = malloc(students * sizeof *marks);
    if (marks == NULL) {
        fprintf(stderr, "Out of memory\n");
        return 1;
    }
    for (int i = 0; i < students; i++)
        marks[i] = (i * 7 + 3) % 6 + 5;  // marks from 5 to 10

    // calloc: room for 11 counters, all set to zero. Ideal for counting.
    int *count = calloc(11, sizeof *count);
    if (count == NULL) { free(marks); return 1; }
    for (int i = 0; i < students; i++) count[marks[i]]++;

    printf("Marks:");
    for (int i = 0; i < students; i++) printf(" %d", marks[i]);
    printf("\n");
    for (int m = 5; m <= 10; m++) {
        printf("%2d | ", m);
        for (int k = 0; k < count[m]; k++) printf("*");
        printf(" %d\n", count[m]);
    }

    free(count);  // every malloc or calloc needs exactly one free
    free(marks);
    marks = NULL;  // a freed pointer must not be used again
    return 0;
}
