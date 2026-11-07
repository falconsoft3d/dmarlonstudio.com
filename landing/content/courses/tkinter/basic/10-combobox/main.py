import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Combobox")
root.geometry("420x250")

countries = ["Argentina", "Chile", "Cuba", "Mexico", "Spain", "Uruguay"]

# readonly: you can only pick one of the values.
ttk.Label(root, text="Country (pick one)").pack(anchor="w", padx=40, pady=(24, 2))
country = ttk.Combobox(root, values=countries, state="readonly", width=28)
country.current(4)  # index 4 of values: "Spain"
country.pack(anchor="w", padx=40)

# normal: you can also type a value that is not in the list.
ttk.Label(root, text="City (pick or type)").pack(anchor="w", padx=40, pady=(14, 2))
city = ttk.Combobox(root, values=["Madrid", "Barcelona", "Valencia"], width=28)
city.set("Seville")
city.pack(anchor="w", padx=40)

result = ttk.Label(root, font=("Helvetica", 16))
result.pack(pady=22)

def show(event=None):
    result.config(text=f"{city.get()}, {country.get()}")

country.bind("<<ComboboxSelected>>", show)
city.bind("<<ComboboxSelected>>", show)
city.bind("<KeyRelease>", show)
show()
root.mainloop()
