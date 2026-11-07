import tkinter as tk
from tkinter import ttk

contacts = {"Ana López": ("ana@example.com", "600 123 456"),
            "Luis Gil": ("luis@example.com", "611 222 333"),
            "Marta Ruiz": ("marta@example.com", "622 444 555")}

root = tk.Tk()
root.title("Contacts")
root.geometry("380x260+80+80")
names = tk.Listbox(root, bg="white", fg="black", highlightthickness=0, height=6, font=("Helvetica", 14))
names.insert("end", *contacts)
names.pack(fill="both", expand=True, padx=12, pady=(12, 6))

def open_details(name):
    # Toplevel: one more window of the same application (and the same mainloop).
    win = tk.Toplevel(root)
    win.title(name)
    win.geometry("360x220+500+110")
    win.resizable(False, False)  # a fixed size, like a dialog
    ttk.Label(win, text=name, font=("Helvetica", 20, "bold")).pack(pady=(24, 8))
    for value in contacts[name]:
        ttk.Label(win, text=value).pack()
    ttk.Button(win, text="Close", command=win.destroy).pack(pady=20)

def show():
    for i in names.curselection():
        open_details(names.get(i))

ttk.Button(root, text="Open details", command=show).pack(pady=(0, 12))
names.selection_set(0)
open_details("Ana López")  # one window open from the start
root.mainloop()
