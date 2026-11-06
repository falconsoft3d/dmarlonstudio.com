from dataclasses import dataclass, field, asdict

@dataclass
class Line:
    product: str
    quantity: int
    unit_price: float

@dataclass
class Invoice:
    number: str
    customer: str
    lines: list[Line] = field(default_factory=list)   # a new list each time
    paid: bool = False

    def __post_init__(self):          # runs right after the generated __init__
        self.customer = self.customer.strip().title()

    def total(self):
        return sum(l.quantity * l.unit_price for l in self.lines)

@dataclass(frozen=True, order=True)  # immutable and comparable
class Version:
    major: int
    minor: int

inv = Invoice("F-2026-014", "  maria lopez ")
inv.lines.append(Line("Chair", 4, 49.5))
inv.lines.append(Line("Table", 1, 230.0))
print(inv.lines[0])                   # free __repr__
print(inv.customer, "owes", inv.total(), "| paid:", inv.paid)
print("Equal:", Line("Chair", 4, 49.5) == inv.lines[0])   # free __eq__
print(asdict(inv)["lines"][1])
print("Newest:", max(Version(1, 9), Version(1, 10), Version(0, 99)))
