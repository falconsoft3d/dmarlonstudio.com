const EventEmitter = require("events");

// A class that extends EventEmitter can announce what happens inside it.
class Shop extends EventEmitter {
  constructor(stock) {
    super();
    this.stock = stock;
  }
  buy(customer, item) {
    if (!this.stock[item]) return this.emit("soldout", item, customer);
    this.stock[item] -= 1;
    this.emit("order", { customer, item, left: this.stock[item] });
  }
}

const shop = new Shop({ mug: 2 });
shop.on("order", (o) => console.log(`Order: ${o.customer} bought a ${o.item}`));
shop.on("order", (o) => o.left === 0 && console.log(`  warehouse: restock ${o.item}`));
shop.once("order", () => console.log("  first order of the day!"));
shop.on("soldout", (item, who) => console.log(`Sorry ${who}, the ${item} is sold out`));

shop.buy("Ana", "mug");
shop.buy("Luis", "mug");
shop.buy("Marta", "mug");
console.log("Listeners for order:", shop.listenerCount("order"));

// "error" is special: emitting it with no listener throws.
try {
  shop.emit("error", new Error("payment gateway down"));
} catch (err) {
  console.log("Nobody listened:", err.message);
}
shop.on("error", (err) => console.log("Logged:", err.message));
shop.emit("error", new Error("payment gateway down"));
