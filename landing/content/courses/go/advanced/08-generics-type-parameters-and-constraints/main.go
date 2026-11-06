package main

import "fmt"

// Number is a constraint: the set of types that T may be.
type Number interface{ ~int | ~int64 | ~float64 }

type Cents int64 // ~int64 also lets in named types such as Cents

func Sum[T Number](values []T) T {
	var total T // the zero value of T
	for _, v := range values {
		total += v
	}
	return total
}

// Map works for any input type T and any output type U.
func Map[T, U any](items []T, f func(T) U) []U {
	out := make([]U, 0, len(items))
	for _, item := range items {
		out = append(out, f(item))
	}
	return out
}

func main() {
	fmt.Println(Sum([]int{3, 5, 8}), Sum([]float64{2.5, 1.25}), Sum([]Cents{1999, 450}))
	fmt.Println(Sum[float64](nil)) // explicit type argument
	labels := Map([]int{7, 12, 30}, func(n int) string { return fmt.Sprintf("#%d", n) })
	fmt.Printf("%v %T\n", labels, labels)
	fmt.Println(Map(labels, func(s string) int { return len(s) }))
}
