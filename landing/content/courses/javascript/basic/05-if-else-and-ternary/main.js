// if runs a block only when its condition is true.
const grade = 7.5;
if (grade >= 5) {
  console.log(`Grade ${grade}: passed`);
} else {
  console.log(`Grade ${grade}: failed`);
}

// else if checks conditions in order; the first true one wins.
const temperature = 12;
if (temperature >= 30) {
  console.log("Hot: drink plenty of water");
} else if (temperature >= 18) {
  console.log("Mild: perfect for a walk");
} else if (temperature >= 5) {
  console.log("Cool: take a jacket");
} else {
  console.log("Cold: better stay indoors");
}

// The ternary operator: condition ? valueIfTrue : valueIfFalse
const basketTotal = 42;
const shipping = basketTotal >= 50 ? 0 : 4.95;
console.log(`Basket: ${basketTotal} euros | Shipping: ${shipping} euros`);

const items = 1;
console.log(`${items} ${items === 1 ? "item" : "items"} in the basket`);

const lives = 0;
console.log(lives > 0 ? "Keep playing" : "Game over");
