const cart = {
  owner: "Ana",
  items: [12.5, 30, 7.25],
  total() {
    return this.items.reduce((sum, price) => sum + price, 0);
  },
  describe() {
    return `${this.owner} owes ${this.total().toFixed(2)} EUR`;
  },
  // An arrow function has no "this" of its own: it uses the method's one.
  labels() {
    return this.items.map((price) => `${this.owner}:${price}`);
  },
};
console.log(cart.describe());
console.log(cart.labels().join(" "));

// Losing "this": the method is called without its object.
const loose = cart.describe;
try { loose(); } catch (err) { console.log("Lost this:", err.message); }

// bind returns a new function with "this" fixed for good.
const bound = cart.describe.bind(cart);
console.log("bind:", bound());

// call and apply run the function now with the "this" you choose.
const otherCart = { owner: "Luis", items: [5, 5], total: cart.total };
console.log("call:", cart.describe.call(otherCart));
function withTax(rate, label) {
  return `${label}: ${(this.total() * (1 + rate)).toFixed(2)} EUR`;
}
console.log(withTax.call(cart, 0.21, "Ana with VAT"));
console.log(withTax.apply(otherCart, [0.1, "Luis with 10%"]));
