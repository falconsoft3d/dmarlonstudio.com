// IIFE: a function that runs at once and keeps its variables private.
const inventory = (function () {
  const items = new Map(); // nothing outside can reach this
  const log = (msg) => console.log(`[inventory] ${msg}`);
  return {
    add(name, qty) {
      items.set(name, (items.get(name) ?? 0) + qty);
      log(`+${qty} ${name}`);
    },
    count: (name) => items.get(name) ?? 0,
  };
})();

inventory.add("pens", 20);
inventory.add("pens", 5);
console.log("pens:", inventory.count("pens"), "| inventory.items:", inventory.items);

// Node wraps every CommonJS file in a function just like that one:
// (function (exports, require, module, __filename, __dirname) { ... })
console.log("Wrapper arguments:", arguments.length, "|", typeof require, typeof module);
console.log("exports === module.exports:", exports === module.exports);

// Whatever ends up in module.exports is what require() returns.
module.exports = { inventory, version: "1.2.0" };
console.log("Exported:", Object.keys(module.exports).join(", "));
console.log("exports still points to the old object:", exports !== module.exports);

// require() caches modules: a second call returns the same object.
const first = require("path");
const second = require("path");
console.log("Cached:", first === second, "| extname:", first.extname("orders.json"));
