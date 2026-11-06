# Grade report: files, strings, lists, dicts, functions and errors.
def grade(mark):
    if mark >= 9:
        return "A"
    if mark >= 7:
        return "B"
    if mark >= 5:
        return "C"
    return "F"

with open("marks.txt", "w") as file:
    file.write("Ana: 8, 9.5, 7\nBen: 4, 6, five\nCarla: 9, 10, 9.5\nDani: 3, 5, 4\n")
averages = {}
with open("marks.txt") as file:
    for line in file:
        name, text = line.split(":")
        marks = []
        for part in text.split(","):
            try:
                marks.append(float(part))
            except ValueError:
                print(f"{name}: '{part.strip()}' is not a mark, skipped")
        averages[name] = sum(marks) / len(marks)

print(f"{'Student':<8}{'Avg':>6}  Grade")
passed, best_name, best = [], "", 0
for name, avg in averages.items():
    print(f"{name:<8}{avg:>6.2f}  {grade(avg)}")
    if avg >= 5:
        passed.append(name)
    if avg > best:
        best_name, best = name, avg
print("Passed:", ", ".join(passed))
print(f"Best average: {best_name} ({best:.2f})")
