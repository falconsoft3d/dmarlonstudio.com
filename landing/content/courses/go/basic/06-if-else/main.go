package main

import "fmt"

func main() {
	temperature := 31

	// The condition needs no parentheses, but the braces are required.
	if temperature > 30 {
		fmt.Println("It is hot: drink water")
	} else if temperature > 15 {
		fmt.Println("Nice weather for a walk")
	} else {
		fmt.Println("Take a coat")
	}

	// && (and), || (or) and ! (not) combine conditions.
	age, hasTicket := 17, true
	if age >= 18 && hasTicket {
		fmt.Println("Welcome to the concert")
	} else if hasTicket && !(age < 16) {
		fmt.Println("Welcome, with an adult")
	} else {
		fmt.Println("Sorry, no entry")
	}

	// An init statement runs first; total only exists inside this if.
	price, units := 18.5, 3
	if total := price * float64(units); total >= 50 {
		fmt.Printf("Total %.2f: free shipping\n", total)
	} else {
		fmt.Printf("Total %.2f + 4.95 shipping\n", total)
	}
}
