#include <array>
#include <iostream>
#include <type_traits>

// constexpr: the compiler can work it out while compiling, if the inputs are known.
constexpr unsigned long long mebibytes(unsigned long long n) { return n * 1024 * 1024; }
constexpr int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }
constexpr std::array<int, 10> makeSquares() {      // a table built at compile time
    std::array<int, 10> t{};
    for (int i = 0; i < 10; ++i) t[i] = i * i;
    return t;
}
constexpr auto squares = makeSquares();
constexpr int width = 1920, height = 1080;
constexpr unsigned long long cacheSize = mebibytes(64);
// static_assert: a check done by the compiler. If it fails, nothing compiles.
static_assert(width * 9 == height * 16, "the screen must be 16:9");
static_assert(cacheSize == 67108864, "64 MiB in bytes");
static_assert(squares[7] == 49 && sizeof(long long) >= 8);

template <typename T>
void describe(T value) {           // if constexpr: only the matching branch is compiled
    if constexpr (std::is_integral_v<T>) std::cout << value << " is a whole number\n";
    else std::cout << value << " is not a whole number\n";
}

int main() {
    constexpr int g = gcd(width, height);
    std::cout << "Aspect ratio " << width / g << ":" << height / g << ", cache " << cacheSize << " bytes\n";
    std::cout << "Square of 7 from the table: " << squares[7] << "\n";
    int n = 84;                    // known only at run time: the same function still works
    std::cout << "gcd(" << n << ", 36) = " << gcd(n, 36) << "\n";
    describe(42); describe(2.5);
}
