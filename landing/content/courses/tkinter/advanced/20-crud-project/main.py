import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Products")
root.geometry("660x260")
form = {name: tk.StringVar() for name in ("Name", "Price", "Stock")}
status = tk.StringVar(value="3 products · Mouse selected")
def act(action):  # Add, Update or Delete: from the menu or from a button
    values, chosen = [var.get() for var in form.values()], tree.selection()
    if action == "Add":
        tree.selection_set(tree.insert("", "end", values=values))
    elif chosen:  # Update or Delete the selected row
        tree.item(chosen[0], values=values) if action == "Update" else tree.delete(chosen[0])
    status.set(f"{action}: {values[0]} · {len(tree.get_children())} products")
menu, edit = tk.Menu(root), tk.Menu(root, tearoff=0)  # the bar and its Edit menu
menu.add_cascade(label="Edit", menu=edit)
root.config(menu=menu)
ttk.Label(root, textvariable=status, relief="sunken", padding=(6, 2)).pack(side="bottom", fill="x")
(row := ttk.Frame(root, padding=(10, 0, 10, 10))).pack(side="bottom", fill="x")
tree = ttk.Treeview(root, columns=tuple(form), show="headings")
tree.pack(fill="both", expand=True, padx=10, pady=10)
for name, var in form.items():  # a column and a field for each value
    tree.heading(name, text=name)
    ttk.Entry(row, textvariable=var, width=11).pack(side="left", padx=(0, 6))
for action in ("Add", "Update", "Delete"):
    edit.add_command(label=action, command=lambda a=action: act(a))
    ttk.Button(row, text=action, command=lambda a=action: act(a)).pack(side="left")
for item in (("Keyboard", "25.90", "14"), ("Mouse", "12.50", "3"), ("Monitor", "149.00", "6")):
    tree.insert("", "end", iid=item[0], values=item)
tree.bind("<<TreeviewSelect>>", lambda e: [  # copy the selected row into the form
    var.set(tree.set(item, name)) for item in tree.selection() for name, var in form.items()])
tree.selection_set("Mouse")
root.mainloop()
