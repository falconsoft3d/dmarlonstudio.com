#include <iostream>
#include <iterator>
#include <list>
#include <string>
#include <vector>

int main() {
    // An iterator points to an element: *it reads it and ++it moves to the next.
    std::vector<std::string> route = {"Madrid", "Zaragoza", "Lleida", "Barcelona"};
    for (auto it = route.begin(); it != route.end(); ++it)
        std::cout << *it << (std::next(it) != route.end() ? " -> " : "\n");

    // Reverse iterators walk backwards: the trip home.
    for (auto it = route.rbegin(); it != route.rend(); ++it)
        std::cout << *it << (std::next(it) != route.rend() ? " -> " : "\n");

    // Vector iterators allow arithmetic; distance counts the steps.
    auto stop = route.begin() + 2;
    std::cout << "Third stop: " << *stop << ", " << std::distance(route.begin(), stop)
              << " steps from the start, " << stop->size() << " letters\n";

    // In a list, erasing and inserting through an iterator is cheap.
    std::list<std::string> playlist = {"Intro", "Ad", "Song A", "Ad", "Song B"};
    for (auto it = playlist.begin(); it != playlist.end();) {
        if (*it == "Ad") it = playlist.erase(it);      // erase returns the next one
        else ++it;
    }
    playlist.insert(std::next(playlist.begin()), "Jingle");   // before the 2nd track
    for (auto it = playlist.cbegin(); it != playlist.cend(); ++it)   // const: read only
        std::cout << "[" << *it << "]";
    std::cout << "\n";
}
