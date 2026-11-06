package main

import "fmt"

func importFile(name string) {
	fmt.Println("open", name)
	defer fmt.Println("close", name) // runs when importFile returns
	for step := 1; step <= 3; step++ {
		defer fmt.Println("  undo step", step) // arguments are evaluated now
	}
	fmt.Println("  importing rows...")
}

func average(scores []int) (avg int, err error) { // recover turns a panic into an error
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("recovered: %v", r) // sets the named result
		}
	}()
	total := 0
	for _, s := range scores {
		total += s
	}
	return total / len(scores), nil // panics if scores is empty
}

func main() {
	defer fmt.Println("main: deferred until the very end")
	importFile("orders.csv")
	for _, scores := range [][]int{{90, 85, 95}, {}} {
		avg, err := average(scores)
		fmt.Println("average:", avg, "| error:", err)
	}
}
