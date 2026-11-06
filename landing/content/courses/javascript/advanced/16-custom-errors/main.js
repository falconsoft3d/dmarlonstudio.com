class AppError extends Error {
  constructor(message, options) {
    super(message, options); // options can carry { cause }
    this.name = this.constructor.name; // "ValidationError", "PaymentError"...
  }
}
class ValidationError extends AppError {
  constructor(field, message) {
    super(message);
    this.field = field;
  }
}
class PaymentError extends AppError {}

function charge(order) {
  if (!order.email) throw new ValidationError("email", "an email is required");
  if (order.amount > 500) {
    throw new PaymentError(`order ${order.id} declined`, { cause: new Error("card limit is 500 EUR") });
  }
  return `Order ${order.id} paid: ${order.amount} EUR`;
}

const orders = [{ id: 1, email: "ana@shop.test", amount: 80 }, { id: 2, amount: 20 }, { id: 3, email: "luis@shop.test", amount: 900 }];
for (const order of orders) {
  try {
    console.log(charge(order));
  } catch (err) {
    if (err instanceof ValidationError) console.log(`${err.name} in "${err.field}": ${err.message}`);
    else if (err instanceof PaymentError) console.log(`${err.name}: ${err.message} (${err.cause.message})`);
    else throw err; // unknown errors keep travelling up
  } finally {
    console.log(`  order ${order.id} closed`); // runs whether it failed or not
  }
}
