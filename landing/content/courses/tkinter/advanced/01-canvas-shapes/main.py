import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Canvas: shapes and text")
root.geometry("520x360")

# A drawing surface: (0, 0) is its top-left corner.
canvas = tk.Canvas(root, bg="white", highlightthickness=0)
info = ttk.Label(root)
info.pack(side="bottom", anchor="w", padx=12, pady=(0, 8))
canvas.pack(fill="both", expand=True, padx=10, pady=10)

# The axes: x grows to the right and y grows downwards.
canvas.create_line(20, 20, 490, 20, arrow="last", fill="gray")
canvas.create_line(20, 20, 20, 300, arrow="last", fill="gray")

# Each create_* takes coordinates and returns the new item's id.
canvas.create_rectangle(60, 60, 180, 140, fill="#4f8cf7", outline="")
canvas.create_oval(220, 50, 320, 150, fill="#f7b84f", outline="#c07d10", width=3)
canvas.create_polygon(380, 150, 430, 50, 480, 150, fill="#5cc28a")
canvas.create_line(60, 200, 160, 260, 260, 200, 340, 260,
                   width=4, fill="#d9534f", smooth=True)
arc = canvas.create_arc(380, 180, 470, 270, start=30, extent=300, fill="#a17be0")

# Text goes at a point; anchor says which side of the text touches it.
canvas.create_text(120, 100, text="rectangle", fill="white", font=("Helvetica", 12, "bold"))
canvas.create_text(490, 32, text="x", anchor="e", tags="axis")
canvas.create_text(32, 290, text="y", anchor="w", tags="axis")

# A tag names a group of items: change them all at once.
canvas.itemconfigure("axis", fill="gray", font=("Helvetica", 13, "italic"))
info.config(text=f"{len(canvas.find_all())} items · the arc is item {arc}: {canvas.coords(arc)}")
root.mainloop()
