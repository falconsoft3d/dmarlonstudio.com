import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Progress")
root.geometry("460x290")

# Determinate: value goes from 0 to maximum.
copied = tk.IntVar(value=65)
ttk.Label(root, text="Copying files").pack(anchor="w", padx=24, pady=(20, 4))
bar = ttk.Progressbar(root, variable=copied, maximum=100, length=410)
bar.pack()
done = ttk.Label(root, text="65 of 100 files")
done.pack(anchor="e", padx=24)

def more():  # step() adds to the value (and wraps round after maximum)
    bar.step(10)
    done.config(text=f"{copied.get()} of 100 files")
ttk.Button(root, text="+10", command=more).pack(anchor="e", padx=20)

# Indeterminate: a block that moves back and forth while we wait.
ttk.Label(root, text="Searching for updates…").pack(anchor="w", padx=24, pady=(8, 4))
busy = ttk.Progressbar(root, mode="indeterminate", length=410)
busy.pack()
busy.start(15)   # it moves every 15 ms; busy.stop() stops it

# orient="vertical": the bar grows upwards.
levels = ttk.Frame(root)
levels.pack(anchor="w", padx=20, pady=(16, 0))
for value in (30, 80, 55, 100):
    ttk.Progressbar(levels, orient="vertical", value=value, length=60).pack(side="left", padx=4)
root.mainloop()
