// An object groups related data as key: value pairs.
const book = {
  title: "Dune",
  author: "F. Herbert",
  year: 1965,
  available: true,
};
console.log(book);

// Read a property with a dot, or with brackets and a string.
const field = "year";
console.log("Title:", book.title, "| Year:", book[field]);

// Change, add and delete properties.
book.available = false;
book.pages = 412;
delete book.year;
console.log(book);
console.log("Has pages?", "pages" in book, "| Keys:", Object.keys(book));

// for...in goes through the keys of an object.
for (const key in book) {
  console.log(`  ${key}: ${book[key]}`);
}

// An array of objects: the usual way to keep records.
const students = [
  { name: "Lucia", grade: 8.5 },
  { name: "Mario", grade: 6 },
];
for (const s of students) console.log(`${s.name} got ${s.grade}`);
