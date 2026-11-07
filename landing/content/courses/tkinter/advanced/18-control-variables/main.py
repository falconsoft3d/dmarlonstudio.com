import tkinter as tk
from tkinter import ttk

PRICES = {"Coffee": 1.80, "Tea": 1.50, "Sandwich": 4.50, "Salad": 6.90}

root = tk.Tk()
root.title("Order")
root.geometry("420x240")
root.configure(padx=24, pady=20)

# Control variables: one value shared by every widget that uses it.
product, quantity = tk.StringVar(value="Sandwich"), tk.IntVar(value=3)
member, total = tk.BooleanVar(value=True), tk.StringVar()

ttk.Label(root, text="Product:").grid(row=0, column=0, sticky="w", pady=6)
ttk.Combobox(root, textvariable=product, values=list(PRICES), state="readonly").grid(row=0, column=1)
ttk.Label(root, text="Quantity:").grid(row=1, column=0, sticky="w", pady=6)
ttk.Spinbox(root, textvariable=quantity, from_=1, to=20, width=6).grid(row=1, column=1, sticky="w")
ttk.Checkbutton(root, text="Member (10% off)", variable=member).grid(row=2, column=1, sticky="w", pady=6)
ttk.Label(root, textvariable=total, font=("Helvetica", 22, "bold")).grid(row=3, column=0, columnspan=2, pady=14)

def recalc(*args):  # trace callbacks get (name, index, mode)
    try:
        amount = PRICES[product.get()] * quantity.get()
    except tk.TclError:  # the spinbox is empty or not a number
        return total.set("Total: -")
    if member.get():
        amount *= 0.9
    total.set(f"Total: {amount:.2f} €")

for var in (product, quantity, member):
    var.trace_add("write", recalc)  # call recalc on every change
recalc()
root.mainloop()
