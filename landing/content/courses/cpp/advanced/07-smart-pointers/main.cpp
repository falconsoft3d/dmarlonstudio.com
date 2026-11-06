#include <iostream>
#include <memory>
#include <string>
#include <vector>

struct Song {
    std::string title;
    explicit Song(std::string t) : title(t) {}
    ~Song() { std::cout << "  (freed " << title << ")\n"; }
};

int main() {
    // unique_ptr: a single owner that frees the object when it goes away.
    std::unique_ptr<Song> demo = std::make_unique<Song>("Demo take");
    std::cout << "Unique: " << demo->title << "\n";
    std::unique_ptr<Song> keeper = std::move(demo);    // ownership moves; it cannot be copied
    std::cout << "demo is " << (demo ? "full" : "empty") << " now\n";
    keeper.reset();                                     // freed right here

    // shared_ptr: several owners and a count of them.
    auto hit = std::make_shared<Song>("Summer Nights");
    std::vector<std::shared_ptr<Song>> rock, party;
    rock.push_back(hit);
    party.push_back(hit);
    std::cout << "Owners of " << hit->title << ": " << hit.use_count() << "\n";
    rock.clear();
    hit.reset();
    std::cout << "Left in party: " << party[0]->title << " (owners: " << party[0].use_count() << ")\n";
    std::cout << "End of main\n";
}   // party is destroyed: its last owner frees the song
