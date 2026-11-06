#include <iostream>
#include <string>
#include <vector>

// One template, many types: the compiler deduces T from the arguments.
template <typename T>
T largest(const std::vector<T>& items) {
    T best = items[0];
    for (const T& x : items)
        if (best < x) best = x;       // the only thing T needs: operator<
    return best;
}

template <typename T>
T clampTo(T value, T low, T high) { return value < low ? low : (high < value ? high : value); }

// Any type with operator< works, including our own.
struct Version {
    int major, minor;
    bool operator<(const Version& o) const { return major != o.major ? major < o.major : minor < o.minor; }
};

int main() {
    std::cout << "Highest score: " << largest(std::vector<int>{12, 47, 33}) << "\n";
    std::cout << "Last word: " << largest(std::vector<std::string>{"pear", "apple", "zucchini"}) << "\n";
    Version v = largest(std::vector<Version>{{1, 4}, {2, 0}, {1, 12}});
    std::cout << "Latest version: " << v.major << "." << v.minor << "\n";
    std::cout << "Volume: " << clampTo(130, 0, 100) << "\n";
    std::cout << "Heating: " << clampTo(3.5, 5.0, 30.0) << "\n";
    // clampTo(7, 0.5, 6.5) fails: T cannot be int and double. Say it explicitly:
    std::cout << "Explicit T: " << clampTo<double>(7, 0.5, 6.5) << "\n";
}
