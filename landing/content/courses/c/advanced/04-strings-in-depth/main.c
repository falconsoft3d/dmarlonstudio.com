#include <stdio.h>
#include <string.h>

int main(void) {
    // strtok splits a line into fields. It writes '\0' over each separator,
    // so it needs a modifiable array, never a string literal.
    char line[] = "Ana Lopez;Madrid;34;Engineer";
    int i = 0;
    for (char *field = strtok(line, ";"); field; field = strtok(NULL, ";"))
        printf("Field %d: %s\n", i++, field);
    printf("line is now just \"%s\"\n", line);

    // snprintf never writes past the buffer and returns the length it needed.
    const char *names[] = {"Ana", "Maximiliano Fernandez"};
    for (int k = 0; k < 2; k++) {
        char badge[16];
        int needed = snprintf(badge, sizeof badge, "Hi, %s!", names[k]);
        printf("Badge \"%s\" needed %d chars: %s\n", badge, needed,
               needed < (int)sizeof badge ? "fits" : "truncated");
    }

    // strncpy does not add '\0' when the source is too long: add it yourself.
    const char *flight = "IB3170-MAD-BCN";
    char code[7];
    strncpy(code, flight, sizeof code - 1);
    code[sizeof code - 1] = '\0';
    printf("Flight code: %s (%zu chars)\n", code, strlen(code));

    // strchr and strstr search inside a string and return a pointer.
    const char *dash = strchr(flight, '-');
    printf("Route: %s, has MAD: %s\n", dash + 1, strstr(flight, "MAD") ? "yes" : "no");
    return 0;
}
