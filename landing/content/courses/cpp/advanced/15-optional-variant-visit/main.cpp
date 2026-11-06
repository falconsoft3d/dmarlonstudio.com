#include <iostream>
#include <map>
#include <optional>
#include <string>
#include <variant>
#include <vector>

// optional: a value that may be missing, with no magic numbers such as -1.
std::optional<int> findPort(const std::map<std::string, int>& config, const std::string& service) {
    auto it = config.find(service);
    if (it == config.end()) return std::nullopt;
    return it->second;
}

using Cell = std::variant<int, double, std::string>;   // a spreadsheet cell: one of these

struct CellPrinter {                 // a visitor: one operator() per type
    void operator()(int n) const { std::cout << "int    " << n << "\n"; }
    void operator()(double d) const { std::cout << "double " << d << "\n"; }
    void operator()(const std::string& s) const { std::cout << "text   \"" << s << "\"\n"; }
};

int main() {
    std::map<std::string, int> config = {{"http", 8080}, {"db", 5432}};
    for (std::string service : {"db", "mail"}) {
        std::optional<int> port = findPort(config, service);
        if (port) std::cout << service << " port: " << *port << "\n";
        else std::cout << service << " port: not set, default " << port.value_or(25) << "\n";
    }
    std::vector<Cell> row = {42, 3.75, std::string("Total"), 7};
    for (const Cell& c : row) std::visit(CellPrinter{}, c);
    std::cout << "Cell 1 is a double? " << (std::holds_alternative<double>(row[1]) ? "yes" : "no")
              << ", cell 2 says " << std::get<std::string>(row[2]) << "\n";
}
