import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Layout with grid")
root.geometry("480x300")

form = ttk.Frame(root, padding=20)
form.pack(fill="both", expand=True)
form.columnconfigure(1, weight=1)  # column 1 grows with the window
form.rowconfigure(3, weight=1)     # and so does row 3 (the notes)

fields = [("First name", "Alan"), ("Last name", "Turing"),
          ("Email", "alan@example.com")]
for row, (label, value) in enumerate(fields):
    # sticky="e": the label sticks to the right edge of its cell.
    ttk.Label(form, text=label + ":").grid(row=row, column=0, sticky="e",
                                           padx=(0, 8), pady=4)
    entry = ttk.Entry(form)
    entry.insert(0, value)
    # columnspan=2: the entry takes two columns; sticky="ew" stretches it.
    entry.grid(row=row, column=1, columnspan=2, sticky="ew", pady=4)

ttk.Label(form, text="Notes:").grid(row=3, column=0, sticky="ne", padx=(0, 8))
notes = tk.Text(form, height=4, width=30, font=("Helvetica", 13),
                highlightthickness=1, highlightbackground="#cbd5e1")
notes.insert("1.0", "sticky=\"nsew\": this box fills its whole cell.")
notes.grid(row=3, column=1, columnspan=2, sticky="nsew", pady=4)

# The buttons share row 4: Cancel in column 1, Save in column 2.
ttk.Button(form, text="Cancel").grid(row=4, column=1, sticky="e", pady=(8, 0))
ttk.Button(form, text="Save").grid(row=4, column=2, sticky="e", padx=(8, 0),
                                   pady=(8, 0))
root.mainloop()
