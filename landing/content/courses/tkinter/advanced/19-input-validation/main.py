import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Sign up")
root.geometry("480x220")
root.configure(padx=24, pady=20)

ttk.Style().map("TEntry", foreground=[("invalid", "#c0392b")])  # red when "invalid"

# %P: the text as it would be after the change (up to 3 digits allowed).
digits = root.register(lambda new: new == "" or (new.isdigit() and len(new) <= 3))

def check_email(name, text):  # %W: the widget's name; True means valid
    ok = "@" in text and "." in text.split("@")[-1]
    root.nametowidget(name).state(["!invalid" if ok else "invalid"])
    errors.config(text="" if ok else "The email needs a domain, like ana@example.com")
    return ok

# validate= says when to check; validatecommand= (registered function, codes).
ttk.Label(root, text="Age:").grid(row=0, column=0, sticky="w", pady=6)
age = ttk.Entry(root, width=6, validate="key", validatecommand=(digits, "%P"),
                invalidcommand=root.bell)  # a beep when a key is rejected
age.grid(row=0, column=1, sticky="w")
ttk.Label(root, text="Email:").grid(row=1, column=0, sticky="w", pady=6)
email = ttk.Entry(root, width=32, validate="focusout",
                  validatecommand=(root.register(check_email), "%W", "%P"))
email.grid(row=1, column=1, sticky="w")
errors = ttk.Label(root, foreground="#c0392b")
errors.grid(row=2, column=1, sticky="w")
age.insert(0, "42")
email.insert(0, "ana@example")
email.validate()            # run the email check now, without leaving the field
root.mainloop()
