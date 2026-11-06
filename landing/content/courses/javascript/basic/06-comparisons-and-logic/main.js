// === compares value AND type; == converts types first (avoid it).
console.log('5 === 5:    ', 5 === 5);
console.log('5 === "5":  ', 5 === "5");
console.log('5 == "5":   ', 5 == "5");
console.log("0 == false: ", 0 == false, "| 0 === false:", 0 === false);
console.log('"apple" !== "Apple":', "apple" !== "Apple");

// Logical operators: && (and), || (or), ! (not)
const age = 16;
const withAdult = true;
console.log("Can enter the concert:", age >= 18 || withAdult);

const isMember = true;
const total = 80;
console.log("Gets the discount:", isMember && total >= 50);
console.log("Is not a member:", !isMember);

// Truthy and falsy: in an if, every value counts as true or false.
// Falsy: false, 0, "", null, undefined and NaN. Everything else is truthy.
const username = "";
if (username) {
  console.log(`Welcome, ${username}`);
} else {
  console.log("Please type your name");
}

// || gives the first truthy value: handy for defaults.
console.log("Name shown:", username || "Guest");
console.log("Boolean(0):", Boolean(0), "| Boolean('0'):", Boolean("0"));
