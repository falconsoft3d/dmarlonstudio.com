// Default values are used when an argument is missing.
function orderCoffee(size = "medium", sugar = 1) {
  return `${size} coffee with ${sugar} sugar`;
}
console.log(orderCoffee("large", 2));
console.log(orderCoffee("small"));
console.log(orderCoffee());

// return ends the function at once: useful to stop early.
function finalPrice(price, discountPercent = 0) {
  if (price < 0) return "invalid price";
  const discount = price * discountPercent / 100;
  return price - discount;
}
console.log(finalPrice(80, 25), "|", finalPrice(80), "|", finalPrice(-5, 10));

// Without return, a function gives back undefined.
function showScore(points) {
  console.log("Score:", points);
}
console.log("showScore returned:", showScore(120));

// Rest parameters (...) collect any number of arguments in an array.
function average(...grades) {
  let sum = 0;
  for (const g of grades) sum += g;
  return grades.length > 0 ? sum / grades.length : 0;
}
console.log("Average:", average(6, 7.5, 9), "| Of nothing:", average());

// To give back several values, return an object.
const stats = (a, b) => ({ total: a + b, difference: a - b });
console.log(stats(30, 12));
