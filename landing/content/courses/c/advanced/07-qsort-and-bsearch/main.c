#include <stdio.h>
#include <stdlib.h>

typedef struct { int code; const char *name; double price; } Product;

// Comparators get two const void * and return <0, 0 or >0.
int by_price(const void *a, const void *b) {
    double x = ((const Product *)a)->price, y = ((const Product *)b)->price;
    return (x > y) - (x < y);  // no subtraction: it could overflow or truncate
}
int by_code(const void *a, const void *b) {
    int x = ((const Product *)a)->code, y = ((const Product *)b)->code;
    return (x > y) - (x < y);
}

int main(void) {
    Product shelf[] = {{3051, "Olive oil", 8.95}, {1007, "Bread", 1.20}, {2210, "Cheese", 6.40},
                       {1530, "Milk", 0.99}, {4100, "Coffee", 4.75}};
    size_t n = sizeof shelf / sizeof shelf[0];
    qsort(shelf, n, sizeof shelf[0], by_price);
    printf("By price:\n");
    for (size_t i = 0; i < n; i++)
        printf("  %4d %-10s %5.2f\n", shelf[i].code, shelf[i].name, shelf[i].price);
    // bsearch needs the array sorted by the same key it searches for.
    qsort(shelf, n, sizeof shelf[0], by_code);
    printf("By code: first %d, last %d\n", shelf[0].code, shelf[n - 1].code);
    int wanted[] = {2210, 9999};
    for (int w = 0; w < 2; w++) {
        Product key = {wanted[w], NULL, 0};
        Product *hit = bsearch(&key, shelf, n, sizeof shelf[0], by_code);
        printf("Code %d: %s\n", wanted[w], hit ? hit->name : "not found");
    }
    return 0;
}
