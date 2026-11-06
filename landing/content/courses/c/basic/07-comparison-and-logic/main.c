#include <stdio.h>

int main(void) {
    int age = 15;
    int has_ticket = 1;  // in C, 0 is false and any other number is true
    double height = 1.42;

    // A comparison gives 1 (true) or 0 (false).
    printf("age == 15: %d\n", age == 15);
    printf("age != 18: %d\n", age != 18);
    printf("age >= 18: %d\n", age >= 18);

    // && (and): both sides must be true.
    if (has_ticket && height >= 1.40) {
        printf("You can ride the roller coaster.\n");
    }
    // || (or): at least one side must be true.
    if (age < 12 || age >= 65) {
        printf("Reduced price.\n");
    } else {
        printf("Full price.\n");
    }
    // ! (not) turns true into false and false into true.
    if (!has_ticket) printf("Buy a ticket first.\n");
    // A range: from 13 to 17, both included.
    int teen = age >= 13 && age <= 17;
    // condition ? a : b picks a when true, b when false.
    printf("Teenager? %s\n", teen ? "yes" : "no");

    // Remember: = assigns a value, == compares two values.
    int lives = 0;
    if (lives == 0) printf("Game over.\n");
    return 0;
}
