const products = [
  { name: "Keyboard", price: 45, stock: 12 },
  { name: "Mouse", price: 20, stock: 0 },
  { name: "Monitor", price: 180, stock: 4 },
  { name: "Webcam", price: 60, stock: 0 },
  { name: "Headset", price: 75, stock: 7 },
];

// forEach runs a function for every element (and returns nothing).
products.forEach((p, i) => {
  console.log(`${i + 1}. ${p.name} - ${p.price} euros`);
});

// map builds a NEW array with one result per element.
const names = products.map((p) => p.name);
console.log("Names:", names);
const withVat = products.map((p) => (p.price * 1.21).toFixed(2));
console.log("With VAT:", withVat);

// filter keeps only the elements for which the function returns true.
const inStock = products.filter((p) => p.stock > 0);
console.log("In stock:", inStock.map((p) => p.name));
const cheap = products.filter((p) => p.price < 50);
console.log("Under 50 euros:", cheap.length, "products");

// Chaining: filter first, then map. The original stays the same.
const sale = products
  .filter((p) => p.stock > 0 && p.price > 50)
  .map((p) => `${p.name} at ${p.price * 0.9}`);
console.log("On sale (-10%):", sale);
console.log("The original still has", products.length, "products");
