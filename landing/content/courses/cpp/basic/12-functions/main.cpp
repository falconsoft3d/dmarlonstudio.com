#include <iostream>
#include <string>
#include <vector>

// A function: return type, name, parameters and body.
double toFahrenheit(double celsius) { return celsius * 9 / 5 + 32; }

// void: it does something, but returns nothing.
void printLine(int width) {
    for (int i = 0; i < width; i++) std::cout << '-';
    std::cout << '\n';
}

// return ends the function as soon as it runs.
std::string describe(double celsius) {
    if (celsius < 10) return "cold";
    if (celsius < 25) return "mild";
    return "hot";
}

double average(std::vector<double> values) {
    double sum = 0;
    for (double v : values) sum += v;
    return values.empty() ? 0 : sum / values.size();
}

int main() {
    std::vector<double> week = {8.5, 14.0, 22.5, 27.0, 31.5};
    printLine(26);
    for (double c : week) std::cout << c << " C = " << toFahrenheit(c) << " F, " << describe(c) << '\n';
    printLine(26);
    std::cout << "Average: " << average(week) << " C, " << describe(average(week)) << '\n';
    return 0;
}
