package main

import "fmt"

// Any type with these two methods is a Carrier: there is no "implements".
type Carrier interface {
	Name() string
	Cost(kg float64) float64
}

type Courier struct{ PerKg float64 }

func (c Courier) Name() string            { return "Courier" }
func (c Courier) Cost(kg float64) float64 { return 4.5 + c.PerKg*kg }

type PostOffice struct{ Flat float64 }

func (p PostOffice) Name() string         { return "Post office" }
func (p PostOffice) Cost(float64) float64 { return p.Flat } // same price for any weight

var _ Carrier = PostOffice{} // compile-time check: fails if a method is missing

func main() {
	carriers := []Carrier{Courier{PerKg: 1.2}, PostOffice{Flat: 7}}
	for _, kg := range []float64{1, 2, 5} {
		for _, c := range carriers {
			fmt.Printf("%3.0f kg  %-12s %6.2f EUR\n", kg, c.Name(), c.Cost(kg))
		}
	}
}
