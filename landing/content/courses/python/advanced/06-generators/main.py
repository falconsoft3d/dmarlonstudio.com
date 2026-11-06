LOG = """2026-03-01 10:02 GET /shop 200
2026-03-01 10:03 GET /cart 200
2026-03-01 10:05 POST /pay 500
2026-03-01 10:06 GET /shop 404
2026-03-01 10:09 POST /pay 200
2026-03-01 10:12 GET /admin 500"""

def read_lines(text):                 # yields one line at a time
    for line in text.splitlines():
        yield line

def errors(lines):                    # consumes another generator
    for line in lines:
        date, time, method, path, status = line.split()
        if int(status) >= 400:
            yield f"{time} {path} -> {status}"

pipeline = errors(read_lines(LOG))    # nothing has run yet
print(type(pipeline).__name__)
print("First:", next(pipeline))       # runs until the first yield
for item in pipeline:                 # continues where it stopped
    print("Next: ", item)

# Generator expression: like a comprehension, with ()
total_500 = sum(1 for line in read_lines(LOG) if line.endswith("500"))
print("Server errors:", total_500)

def invoice_numbers(start):
    while True:                       # infinite, but lazy
        yield f"INV-{start}"
        start += 1

numbers = invoice_numbers(2040)
print([next(numbers) for _ in range(3)])
