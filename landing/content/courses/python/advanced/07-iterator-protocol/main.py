class Paginator:
    """Iterates over a list of results, one page at a time."""

    def __init__(self, items, page_size):
        self.items = items
        self.page_size = page_size
        self.start = 0

    def __iter__(self):
        return self                   # this object is its own iterator

    def __next__(self):
        if self.start >= len(self.items):
            raise StopIteration       # tells for that there is no more
        page = self.items[self.start:self.start + self.page_size]
        self.start += self.page_size
        return page

orders = [f"#{n}" for n in range(1001, 1011)]

# What a for loop does behind the scenes: iter() and next()
it = iter(["ok", "fail"])
print(next(it), next(it))
try:
    next(it)
except StopIteration:
    print("StopIteration: the list is used up")

for number, page in enumerate(Paginator(orders, 4), start=1):
    print(f"Page {number}: {page}")

# Any function that loops accepts our iterator
print("Pages:", len(list(Paginator(orders, 3))))
