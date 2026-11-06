package main

import "fmt"

// PriceRule is a function type: any func(float64) float64 fits.
type PriceRule func(float64) float64

func percentOff(pct float64) PriceRule {
	return func(price float64) float64 { return price * (1 - pct/100) } // remembers pct
}

// invoiceNumbers returns a closure with its own counter, kept between calls.
func invoiceNumbers(prefix string) func() string {
	n := 0
	return func() string {
		n++
		return fmt.Sprintf("%s-%03d", prefix, n)
	}
}

func main() {
	addVAT := func(price float64) float64 { return price * 1.21 } // a function value
	rules := []PriceRule{percentOff(10), percentOff(5), addVAT}
	next := invoiceNumbers("INV")
	for _, price := range []float64{100, 40, 25} {
		final := price
		for _, apply := range rules {
			final = apply(final)
		}
		fmt.Printf("%s  %6.2f -> %6.2f\n", next(), price, final)
	}
	other := invoiceNumbers("REF") // a new closure starts its own count
	fmt.Println(other(), other(), "| main series goes on:", next())
}
