// pipe and compose take functions and return a new function.
const pipe = (...fns) => (x) => fns.reduce((acc, fn) => fn(acc), x);
const compose = (...fns) => (x) => fns.reduceRight((acc, fn) => fn(acc), x);

// Small single-purpose steps for cleaning a username.
const trim = (s) => s.trim();
const lower = (s) => s.toLowerCase();
const dots = (s) => s.split(" ").join(".");
const cleanUsername = pipe(trim, lower, dots);
console.log(cleanUsername("  Ana Maria Ruiz "));

// compose reads right to left: the last function runs first.
const shout = compose((s) => s + "!", (s) => s.toUpperCase());
console.log(shout("order shipped"));

// A function that wraps another one to add logging.
function withLog(name, fn) {
  return (...args) => {
    const result = fn(...args);
    console.log(`  ${name}(${args.join(", ")}) = ${result}`);
    return result;
  };
}
const addVat = withLog("addVat", (net) => +(net * 1.21).toFixed(2));
const coupon = withLog("coupon", (price) => price - 5);
console.log("Checkout:", pipe(addVat, coupon)(100));

// Functions as data: a list of rules combined into one test.
const every = (...rules) => (item) => rules.every((rule) => rule(item));
const freeShipping = every((o) => o.total > 50, (o) => o.country === "ES");
const orders = [{ id: 1, total: 80, country: "ES" }, { id: 2, total: 30, country: "ES" }, { id: 3, total: 90, country: "FR" }];
console.log("Free shipping:", orders.filter(freeShipping).map((o) => `#${o.id}`).join(", "));
