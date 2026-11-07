import tkinter as tk
from tkinter import ttk

# The main window: one Tk() per application.
root = tk.Tk()
root.title("My first window")
root.geometry("420x220")      # width x height in pixels
root.resizable(False, False)  # fixed size

# A label and a button inside the window.
ttk.Label(root, text="Hello from tkinter!", font=("Helvetica", 18)).pack(pady=(40, 16))
ttk.Button(root, text="Close", command=root.destroy).pack()

# mainloop() shows the window and waits for clicks and keys.
root.mainloop()
