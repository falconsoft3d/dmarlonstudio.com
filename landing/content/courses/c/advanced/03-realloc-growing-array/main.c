#include <stdio.h>
#include <stdlib.h>

// A growing array: the data, how many are used and how many fit.
typedef struct { double *data; size_t len, cap; } Readings;

int push(Readings *r, double value) {
    if (r->len == r->cap) {
        size_t new_cap = r->cap ? r->cap * 2 : 2;
        // realloc into a temporary: if it fails, the old block is still ours.
        double *bigger = realloc(r->data, new_cap * sizeof *bigger);
        if (bigger == NULL) return 0;
        printf("  grow: %zu -> %zu\n", r->cap, new_cap);
        r->data = bigger;
        r->cap = new_cap;
    }
    r->data[r->len++] = value;
    return 1;
}

int main(void) {
    Readings temps = {NULL, 0, 0};  // realloc(NULL, n) works like malloc(n)
    double sensor[] = {18.5, 19.0, 20.25, 21.0, 22.5, 21.75, 20.0, 19.5, 18.0};
    for (size_t i = 0; i < sizeof sensor / sizeof sensor[0]; i++)
        if (!push(&temps, sensor[i])) { free(temps.data); return 1; }

    double sum = 0;
    for (size_t i = 0; i < temps.len; i++) sum += temps.data[i];
    printf("%zu readings, capacity %zu, average %.2f\n",
           temps.len, temps.cap, sum / temps.len);

    free(temps.data);
    return 0;
}
