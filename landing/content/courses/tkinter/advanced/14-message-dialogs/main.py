import tkinter as tk
from tkinter import ttk, messagebox, simpledialog

root = tk.Tk()
root.title("Dialogs")
root.geometry("520x250")

# Each function opens a modal dialog and returns when it is closed.
dialogs = {
    "showinfo": lambda: messagebox.showinfo("Info", "The file was saved."),
    "showwarning": lambda: messagebox.showwarning("Warning", "The disk is almost full."),
    "showerror": lambda: messagebox.showerror("Error", "File not found."),
    "askyesno": lambda: messagebox.askyesno("Delete", "Delete the file?"),
    "askokcancel": lambda: messagebox.askokcancel("Print", "Print 12 pages?"),
    "askyesnocancel": lambda: messagebox.askyesnocancel("Close", "Save the changes?"),
    "askstring": lambda: simpledialog.askstring("Name", "Your name:", initialvalue="Ana"),
    "askinteger": lambda: simpledialog.askinteger("Age", "Your age:", minvalue=0, maxvalue=120),
    "askfloat": lambda: simpledialog.askfloat("Price", "Price:", initialvalue=9.95),
}
result = tk.StringVar(value="askyesno() returned True")

def run(name):  # call the dialog and show what it returned
    value = dialogs[name]()
    result.set(f"{name}() returned {value!r}")

grid = ttk.Frame(root, padding=16)
grid.pack()
for i, name in enumerate(dialogs):
    ttk.Button(grid, text=name, command=lambda n=name: run(n)).grid(
        row=i // 3, column=i % 3, sticky="ew", padx=4, pady=4)
ttk.Label(root, text="Last result:").pack()
ttk.Label(root, textvariable=result, font=("Menlo", 13)).pack(pady=6)
root.mainloop()
