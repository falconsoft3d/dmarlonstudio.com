import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Listbox")
root.geometry("480x320")

fruits = ["Apple", "Banana", "Cherry", "Grape", "Mango", "Orange", "Pear"]
status = ttk.Label(root, foreground="#1d4ed8")
status.pack(side="bottom", pady=(0, 12))

def show(listbox):
    names = [listbox.get(i) for i in listbox.curselection()]
    status.config(text="Selected: " + (", ".join(names) or "none"))

def make_list(title, mode, selected):
    box = ttk.Frame(root, padding=12)
    box.pack(side="left", fill="both", expand=True)
    ttk.Label(box, text=title).pack(anchor="w", pady=(0, 4))
    # exportselection=False: each list keeps its own selection.
    lb = tk.Listbox(box, selectmode=mode, height=7, exportselection=False)
    lb.pack(fill="both", expand=True)
    lb.insert("end", *fruits)
    for index in selected:
        lb.selection_set(index)
    lb.bind("<<ListboxSelect>>", lambda event: show(lb))
    return lb

make_list("One item (browse)", "browse", [2])
many = make_list("Several items (multiple)", "multiple", [0, 3, 4])
show(many)
root.mainloop()
