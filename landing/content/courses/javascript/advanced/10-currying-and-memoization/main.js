// Currying: one function per argument, each returning the next one.
const price = (vat) => (discount) => (net) => +(net * (1 - discount) * (1 + vat)).toFixed(2);
const spain = price(0.21);
const spainSale = spain(0.1);
console.log("Sale prices:", spainSale(100), spainSale(250), "| full price:", spain(0)(100));

// A generic curry helper: waits until it has every parameter.
function curry(fn) {
  return function curried(...args) {
    return args.length >= fn.length ? fn(...args) : (...more) => curried(...args, ...more);
  };
}
const shipping = curry((zone, kilos, express) => (zone === "EU" ? 5 : 12) + kilos * 2 + (express ? 10 : 0));
const toEurope = shipping("EU");
console.log("EU 3 kg express:", toEurope(3)(true), "| EU 1 kg:", toEurope(1, false));
console.log("World 2 kg:", shipping("World", 2, false));

// Memoization: remember each result so it is computed only once.
function memoize(fn) {
  const cache = new Map();
  return (n) => {
    if (!cache.has(n)) cache.set(n, fn(n));
    return cache.get(n);
  };
}
let calls = 0;
const slowFib = (n) => (calls++, n < 2 ? n : slowFib(n - 1) + slowFib(n - 2));
console.log("fib(25) =", slowFib(25), "in", calls, "calls");

calls = 0;
const fastFib = memoize((n) => (calls++, n < 2 ? n : fastFib(n - 1) + fastFib(n - 2)));
console.log("fib(25) =", fastFib(25), "in", calls, "calls (memoized)");
console.log("fib(25) again:", fastFib(25), "- still", calls, "calls");
