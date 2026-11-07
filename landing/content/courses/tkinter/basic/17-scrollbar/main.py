import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Scrollbars")
root.geometry("580x320")

# Left: a Listbox with 40 items and a vertical scrollbar.
left = ttk.Frame(root, padding=10)
left.pack(side="left", fill="y")
items = tk.Listbox(left, width=16, height=10)
bar = ttk.Scrollbar(left, orient="vertical", command=items.yview)
items.config(yscrollcommand=bar.set)  # the two talk to each other
bar.pack(side="right", fill="y")
items.pack(side="left", fill="y")
items.insert("end", *[f"Item {n:02d}" for n in range(1, 41)])
items.yview_moveto(0.3)  # start scrolled down a little
items.selection_set(15)

# Right: a Text without wrapping, with vertical and horizontal bars.
right = ttk.Frame(root, padding=10)
right.pack(side="left", fill="both", expand=True)
right.rowconfigure(0, weight=1)
right.columnconfigure(0, weight=1)
text = tk.Text(right, wrap="none", width=30, height=10)
ys = ttk.Scrollbar(right, orient="vertical", command=text.yview)
xs = ttk.Scrollbar(right, orient="horizontal", command=text.xview)
text.config(yscrollcommand=ys.set, xscrollcommand=xs.set)
text.grid(row=0, column=0, sticky="nsew")
ys.grid(row=0, column=1, sticky="ns")
xs.grid(row=1, column=0, sticky="ew")
for n in range(1, 31):
    text.insert("end", f"Line {n}: " + "too long to fit, scroll sideways " * 2 + "\n")
root.mainloop()
