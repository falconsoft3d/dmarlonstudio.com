const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const users = { 1: { name: "Ana", cartId: 10 }, 2: { name: "Luis", cartId: 20 } };
const carts = { 10: [{ item: "Book", price: 15 }, { item: "Lamp", price: 32 }] };

async function getUser(id) {
  await delay(20); // pretend this is a database query
  if (!users[id]) throw new Error(`user ${id} not found`);
  return users[id];
}
async function getCart(cartId) {
  await delay(20);
  return carts[cartId] ?? [];
}

// await pauses this function (not the whole program) until the promise settles.
async function cartSummary(userId) {
  try {
    const user = await getUser(userId);
    const cart = await getCart(user.cartId);
    const total = cart.reduce((sum, line) => sum + line.price, 0);
    return `${user.name}: ${cart.length} items, ${total} EUR`;
  } catch (err) {
    return `Error: ${err.message}`; // a rejected await lands in catch
  }
}

async function main() {
  const pending = cartSummary(1);
  console.log("An async function returns:", pending.constructor.name);
  console.log(await pending);
  for (const id of [2, 3]) console.log(await cartSummary(id));
  console.log("Done");
}
main();
