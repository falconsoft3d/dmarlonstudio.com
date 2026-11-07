import tkinter as tk
from tkinter import ttk

files = {"project": {"src": {"main.py": "4 KB", "app.py": "12 KB"}, "README.md": "2 KB",
                     "docs": {"manual.pdf": "1.2 MB", "notes.txt": "3 KB"}},
         "photos": {"2025": {"beach.jpg": "3.1 MB"}, "cat.png": "640 KB"}}

root = tk.Tk()
root.title("Files")
root.geometry("460x310")

# Column #0 is the tree itself; "size" is an extra column.
tree = ttk.Treeview(root, columns=("size",))
tree.heading("#0", text="Name", anchor="w")
tree.heading("size", text="Size", anchor="e")
tree.column("size", width=100, anchor="e")
def add(parent, items):  # insert(parent, ...) makes a child of that node
    for name, value in items.items():
        path = f"{parent}/{name}" if parent else name
        folder = isinstance(value, dict)  # open=True shows a folder's children
        tree.insert(parent, "end", iid=path, text=name + "/" * folder,
                    values=() if folder else (value,), open=name != "photos")
        if folder:
            add(path, value)

add("", files)
info = ttk.Label(root)
info.pack(side="bottom", anchor="w", padx=12, pady=(0, 10))
tree.pack(fill="both", expand=True, padx=10, pady=10)
tree.bind("<<TreeviewSelect>>", lambda e: info.config(
    text=f"Selected: {tree.focus()}   (parent: {tree.parent(tree.focus())})"))
tree.selection_set("project/src/app.py")
tree.focus("project/src/app.py")
root.mainloop()
