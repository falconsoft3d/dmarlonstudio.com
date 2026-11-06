class Account {
  constructor(owner, balance = 0) {
    this.owner = owner;
    this.balance = balance;
  }
  deposit(amount) {
    this.balance += amount;
    return this; // returning this allows chaining
  }
  toString() {
    return `${this.owner}: ${this.balance.toFixed(2)} EUR`;
  }
}

// SavingsAccount inherits everything from Account and adds interest.
class SavingsAccount extends Account {
  constructor(owner, balance, rate) {
    super(owner, balance); // runs Account's constructor first
    this.rate = rate;
  }
  addInterest() {
    return this.deposit(this.balance * this.rate);
  }
  toString() {
    return `${super.toString()} (savings at ${this.rate * 100}%)`;
  }
}

const current = new Account("Ana").deposit(150).deposit(50);
const savings = new SavingsAccount("Luis", 1000, 0.02).addInterest();
console.log(String(current));
console.log(String(savings));
console.log("Is savings an Account?", savings instanceof Account);
console.log("A class is a", typeof SavingsAccount);
