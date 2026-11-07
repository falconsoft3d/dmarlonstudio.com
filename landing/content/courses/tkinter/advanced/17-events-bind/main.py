import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Events")
root.geometry("520x300")
last = tk.StringVar(value="<Button-1>  at x=300, y=70")
where = tk.StringVar(value="Mouse at x=300, y=70")

pad = tk.Canvas(root, bg="white", height=180, highlightthickness=1, highlightbackground="#bbbbbb")
pad.pack(fill="x", padx=12, pady=12)
pad.create_text(10, 8, anchor="nw", fill="gray",
                text="Click, double-click or move the mouse here; press any key")
ttk.Label(root, textvariable=last, font=("Menlo", 14)).pack()
ttk.Label(root, textvariable=where).pack(pady=6)

def clicked(event):  # every handler receives an Event with the details
    last.set(f"<Button-{event.num}>  at x={event.x}, y={event.y}")
    pad.create_oval(event.x - 5, event.y - 5, event.x + 5, event.y + 5, fill="#4f8cf7", width=0)

def key(event):  # keysym: the key's name; char: the character it types
    last.set(f"<Key>  keysym={event.keysym!r}  char={event.char!r}")

# bind(sequence, handler): "<Modifier-Type-Detail>".
pad.bind("<Button>", clicked)  # any mouse button; num says which one
pad.bind("<Double-Button-1>", lambda e: last.set("<Double-Button-1>"))
pad.bind("<Motion>", lambda e: where.set(f"Mouse at x={e.x}, y={e.y}"))
pad.bind("<Leave>", lambda e: where.set("The mouse left the pad"))
root.bind("<Key>", key)  # keys go to the window that has the focus
root.bind("<Control-s>", lambda e: last.set("<Control-s>  (save)"))

for x, y in ((90, 120), (190, 60), (300, 70)):  # three earlier clicks
    pad.create_oval(x - 5, y - 5, x + 5, y + 5, fill="#4f8cf7", width=0)
root.mainloop()
