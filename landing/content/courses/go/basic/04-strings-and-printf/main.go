package main

import "fmt"

func main() {
	product := "Coffee"
	price := 3.5
	units := 4

	// + joins strings; len counts their bytes.
	label := product + " beans"
	fmt.Println(label, "has", len(label), "characters")

	// Printf fills each verb with a value, in order.
	fmt.Printf("%s costs %.2f euros\n", product, price)
	fmt.Printf("%d units: %.2f euros\n", units, price*float64(units))

	// %v prints any value; %q adds quotes.
	fmt.Printf("%v | %v | %q\n", units, price, product)

	// A width lines up columns: %-8s to the left, %6.2f to the right.
	fmt.Printf("%-8s|%6.2f|\n", "Tea", 2.25)
	fmt.Printf("%-8s|%6.2f|\n", "Cocoa", 12.4)
	fmt.Printf("%-8s|%6d|\n", "Units", units)

	// Sprintf returns the text instead of printing it.
	receipt := fmt.Sprintf("%dx %s = %.2f", units, product, price*float64(units))
	fmt.Println("Receipt:", receipt)
	fmt.Printf("VAT: %d%%\n", 21) // %% writes a percent sign
}
