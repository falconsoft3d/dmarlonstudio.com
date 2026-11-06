package main

import "fmt"

func main() {
	// Classic form: init; condition; post.
	for i := 1; i <= 5; i++ {
		fmt.Printf("%d x 7 = %d\n", i, i*7)
	}

	// Only a condition: this is Go's "while".
	savings, months := 100.0, 0
	for savings < 150 {
		savings *= 1.10
		months++
	}
	fmt.Printf("%.2f euros after %d months\n", savings, months)

	// No condition at all: it repeats until break.
	n := 0
	for {
		n++
		if n%2 == 0 {
			continue // skip even numbers
		}
		if n*n > 50 {
			break // leave the loop
		}
		fmt.Print(n*n, " ")
	}
	fmt.Println("<- odd squares up to 50")
}
