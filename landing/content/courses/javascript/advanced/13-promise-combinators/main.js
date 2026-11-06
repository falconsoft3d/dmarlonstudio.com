// A fake service that answers (or fails) after a fixed delay in ms.
function service(name, ms, ok = true) {
  return new Promise((resolve, reject) =>
    setTimeout(() => (ok ? resolve(`${name} ${ms}ms`) : reject(new Error(`${name} failed`))), ms)
  );
}

async function main() {
  // all: waits for every promise; results keep the order of the array.
  const page = await Promise.all([service("prices", 60), service("stock", 20), service("reviews", 40)]);
  console.log("all:", page.join(" | "));

  // all rejects as soon as one of the promises rejects.
  try {
    await Promise.all([service("prices", 30), service("payments", 10, false)]);
  } catch (err) {
    console.log("all rejected:", err.message);
  }

  // allSettled: never rejects; it reports the outcome of each one.
  const sent = await Promise.allSettled([service("email", 20), service("sms", 10, false)]);
  for (const r of sent) console.log("allSettled:", r.status, "-", r.value ?? r.reason.message);

  // race: the first promise to settle wins, fulfilled or rejected.
  const fastest = await Promise.race([service("mirror-eu", 50), service("mirror-us", 15)]);
  console.log("race winner:", fastest);

  // any: the first one to fulfil wins; failures are ignored.
  const firstOk = await Promise.any([service("cache", 5, false), service("database", 25)]);
  console.log("any:", firstOk);
}
main();
