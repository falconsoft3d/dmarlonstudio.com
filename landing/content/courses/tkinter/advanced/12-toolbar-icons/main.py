import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Ribbon")
root.geometry("520x260")

def icon(*boxes):  # a 24x24 icon from (color, x1, y1, x2, y2) rectangles
    img = tk.PhotoImage(width=24, height=24)
    for color, *box in boxes:
        img.put(color, to=tuple(box))
    return img

icons = {  # keep them in a dict: an image without references disappears
    "New": icon(("#868e96", 4, 1, 20, 23), ("white", 5, 2, 19, 22), ("#adb5bd", 8, 8, 16, 9)),
    "Open": icon(("#e0a526", 1, 5, 11, 9), ("#f2b632", 1, 8, 23, 21)),
    "Save": icon(("#3b5bdb", 2, 2, 22, 22), ("white", 7, 3, 17, 9), ("#dbe4ff", 5, 13, 19, 20)),
    "Copy": icon(("#adb5bd", 2, 2, 15, 17), ("#868e96", 9, 7, 22, 22), ("white", 10, 8, 21, 21)),
    "Paste": icon(("#a9712b", 3, 4, 21, 23), ("white", 6, 8, 18, 21), ("#495057", 8, 1, 16, 6)),
}
status = ttk.Label(root, text="Clicked: Save", relief="sunken", padding=(6, 2))
status.pack(side="bottom", fill="x")

# The ribbon: groups (LabelFrame) of toolbar buttons, the icon above the text.
ribbon = ttk.Frame(root, padding=6)
ribbon.pack(fill="x")
for group, names in (("File", "New Open Save"), ("Clipboard", "Copy Paste")):
    box = ttk.LabelFrame(ribbon, text=group, padding=4)
    box.pack(side="left", padx=4)
    for name in names.split():
        ttk.Button(box, text=name, image=icons[name], compound="top", style="Toolbutton",
                   command=lambda n=name: status.config(text=f"Clicked: {n}")).pack(side="left", padx=2)
tk.Text(root, bd=1, relief="solid").pack(fill="both", expand=True, padx=8, pady=(0, 8))
root.mainloop()
