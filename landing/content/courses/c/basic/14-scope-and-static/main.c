#include <stdio.h>

int total_visits = 0;  // global: every function below can use it

void visit(const char page[]) {
    static int calls = 0;  // static: keeps its value between calls
    int local = 0;         // a normal local starts again on every call
    calls++;
    local++;
    total_visits++;
    printf("%-5s calls=%d local=%d\n", page, calls, local);
}

int next_ticket(void) {
    static int number = 100;  // set to 100 only the first time
    return ++number;          // add 1, then give the new value
}

int main(void) {
    visit("home");
    visit("shop");
    visit("cart");
    printf("Total visits: %d\n", total_visits);

    for (int i = 0; i < 3; i++) printf("Ticket %d\n", next_ticket());

    int lives = 3;
    {   // a block has its own scope: this lives hides the outer one
        int lives = 99;
        printf("inside the block: lives = %d\n", lives);
    }
    printf("outside the block: lives = %d\n", lives);
    return 0;
}
