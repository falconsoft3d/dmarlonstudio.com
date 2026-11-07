import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Sliders")
root.geometry("520x320")

# tk.Scale vertical: from_ at the top, to at the bottom.
temp = tk.DoubleVar(value=21.5)
tk.Scale(root, label="°C", from_=30, to=10, resolution=0.5, orient="vertical",
         variable=temp, length=250).pack(side="right", padx=28, pady=16)

# tk.Scale horizontal: it shows its title and its current value.
volume = tk.IntVar(value=70)
tk.Scale(root, label="Volume", from_=0, to=100, orient="horizontal",
         variable=volume, length=320).pack(anchor="w", padx=24, pady=(18, 12))

# ttk.Scale: the system look, without text; a label shows the value.
zoom = tk.DoubleVar(value=1.5)
ttk.Label(root, text="Zoom").pack(anchor="w", padx=24)
ttk.Scale(root, from_=0.5, to=3, variable=zoom, length=320,
          command=lambda value: show()).pack(anchor="w", padx=24)
summary = ttk.Label(root, font=("Helvetica", 14), foreground="#1d4ed8")
summary.pack(anchor="w", padx=24, pady=18)

def show(*args):
    summary.config(text=f"Volume {volume.get()} · {temp.get()} °C"
                        f" · zoom {zoom.get():.1f}x")

volume.trace_add("write", show)
temp.trace_add("write", show)
show()
root.mainloop()
