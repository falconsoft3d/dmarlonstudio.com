import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Spinbox")
root.geometry("420x280")

quantity = tk.StringVar(value="3")
size = tk.StringVar(value="M")
price = tk.StringVar(value="12.50")
total = ttk.Label(root, font=("Helvetica", 15), foreground="#1d4ed8")

def update(*args):
    q, p = quantity.get(), price.get()
    ok = q.isdigit() and p.replace(".", "", 1).isdigit()
    total.config(text=f"{q} × size {size.get()} = ${int(q) * float(p):.2f}"
                 if ok else "Type a valid number")

def spinbox(label, **options):
    ttk.Label(root, text=label).pack(anchor="w", padx=40, pady=(12, 2))
    ttk.Spinbox(root, width=10, **options).pack(anchor="w", padx=40)

# Numbers: from_, to and increment (the step of each arrow click).
spinbox("Quantity (1 to 20)", from_=1, to=20, increment=1, textvariable=quantity)
# A fixed list of values; wrap=True goes back to the first after the last.
spinbox("Size", values=("XS", "S", "M", "L", "XL"), wrap=True,
        state="readonly", textvariable=size)
spinbox("Price", from_=0, to=50, increment=0.25, format="%.2f", textvariable=price)

total.pack(anchor="w", padx=40, pady=18)
for var in (quantity, size, price):
    var.trace_add("write", update)
update()
root.mainloop()
