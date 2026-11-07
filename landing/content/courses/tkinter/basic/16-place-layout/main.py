import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Layout with place")
root.geometry("540x330")

# Absolute: x and y in pixels from the top-left corner of the window.
ttk.Label(root, text="x=20, y=20").place(x=20, y=20)
ttk.Button(root, text="x=20, y=50, width=180").place(x=20, y=50, width=180)
ttk.Entry(root).place(x=20, y=94, width=180, height=28)

# Relative: fractions of the window, from 0.0 to 1.0.
panel = tk.Frame(root, bg="#dbeafe")
panel.place(relx=0.45, rely=0.06, relwidth=0.5, relheight=0.55)
tk.Label(panel, text="relx=0.45, rely=0.06\nrelwidth=0.5, relheight=0.55",
         bg="#dbeafe").place(relx=0.5, rely=0.5, anchor="center")

# anchor="center": the point (relx, rely) is the middle of the widget.
tk.Label(root, text="relx=0.5, rely=0.75, anchor=center", bg="#fef08a",
         padx=6, pady=6).place(relx=0.5, rely=0.75, anchor="center")

# Both together: the bottom-right corner, then 16 pixels inwards.
ttk.Button(root, text="OK").place(relx=1.0, rely=1.0, x=-16, y=-16, anchor="se")
root.mainloop()
