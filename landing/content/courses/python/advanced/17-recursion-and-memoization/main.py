project = {                               # folders are dicts, files are KB
    "README.md": 4,
    "src": {"main.py": 12, "utils": {"dates.py": 3, "money.py": 5}},
    "docs": {"manual.pdf": 820, "img": {"logo.png": 64}},
}

def size(item):
    if not isinstance(item, dict):        # base case: a plain file
        return item
    return sum(size(child) for child in item.values())   # calls itself

def show(folder, depth=0):
    for name, item in folder.items():
        print("  " * depth + f"{name} ({size(item)} KB)")
        if isinstance(item, dict):
            show(item, depth + 1)         # one level deeper

memo = {}

def ways_to_pay(amount, coins):           # amount in cents
    if amount == 0:
        return 1
    if amount < 0 or not coins:
        return 0
    key = (amount, coins)
    if key not in memo:                   # work out each case only once
        use_it = ways_to_pay(amount - coins[0], coins)   # pay one coins[0]
        skip_it = ways_to_pay(amount, coins[1:])         # never use it
        memo[key] = use_it + skip_it
    return memo[key]

show(project)
print("Ways to pay 1 EUR:", ways_to_pay(100, (50, 20, 10, 5, 2, 1)))
print("Cases remembered:", len(memo))
