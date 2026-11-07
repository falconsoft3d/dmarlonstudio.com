import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Editor")
root.geometry("460x300")
wrap, zoom = tk.BooleanVar(value=True), tk.StringVar(value="100%")

# The bar is a Menu; each cascade opens another Menu (tearoff=0: no dashed line).
bar = tk.Menu(root)
file = tk.Menu(bar, tearoff=0)
file.add_command(label="New", accelerator="Ctrl+N", command=lambda: print("New"))
file.add_command(label="Open…", accelerator="Ctrl+O")
file.add_separator()
file.add_command(label="Quit", command=root.destroy)
view = tk.Menu(bar, tearoff=0)
view.add_checkbutton(label="Word wrap", variable=wrap)   # on / off
for size in ("75%", "100%", "150%"):                      # one of several
    view.add_radiobutton(label=f"Zoom {size}", variable=zoom, value=size)
root.bind("<Control-n>", lambda e: print("New"))  # accelerator is only the text

# On macOS the bar sits at the top of the screen: list it in the window too.
ttk.Label(root, text=f"Word wrap = {wrap.get()}, zoom = {zoom.get()}").pack(side="bottom", pady=8)
listing = tk.Text(root, bg="white", fg="black", font=("Menlo", 12), padx=12, pady=10)
listing.pack(fill="both", expand=True)
for title, menu in (("File", file), ("View", view)):
    bar.add_cascade(label=title, menu=menu)
    listing.insert("end", f"{title}\n")
    for i in range(menu.index("end") + 1):
        sep = menu.type(i) == "separator"
        label, keys = ("─" * 12, "") if sep else (menu.entrycget(i, "label"), menu.entrycget(i, "accelerator"))
        listing.insert("end", f"   {label:<14}{keys:<8}{menu.type(i)}\n")
root.config(menu=bar)
root.mainloop()
