import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Notes")
root.geometry("520x280")

# A label at the bottom; the Text takes the rest of the window.
status = ttk.Label(root, foreground="#475569")
status.pack(side="bottom", anchor="w", padx=14, pady=(0, 10))

text = tk.Text(root, wrap="word", font=("Helvetica", 14), padx=10, pady=8,
               highlightthickness=1, highlightbackground="#cbd5e1")
text.pack(fill="both", expand=True, padx=12, pady=12)
# Tags give a style to parts of the text.
text.tag_configure("title", font=("Helvetica", 18, "bold"))
text.tag_configure("bold", font=("Helvetica", 14, "bold"))
text.tag_configure("red", foreground="#dc2626")
text.tag_configure("mark", background="#fef08a")

# insert(position, text, tag): "end" adds the text at the end.
text.insert("end", "Shopping list\n", "title")
text.insert("end", "Buy ")
text.insert("end", "bread", "bold")
text.insert("end", " and ")
text.insert("end", "milk", "red")
text.insert("end", " before Friday. Long lines wrap by whole words "
            "when they do not fit in the width of the box.\n")
text.insert("end", "This line is highlighted.", "mark")

# Positions are "line.column"; "end-1c" is the last character.
lines = text.index("end-1c").split(".")[0]
status.config(text=f"{lines} lines · {len(text.get('1.0', 'end-1c'))} chars")
root.mainloop()
