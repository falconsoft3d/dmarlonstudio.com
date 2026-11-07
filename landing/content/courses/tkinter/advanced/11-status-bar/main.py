import tkinter as tk

root = tk.Tk()
root.title("Notes")
root.geometry("520x260")

# The status bar: a Frame docked at the bottom with sunken labels inside.
bar = tk.Frame(root, bd=1, relief="sunken")
bar.pack(side="bottom", fill="x")   # packed first, so it always keeps its place
message = tk.Label(bar, text="Ready", anchor="w", padx=6)
message.pack(side="left", fill="x", expand=True)
cells = {}
for name, width in (("position", 14), ("words", 10), ("encoding", 7)):
    cells[name] = tk.Label(bar, width=width, relief="sunken", bd=1)
    cells[name].pack(side="left")
cells["encoding"].config(text="UTF-8")

text = tk.Text(root, wrap="word", bg="white", fg="black", font=("Helvetica", 14),
               padx=10, pady=8, insertbackground="black", highlightthickness=0)
text.pack(fill="both", expand=True)
text.insert("1.0", "Shopping list\n\nBread, milk and eggs.\nCall Ana about the trip.")

def update(event=None):  # read the editor and write the bar
    line, col = text.index("insert").split(".")
    cells["position"].config(text=f"Ln {line}, Col {int(col) + 1}")
    cells["words"].config(text=f"{len(text.get('1.0', 'end').split())} words")

text.bind("<KeyRelease>", update)       # after each key…
text.bind("<ButtonRelease-1>", update)  # …and each click in the text
text.mark_set("insert", "3.6")          # the cursor after "Bread,"
update()
message.config(text="Opened notes.txt")                 # a message from code…
root.after(4000, lambda: message.config(text="Ready"))  # …that goes after 4 s
root.mainloop()
