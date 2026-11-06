#include <iostream>
#include <map>
#include <string>

int main() {
    // A map links keys to values, and keeps the keys in order.
    std::map<std::string, int> stock = {{"pears", 5}, {"apples", 12}, {"plums", 0}};
    std::cout << "Apples: " << stock["apples"] << '\n';

    // [] changes a value, or creates the key if it is new.
    stock["pears"] = 8;
    stock["kiwis"] = 20;

    // count() checks a key without creating it (0 or 1).
    if (stock.count("bananas") == 0) std::cout << "No bananas today\n";

    // erase() removes a key together with its value.
    stock.erase("plums");

    // Each element is a pair: first is the key and second, the value.
    int pieces = 0;
    for (const auto& item : stock) {
        std::cout << item.first << ": " << item.second << '\n';
        pieces += item.second;
    }
    std::cout << stock.size() << " fruits, " << pieces << " pieces\n";

    // Counting is a classic job: a missing key starts at 0.
    std::map<char, int> letters;
    for (char c : std::string("banana")) letters[c]++;
    for (const auto& item : letters) std::cout << item.first << '=' << item.second << ' ';
    std::cout << '\n';
    return 0;
}
