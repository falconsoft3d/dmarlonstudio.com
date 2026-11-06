const log = [
  "2024-03-01 10:15:02 INFO  user=ana order=A-1001 total=59.90",
  "2024-03-01 10:16:45 ERROR user=luis order=A-1002 payment declined",
  "2024-03-01 10:20:11 INFO  user=marta order=B-2001 total=120.00",
];

// Named groups (?<name>...) pick out each part of a line.
const lineRe = /^(?<date>\d{4}-\d{2}-\d{2}) (?<time>[\d:]+) (?<level>[A-Z]+)\s+user=(?<user>\w+)/;
for (const line of log) {
  const { time, level, user } = line.match(lineRe).groups;
  console.log(`${time} ${level.padEnd(5)} ${user}`);
}

// test() answers yes or no; the i flag ignores upper and lower case.
console.log("Any errors?", log.some((line) => /error/i.test(line)));

// The g flag with matchAll finds every match, with its groups.
const ids = [...log.join("\n").matchAll(/order=([A-Z]-\d+)/g)].map((m) => m[1]);
console.log("Orders:", ids.join(", "));

// replace() with a function builds each replacement.
console.log(log[1].replace(/user=(\w)\w*/, (whole, first) => `user=${first}***`));

// Validating input: ^ and $ make the whole text match.
const email = /^[\w.+-]+@[\w-]+\.[a-z]{2,}$/i;
for (const value of ["ana@shop.es", "luis@shop", "marta.r+news@mail.com"]) {
  console.log(value.padEnd(22), email.test(value) ? "valid" : "invalid");
}
