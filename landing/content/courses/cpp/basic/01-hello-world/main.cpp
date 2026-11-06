// iostream gives us std::cout, the console output.
#include <iostream>

// Every C++ program starts running in main().
int main() {
    std::cout << "Hello, world!" << std::endl;

    // << chains several pieces into one line.
    std::cout << "Welcome to " << "C++" << " in DMarlon Studio" << '\n';

    // Numbers are printed just like text.
    std::cout << "This course has " << 20 << " lessons." << '\n';
    std::cout << "2 + 3 = " << 2 + 3 << '\n';

    // \n starts a new line inside the text; \t inserts a tab.
    std::cout << "Line one\nLine two\n";
    std::cout << "Name:\tAda\n";

    // Returning 0 tells the system that everything went well.
    return 0;
}
