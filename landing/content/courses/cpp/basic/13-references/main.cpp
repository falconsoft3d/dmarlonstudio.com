#include <iostream>
#include <vector>

// By value: the function gets a copy, so the original does not change.
void addBonusCopy(int points) { points += 50; std::cout << "Inside the copy:     " << points << '\n'; }

// By reference (&): the function works on the original variable.
void addBonus(int& points) { points += 50; }

// const reference: no copy and no changes. Ideal for strings and vectors.
double total(const std::vector<double>& prices) {
    double sum = 0;
    for (double p : prices) sum += p;
    return sum;
}

int main() {
    int score = 100;
    addBonusCopy(score);
    std::cout << "After the copy:      " << score << '\n';
    addBonus(score);
    std::cout << "After the reference: " << score << '\n';

    int& alias = score;  // a reference: another name for the same variable
    alias = 0;
    std::cout << "alias = 0, so score is now " << score << '\n';

    // In a for, & changes each element in place: a 10% discount.
    std::vector<double> basket = {20.0, 12.5, 7.5};
    for (double& p : basket) p *= 0.9;
    for (const double& p : basket) std::cout << p << ' ';
    std::cout << "\nTotal after discount: " << total(basket) << '\n';
    return 0;
}
