#include <iostream>
#include <utility>
#include <vector>

class Image {                 // owns a raw buffer, so it needs the rule of five
    int size_;
    int* pixels_;
public:
    explicit Image(int size) : size_(size), pixels_(new int[size]()) {}
    ~Image() { delete[] pixels_; }                                          // 1 destructor
    Image(const Image& o) : size_(o.size_), pixels_(new int[o.size_]) {     // 2 copy: deep
        for (int i = 0; i < size_; ++i) pixels_[i] = o.pixels_[i];
        std::cout << "copy " << size_ << " pixels\n";
    }
    Image(Image&& o) noexcept : size_(o.size_), pixels_(o.pixels_) {       // 3 move: steal
        o.size_ = 0; o.pixels_ = nullptr; std::cout << "move, no copy\n";
    }
    Image& operator=(Image o) noexcept {      // 4 and 5: copy and move assignment
        std::swap(size_, o.size_); std::swap(pixels_, o.pixels_); return *this;
    }
    int size() const { return size_; }
};

int main() {
    Image photo(1920 * 1080);
    Image backup = photo;                  // copy constructor
    Image thumb = std::move(photo);        // move constructor: photo is left empty
    std::cout << "photo " << photo.size() << ", backup " << backup.size() << ", thumb " << thumb.size() << "\n";
    std::vector<Image> album; album.reserve(2);
    album.push_back(Image(640 * 480));     // a temporary is moved, not copied
    album.push_back(std::move(backup));
    backup = thumb;                        // copy assignment: o is a copy of thumb
    std::cout << "album " << album.size() << ", backup " << backup.size() << "\n";
}
