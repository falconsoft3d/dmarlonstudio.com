#include <stdio.h>
#include <stdlib.h>
#define N 6

int col[N], solutions = 0;  // col[r]: the column of the queen in row r

// Can a queen go at (row, c) without attacking the rows above?
int safe(int row, int c) {
    for (int r = 0; r < row; r++)
        if (col[r] == c || abs(col[r] - c) == row - r) return 0;  // column or diagonal
    return 1;
}

void place(int row) {
    if (row == N) {                       // all rows filled: a solution
        if (++solutions == 1)             // draw only the first one
            for (int r = 0; r < N; r++) {
                for (int c = 0; c < N; c++) printf(c == col[r] ? " Q" : " .");
                printf("\n");
            }
        return;
    }
    for (int c = 0; c < N; c++)
        if (safe(row, c)) {
            col[row] = c;                 // try this column...
            place(row + 1);               // ...solve the rest recursively...
        }                                 // ...and backtrack: the loop tries the next one
}

int main(void) {
    place(0);
    printf("%d queens on a %dx%d board: %d solutions\n", N, N, N, solutions);
    return 0;
}
