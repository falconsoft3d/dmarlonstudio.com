import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Sign up")
root.geometry("480x310")
form = ttk.Frame(root, padding=(28, 18))
form.pack(fill="both", expand=True)
form.columnconfigure(1, weight=1)  # column 1 grows with the window
for r, text in enumerate(["Name:", "Password:", "Country:", "Plan:"]):  # column 0
    ttk.Label(form, text=text).grid(row=r, column=0, sticky="e", padx=(0, 10))

def put(widget, row, sticky="ew"):  # column 1: the widgets
    widget.grid(row=row, column=1, sticky=sticky, pady=5)
    return widget

name = put(ttk.Entry(form), 0)
name.insert(0, "Linus Torvalds")
put(ttk.Entry(form, show="•"), 1).insert(0, "kernel42")
country = put(ttk.Combobox(form, values=["Finland", "Spain"], state="readonly"), 2)
country.current(0)
plan, plans = tk.StringVar(value="Pro"), put(ttk.Frame(form), 3, "w")
for p in ("Free", "Pro", "Team"):
    ttk.Radiobutton(plans, text=p, value=p, variable=plan).pack(side="left", padx=(0, 12))
terms = tk.BooleanVar(value=True)
put(ttk.Checkbutton(form, text="I accept the terms", variable=terms), 4, "w")
status = ttk.Label(form, text="Press Register to finish.", foreground="#475569")
status.grid(row=6, column=0, columnspan=2, pady=14)

def register():
    ok = f"Welcome, {name.get()}! {plan.get()} plan, {country.get()}."
    status.config(text=ok if terms.get() else "Please accept the terms first.")
put(ttk.Button(form, text="Register", command=register), 5, "e")
root.mainloop()
