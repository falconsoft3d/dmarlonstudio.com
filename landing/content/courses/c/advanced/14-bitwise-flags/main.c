#include <stdio.h>

// One bit per permission: 1, 2, 4, 8...
enum { READ = 1 << 0, WRITE = 1 << 1, DELETE = 1 << 2, ADMIN = 1 << 3 };

void show(const char *who, unsigned perms) {
    printf("%-6s ", who);
    for (int bit = 3; bit >= 0; bit--) putchar(perms >> bit & 1 ? '1' : '0');  // binary
    printf(" %s%s%s%s\n", perms & READ ? " read" : "", perms & WRITE ? " write" : "",
           perms & DELETE ? " delete" : "", perms & ADMIN ? " admin" : "");
}

int main(void) {
    unsigned ana = READ | WRITE;  // | turns bits on
    show("Ana", ana);
    ana |= DELETE;               // add one permission
    show("Ana", ana);
    ana &= ~WRITE;               // & with ~ turns one bit off
    show("Ana", ana);
    ana ^= ADMIN;                // ^ toggles: on now, off if repeated
    show("Ana", ana);

    unsigned guest = READ;
    printf("Guest can write? %s\n", (guest & WRITE) ? "yes" : "no");
    printf("Common to both: %u\n", ana & guest);

    int bits = 0;
    for (unsigned v = ana; v; v &= v - 1) bits++;  // clears the lowest 1 each time
    printf("Ana has %d permissions; 5 << 2 = %d, 40 >> 3 = %d\n", bits, 5 << 2, 40 >> 3);
    return 0;
}
