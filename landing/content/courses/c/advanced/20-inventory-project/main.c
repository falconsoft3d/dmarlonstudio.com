#include <stdio.h>
#include <stdlib.h>
typedef struct Item { char name[20]; int qty; double price; struct Item *next; } Item;
Item *add(Item *head, const char *name, int qty, double price) {  // a new node in front
    Item *it = malloc(sizeof *it);
    if (!it) exit(EXIT_FAILURE);
    snprintf(it->name, sizeof it->name, "%s", name);
    it->qty = qty; it->price = price; it->next = head;
    return it;
}
void free_all(Item *it) { while (it) { Item *next = it->next; free(it); it = next; } }
Item *load(const char *path) {  // reads the file into a new list; NULL if it cannot
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    Item *head = NULL; char name[20]; int qty; double price;
    while (fscanf(f, " %19[^;];%d;%lf", name, &qty, &price) == 3) head = add(head, name, qty, price);
    fclose(f);
    return head;
}

int main(void) {
    Item *stock = add(add(add(NULL, "Screws x100", 40, 4.25), "Drill", 3, 59.00), "Hammer", 12, 9.90);
    FILE *f = fopen("inventory.csv", "w");
    if (!f) { free_all(stock); return 1; }
    for (const Item *it = stock; it; it = it->next) fprintf(f, "%s;%d;%.2f\n", it->name, it->qty, it->price);
    fclose(f); free_all(stock);  // now the data lives only in the file
    stock = load("inventory.csv");
    double total = 0;
    for (const Item *it = stock; it; total += it->qty * it->price, it = it->next)
        printf("%-12s %3d x %6.2f%s\n", it->name, it->qty, it->price, it->qty < 5 ? "  REORDER" : "");
    printf("Stock value: %.2f\n", total);
    free_all(stock); remove("inventory.csv");
    return 0;
}
