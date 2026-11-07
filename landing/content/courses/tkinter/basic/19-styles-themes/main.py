import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Styles and themes")
root.geometry("500x260")

style = ttk.Style()
style.theme_use("clam")  # a built-in theme that lets you change colours

# configure() changes a style; "TButton" is the style of every ttk.Button.
style.configure("TButton", font=("Helvetica", 12), padding=(12, 6))
# A new style that inherits from TButton: <Name>.TButton.
style.configure("Accent.TButton", background="#2563eb", foreground="white")
style.map("Accent.TButton", background=[("active", "#1d4ed8"),
                                        ("disabled", "#93c5fd")])
style.configure("Danger.TButton", background="#dc2626", foreground="white")
style.configure("Title.TLabel", font=("Helvetica", 20, "bold"),
                foreground="#1e3a8a")

main = ttk.Frame(root, padding=20)
main.pack(fill="both", expand=True)
ttk.Label(main, text="Custom styles", style="Title.TLabel").pack(anchor="w")
ttk.Label(main, text="Themes: " + ", ".join(sorted(style.theme_names())),
          wraplength=440).pack(anchor="w", pady=(4, 16))

row = ttk.Frame(main)
row.pack(anchor="w")
ttk.Button(row, text="Normal").pack(side="left")
ttk.Button(row, text="Accent", style="Accent.TButton").pack(side="left", padx=8)
ttk.Button(row, text="Delete", style="Danger.TButton").pack(side="left")
ttk.Button(main, text="Disabled accent", style="Accent.TButton",
           state="disabled").pack(anchor="w", pady=12)
root.mainloop()
