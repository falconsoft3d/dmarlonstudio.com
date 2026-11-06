#include <stdio.h>

// A struct groups related data under one name.
struct Product {
    char name[20];
    double price;
    int stock;
};

void show(struct Product p) {  // gets a copy: enough to read it
    printf("%-10s %6.2f  stock %2d\n", p.name, p.price, p.stock);
}

// A pointer lets the function change the struct; -> reaches its fields.
void sell(struct Product *p, int units) {
    if (units > p->stock) units = p->stock;
    p->stock -= units;
    printf("Sold %d x %s\n", units, p->name);
}

int main(void) {
    struct Product mug = {"Mug", 7.50, 12};
    struct Product lamp = {.name = "Lamp", .price = 24.90, .stock = 3};

    mug.price = 6.95;  // the dot reaches each field
    show(mug);
    show(lamp);

    sell(&mug, 5);
    sell(&lamp, 4);  // only 3 left
    show(mug);
    show(lamp);
    return 0;
}
