const EventEmitter = require("events");
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// An order queue: private state, events and asynchronous work in one class.
class OrderQueue extends EventEmitter {
  #pending = [];
  #stock;
  constructor(stock) { super(); this.#stock = { ...stock }; }
  add(order) {
    this.#pending.push(order);
    this.emit("queued", order);
  }
  async run() {
    let revenue = 0;
    while (this.#pending.length > 0) {
      const order = this.#pending.shift();
      await delay(10 * order.qty); // pretend to pack the parcel
      const have = this.#stock[order.item] ?? 0;
      if (have < order.qty) { this.emit("failed", order, `only ${have} ${order.item} left`); continue; }
      this.#stock[order.item] = have - order.qty;
      revenue += order.qty * order.price;
      this.emit("packed", order);
    }
    this.emit("idle", revenue, this.#stock);
  }
}

const queue = new OrderQueue({ book: 5, lamp: 1 });
queue.on("queued", (o) => console.log(`queued #${o.id}: ${o.qty} x ${o.item}`));
queue.on("packed", (o) => console.log(`packed #${o.id}`));
queue.on("failed", (o, reason) => console.log(`failed #${o.id}: ${reason}`));
queue.on("idle", (total, stock) => console.log(`idle: ${total} EUR, stock ${JSON.stringify(stock)}`));
[["book", 2, 15], ["lamp", 2, 40], ["book", 3, 15]].forEach(([item, qty, price], i) => queue.add({ id: i + 1, item, qty, price }));
queue.run().then(() => console.log("All orders processed"));
