// A shopping list that changes as we go.
const list = ["bread", "milk", "eggs"];

list.push("cheese");        // add at the end
console.log("push:   ", list);
const last = list.pop();    // remove from the end
console.log("pop:    ", list, "removed", last);

list.unshift("coffee");     // add at the start
console.log("unshift:", list);
const first = list.shift(); // remove from the start
console.log("shift:  ", list, "removed", first);

// includes and indexOf: is it there, and where?
console.log("Has milk?", list.includes("milk"));
console.log("Position of eggs:", list.indexOf("eggs"));
console.log("Position of tea:", list.indexOf("tea")); // -1: not found

// slice copies a part and leaves the original as it was.
const queue = ["Ana", "Ben", "Carla", "David", "Eva"];
console.log("First three:", queue.slice(0, 3));
console.log("From the third on:", queue.slice(2));

// splice changes the original: it removes and/or inserts.
const removed = queue.splice(1, 2); // remove 2 from index 1
console.log("splice removed", removed, "->", queue);
queue.splice(1, 0, "Fran");         // insert at index 1, remove none
console.log("After inserting:", queue);
