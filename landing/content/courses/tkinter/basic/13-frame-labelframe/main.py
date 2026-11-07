import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Frames")
root.geometry("520x330")

# Each row is a small Frame: the label on the left, the entry beside it.
def field(parent, label, value):
    row = ttk.Frame(parent)
    row.pack(fill="x", pady=3)
    ttk.Label(row, text=label, width=8).pack(side="left")
    entry = ttk.Entry(row)
    entry.insert(0, value)
    entry.pack(side="left", fill="x", expand=True)

# LabelFrame: a frame with a border and a title.
person = ttk.LabelFrame(root, text="Personal data", padding=12)
person.pack(fill="x", padx=16, pady=(16, 0))
field(person, "Name", "Grace Hopper")
field(person, "Email", "grace@example.com")

address = ttk.LabelFrame(root, text="Address", padding=12)
address.pack(fill="x", padx=16, pady=12)
field(address, "Street", "12 Navy Road")
field(address, "City", "Arlington")

# A frame for the buttons, aligned to the right.
buttons = ttk.Frame(root)
buttons.pack(fill="x", padx=16)
ttk.Button(buttons, text="Save").pack(side="right")
ttk.Button(buttons, text="Cancel").pack(side="right", padx=8)
root.mainloop()
