// stdio.h brings printf, which writes text on the screen.
#include <stdio.h>

// Every C program starts running in main.
int main(void) {
    printf("Hello, world!\n");
    printf("Welcome to the C course.\n");

    // \n starts a new line; without it, the text carries on.
    printf("One, ");
    printf("two, ");
    printf("three!\n");

    // \t inserts a tab, handy for simple columns.
    printf("Day\tWeather\n");
    printf("Mon\tSunny\n");
    printf("Tue\tRainy\n");

    // \" writes quotes inside the text.
    printf("She said \"C is fast\".\n");

    return 0;  // 0 tells the system that all went well
}
