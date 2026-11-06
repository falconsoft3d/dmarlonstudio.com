# Saving for a bike: add money every week until you have enough.
goal = 100
savings = 0
week = 0

while savings < goal:
    week += 1       # the same as week = week + 1
    savings += 22
    print(f"Week {week}: {savings} euros saved")

print(f"Goal reached in {week} weeks!")
print(f"Change left over: {savings - goal} euros")

# A countdown: the loop stops when the condition becomes false.
count = 3
while count > 0:
    print(count, "...")
    count -= 1
print("Lift-off!")
