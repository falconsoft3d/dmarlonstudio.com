#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { char *name; int *scores; int count; } Player;

// A heap copy of a string (strdup is not part of standard C11).
char *copy_text(const char *s) {
    char *copy = malloc(strlen(s) + 1);  // +1 for the final '\0'
    return copy ? strcpy(copy, s) : NULL;
}

int main(void) {
    const char *names[] = {"Lucia", "Hugo", "Martina"};
    int n = 3;
    Player *team = malloc(n * sizeof *team);  // an array of structs on the heap
    if (!team) return 1;
    for (int i = 0; i < n; i++) {
        team[i].name = copy_text(names[i]);
        team[i].count = i + 2;                // each player has a different size
        team[i].scores = malloc(team[i].count * sizeof(int));
        if (!team[i].name || !team[i].scores) exit(EXIT_FAILURE);
        for (int k = 0; k < team[i].count; k++) team[i].scores[k] = 10 + (i * 5 + k * 3) % 9;
    }
    for (Player *p = team; p < team + n; p++) {  // p->name is (*p).name
        int total = 0;
        printf("%-8s", p->name);
        for (int k = 0; k < p->count; k++) { printf(" %2d", p->scores[k]); total += p->scores[k]; }
        printf("  | total %d\n", total);
    }
    for (int i = 0; i < n; i++) { free(team[i].name); free(team[i].scores); }
    free(team);  // inside out: first what each struct owns, then the array
    return 0;
}
