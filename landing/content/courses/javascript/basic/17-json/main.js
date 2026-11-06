// An object in memory: a saved game.
const save = {
  player: "Nora",
  level: 7,
  inventory: ["sword", "potion"],
  settings: { music: true, volume: 8 },
};

// JSON.stringify turns it into text, ready to store or send.
const text = JSON.stringify(save);
console.log(text);
console.log("Type:", typeof text, "| Length:", text.length);

// With a third argument, the text is indented and easier to read.
console.log(JSON.stringify(save.settings, null, 2));

// JSON.parse turns the text back into an object: a separate copy.
const loaded = JSON.parse(text);
loaded.level += 1;
console.log(`${loaded.player} goes on to level ${loaded.level}`);
console.log("Second item:", loaded.inventory[1], "| Saved level:", save.level);

// Data from a server arrives as JSON text.
const reply = '{"city":"Madrid","temps":[21,24,19],"rain":null}';
const weather = JSON.parse(reply);
console.log(weather.city, "| Max:", Math.max(...weather.temps), "| Rain:", weather.rain);

// JSON has no undefined or functions: those keys are left out.
const item = { name: "pen", note: undefined, price: 1.5, show: () => 1 };
console.log(JSON.stringify(item));
