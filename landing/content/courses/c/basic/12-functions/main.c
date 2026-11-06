#include <stdio.h>

// A function groups code under a name. void: it gives nothing back.
void print_line(void) {
    printf("------------------------\n");
}

// This one receives a value: how many stars to draw.
void print_stars(int count) {
    for (int i = 0; i < count; i++) printf("*");
    printf("\n");
}

// This one gives a value back with return.
double celsius_to_fahrenheit(double celsius) {
    return celsius * 9 / 5 + 32;
}

int main(void) {
    print_line();
    printf("Hotel reviews\n");
    print_line();
    printf("Sea View   "); print_stars(5);
    printf("City Inn   "); print_stars(3);
    printf("Old Mill   "); print_stars(4);
    print_line();

    // The result can be used like any other value.
    printf("25 C is %.1f F\n", celsius_to_fahrenheit(25));
    double cold = celsius_to_fahrenheit(-5);
    printf("-5 C is %.1f F\n", cold);
    return 0;
}
