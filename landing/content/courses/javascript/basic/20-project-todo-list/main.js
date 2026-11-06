// A small to-do list driven by text commands.
const commands = ["add Buy milk", "add Call the dentist", "add Water the plants",
  "done 1", "remove 2", "done 7", "add Finish the JavaScript course", "jump 3"];

const tasks = [];
let nextId = 1;

function run(line) {
  const [command, ...words] = line.split(" ");
  const text = words.join(" ");
  if (command === "add") {
    tasks.push({ id: nextId, title: text, done: false });
    return `added #${nextId++} "${text}"`;
  }
  const task = tasks.find((t) => t.id === Number(text));
  if (!task) throw new Error(`there is no task #${text}`);
  if (command === "done") task.done = true;
  else if (command === "remove") tasks.splice(tasks.indexOf(task), 1);
  else throw new Error(`unknown command "${command}"`);
  return `${command} #${task.id}`;
}

for (const line of commands) {
  try { console.log("ok   ", run(line)); }
  catch (error) { console.log("error", error.message); }
}

for (const { id, title, done } of tasks) {
  console.log(`${done ? "[x]" : "[ ]"} ${String(id).padStart(2)}  ${title}`);
}
const pending = tasks.filter((t) => !t.done).length;
console.log(`${tasks.length} tasks, ${pending} pending`);
console.log("Saved as JSON:", JSON.stringify(tasks).length, "characters");
