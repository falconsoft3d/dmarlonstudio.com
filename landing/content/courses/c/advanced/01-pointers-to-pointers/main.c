#include <stdio.h>
#include <string.h>

// Receives the address of a pointer and makes it point at the cheapest price.
void find_cheapest(double *prices, int n, double **cheapest) {
    *cheapest = prices;
    for (double *p = prices + 1; p < prices + n; p++)
        if (*p < **cheapest) *cheapest = p;
}

int main(void) {
    double prices[] = {4.50, 3.20, 5.10, 2.95, 3.80};
    int n = sizeof prices / sizeof prices[0];

    // Pointer arithmetic: p + 2 moves two elements, not two bytes.
    double *p = prices;
    printf("First: %.2f, third: %.2f\n", *p, *(p + 2));
    printf("Bytes from p to p + 1: %td\n", (char *)(p + 1) - (char *)p);
    printf("Elements from start to end: %td\n", (prices + n) - p);

    double *cheapest = NULL;
    find_cheapest(prices, n, &cheapest);
    printf("Cheapest: %.2f at index %td\n", *cheapest, cheapest - prices);

    // A list of strings is an array of pointers: char ** walks through it.
    const char *shops[] = {"Bakery", "Market", "Kiosk", NULL};
    for (const char **s = shops; *s != NULL; s++)
        printf("Shop %td: %-7s first letter %c, %zu letters\n",
               s - shops, *s, **s, strlen(*s));

    const char **second = shops + 1;
    printf("Through **: %s starts with %c\n", *second, **second);
    return 0;
}
