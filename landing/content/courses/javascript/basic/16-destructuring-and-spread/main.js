// Array destructuring: take the values out by position.
const podium = ["Lewis", "Max", "Charles", "Lando", "Oscar"];
const [gold, silver, bronze, ...rest] = podium;
console.log(`Gold: ${gold}, silver: ${silver}, bronze: ${bronze}`);
console.log("The rest:", rest);

// Swap two variables without a temporary one.
let home = 2;
let away = 3;
[home, away] = [away, home];
console.log("Swapped score:", home, "-", away);

// Object destructuring: take the values out by name.
const player = { name: "Nora", level: 12, coins: 340 };
const { name, level, lives = 3 } = player; // lives gets a default
console.log(`${name} is on level ${level} with ${lives} lives`);

// Destructuring in parameters and in for...of
const describe = ({ name, coins }) => `${name} has ${coins} coins`;
console.log(describe(player));
for (const [item, qty] of Object.entries({ swords: 2, potions: 5 })) {
  console.log(`  ${item}: ${qty}`);
}

// Spread (...) unpacks arrays and objects to copy or combine them.
const weekA = [12, 15];
const weekB = [9, 20];
const scores = [...weekA, ...weekB, 30];
console.log("All scores:", scores, "| Best:", Math.max(...scores));

const upgraded = { ...player, level: 13, coins: player.coins + 50 };
console.log("Before:", player);
console.log("After: ", upgraded);
