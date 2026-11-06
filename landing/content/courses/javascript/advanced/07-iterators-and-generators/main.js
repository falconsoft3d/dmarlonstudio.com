// A generator pauses at each yield and resumes on the next call to next().
function* invoiceNumbers(prefix, start) {
  for (let n = start; ; n++) {
    yield `${prefix}-${String(n).padStart(4, "0")}`;
  }
}
const numbers = invoiceNumbers("INV", 7);
console.log(numbers.next().value);
console.log(numbers.next().value);
console.log(numbers.next());

// Any object with [Symbol.iterator] works with for...of and spread.
class Playlist {
  constructor(...songs) {
    this.songs = songs;
  }
  *[Symbol.iterator]() {
    for (const song of this.songs) yield song.toUpperCase();
  }
}
const party = new Playlist("intro", "hit single", "encore");
for (const song of party) console.log("Playing", song);
console.log([...party].length, "songs in the playlist");

// A hand-written iterator: an object whose next() returns { value, done }.
function countdown(from) {
  let current = from;
  return {
    [Symbol.iterator]() { return this; },
    next: () => (current > 0 ? { value: current--, done: false } : { value: undefined, done: true }),
  };
}
console.log("Launch in", [...countdown(3)].join(", "));
