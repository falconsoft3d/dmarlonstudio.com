package main

import "fmt"

// A constant never changes.
const vatRate = 0.21

// iota numbers the constants of a group: 0, 1, 2...
const (
	Small = iota
	Medium
	Large
)

func main() {
	pizzas, guests := 7, 3
	fmt.Println("Pizzas per guest:", pizzas/guests) // int / int drops decimals
	fmt.Println("Pizzas left over:", pizzas%guests) // % is the remainder

	// Mixing int and float64 needs a conversion.
	share := float64(pizzas) / float64(guests)
	fmt.Println("Exact share:", share)

	price := 12.5
	total := price * float64(pizzas)
	fmt.Println("Total:", total, "VAT:", total*vatRate)

	count := 10
	count += 5 // count = count + 5
	count *= 2
	count++
	fmt.Println("Counter:", count)
	fmt.Println("Sizes:", Small, Medium, Large)
}
