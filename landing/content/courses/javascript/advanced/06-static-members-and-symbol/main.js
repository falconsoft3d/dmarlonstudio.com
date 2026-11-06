class Order {
  static #nextId = 1; // belongs to the class, shared by all orders
  static TAX = 0.21;
  static fromLine(line) { // static factory: Order.fromLine("Ana;100")
    const [customer, amount] = line.split(";");
    return new Order(customer, Number(amount));
  }
  constructor(customer, amount) {
    this.id = Order.#nextId++;
    this.customer = customer;
    this.amount = amount;
  }
  // Well-known symbols change how the language treats the object.
  get [Symbol.toStringTag]() {
    return "Order";
  }
  [Symbol.toPrimitive](hint) {
    if (hint === "number") return this.amount * (1 + Order.TAX);
    return `Order #${this.id} for ${this.customer}`;
  }
}

const orders = ["Ana;100", "Luis;40", "Marta;250"].map((line) => Order.fromLine(line));
console.log(`${orders[0]} | ${orders[2]}`);
console.log("Total with tax:", orders.reduce((sum, o) => sum + Number(o), 0).toFixed(2));
console.log(Object.prototype.toString.call(orders[1]), "| TAX:", Order.TAX);

// A Symbol is a unique key: it never clashes with other properties.
const internal = Symbol("internal");
orders[2][internal] = "priority";
console.log("Keys:", Object.keys(orders[2]).join(", "));
console.log("Symbol value:", orders[2][internal]);
console.log("Unique:", Symbol("id") === Symbol("id"), "| registry:", Symbol.for("id") === Symbol.for("id"));
