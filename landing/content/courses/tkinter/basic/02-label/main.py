import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Labels")
root.geometry("480x320")

# ttk.Label takes the system look: here, just text and a bigger font.
ttk.Label(root, text="A simple label",
          font=("Helvetica", 20, "bold")).pack(pady=(18, 10))

# tk.Label lets you choose colours: fg is the text, bg the box.
tk.Label(root, text="White on blue", fg="white", bg="#2563eb",
         font=("Helvetica", 14), padx=14, pady=6).pack(pady=4)

# anchor places the text inside a label wider than the text.
tk.Label(root, text="Anchored to the right (e)", width=40, anchor="e",
         bg="#e5e7eb", pady=4).pack(pady=4)
tk.Label(root, text="Anchored to the left (w)", width=40, anchor="w",
         bg="#e5e7eb", pady=4).pack(pady=4)

# wraplength breaks a long text into lines (in pixels).
long_text = ("This label has a long text that does not fit on one line, "
             "so wraplength breaks it into several centred lines.")
ttk.Label(root, text=long_text, wraplength=320, justify="center",
          foreground="#475569").pack(pady=10)

root.mainloop()
