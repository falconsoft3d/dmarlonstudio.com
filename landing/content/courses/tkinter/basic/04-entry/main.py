import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Entry and StringVar")
root.geometry("440x250")

# A StringVar holds the text; the entry shows it and edits it.
name = tk.StringVar(value="Ada Lovelace")

ttk.Label(root, text="Your name:").pack(anchor="w", padx=32, pady=(28, 4))
entry = ttk.Entry(root, textvariable=name, width=36)
entry.pack(anchor="w", padx=32)
entry.focus()

# This label follows the variable: it changes as you type.
greeting = ttk.Label(root, font=("Helvetica", 18))
greeting.pack(pady=22)


def update(*args):
    greeting.config(text=f"Hello, {name.get() or 'nobody'}!")


name.trace_add("write", update)  # call update on every change
update()

ttk.Button(root, text="Clear", command=lambda: name.set("")).pack()

root.mainloop()
