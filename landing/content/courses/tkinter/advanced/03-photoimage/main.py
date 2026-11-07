import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Images made in code")
root.geometry("480x300")

# An empty 8x8 image: put() paints it, one "{...}" per row of pixels.
dark, light = "#3b5bdb", "#dbe4ff"
rows = ["{" + " ".join(dark if (x + y) % 2 else light for x in range(8)) + "}"
        for y in range(8)]
board = tk.PhotoImage(width=8, height=8)
board.put(" ".join(rows))
big_board = board.zoom(16)          # 8x8 -> 128x128: each pixel, a square

# A 16x16 icon: put(color, to=(x1, y1, x2, y2)) fills a rectangle.
icon = tk.PhotoImage(width=16, height=16)
icon.put("#f7b84f", to=(0, 0, 16, 16))
icon.put("#c07d10", to=(0, 0, 16, 3))
for i in range(3, 16):              # one pixel at a time: a diagonal
    icon.put("#d9534f", to=(i, i))
big_icon = icon.zoom(3)             # 48x48

# Show them: image= in a Label; image= and compound= in a Button.
ttk.Label(root, image=big_board).pack(side="left", padx=24)
side = ttk.Frame(root)
side.pack(side="left")
ttk.Label(side, text="zoom(3) of a 16x16 icon:").pack(anchor="w")
ttk.Label(side, image=big_icon).pack(anchor="w", pady=(4, 16))
ttk.Button(side, text="Save", image=icon, compound="left").pack(anchor="w")
ttk.Button(side, text="Open", image=icon, compound="top").pack(anchor="w", pady=8)
root.mainloop()
