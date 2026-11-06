#include <iostream>

int main() {
    // while repeats the block as long as the condition is true.
    int savings = 0, months = 0;
    while (savings < 500) {
        savings += 120;
        months++;
    }
    std::cout << "Goal reached in " << months << " months: " << savings << " euros\n";

    // A countdown: seconds-- uses the value, then subtracts one.
    int seconds = 5;
    while (seconds > 0) std::cout << seconds-- << "... ";
    std::cout << "Lift off!\n";

    // do-while runs the block once before checking the condition.
    int energy = 0;
    do {
        std::cout << "The player gets one turn (energy " << energy << ")\n";
    } while (energy > 0);

    // break leaves the loop; continue jumps to the next round.
    int n = 0;
    while (true) {
        n++;
        if (n % 3 == 0) continue;  // skip multiples of 3
        if (n > 10) break;
        std::cout << n << ' ';
    }
    std::cout << '\n';
    return 0;
}
