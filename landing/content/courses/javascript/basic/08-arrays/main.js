// An array is an ordered list inside [ ].
const fruits = ["apple", "banana", "cherry", "mango"];
console.log(fruits);
console.log("How many:", fruits.length);

// Positions (indexes) start at 0.
console.log("First:", fruits[0], "| Last:", fruits[fruits.length - 1]);
console.log("Position 10:", fruits[10]);

// Change an element through its index.
fruits[1] = "kiwi";
console.log("After the change:", fruits);

// An array of numbers: one week of temperatures.
const temps = [18, 21, 19, 24, 26, 22, 17];
let sum = 0;
for (let i = 0; i < temps.length; i++) {
  sum += temps[i];
}
console.log("Average temperature:", (sum / temps.length).toFixed(1));

// for...of goes through the values directly, without indexes.
let warmDays = 0;
for (const t of temps) {
  if (t >= 22) warmDays++;
}
console.log("Days at 22 or more:", warmDays);

// An array of arrays: a noughts and crosses board.
const board = [["X", "O", "X"], [" ", "X", "O"], ["O", " ", "X"]];
console.log("Centre square:", board[1][1]);
for (const row of board) console.log(row);
