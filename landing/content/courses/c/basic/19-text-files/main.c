#include <stdio.h>

int main(void) {
    // "w" creates the file in the current folder (or empties it).
    FILE *out = fopen("scores.txt", "w");
    if (out == NULL) {
        printf("Cannot create scores.txt\n");
        return 1;
    }
    fprintf(out, "Ana 87\n");  // like printf, but into the file
    fprintf(out, "Luis 92\n");
    fprintf(out, "Marta 78\n");
    fclose(out);               // closing saves everything

    // "a" appends at the end without deleting what was there.
    out = fopen("scores.txt", "a");
    if (out == NULL) return 1;
    fprintf(out, "Pablo 95\n");
    fclose(out);

    // "r" opens it for reading; fscanf reads like scanf.
    FILE *in = fopen("scores.txt", "r");
    if (in == NULL) return 1;
    char name[20];
    int score, count = 0, total = 0;
    while (fscanf(in, "%19s %d", name, &score) == 2) {
        printf("%-6s %3d\n", name, score);
        count++;
        total += score;
    }
    fclose(in);
    printf("%d players, average %.1f\n", count, (double)total / count);
    return 0;
}
