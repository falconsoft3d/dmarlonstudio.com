// Every Go program starts in package main, at func main.
package main

import "fmt" // the package for printing text

func main() {
	fmt.Println("Hello, world!")
	fmt.Println("Welcome to the Go course.")

	// Println puts spaces between its values and ends the line.
	fmt.Println("Lessons:", 20, "Level:", "basic")
	fmt.Println("2 + 3 =", 2+3)

	// Print adds no newline: \n ends the line.
	fmt.Print("Step ")
	fmt.Print("by step\n")

	// An empty Println writes a blank line.
	fmt.Println()
	fmt.Println("Bye!")
}
