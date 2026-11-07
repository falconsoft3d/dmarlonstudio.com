import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Click counter")
root.geometry("400x250")

count = 5  # starts at 5, so the label already shows a number

label = ttk.Label(root, text=f"Clicks: {count}", font=("Helvetica", 24))
label.pack(pady=(34, 20))

def add():
    global count
    count += 1
    label.config(text=f"Clicks: {count}")

def reset():
    global count
    count = 0
    label.config(text=f"Clicks: {count}")


# A frame keeps the two buttons side by side.
row = ttk.Frame(root)
row.pack()
ttk.Button(row, text="Add one", command=add).pack(side="left", padx=6)
ttk.Button(row, text="Reset", command=reset).pack(side="left", padx=6)

# A disabled button: visible, but it cannot be clicked.
ttk.Button(root, text="Not available", state="disabled").pack(pady=18)

root.mainloop()
