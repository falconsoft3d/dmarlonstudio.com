#include <stdio.h>

// Include guard: normally the whole body of a header file such as shop.h.
#ifndef SHOP_H                // first time: SHOP_H is not defined yet
#define SHOP_H
struct item { const char *name; double price; };
#endif
#ifndef SHOP_H                // shop.h included again: now it is skipped,
struct item { const char *name; double price; };  // or this would be an error
#endif

#define VAT_RATE 0.21         // replaced by its text before compiling
#define SQUARE_BAD(x) x * x   // no parentheses: a classic bug
#define SQUARE(x) ((x) * (x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define SHOW(expr) printf("%-17s = %g\n", #expr, (double)(expr))  // # makes text
#define FIELD(name) item_##name                                    // ## glues tokens
#define DEBUG 1

int main(void) {
    struct item tea = {"Green tea", 4.50};
    printf("%s with VAT: %.2f\n", tea.name, tea.price * (1 + VAT_RATE));
    SHOW(SQUARE_BAD(1 + 2));  // becomes 1 + 2 * 1 + 2
    SHOW(SQUARE(1 + 2));
    SHOW(MAX(7, 12));
    int FIELD(stock) = 40;    // declares item_stock
    printf("item_stock = %d\n", item_stock);
#if DEBUG
    printf("[debug] %s, line %d, C standard %ld\n", __FILE__, __LINE__, __STDC_VERSION__);
#else
    printf("Release build\n");
#endif
    return 0;
}
