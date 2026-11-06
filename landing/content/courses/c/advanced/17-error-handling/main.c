#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Return codes: the function reports what happened; the result goes in *out.
typedef enum { OK, ERR_EMPTY, ERR_NOT_NUMBER, ERR_RANGE } Status;
const char *status_text(Status s) {
    static const char *texts[] = {"ok", "empty text", "not a whole number", "out of range"};
    return texts[s];
}
Status parse_quantity(const char *text, long *out) {
    if (*text == '\0') return ERR_EMPTY;
    char *end;
    errno = 0;                         // strtol only sets errno when it fails
    long value = strtol(text, &end, 10);
    if (end == text || *end != '\0') return ERR_NOT_NUMBER;  // "12kg": end points at k
    if (errno == ERANGE || value < 1 || value > 500) return ERR_RANGE;
    *out = value;
    return OK;
}

int main(void) {
    const char *inputs[] = {"25", "", "12kg", "abc", "99999999999999999999", "0"};
    for (int i = 0; i < 6; i++) {
        long qty = 0;
        Status st = parse_quantity(inputs[i], &qty);
        printf("%-22s %s (%ld)\n", *inputs[i] ? inputs[i] : "(empty)", status_text(st), qty);
    }
    FILE *f = fopen("missing-orders.csv", "r");  // the standard library uses errno
    if (f == NULL) printf("Cannot open missing-orders.csv: %s\n", strerror(errno));
    else fclose(f);
    return EXIT_SUCCESS;
}
