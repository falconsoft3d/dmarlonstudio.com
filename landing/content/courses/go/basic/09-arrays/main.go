package main

import "fmt"

func main() {
	// An array has a fixed length, and it is part of its type.
	var rainfall [7]float64
	rainfall[0] = 2.5
	rainfall[3] = 11
	rainfall[6] = 4.25
	fmt.Println("Rainfall:", rainfall)

	// [...] lets Go count the elements of the literal.
	days := [...]string{"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"}
	fmt.Println("Days in a week:", len(days))

	total, wettest := 0.0, 0
	for i := 0; i < len(rainfall); i++ {
		total += rainfall[i]
		if rainfall[i] > rainfall[wettest] {
			wettest = i
		}
	}
	fmt.Printf("Total: %.2f mm\n", total)
	fmt.Println("Wettest day:", days[wettest])

	// Assigning an array copies all of it.
	backup := rainfall
	backup[0] = 99
	fmt.Println("Monday:", rainfall[0], "in the copy:", backup[0])

	// Arrays of the same type can be compared with ==.
	fmt.Println("Same data?", backup == rainfall)
}
