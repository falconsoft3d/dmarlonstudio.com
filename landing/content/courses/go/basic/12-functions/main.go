package main

import "fmt"

// Parameters go with their types; the result type comes last.
func vat(price float64) float64 { return price * 0.21 }

// A function can return several values.
func share(sweets, children int) (int, int) {
	return sweets / children, sweets % children
}

// Named results start at zero; a bare return sends them back.
func lowHigh(numbers []int) (low, high int) {
	low, high = numbers[0], numbers[0]
	for i := 1; i < len(numbers); i++ {
		if numbers[i] < low {
			low = numbers[i]
		} else if numbers[i] > high {
			high = numbers[i]
		}
	}
	return
}

func main() {
	fmt.Printf("VAT on 40 euros: %.2f\n", vat(40))
	each, left := share(17, 5)
	fmt.Println("Sweets each:", each, "left over:", left)
	_, rest := share(100, 7) // _ ignores a result
	fmt.Println("Left over from 100 among 7:", rest)
	low, high := lowHigh([]int{18, 25, 9, 31, 22})
	fmt.Println("Lowest:", low, "highest:", high)
}
