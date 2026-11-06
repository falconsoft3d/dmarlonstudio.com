#include <iostream>
#include <string>

int main() {
    std::string name;
    std::cout << "What is your name? ";
    // getline reads the whole line, spaces included.
    std::getline(std::cin, name);
    std::cout << "\nHello, " << name << "!\n";

    int tickets;
    double price;
    std::cout << "How many tickets? ";
    // >> reads one word and converts it to the type of the variable.
    std::cin >> tickets;
    std::cout << "\nPrice per ticket? ";
    std::cin >> price;
    std::cout << "\n" << tickets << " tickets cost " << tickets * price << " euros\n";

    // After >>, the Enter key is still waiting: std::ws skips it.
    std::string film;
    std::cout << "Which film? ";
    std::getline(std::cin >> std::ws, film);
    std::cout << "\nEnjoy " << film << ", " << name << "!\n";

    // Several values on one line: >> skips the spaces between them.
    int row, seat;
    std::cout << "Row and seat? ";
    std::cin >> row >> seat;
    std::cout << "\nYour seat: row " << row << ", seat " << seat << '\n';
    return 0;
}
