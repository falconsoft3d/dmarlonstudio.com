const orders = [
  { id: 1, customer: "Ana", product: "Laptop" },
  { id: 2, customer: "Luis", product: "Mouse" },
  { id: 3, customer: "Ana", product: "Mouse" },
  { id: 4, customer: "Marta", product: "Keyboard" },
];

// Set: a collection of unique values.
const products = new Set(orders.map((o) => o.product));
console.log("Products:", [...products].join(", "), `(${products.size})`);
console.log("Do we sell monitors?", products.has("Monitor"));

// Map: keys of any type, kept in insertion order.
const byCustomer = new Map();
for (const o of orders) {
  const ids = byCustomer.get(o.customer) ?? [];
  byCustomer.set(o.customer, [...ids, o.id]);
}
for (const [customer, ids] of byCustomer) console.log(customer, "->", ids.join(", "));

// Objects as keys: a Map compares them by identity, not by content.
const status = new Map([[orders[0], "shipped"]]);
console.log("Order 1:", status.get(orders[0]), "| copy:", status.get({ ...orders[0] }));

// WeakMap: extra data per object that does not keep the object alive.
const visits = new WeakMap();
function visit(user) {
  visits.set(user, (visits.get(user) ?? 0) + 1);
  return visits.get(user);
}
const ana = { name: "Ana" };
visit(ana);
visit(ana);
console.log(ana.name, "visits:", visit(ana), "| stored on the object?", "visits" in ana);
