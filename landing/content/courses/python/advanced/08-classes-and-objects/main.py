class Player:
    """A player in a small role-playing game."""
    max_health = 100                  # class attribute: shared by all

    def __init__(self, name, attack):
        self.name = name              # instance attributes: one per object
        self.attack = attack
        self.health = Player.max_health
        self.inventory = []

    def hit(self, other):
        other.health = max(0, other.health - self.attack)
        print(f"{self.name} hits {other.name}: {other.health} HP left")

    def pick_up(self, item):
        self.inventory.append(item)

    @property
    def alive(self):                  # used like an attribute, no ()
        return self.health > 0

    def __str__(self):
        return f"{self.name} ({self.health}/{self.max_health} HP)"

hero = Player("Aria", attack=35)
orc = Player("Grok", attack=20)
hero.pick_up("potion")
while orc.alive:
    hero.hit(orc)
print(hero, "| inventory:", hero.inventory)
print(orc, "| alive:", orc.alive)
print("Same class:", type(hero) is type(orc), "| same object:", hero is orc)
