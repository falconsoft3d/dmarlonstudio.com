package main

import "fmt"

func main() {
	// var declares a variable with its type.
	var city string = "Valencia"
	var population int = 800000

	// := declares it and takes the type from the value.
	temperature := 21.5
	isCoastal := true

	// Without a value, a variable starts at its zero value.
	var visitors int
	var note string

	fmt.Println("City:", city)
	fmt.Println("Population:", population)
	fmt.Println("Temperature:", temperature)
	fmt.Println("Coastal:", isCoastal)
	fmt.Println("Visitors:", visitors, "Note: ["+note+"]")

	// %T prints the type of each value.
	fmt.Printf("Types: %T %T %T %T\n", city, population, temperature, isCoastal)

	// = gives a new value of the same type.
	population = 810000
	visitors += 1500
	fmt.Println("Now:", population, "people and", visitors, "visitors")
}
