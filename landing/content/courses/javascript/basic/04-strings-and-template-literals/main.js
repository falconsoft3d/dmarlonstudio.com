const product = "Running shoes";
const price = 59.9;
const quantity = 2;

// Joining strings with +
console.log("Product: " + product);

// Template literals: backticks and ${...} for any expression
console.log(`${quantity} x ${product} = ${price * quantity} euros`);

// Length and single characters (positions start at 0)
console.log(`"${product}" has ${product.length} characters`);
console.log("First letter:", product[0], "| Last:", product[product.length - 1]);

// Upper and lower case
console.log(product.toUpperCase());
console.log(product.toLowerCase());

// Searching inside a string
console.log("Contains 'shoes'?", product.includes("shoes"));
console.log("Starts with 'Run'?", product.startsWith("Run"));

// Template literals can span several lines
const receipt = `--- Receipt ---
Item:  ${product}
Total: ${(price * quantity).toFixed(2)} euros`;
console.log(receipt);
