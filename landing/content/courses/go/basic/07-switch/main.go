package main

import "fmt"

func main() {
	day := "Saturday"
	// Each case ends on its own: no break needed.
	switch day {
	case "Saturday", "Sunday":
		fmt.Println(day, "is weekend")
	default:
		fmt.Println(day, "is a working day")
	}

	// With no value, switch works like a chain of if / else.
	score := 82
	switch {
	case score >= 90:
		fmt.Println(score, "-> grade A")
	case score >= 80:
		fmt.Println(score, "-> grade B")
	default:
		fmt.Println(score, "-> grade C")
	}

	// An init statement, and fallthrough to run the next case too.
	switch level := 2; level {
	case 2:
		fmt.Println("Level 2: bonus unlocked")
		fallthrough
	case 1:
		fmt.Println("Level 1: basics done")
	}
}
