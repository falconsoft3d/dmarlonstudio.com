#include <algorithm>
#include <iostream>
#include <memory>
#include <vector>

struct Shape {                     // the interface every shape on the canvas follows
    const char* name;
    explicit Shape(const char* n) : name(n) {}
    virtual ~Shape() = default;
    virtual double area() const = 0;
};
struct Circle : Shape {
    double r;
    Circle(const char* n, double r) : Shape(n), r(r) {}
    double area() const override { return 3.14159 * r * r; }
};
struct Rect : Shape {
    double w, h;
    Rect(const char* n, double w, double h) : Shape(n), w(w), h(h) {}
    double area() const override { return w * h; }
};

int main() {
    std::vector<std::unique_ptr<Shape>> canvas;      // the canvas owns its shapes
    canvas.push_back(std::make_unique<Rect>("banner", 6, 2.5));
    canvas.push_back(std::make_unique<Circle>("logo", 1.5));
    canvas.push_back(std::make_unique<Rect>("dot", 0.5, 0.4));
    canvas.push_back(std::make_unique<Rect>("button", 3, 1));
    canvas.erase(std::remove_if(canvas.begin(), canvas.end(), [](const auto& s) { return s->area() < 1; }), canvas.end());
    std::sort(canvas.begin(), canvas.end(), [](const auto& a, const auto& b) { return a->area() > b->area(); });
    double total = 0;
    for (const auto& s : canvas) { total += s->area(); std::cout << s->name << ": " << s->area() << "\n"; }
    std::cout << canvas.size() << " shapes, total area " << total << "\n";
}
