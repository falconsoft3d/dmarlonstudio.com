#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

struct Task { std::string title; int priority; double hours; };

int main() {
    std::vector<Task> tasks = {{"Fix login", 3, 2.5}, {"Write docs", 1, 4}, {"Release", 5, 1}, {"Review PR", 3, 0.5}};

    // A lambda is a function written in place: [captures](parameters) { body }.
    auto byPriority = [](const Task& a, const Task& b) { return a.priority > b.priority; };
    std::stable_sort(tasks.begin(), tasks.end(), byPriority);

    // [budget] copies the variable; [&planned] works on the original.
    double budget = 4.0, planned = 0;
    auto fits = [budget, &planned](const Task& t) {
        if (planned + t.hours > budget) return false;
        planned += t.hours;
        return true;
    };
    for (const Task& t : tasks)
        std::cout << (fits(t) ? "[today] " : "[later] ") << t.title << " (p" << t.priority << ")\n";
    std::cout << "Planned: " << planned << " of " << budget << " hours\n";

    // mutable lets a lambda change its own copy of a captured value.
    int ticket = 100;
    auto nextTicket = [ticket]() mutable { return ++ticket; };
    int a = nextTicket(), b = nextTicket();
    std::cout << "Tickets " << a << " and " << b << ", but ticket is still " << ticket << "\n";

    auto twice = [](auto x) { return x + x; };     // generic lambda: auto parameter
    std::cout << twice(21) << " " << twice(std::string("ha")) << "\n";
}
