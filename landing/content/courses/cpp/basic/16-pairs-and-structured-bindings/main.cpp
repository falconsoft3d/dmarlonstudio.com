#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <vector>

// A function can return two results inside a pair.
std::pair<int, int> minMax(const std::vector<int>& values) {
    int lo = values[0], hi = values[0];
    for (int v : values) {
        if (v < lo) lo = v;
        if (v > hi) hi = v;
    }
    return {lo, hi};
}

int main() {
    // A pair holds two values, which may have different types.
    std::pair<std::string, double> product = {"Headphones", 59.99};
    std::cout << product.first << " cost " << product.second << " euros\n";

    auto city = std::make_pair("Valencia", 26);  // make_pair deduces the types
    std::cout << city.first << ": " << city.second << " C\n";

    // Structured bindings give a name to each part.
    std::vector<int> week = {19, 24, 17, 28, 22};
    auto [coldest, hottest] = minMax(week);
    std::cout << "This week: from " << coldest << " to " << hottest << " C\n";

    // They are very handy to go through a map.
    std::map<std::string, int> goals = {{"Lola", 7}, {"Iker", 12}, {"Sara", 9}};
    for (const auto& [player, count] : goals) std::cout << player << " scored " << count << '\n';
    return 0;
}
