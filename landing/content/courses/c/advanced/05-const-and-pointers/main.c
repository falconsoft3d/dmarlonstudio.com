#include <ctype.h>
#include <stdio.h>

typedef struct { const char *title; double price; int stock; } Book;

// const Book *: the function promises to only read the book.
void show(const Book *b) {
    printf("%-15s %6.2f  stock %2d\n", b->title, b->price, b->stock);
    // b->stock = 0;  // error: assignment to a read-only location
}

void sell(Book *b, int units) { b->stock -= units; }  // Book *: may change it

int count_upper(const char *s) {
    int n = 0;
    for (; *s; s++)  // s itself moves; what it points to is read-only
        if (isupper((unsigned char)*s)) n++;
    return n;
}

int main(void) {
    Book book = {"The C Language", 39.90, 12};
    show(&book);
    sell(&book, 3);
    show(&book);
    char city[] = "madrid";
    const char *shop = "Libros DMarlon";  // pointer to const: can move, can't write
    char *const first = city;             // const pointer: can write, can't move
    first[0] = 'M';                       // first = shop; would not compile
    const double vat = 0.04;
    const double *const rate = &vat;      // neither the pointer nor the value
    printf("%s (%d capitals) in %s, VAT %.0f%%\n", shop, count_upper(shop), city, *rate * 100);
    return 0;
}
