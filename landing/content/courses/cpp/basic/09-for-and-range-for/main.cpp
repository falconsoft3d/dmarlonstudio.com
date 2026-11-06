#include <iostream>
#include <string>

int main() {
    // for (start; condition; step): the classic counting loop.
    for (int i = 1; i <= 5; i++) {
        std::cout << "7 x " << i << " = " << 7 * i << '\n';
    }

    // Adding up inside a loop, in steps of 2.
    int sum = 0;
    for (int n = 2; n <= 100; n += 2) sum += n;
    std::cout << "2 + 4 + ... + 100 = " << sum << '\n';

    // Range-based for: goes through every element of a collection.
    double temps[] = {18.5, 21.0, 24.5, 19.0};
    double total = 0;
    for (double t : temps) total += t;
    std::cout << "Average temperature: " << total / 4 << '\n';

    // A string is a collection of characters.
    int vowels = 0;
    for (char c : std::string("programming"))
        if (c == 'a' || c == 'e' || c == 'i' || c == 'o' || c == 'u') vowels++;
    std::cout << "Vowels in \"programming\": " << vowels << '\n';

    // Nested loops: a small multiplication grid.
    for (int row = 1; row <= 3; row++) {
        for (int col = 1; col <= 4; col++) std::cout << row * col << '\t';
        std::cout << '\n';
    }
    return 0;
}
