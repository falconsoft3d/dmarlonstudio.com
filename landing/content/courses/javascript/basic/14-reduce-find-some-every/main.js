const orders = [
  { id: 101, customer: "Ana", total: 35.5, paid: true },
  { id: 102, customer: "Luis", total: 120, paid: true },
  { id: 103, customer: "Marta", total: 64.25, paid: false },
  { id: 104, customer: "Ana", total: 18, paid: true },
];

// reduce combines all the elements into one value: here, a sum.
const revenue = orders.reduce((sum, o) => sum + o.total, 0);
console.log("Total of all orders:", revenue);

// The starting value can be anything, such as an object to group.
const perCustomer = orders.reduce((acc, o) => {
  acc[o.customer] = (acc[o.customer] || 0) + o.total;
  return acc;
}, {});
console.log("Per customer:", perCustomer);

// Without a starting value, reduce begins with the first element.
const biggest = orders.reduce((best, o) => (o.total > best.total ? o : best));
console.log("Biggest order:", biggest.id, "by", biggest.customer);

// find returns the FIRST element that matches (or undefined).
const unpaid = orders.find((o) => !o.paid);
console.log("First unpaid:", unpaid.id, unpaid.customer);
console.log("Order 999:", orders.find((o) => o.id === 999));
console.log("Position of 103:", orders.findIndex((o) => o.id === 103));

// some: is there at least one? every: are all of them?
console.log("Any order over 100?", orders.some((o) => o.total > 100));
console.log("All paid?", orders.every((o) => o.paid));
