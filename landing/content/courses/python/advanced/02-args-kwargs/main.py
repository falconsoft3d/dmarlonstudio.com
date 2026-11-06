def invoice_total(*amounts, discount=0.0, tax=0.21):
    """Any number of amounts; discount and tax are keyword-only."""
    net = sum(amounts) * (1 - discount)
    return round(net * (1 + tax), 2)


def log_event(event, **details):
    """Extra named arguments arrive in a dict."""
    fields = ", ".join(f"{key}={value}" for key, value in details.items())
    print(f"[{event}] {fields}")


def ship(order_id, *, express=False):
    """The bare * makes express keyword-only."""
    speed = "express" if express else "standard"
    print(f"Order {order_id} ships by {speed} delivery")


print("Total:", invoice_total(100, 50, 25))
print("With 10% off:", invoice_total(100, 50, 25, discount=0.1))
print("Reduced tax:", invoice_total(80, tax=0.10))

prices = [19.99, 5.01, 75.0]
print("From a list:", invoice_total(*prices))  # unpack a list into *amounts

log_event("login", user="ana", ip="10.0.0.7")
extra = {"order": 1042, "status": "shipped"}
log_event("update", **extra)       # unpack a dict into **details

ship(1042, express=True)
try:
    ship(1043, True)               # positional: not allowed
except TypeError as error:
    print("Error:", error)
