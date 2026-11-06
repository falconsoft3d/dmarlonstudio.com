// A Proxy wraps an object and intercepts operations through "traps".
function validated(target, rules) {
  return new Proxy(target, {
    set(obj, key, value, receiver) {
      if (rules[key] && !rules[key](value)) {
        throw new TypeError(`invalid ${key}: ${JSON.stringify(value)}`);
      }
      console.log(`set ${key} = ${JSON.stringify(value)}`);
      return Reflect.set(obj, key, value, receiver); // the normal assignment
    },
    get(obj, key, receiver) {
      return key in obj ? Reflect.get(obj, key, receiver) : `(no ${String(key)})`;
    },
    deleteProperty(obj, key) {
      if (key === "id") throw new Error("id cannot be deleted");
      return Reflect.deleteProperty(obj, key);
    },
  });
}

const user = validated({ id: 7 }, {
  email: (v) => typeof v === "string" && v.includes("@"),
  age: (v) => Number.isInteger(v) && v >= 18,
});
user.email = "ana@shop.es";
user.age = 34;
for (const attempt of [() => (user.age = 15), () => delete user.id]) {
  try { attempt(); } catch (err) { console.log(`${err.name}: ${err.message}`); }
}
console.log(user.email, user.age, user.phone);
console.log("Reflect.ownKeys:", Reflect.ownKeys(user).join(", "));
console.log("Has email?", Reflect.has(user, "email"), "| has phone?", "phone" in user);
