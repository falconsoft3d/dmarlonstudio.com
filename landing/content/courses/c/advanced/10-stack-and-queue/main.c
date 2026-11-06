#include <stdio.h>
#include <string.h>
#define CAP 16  // room in the stack and in the queue
int balanced(const char *text) {
    char stack[CAP]; int top = 0;  // a stack (LIFO): last in, first out
    for (; *text; text++) {
        const char *closer = strchr(")]}", *text);
        if (strchr("([{", *text)) {
            if (top == CAP) return 0;  // too deep for our stack
            stack[top++] = *text;      // push
        } else if (closer && (top == 0 || stack[--top] != "([{"[closer - ")]}"]))
            return 0;                  // pop: it must be the matching opener
    }
    return top == 0;  // nothing left open
}

typedef struct { const char *items[CAP]; int head, count; } Queue;  // FIFO ring buffer
void enqueue(Queue *q, const char *job) { q->items[(q->head + q->count++) % CAP] = job; }
const char *dequeue(Queue *q) {  // head moves forward and wraps around
    const char *job = q->items[q->head];
    q->head = (q->head + 1) % CAP; q->count--;
    return job;
}

int main(void) {
    const char *exprs[] = {"(a[i] + b) * {c}", "f(x[0)]", "((total)"};
    for (int i = 0; i < 3; i++)
        printf("%-18s %s\n", exprs[i], balanced(exprs[i]) ? "balanced" : "NOT balanced");
    Queue printer = {.head = 0, .count = 0};
    enqueue(&printer, "invoice.pdf"); enqueue(&printer, "photo.png");
    printf("Printing %s\n", dequeue(&printer)); enqueue(&printer, "report.docx");
    while (printer.count > 0) printf("Printing %s\n", dequeue(&printer));
    return 0;
}
