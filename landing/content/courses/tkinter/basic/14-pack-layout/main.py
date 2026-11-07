import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Layout with pack")
root.geometry("560x340")

def box(text, colour):
    # tk.Label, not ttk: the macOS theme ignores ttk background colours.
    return tk.Label(root, text=text, bg=colour, fg="white", padx=12, pady=8,
                    font=("Helvetica", 13, "bold"))

# side says which edge each widget sticks to; the order matters.
box("side=top, fill=x", "#2563eb").pack(side="top", fill="x")

# A toolbar: buttons in a row with side="left", one with side="right".
bar = ttk.Frame(root, padding=6)
bar.pack(side="top", fill="x")
for name in ("New", "Open", "Save"):
    ttk.Button(bar, text=name).pack(side="left", padx=2)
ttk.Button(bar, text="Help").pack(side="right", padx=2)

box("side=bottom, fill=x", "#475569").pack(side="bottom", fill="x")
box("side=left\nfill=y", "#16a34a").pack(side="left", fill="y")
box("side=right\nfill=y", "#ea580c").pack(side="right", fill="y")

# expand=True takes the space left over; fill="both" uses all of it.
box("expand=True\nfill=both", "#9333ea").pack(fill="both", expand=True,
                                              padx=10, pady=10)
root.mainloop()
