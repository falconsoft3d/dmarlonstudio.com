import tkinter as tk
from tkinter import ttk

root = tk.Tk()
root.title("Countdown")
root.geometry("380x230")
START = 5 * 60            # five minutes, in seconds
left, job = START, None   # job: the id of the pending after() call

display = ttk.Label(root, text="05:00", font=("Helvetica", 56, "bold"))
display.pack(pady=(20, 4))
bar = ttk.Progressbar(root, maximum=START, value=START, length=300)  # time left
bar.pack()

def tick():  # runs once a second and books the next run itself
    global left, job
    left -= 1
    display.config(text=f"{left // 60:02d}:{left % 60:02d}")
    bar.config(value=left)
    job = root.after(1000, tick) if left > 0 else None

def toggle():  # after_cancel() removes the pending call: the clock stops
    global job
    if job:
        root.after_cancel(job)
        job = None
    else:
        job = root.after(1000, tick)
    button.config(text="Pause" if job else "Start")

button = ttk.Button(root, text="Pause", command=toggle)
button.pack(pady=16)
job = root.after(1000, tick)  # after(ms, function): call it once, later
root.mainloop()
