package main

import "fmt"

type Line struct {
	Item  string
	Qty   int
	Price float64
}

func produce(lines []Line) <-chan Line { // sends every line, then closes the channel
	out := make(chan Line) // unbuffered: each send waits for a receiver
	go func() {
		defer close(out)
		for _, l := range lines {
			out <- l
		}
	}()
	return out
}

func main() {
	lines := []Line{{"Coffee", 2, 3.5}, {"Croissant", 3, 1.8}, {"Orange juice", 1, 2.9}}
	total := make(chan float64)
	go func() { // a second stage: receives the lines, sends back one total
		sum := 0.0
		for l := range produce(lines) { // the loop ends when produce closes its channel
			fmt.Printf("%-13s %d x %.2f\n", l.Item, l.Qty, l.Price)
			sum += float64(l.Qty) * l.Price
		}
		total <- sum
	}()
	fmt.Printf("total: %.2f EUR\n", <-total) // main waits here until the total arrives
}
