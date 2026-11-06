#include <deque>
#include <iostream>
#include <set>
#include <string>
#include <unordered_map>

int main() {
    // std::set: unique values, always kept in order.
    std::set<std::string> tags;
    for (const char* t : {"cpp", "linux", "fltk", "cpp", "gui", "linux"}) tags.insert(t);
    std::cout << tags.size() << " tags:";
    for (const auto& t : tags) std::cout << " " << t;
    std::cout << "\nHas 'gui'? " << (tags.count("gui") ? "yes" : "no") << "\n";

    // std::unordered_map: a hash table. Fast look-ups, but no order.
    std::unordered_map<std::string, int> visits;
    for (const char* page : {"/home", "/download", "/home", "/courses", "/home", "/download"})
        ++visits[page];                                   // a missing key starts at 0
    for (const char* page : {"/home", "/download", "/courses", "/blog"}) {
        auto it = visits.find(page);                      // find does not add keys
        std::cout << page << ": " << (it != visits.end() ? it->second : 0) << "\n";
    }

    // std::deque: fast to add and remove at both ends.
    std::deque<std::string> jobs = {"invoice.pdf", "report.pdf"};
    jobs.push_back("photo.png");
    jobs.push_front("URGENT.pdf");                        // jumps the queue
    while (!jobs.empty()) {
        std::cout << "Printing " << jobs.front() << "\n";
        jobs.pop_front();
    }
}
