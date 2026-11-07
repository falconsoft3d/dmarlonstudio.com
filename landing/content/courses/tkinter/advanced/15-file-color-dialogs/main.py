import tkinter as tk
from tkinter import ttk, filedialog, colorchooser

root = tk.Tk()
root.title("File and color dialogs")
root.geometry("560x240")
root.configure(padx=16, pady=12)  # space around the grid
TYPES = [("Text files", "*.txt"), ("All files", "*.*")]  # (description, pattern)

# They return a path ("" if cancelled), a tuple of paths or a color.
dialogs = {
    "Open…": lambda: filedialog.askopenfilename(title="Open", filetypes=TYPES),
    "Open several…": lambda: filedialog.askopenfilenames(filetypes=TYPES),
    "Save as…": lambda: filedialog.asksaveasfilename(
        defaultextension=".txt", initialfile="copy.txt", filetypes=TYPES),
    "Folder…": lambda: filedialog.askdirectory(title="Choose a folder"),
    "Color…": lambda: colorchooser.askcolor(color=swatch["bg"], title="Pick a color"),
}
shown = {"Open…": "/Users/ana/notes.txt", "Open several…": ("/Users/ana/a.txt", "/Users/ana/b.txt"),
         "Save as…": "/Users/ana/copy.txt", "Color…": ((79, 140, 247), "#4f8cf7")}
results = {name: tk.StringVar(value=repr(shown.get(name, ""))) for name in dialogs}

def run(name):
    value = dialogs[name]()
    results[name].set(repr(value))
    if name == "Color…" and value[1]:   # (None, None) when cancelled
        swatch.config(bg=value[1])

for row, name in enumerate(dialogs):  # a button and its result on each row
    ttk.Button(root, text=name, width=14, command=lambda n=name: run(n)).grid(row=row, column=0, pady=4)
    ttk.Label(root, textvariable=results[name]).grid(row=row, column=1, sticky="w", padx=10)
swatch = tk.Label(root, bg="#4f8cf7", width=4)
swatch.grid(row=4, column=2)
root.mainloop()
