import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Separator, Message and Sizegrip")
root.geometry("480x260")

# Status bar at the bottom, with a Sizegrip in the right-hand corner.
status = ttk.Frame(root)
status.pack(side="bottom", fill="x")
ttk.Label(status, text="Ready").pack(side="left", padx=8, pady=2)
ttk.Sizegrip(status).pack(side="right", anchor="se")
ttk.Separator(root, orient="horizontal").pack(side="bottom", fill="x")

ttk.Label(root, text="About Message",
          font=("Helvetica", 16, "bold")).pack(anchor="w", padx=16, pady=(16, 4))
# tk.Message breaks its text into lines by itself; width is in pixels.
tk.Message(root, width=440, text="A Message is like a label that wraps its "
           "own text. Here it uses a width of 440 pixels, so the lines break "
           "near the edge of the window.").pack(anchor="w", padx=12)

# A horizontal Separator: a thin line between two parts.
ttk.Separator(root, orient="horizontal").pack(fill="x", padx=16, pady=12)

# A vertical Separator between labels in a row.
row = ttk.Frame(root)
row.pack(anchor="w", padx=16)
for i, word in enumerate(("Left", "Middle", "Right")):
    if i:
        ttk.Separator(row, orient="vertical").pack(side="left", fill="y", padx=14)
    ttk.Label(row, text=word, font=("Helvetica", 14)).pack(side="left", pady=4)
root.mainloop()
