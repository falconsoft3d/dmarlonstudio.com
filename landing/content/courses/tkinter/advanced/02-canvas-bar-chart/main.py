import tkinter as tk
from tkinter import ttk

sales = {"Jan": 42, "Feb": 58, "Mar": 35, "Apr": 71, "May": 64, "Jun": 88}

root = tk.Tk()
root.title("Monthly sales")
root.geometry("560x380")
canvas = tk.Canvas(root, bg="white", highlightthickness=0, height=340)
canvas.pack(fill="x")
best = max(sales, key=sales.get)
ttk.Label(root, text=f"Total: {sum(sales.values())} units · best month: {best}").pack(pady=8)

W, LEFT, TOP, BOTTOM, MAX = 560, 50, 60, 310, 100
step = (W - LEFT - 20) / len(sales)   # room for each bar

def y_of(value):  # a value -> a y coordinate (0 at the bottom)
    return BOTTOM - value / MAX * (BOTTOM - TOP)

canvas.create_text(W / 2, 26, text="Units sold per month", font=("Helvetica", 15, "bold"))
for v in range(0, MAX + 1, 25):       # grid lines with their values
    canvas.create_line(LEFT, y_of(v), W - 20, y_of(v), fill="#e5e5e5")
    canvas.create_text(LEFT - 8, y_of(v), text=v, anchor="e", fill="gray")
canvas.create_line(LEFT, BOTTOM, W - 20, BOTTOM)  # x axis

for i, (month, value) in enumerate(sales.items()):
    x0 = LEFT + i * step + 12
    x1 = x0 + step - 24
    color = "#2e9d5b" if month == best else "#4f8cf7"
    canvas.create_rectangle(x0, y_of(value), x1, BOTTOM, fill=color, width=0)
    canvas.create_text((x0 + x1) / 2, y_of(value) - 10, text=value)
    canvas.create_text((x0 + x1) / 2, BOTTOM + 14, text=month)
root.mainloop()
