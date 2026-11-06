#include <stdio.h>

// enum names a set of whole numbers: RED is 0, YELLOW 1, GREEN 2.
enum Light { RED, YELLOW, GREEN };

// typedef gives a type a short name; values can be chosen.
typedef enum { SMALL = 1, MEDIUM, LARGE } Size;  // MEDIUM is 2

typedef struct { char name[12]; Size size; double price; } Coffee;

enum Light next(enum Light light) {
    switch (light) {
        case RED:    return GREEN;
        case GREEN:  return YELLOW;
        default:     return RED;
    }
}

int main(void) {
    const char *light_names[] = {"red", "yellow", "green"};
    enum Light light = RED;
    for (int i = 0; i < 4; i++) {
        printf("Light %d: %s\n", light, light_names[light]);
        light = next(light);
    }

    const char *size_names[] = {"", "small", "medium", "large"};
    Coffee orders[] = {{"Latte", MEDIUM, 2.10}, {"Espresso", SMALL, 1.40},
                       {"Mocha", LARGE, 2.60}};
    for (int i = 0; i < 3; i++)
        printf("%-9s %-7s %.2f\n", orders[i].name,
               size_names[orders[i].size], orders[i].price);
    return 0;
}
