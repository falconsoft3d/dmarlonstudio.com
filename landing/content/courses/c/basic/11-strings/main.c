#include <stdio.h>
#include <string.h>

int main(void) {
    // A string is a char array that ends with the character '\0'.
    char city[20] = "Madrid";
    printf("%s has %zu letters\n", city, strlen(city));
    printf("The array has room for %zu chars\n", sizeof(city));
    printf("First: %c, last: %c\n", city[0], city[strlen(city) - 1]);

    // = cannot copy an array: strcpy copies the text.
    char copy[20];
    strcpy(copy, city);
    copy[0] = 'm';
    printf("Original: %s, copy: %s\n", city, copy);

    // strcat adds text at the end (there must be room for it).
    char greeting[40] = "Hello from ";
    strcat(greeting, city);
    printf("%s\n", greeting);

    // strcmp gives 0 if equal, <0 or >0 for alphabetical order.
    char a[] = "pear", b[] = "apple";
    if (strcmp(a, b) == 0) printf("Same fruit\n");
    else if (strcmp(a, b) < 0) printf("%s comes before %s\n", a, b);
    else printf("%s comes before %s\n", b, a);

    // Walk the string until '\0', counting the letter 'o'.
    int found = 0;
    for (int i = 0; greeting[i] != '\0'; i++)
        if (greeting[i] == 'o') found++;
    printf("'%s' has the letter o %d times\n", greeting, found);
    return 0;
}
