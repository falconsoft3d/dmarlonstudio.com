# A set keeps each value only once. It uses { } or set().
visits = ["ana", "ben", "ana", "carla", "ben", "ana"]
people = set(visits)
print("Visits:", len(visits), "| Different people:", len(people))

# A set has no order: sorted() gives a sorted list to print.
print("Who came:", sorted(people))

# Two clubs at school: who is in each one?
chess = {"ana", "ben", "carla", "dani"}
football = {"ben", "dani", "eva", "fran"}

print("Both clubs:", sorted(chess & football))
print("Any club:", sorted(chess | football))
print("Only chess:", sorted(chess - football))
print("Just one club:", sorted(chess ^ football))

# add() and discard() change the set.
football.add("ana")
football.add("ben")         # already there: nothing changes
football.discard("fran")
print("Football now:", sorted(football))
print("Is eva in chess?", "eva" in chess)
