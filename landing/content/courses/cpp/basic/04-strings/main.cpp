#include <iostream>
#include <string>

int main() {
    std::string first = "Grace";
    std::string last = "Hopper";
    // + joins strings; size() counts the characters.
    std::string full = first + " " + last;
    std::cout << full << " has " << full.size() << " characters\n";

    // [] reads one character by position (the first one is 0).
    std::cout << "Initials: " << first[0] << last[0] << '\n';

    // substr(start, length) copies a part; without length, up to the end.
    std::string code = "ES-2024-MAD";
    std::cout << "Country: " << code.substr(0, 2) << ", city: " << code.substr(8) << '\n';

    // find() returns the position, or std::string::npos if it is missing.
    std::cout << "The year starts at position " << code.find("2024") << '\n';
    std::cout << "BCN found? " << (code.find("BCN") != std::string::npos) << '\n';

    // A std::string can grow and be changed in place.
    std::string message = "Order";
    message += " shipped";
    message.replace(0, 5, "Parcel");
    std::cout << message << '\n';

    // Converting between text and numbers.
    int units = std::stoi("12");
    double price = std::stod("2.5");
    std::cout << "Units: " + std::to_string(units) << ", total: " << units * price << '\n';
    return 0;
}
