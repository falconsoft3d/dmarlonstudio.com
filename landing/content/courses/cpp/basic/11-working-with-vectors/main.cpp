#include <algorithm>
#include <functional>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<std::string> list = {"milk", "bread", "eggs"};
    list.push_back("apples");                 // at the end
    list.insert(list.begin(), "coffee");      // at the start
    list.insert(list.begin() + 2, "butter");  // before position 2
    for (auto item : list) std::cout << item << ' ';
    std::cout << "(" << list.size() << " items)\n";

    // erase removes by position (here, the second item); pop_back, the last one.
    list.erase(list.begin() + 1);
    list.pop_back();

    // sort from <algorithm> puts a range in order: begin() to end().
    std::sort(list.begin(), list.end());
    for (auto item : list) std::cout << item << ' ';
    std::cout << "(" << list.size() << " items)\n";

    // Game scores: lowest, highest and a top list from high to low.
    std::vector<int> scores = {450, 120, 899, 75, 300};
    std::cout << "Lowest: " << *std::min_element(scores.begin(), scores.end())
              << ", highest: " << *std::max_element(scores.begin(), scores.end()) << '\n';
    std::sort(scores.begin(), scores.end(), std::greater<int>());
    for (int s : scores) std::cout << s << ' ';
    list.clear();
    std::cout << "\nList empty? " << std::boolalpha << list.empty() << '\n';
    return 0;
}
