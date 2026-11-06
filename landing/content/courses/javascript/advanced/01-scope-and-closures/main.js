// Each call to createCounter gets its own private "count".
function createCounter(label) {
  let count = 0; // lives on inside the closure
  return function next() {
    count += 1;
    return `${label} #${count}`;
  };
}

const nextOrder = createCounter("Order");
const nextInvoice = createCounter("Invoice");
console.log(nextOrder());
console.log(nextOrder());
console.log(nextInvoice());
console.log(nextOrder());

// Block scope: let creates a new binding on every loop turn.
const tasks = [];
for (let i = 1; i <= 3; i++) {
  tasks.push(() => `task ${i}`);
}
console.log(tasks.map((run) => run()).join(", "));

// A closure can also keep settings, such as a discount rate.
function makeDiscount(rate) {
  return (price) => +(price * (1 - rate)).toFixed(2);
}
const blackFriday = makeDiscount(0.3);
console.log("Black Friday price:", blackFriday(49.9));
console.log("Is count visible here?", typeof count);
