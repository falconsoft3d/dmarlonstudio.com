import tkinter as tk
from tkinter import ttk

products = [("P-001", "Keyboard", 25.9, 14), ("P-002", "Mouse", 12.5, 3),
            ("P-003", "Monitor 24\"", 149.0, 6), ("P-004", "USB cable", 4.95, 40),
            ("P-005", "Webcam", 39.99, 2), ("P-006", "Headphones", 59.0, 9),
            ("P-007", "Laptop stand", 29.5, 11)]

root = tk.Tk()
root.title("Products")
root.geometry("560x290")

# Columns by name; show="headings" hides the tree column (#0).
tree = ttk.Treeview(root, columns=("code", "name", "price", "stock"), show="headings")
for col, title, width, anchor in [("code", "Code", 80, "w"), ("name", "Name", 220, "w"),
                                  ("price", "Price", 100, "e"), ("stock", "Stock", 80, "e")]:
    tree.heading(col, text=title)
    tree.column(col, width=width, anchor=anchor)

# One row per product; the tag "low" paints the rows with little stock.
for code, name, price, stock in products:
    tree.insert("", "end", iid=code, values=(code, name, f"{price:.2f}", stock),
                tags=("low",) if stock < 5 else ())
tree.tag_configure("low", foreground="#c0392b")
info = ttk.Label(root)
info.pack(side="bottom", anchor="w", padx=12, pady=(0, 10))
tree.pack(fill="both", expand=True, padx=10, pady=10)
def show(event):  # <<TreeviewSelect>>: the selection has changed
    code, name, price, stock = tree.item(tree.focus(), "values")
    info.config(text=f"Selected: {name} ({code}), {price} each, {stock} in stock")
tree.bind("<<TreeviewSelect>>", show)
tree.selection_set("P-003")  # a row chosen from code
tree.focus("P-003")
root.mainloop()
