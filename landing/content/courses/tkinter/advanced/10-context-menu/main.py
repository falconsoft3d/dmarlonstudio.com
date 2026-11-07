import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Menus inside the window")
root.geometry("460x250")
last = tk.StringVar(value="Last action: Copy")
do = lambda action: last.set(f"Last action: {action}")

# A context menu: a Menu outside the bar, shown with tk_popup(x, y).
popup = tk.Menu(root, tearoff=0)
for action in ("Cut", "Copy", "Paste", "Select all"):
    popup.add_command(label=action, command=lambda a=action: do(a))

area = tk.Label(root, text="Right-click here", bg="white", fg="gray", relief="solid", bd=1)
area.pack(fill="x", padx=20, pady=20, ipady=30)
for click in ("<Button-3>", "<Button-2>"):  # right button (Button-2: older Tk on macOS)
    area.bind(click, lambda e: popup.tk_popup(e.x_root, e.y_root))

# Menubutton: a button that drops down its own Menu.
row = ttk.Frame(root)
row.pack()
export = ttk.Menubutton(row, text="Export")
formats = tk.Menu(export, tearoff=0)
for fmt in ("PDF", "CSV", "Excel"):
    formats.add_command(label=fmt, command=lambda f=fmt: do(f"Export as {f}"))
export["menu"] = formats
export.pack(side="left", padx=10)

# OptionMenu: shows the chosen value of a list and keeps it in a variable.
size = tk.StringVar(value="Medium")
tk.OptionMenu(row, size, "Small", "Medium", "Large", command=lambda v: do(f"Size {v}")).pack(side="left")
ttk.Label(root, textvariable=last).pack(pady=18)
root.mainloop()
