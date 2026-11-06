#include <functional>
#include <iostream>
#include <map>
#include <string>
#include <vector>

// A small event system: each event name keeps a list of callbacks.
class EventBus {
    using Handler = std::function<void(const std::string&)>;    // any callable with this signature
    std::map<std::string, std::vector<Handler>> handlers_;
public:
    void on(const std::string& event, Handler h) { handlers_[event].push_back(h); }
    void emit(const std::string& event, const std::string& data) {
        std::cout << "emit " << event << "\n";
        for (const Handler& h : handlers_[event]) h(data);
    }
};

void writeLog(const std::string& data) { std::cout << "  [log] " << data << "\n"; }
struct Cart {
    int items = 0;
    void add(const std::string& p) { std::cout << "  [cart] " << p << ", " << ++items << " item(s)\n"; }
};

int main() {
    EventBus bus; Cart cart; int clicks = 0;
    bus.on("click", [&clicks](const std::string& button) { std::cout << "  [ui] click " << ++clicks << ": " << button << "\n"; });
    bus.on("click", writeLog);                                  // a plain function fits too
    bus.on("add", [&cart](const std::string& p) { cart.add(p); });   // calls a method
    bus.emit("click", "Buy now");
    bus.emit("add", "Headphones");
    bus.emit("add", "Charger");
    bus.emit("close", "nobody listens");                        // no handlers: nothing runs
}
