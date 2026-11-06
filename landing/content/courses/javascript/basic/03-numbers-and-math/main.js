// Whole numbers and decimals are all of type "number".
const width = 4.5; // metres
const length = 3.2;
const area = width * length;
console.log("Area:", area, "m2");
console.log("Rounded:", Math.round(area), "| Two decimals:", area.toFixed(2));

// Division, whole part and remainder
const eggs = 27;
console.log("27 / 12 =", eggs / 12);
console.log("Full boxes of 12:", Math.floor(eggs / 12));
console.log("Eggs left over:", eggs % 12);

// Powers and roots
console.log("2 to the 10th:", 2 ** 10, "| Square root of 144:", Math.sqrt(144));

// Highest, lowest, rounding up
console.log("Warmest day:", Math.max(14, 19, 23, 17, 9));
console.log("Coldest day:", Math.min(14, 19, 23, 17, 9));
console.log("Buses for 130 people (55 seats):", Math.ceil(130 / 55));

// Decimals are not always exact in binary:
console.log(0.1 + 0.2, "->", (0.1 + 0.2).toFixed(2));

// From text to number
console.log(Number("42") + 8, "| parseInt:", parseInt("15 kg"), "| Not a number:", Number("abc"));
