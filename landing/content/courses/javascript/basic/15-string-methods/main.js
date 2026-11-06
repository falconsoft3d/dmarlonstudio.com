// Text typed by people is often messy.
const raw = "   Margarita, Pepperoni , Four Cheese,Hawaiian  ";

// trim removes the spaces at both ends.
const clean = raw.trim();
console.log(`[${clean}]`);

// split cuts a string into an array; join glues an array back.
const pizzas = clean.split(",").map((p) => p.trim());
console.log(pizzas);
console.log(pizzas.join(" | "));

// replace changes the first match; replaceAll changes all of them.
const notice = "Today: Margarita. Margarita for 8 euros.";
console.log(notice.replace("Margarita", "Hawaiian"));
console.log(notice.replaceAll("Margarita", "Pepperoni"));

// padEnd and padStart fill up to a length: perfect for columns.
const menu = [["Margarita", 8], ["Pepperoni", 9.5], ["Four Cheese", 11]];
for (const item of menu) {
  console.log(item[0].padEnd(14, ".") + item[1].toFixed(2).padStart(7));
}
console.log("Order number", String(42).padStart(5, "0"));

// slice, indexOf and repeat
const code = "ORD-00042-PIZZA";
const dash = code.indexOf("-");
console.log("Prefix:", code.slice(0, dash), "| Type:", code.slice(code.lastIndexOf("-") + 1));
console.log("=".repeat(21));
