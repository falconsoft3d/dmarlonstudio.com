// Some mistakes stop the program: try/catch captures them.
const user = null;
try {
  console.log(user.name); // reading a property of null fails
} catch (error) {
  console.log("Caught:", error.name, "-", error.message);
}

function safeParse(text) {
  try {
    return JSON.parse(text); // throws if the text is not valid JSON
  } catch (error) {
    console.log(`Not valid JSON: ${text}`);
    return null;
  } finally {
    console.log("  (finally always runs)");
  }
}
console.log(safeParse('{"stock": 5}'));
console.log(safeParse("{stock: 5}"));

// throw raises your own error when the data is wrong.
function withdraw(balance, amount) {
  if (amount <= 0) throw new Error("the amount must be positive");
  if (amount > balance) throw new RangeError(`only ${balance} euros left`);
  return balance - amount;
}
for (const amount of [30, -10, 500]) {
  try {
    console.log(`Withdraw ${amount}: balance ${withdraw(100, amount)}`);
  } catch (error) {
    console.log(`Withdraw ${amount} failed: ${error.message} (${error.name})`);
  }
}
