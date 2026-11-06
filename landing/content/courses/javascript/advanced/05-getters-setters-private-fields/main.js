class Product {
  #price = 0; // private: only code inside the class can touch it
  #changes = 0;

  constructor(name, price) {
    this.name = name;
    this.price = price; // goes through the setter below
  }
  get price() {
    return this.#price;
  }
  set price(value) {
    if (typeof value !== "number" || value < 0) {
      throw new RangeError(`Invalid price for ${this.name}: ${value}`);
    }
    this.#price = value;
    this.#changes++;
  }
  get priceWithVat() {
    return +(this.#price * 1.21).toFixed(2);
  }
  get changes() {
    return this.#changes;
  }
}

const mouse = new Product("Mouse", 20);
mouse.price = 18;
console.log(mouse.name, mouse.price, "->", mouse.priceWithVat, "with VAT");
try { mouse.price = -3; } catch (err) { console.log(`${err.name}: ${err.message}`); }
console.log("Price is still", mouse.price, "after", mouse.changes, "changes");
mouse.priceWithVat = 1; // a getter without a setter ignores assignments
console.log("With VAT:", mouse.priceWithVat, "| keys:", Object.keys(mouse).join(", "));
console.log("From outside:", mouse["#price"]);
