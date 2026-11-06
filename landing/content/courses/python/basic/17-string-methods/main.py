# Ingredients typed in a hurry: spaces and capitals all over.
raw = "   tomato, Onion ,garlic,  PEPPER  "

# strip() removes the spaces at both ends.
clean = raw.strip()
print(f"[{clean}]")

# split() cuts a string into a list, at each comma.
parts = clean.split(",")
print(parts)

# Tidy each piece: no spaces and in lower case.
items = []
for part in parts:
    items.append(part.strip().lower())
print(items)

# join() glues a list into one string.
print(" | ".join(items))

title = "salsa verde recipe"
print(title.upper())
print(title.title())
print(title.replace("verde", "roja"))
print("Starts with 'salsa'?", title.startswith("salsa"))
print("How many 'e':", title.count("e"))
print("Where is 'recipe'?", title.find("recipe"))
