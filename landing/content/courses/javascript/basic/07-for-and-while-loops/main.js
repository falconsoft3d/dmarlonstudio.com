// for: start; condition; step. A multiplication table.
for (let i = 1; i <= 5; i++) {
  console.log(`7 x ${i} = ${7 * i}`);
}

// while repeats as long as the condition is true.
// 100 euros saved, +5% every year: how long until 130?
let savings = 100;
let years = 0;
while (savings < 130) {
  savings = savings * 1.05;
  years++;
}
console.log(`After ${years} years: ${savings.toFixed(2)} euros`);

// continue jumps to the next round; break leaves the loop.
for (let level = 1; level <= 10; level++) {
  if (level % 2 === 0) continue; // skip even levels
  if (level > 7) break;          // stop after level 7
  console.log("Playing level", level);
}

// A loop that builds a string step by step
let countdown = "";
for (let n = 5; n >= 1; n--) {
  countdown += n + " ";
}
console.log(countdown + "Lift-off!");
