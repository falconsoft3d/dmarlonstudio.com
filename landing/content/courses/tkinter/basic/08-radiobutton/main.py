import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Shipping")
root.geometry("420x240")

ttk.Label(root, text="Shipping method",
          font=("Helvetica", 16, "bold")).pack(anchor="w", padx=24, pady=(20, 8))

# One StringVar for the whole group: it holds the chosen value.
method = tk.StringVar(value="express")
options = [("Standard (5 days)", "standard"),
           ("Express (2 days)", "express"),
           ("Pick up in store", "pickup")]
prices = {"standard": 3.99, "express": 9.99, "pickup": 0.0}

cost = ttk.Label(root, font=("Helvetica", 14))

def update():
    cost.config(text=f"Cost: ${prices[method.get()]:.2f}")

# Same variable, different value: only one can be selected.
for text, value in options:
    ttk.Radiobutton(root, text=text, value=value, variable=method,
                    command=update).pack(anchor="w", padx=36, pady=3)

cost.pack(anchor="w", padx=24, pady=16)
update()
root.mainloop()
