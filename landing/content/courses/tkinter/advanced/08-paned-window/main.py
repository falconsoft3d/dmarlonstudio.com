import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Mail")
root.geometry("640x360")
ttk.Label(root, text="Drag the dividers to resize the panes").pack(side="bottom", anchor="w", padx=10, pady=(0, 6))
look = dict(bg="white", fg="black", highlightthickness=0, exportselection=False)

# A Panedwindow splits its space; drag the sash between panes to resize them.
outer = ttk.Panedwindow(root, orient="horizontal")
outer.pack(fill="both", expand=True, padx=8, pady=8)
folders = tk.Listbox(outer, width=16, activestyle="none", **look)
folders.insert("end", "Inbox", "Sent", "Drafts", "Archive", "Trash")
folders.selection_set(0)

# Panes can be nested: the right side is split again, top to bottom.
right = ttk.Panedwindow(outer, orient="vertical")
mails = tk.Listbox(right, height=5, activestyle="none", **look)
for line in ["Ana — Meeting on Monday", "Luis — Invoice 2041",
             "Marta — Photos from the trip", "Shop — Your order has shipped"]:
    mails.insert("end", line)
mails.selection_set(0)
body = tk.Text(right, height=6, wrap="word", font=("Helvetica", 13), padx=8, pady=6, **look)
body.insert("1.0", "Hi team,\n\nThe meeting is on Monday at 10:00 in room 2.\n\nAna")

# add(child, weight=n): extra space is shared out by weight.
outer.add(folders, weight=1)
outer.add(right, weight=4)
right.add(mails, weight=1)
right.add(body, weight=2)
root.mainloop()
