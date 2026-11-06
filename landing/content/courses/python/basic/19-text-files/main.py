players = [("Ana", 120), ("Ben", 95), ("Carla", 140)]

# "w" creates the file (or empties it) to write in it.
with open("scores.txt", "w") as file:
    for name, points in players:
        file.write(f"{name},{points}\n")

# "a" adds at the end without deleting what was there.
with open("scores.txt", "a") as file:
    file.write("Dani,110\n")

# read() gives the whole file as one string.
with open("scores.txt") as file:
    print(file.read(), end="")

# Line by line, to turn the text back into data.
best_name, best_points = "", 0
with open("scores.txt") as file:
    for line in file:
        name, points = line.strip().split(",")
        if int(points) > best_points:
            best_name, best_points = name, int(points)
print(f"Best player: {best_name} with {best_points} points")

# Opening a file that does not exist raises an error.
try:
    with open("missing.txt") as file:
        print(file.read())
except FileNotFoundError:
    print("missing.txt does not exist yet")
