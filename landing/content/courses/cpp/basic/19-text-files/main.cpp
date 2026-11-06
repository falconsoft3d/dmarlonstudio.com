#include <fstream>
#include <iostream>
#include <string>

int main() {
    // ofstream writes a file in the current folder (it creates or empties it).
    std::ofstream out("temperatures.txt");
    out << "Madrid 24.5\n" << "Bilbao 17.5\n" << "Sevilla 31.2\n";
    out.close();

    // std::ios::app adds at the end instead of starting again.
    std::ofstream more("temperatures.txt", std::ios::app);
    more << "Valencia 26.8\n";
    more.close();

    // ifstream reads it; always check that it could be opened.
    std::ifstream in("temperatures.txt");
    if (!in) { std::cout << "Could not open the file\n"; return 1; }

    // >> reads word by word, just like std::cin, until the end of the file.
    std::string city, hottestCity;
    double temp, hottest = -100;
    int count = 0;
    while (in >> city >> temp) {
        std::cout << city << ": " << temp << " C\n";
        if (temp > hottest) { hottest = temp; hottestCity = city; }
        count++;
    }
    std::cout << count << " cities, the hottest is " << hottestCity << " (" << hottest << " C)\n";
    return 0;
}
