#include <iostream>
#include <string>
#include <vector>

int main() {
    // A vector is a list that knows its size and can grow.
    std::vector<std::string> players = {"Ana", "Luis", "Marta"};
    std::vector<int> scores = {120, 95, 140};
    std::cout << "Players: " << players.size() << '\n';
    std::cout << "First: " << players[0] << ", last: " << players.back() << '\n';

    scores[1] = 110;  // [] also changes an element; positions start at 0

    // A for with an index, to use two vectors at the same time.
    for (std::size_t i = 0; i < players.size(); i++)
        std::cout << players[i] << ": " << scores[i] << " points\n";

    // push_back adds an element at the end.
    players.push_back("Pablo");
    scores.push_back(130);

    // A range-based for reads every value.
    int total = 0;
    for (int s : scores) total += s;
    std::cout << "Total: " << total << ", average: " << total / static_cast<double>(scores.size()) << '\n';

    // at() checks that the position exists; [] does not.
    std::cout << "Fourth player: " << players.at(3) << '\n';

    // A vector of 4 elements, all of them 3.
    std::vector<int> lives(4, 3);
    std::cout << "Lives of player 2: " << lives[1] << " (" << lives.size() << " players)\n";
    return 0;
}
