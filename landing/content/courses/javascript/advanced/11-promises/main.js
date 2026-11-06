const stock = { laptop: 3, mouse: 0 };

// A promise stands for a result that arrives later.
function checkStock(product) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (!(product in stock)) reject(new Error(`Unknown product: ${product}`));
      else if (stock[product] === 0) reject(new Error(`${product} is out of stock`));
      else resolve({ product, units: stock[product] });
    }, 50); // pretend the warehouse takes 50 ms to answer
  });
}

console.log("1. Asking the warehouse...");

checkStock("laptop")
  .then((info) => {
    console.log(`3. ${info.units} units of ${info.product}`);
    return info.units * 899; // the next then receives this value
  })
  .then((value) => {
    console.log(`4. Stock value: ${value} EUR`);
    return checkStock("mouse"); // returning a promise: the chain waits for it
  })
  .then(() => console.log("This line is skipped"))
  .catch((err) => console.log("5. Error:", err.message))
  .finally(() => console.log("6. Request closed"));

console.log("2. This line runs before the answer arrives");
