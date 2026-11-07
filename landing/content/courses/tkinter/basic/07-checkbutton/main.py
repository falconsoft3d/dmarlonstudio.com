import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Pizza toppings")
root.geometry("400x270")

ttk.Label(root, text="Choose your toppings",
          font=("Helvetica", 16, "bold")).pack(anchor="w", padx=24, pady=(20, 8))

summary = ttk.Label(root, foreground="#1d4ed8")
toppings = {"Cheese": True, "Mushrooms": False, "Olives": True,
            "Pepperoni": False, "Pineapple": False}
choices = {}  # name -> BooleanVar

def update():
    chosen = [name for name, var in choices.items() if var.get()]
    summary.config(text="Selected: " + (", ".join(chosen) or "none"))

# One BooleanVar per checkbox: True while it is checked.
for name, checked in toppings.items():
    choices[name] = tk.BooleanVar(value=checked)
    ttk.Checkbutton(root, text=name, variable=choices[name],
                    command=update).pack(anchor="w", padx=36, pady=2)

summary.pack(anchor="w", padx=24, pady=14)
update()
root.mainloop()
