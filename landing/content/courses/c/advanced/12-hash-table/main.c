#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define BUCKETS 5

typedef struct Entry { const char *key; double price; struct Entry *next; } Entry;  // one list per bucket
unsigned long hash(const char *s) {  // djb2: the same text, always the same number
    unsigned long h = 5381;
    while (*s) h = h * 33 + (unsigned char)*s++;
    return h % BUCKETS;               // and % turns it into a bucket
}
unsigned long put(Entry *table[], const char *key, double price) {
    unsigned long b = hash(key);
    Entry *e = malloc(sizeof *e);
    if (!e) exit(EXIT_FAILURE);
    e->key = key; e->price = price; e->next = table[b]; table[b] = e;
    return b;
}
Entry *get(Entry *table[], const char *key) {  // only one bucket is searched
    for (Entry *e = table[hash(key)]; e; e = e->next)
        if (strcmp(e->key, key) == 0) return e;
    return NULL;
}
int main(void) {
    Entry *table[BUCKETS] = {NULL};
    const char *drinks[] = {"coffee", "tea", "juice", "water", "cola", "milk"};
    for (int i = 0; i < 6; i++)
        printf("%-7s -> bucket %lu\n", drinks[i], put(table, drinks[i], 1.10 + i * 0.35));
    Entry *cola = get(table, "cola");
    printf("cola costs %.2f, soup is %s\n", cola->price, get(table, "soup") ? "found" : "missing");
    for (int b = 0; b < BUCKETS; b++)  // free every list
        for (Entry *e = table[b], *next; e; e = next) { next = e->next; free(e); }
    return 0;
}
