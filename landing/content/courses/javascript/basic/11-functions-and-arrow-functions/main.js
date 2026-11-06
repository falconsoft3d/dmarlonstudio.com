// A function declaration: a named block of code you can reuse.
function greet(name) {
  console.log(`Hello, ${name}! Welcome to the shop.`);
}
greet("Laura");
greet("Pedro");

// A function can calculate a value and return it.
function celsiusToFahrenheit(celsius) {
  return celsius * 9 / 5 + 32;
}
console.log("20 C =", celsiusToFahrenheit(20), "F");
console.log("-5 C =", celsiusToFahrenheit(-5), "F");

// Arrow functions: a shorter way to write a function.
const double = (n) => n * 2;
const isEven = (n) => n % 2 === 0;
console.log("double(21):", double(21), "| isEven(7):", isEven(7));

// With several lines, an arrow function needs { } and return.
const shippingCost = (total) => {
  if (total >= 50) return 0;
  return 4.95;
};
console.log("Shipping for 30 euros:", shippingCost(30));
console.log("Shipping for 75 euros:", shippingCost(75));

// Functions are values: you can pass them to other functions.
const applyTwice = (fn, value) => fn(fn(value));
console.log("applyTwice(double, 5):", applyTwice(double, 5));

// Declarations can be called before they appear in the file.
console.log("square(9):", square(9));
function square(n) { return n * n; }
