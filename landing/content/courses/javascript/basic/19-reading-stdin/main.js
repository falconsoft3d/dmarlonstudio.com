// Read everything typed on the keyboard (stdin) as one string.
const fs = require("fs");
const input = fs.readFileSync(0, "utf8");

// Split it into lines and drop the empty ones.
const lines = input.split("\n").map((l) => l.trim()).filter((l) => l !== "");
console.log(`Read ${lines.length} lines`);

// Each line has a name and a grade separated by a space.
const students = [];
for (const line of lines) {
  const [name, gradeText] = line.split(" ");
  const grade = Number(gradeText);
  if (Number.isNaN(grade)) {
    console.log(`Skipping "${line}": the grade is not a number`);
    continue;
  }
  students.push({ name, grade });
}

// A small report with what we have read.
for (const { name, grade } of students) {
  const result = grade >= 5 ? "passed" : "failed";
  console.log(`${name.padEnd(6)} ${grade.toFixed(2).padStart(5)}  ${result}`);
}
const sum = students.reduce((acc, s) => acc + s.grade, 0);
console.log("Class average:", (sum / students.length).toFixed(2));
