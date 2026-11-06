// const: a value that will not change. let: a value that can change.
const shopName = "Corner Bakery";
let loavesLeft = 40;
console.log(shopName, "opens with", loavesLeft, "loaves");

loavesLeft = loavesLeft - 12; // let accepts a new value
console.log("After the morning rush:", loavesLeft);

// typeof tells you the type of any value.
const price = 1.25;
const isOpen = true;
let nextDelivery; // declared, but without a value yet
const closedDay = null;

console.log(typeof shopName);  // string
console.log(typeof price);     // number
console.log(typeof isOpen);    // boolean
console.log(typeof nextDelivery, nextDelivery);
console.log(typeof closedDay); // "object": an old quirk of the language

// The type belongs to the value, not to the variable.
let label = 42;
console.log(typeof label);
label = "forty-two";
console.log(typeof label);

// Giving a const a new value is an error (remove the // to see it):
// shopName = "New Bakery";
