# A shopping list that grows and shrinks.
shopping = ["milk", "bread", "eggs"]

shopping.append("apples")       # add at the end
shopping.insert(0, "coffee")    # add at a position
print("After adding:", shopping)

shopping.remove("bread")        # remove by value
last = shopping.pop()           # remove the last one and return it
print("Removed:", last)
print("Now:", shopping)

# sort() puts the list in order (it changes the list itself).
scores = [72, 95, 58, 88, 64]
scores.sort()
print("Sorted:", scores)
scores.sort(reverse=True)
print("Best first:", scores)

# Slicing: list[start:stop] takes a part (stop is not included).
print("Top 3:", scores[:3])
print("The rest:", scores[3:])
print("Middle:", scores[1:4])
print("Backwards:", scores[::-1])
print("Position of 88:", scores.index(88))
