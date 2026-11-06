#include <array>
#include <iostream>
#include <string>

// A class template: T is the element type, N a size fixed at compile time.
template <typename T, std::size_t N>
class RingBuffer {
    std::array<T, N> data_{};
    std::size_t next_ = 0, count_ = 0;
public:
    void push(const T& value) {                 // when full, overwrites the oldest
        data_[next_] = value;
        next_ = (next_ + 1) % N;
        if (count_ < N) ++count_;
    }
    std::size_t size() const { return count_; }
    const T& operator[](std::size_t i) const { return data_[(next_ + N - count_ + i) % N]; }   // 0 = oldest
    void show(const std::string& label) const {
        std::cout << label << " [" << count_ << "/" << N << "]:";
        for (std::size_t i = 0; i < count_; ++i) std::cout << " " << (*this)[i];
        std::cout << "\n";
    }
};

int main() {
    RingBuffer<double, 4> temps;                // the last 4 sensor readings
    for (double t : {18.5, 19.0, 21.2, 22.8, 23.1, 20.4}) temps.push(t);
    temps.show("Temperatures");
    RingBuffer<std::string, 3> recent;          // the last 3 files opened
    recent.push("main.cpp");
    recent.show("Recent files");
    for (auto f : {"shape.h", "README.md", "Makefile"}) recent.push(f);
    recent.show("Recent files");
}
