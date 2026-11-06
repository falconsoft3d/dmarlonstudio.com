#include <stdio.h>
#include <stdlib.h>

typedef struct Task { int id; const char *title; struct Task *next; } Task;
// A new node on the heap, linked in front of `next` (NULL: the end).
Task *new_task(int id, const char *title, Task *next) {
    Task *t = malloc(sizeof *t);
    if (!t) exit(EXIT_FAILURE);
    t->id = id; t->title = title; t->next = next;
    return t;
}
// Task **link points at the pointer we may change: head or some ->next.
void append(Task **link, Task *t) {
    while (*link) link = &(*link)->next;
    *link = t;
}
void remove_id(Task **link, int id) {
    while (*link && (*link)->id != id) link = &(*link)->next;
    if (*link) { Task *gone = *link; *link = gone->next; free(gone); }
}
void print(const char *label, const Task *t) {
    for (printf("%-9s", label); t; t = t->next) printf(" [%d %s]", t->id, t->title);
    printf("\n");
}

int main(void) {
    Task *todo = NULL;  // an empty list
    append(&todo, new_task(1, "Invoice", NULL)); append(&todo, new_task(2, "Call Ana", NULL));
    append(&todo, new_task(3, "Backup", NULL));  print("Start:", todo);
    remove_id(&todo, 2);                         print("Done 2:", todo);
    todo = new_task(4, "Server", todo);          print("Urgent:", todo);
    while (todo) { Task *next = todo->next; free(todo); todo = next; }  // free all
    return 0;
}
