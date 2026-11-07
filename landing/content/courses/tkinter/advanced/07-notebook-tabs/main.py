import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Settings")
root.geometry("460x300")
name, reopen = tk.StringVar(value="Ana López"), tk.BooleanVar(value=True)

# A Notebook holds pages; each page is a Frame added with a tab text.
book = ttk.Notebook(root)
book.pack(fill="both", expand=True, padx=10, pady=(10, 4))

general = ttk.Frame(book, padding=16)
ttk.Label(general, text="Name:").grid(row=0, column=0, sticky="w", pady=4)
ttk.Entry(general, width=28, textvariable=name).grid(row=0, column=1)
ttk.Label(general, text="Language:").grid(row=1, column=0, sticky="w", pady=4)
language = ttk.Combobox(general, width=26, values=["English", "Spanish"], state="readonly")
language.grid(row=1, column=1)
language.set("English")
ttk.Checkbutton(general, text="Open the last project at start",
                variable=reopen).grid(row=2, column=1, sticky="w", pady=8)

book.add(general, text="General")
book.add(ttk.Label(book, text="Theme and font size go here.", padding=16), text="Appearance")
book.add(ttk.Frame(book), text="Advanced", state="disabled")  # greyed out

# <<NotebookTabChanged>> fires when another tab is shown.
status = ttk.Label(root)
status.pack(anchor="w", padx=14, pady=(0, 8))
book.bind("<<NotebookTabChanged>>", lambda e: status.config(
    text=f"Tab {book.index('current') + 1} of {book.index('end')}: {book.tab('current', 'text')}"))
book.select(general)  # the page shown at start
root.mainloop()
