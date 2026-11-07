import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Sign in")
root.geometry("420x290")
password = tk.StringVar(value="secret123")

ttk.Label(root, text="User").pack(anchor="w", padx=60, pady=(24, 2))
user = ttk.Entry(root, width=30)
user.insert(0, "marlon")
user.pack(anchor="w", padx=60)

# show="•" draws every character as a dot; the text is still there.
ttk.Label(root, text="Password").pack(anchor="w", padx=60, pady=(12, 2))
secret = ttk.Entry(root, textvariable=password, show="•", width=30)
secret.pack(anchor="w", padx=60)

def toggle():
    hidden = secret.cget("show") != ""
    secret.config(show="" if hidden else "•")
    button.config(text="Hide" if hidden else "Show")

button = ttk.Button(root, text="Show", command=toggle)
button.pack(anchor="w", padx=56, pady=10)
info = ttk.Label(root, foreground="#475569")
info.pack(anchor="w", padx=60)

def show_length(*args):  # get() returns the real text, not the dots
    info.config(text=f"Length: {len(password.get())} characters")

password.trace_add("write", show_length)
show_length()
root.mainloop()
