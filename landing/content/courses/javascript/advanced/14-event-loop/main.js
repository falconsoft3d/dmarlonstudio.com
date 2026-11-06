// The numbers show the order Node guarantees, not the order in the file.
console.log("1. script starts (synchronous code)");

setTimeout(() => {
  console.log("8. timeout A (macrotask)");
  Promise.resolve().then(() => console.log("9. microtask created by timeout A"));
}, 0);
setTimeout(() => console.log("10. timeout B (macrotask)"), 0);

Promise.resolve().then(() => console.log("5. promise.then (microtask)"));
queueMicrotask(() => console.log("6. queueMicrotask (microtask)"));
process.nextTick(() => console.log("4. process.nextTick (before promises)"));

async function checkout() {
  console.log("2. checkout runs synchronously until its first await");
  await null;
  console.log("7. checkout resumes after await (microtask)");
}
checkout();

console.log("3. script ends: now the microtasks, then the timers");
