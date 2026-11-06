const product = {
  describe() {
    return `${this.name} - ${this.price.toFixed(2)} EUR`;
  },
};

// laptop's prototype is product, so it inherits describe().
const laptop = Object.create(product);
laptop.name = "Laptop";
laptop.price = 899;
console.log(laptop.describe());
console.log("Own describe?", Object.hasOwn(laptop, "describe"));
console.log("Prototype is product?", Object.getPrototypeOf(laptop) === product);

// Constructor functions share methods through .prototype.
function User(name, role) {
  this.name = name;
  this.role = role;
}
User.prototype.greet = function () {
  return `Hi, I am ${this.name} (${this.role})`;
};
const ana = new User("Ana", "admin");
const luis = new User("Luis", "editor");
console.log(ana.greet());
console.log("Same function in both?", ana.greet === luis.greet);
luis.greet = () => "Luis says hello his own way"; // own property shadows the prototype
console.log(luis.greet(), "|", ana.greet());

// The chain ends in Object.prototype, then null.
const names = new Map([[User.prototype, "User.prototype"], [Object.prototype, "Object.prototype"]]);
const chain = [];
for (let p = Object.getPrototypeOf(ana); p; p = Object.getPrototypeOf(p)) chain.push(names.get(p));
console.log("ana ->", chain.join(" -> "), "-> null");
