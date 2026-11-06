#include <stdarg.h>
#include <stdio.h>

// The first argument says how many numbers follow.
double average(int count, ...) {
    va_list args;
    va_start(args, count);         // start after the last named parameter
    double sum = 0;
    for (int i = 0; i < count; i++)
        sum += va_arg(args, double);  // floats arrive as double
    va_end(args);                  // always pair va_start with va_end
    return count ? sum / count : 0;
}

// A printf-like logger: the format string says what the extra arguments are.
void log_msg(const char *level, const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("[%-5s] ", level);
    vprintf(format, args);         // the v... versions take a va_list
    printf("\n");
    va_end(args);
}

int main(void) {
    printf("Average of 3: %.2f\n", average(3, 7.5, 9.0, 6.0));
    printf("Average of 5: %.2f\n", average(5, 4.0, 8.0, 15.0, 16.0, 23.0));
    printf("Average of 0: %.2f\n", average(0));
    log_msg("INFO", "Server started on port %d", 8080);
    log_msg("WARN", "Disk %s is %d%% full", "/data", 91);
    log_msg("ERROR", "Order %s: %d items, total %.2f", "A-104", 3, 59.85);
    return 0;
}
