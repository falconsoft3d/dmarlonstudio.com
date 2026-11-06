package main

import (
	"fmt"
	"sort"
)

type Product struct {
	Name, Category string
	Price          float64
}

// ByName implements sort.Interface: Len, Less and Swap.
type ByName []Product

func (p ByName) Len() int           { return len(p) }
func (p ByName) Less(i, j int) bool { return p[i].Name < p[j].Name }
func (p ByName) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }

func (p Product) String() string { return fmt.Sprintf("%s/%s/%.0f", p.Name, p.Category, p.Price) }

func main() {
	ps := []Product{{"Mouse", "tech", 25}, {"Desk", "office", 180}, {"Lamp", "office", 40}, {"Cable", "tech", 9}}
	sort.Sort(ByName(ps))
	fmt.Printf("%-12s%v\n", "by name", ps)
	sort.Slice(ps, func(i, j int) bool { return ps[i].Price < ps[j].Price })
	fmt.Printf("%-12s%v\n", "by price", ps)
	i := sort.Search(len(ps), func(i int) bool { return ps[i].Price >= 30 }) // binary search
	fmt.Println("first from 30 EUR:", ps[i].Name)
	sort.SliceStable(ps, func(i, j int) bool { return ps[i].Category < ps[j].Category })
	fmt.Printf("%-12s%v\n", "by category", ps) // stable: keeps the price order inside each category
	sort.Sort(sort.Reverse(ByName(ps)))
	fmt.Printf("%-12s%v\n", "name desc", ps)
}
