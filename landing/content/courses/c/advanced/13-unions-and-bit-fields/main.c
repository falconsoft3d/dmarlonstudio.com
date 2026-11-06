#include <stdint.h>
#include <stdio.h>

// A tagged union: the enum says which member of the union is in use.
typedef enum { INT, REAL, TEXT } Kind;
typedef struct {
    const char *name;
    Kind kind;
    union { int i; double d; const char *s; } value;  // all share the same bytes
} Setting;

// Bit fields: a date packed into 21 bits of one unsigned int.
typedef struct { unsigned day : 5, month : 4, year : 12; } Date;

void show(const Setting *s) {
    switch (s->kind) {
    case INT:  printf("%-9s = %d\n", s->name, s->value.i); break;
    case REAL: printf("%-9s = %.2f\n", s->name, s->value.d); break;
    case TEXT: printf("%-9s = \"%s\"\n", s->name, s->value.s); break;
    }
}

int main(void) {
    Setting config[] = {{"port", INT, {.i = 8080}}, {"timeout", REAL, {.d = 2.5}},
                        {"language", TEXT, {.s = "es"}}};
    for (int k = 0; k < 3; k++) show(&config[k]);
    printf("sizeof union: %zu (its biggest member)\n", sizeof config[0].value);

    Date release = {.day = 14, .month = 3, .year = 2026};
    printf("Date %02u/%02u/%u in %zu bytes\n", release.day, release.month, release.year, sizeof release);
    union { float f; uint32_t bits; } pun = {.f = 1.0f};  // read the bytes of a float
    printf("1.0f is stored as 0x%08X\n", (unsigned)pun.bits);
    return 0;
}
