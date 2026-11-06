package main

import "fmt"

type Product struct {
	Name  string
	Price float64
	Stock int
}

func (p Product) Value() float64 { return p.Price * float64(p.Stock) }

// Sell lowers the stock, or returns an error if there is not enough.
func (p *Product) Sell(units int) error {
	if units > p.Stock {
		return fmt.Errorf("%s: asked for %d, only %d left", p.Name, units, p.Stock)
	}
	p.Stock -= units
	return nil
}

func main() {
	shop := []Product{{"Notebook", 2.5, 40}, {"Pen", 1.2, 100}, {"Mug", 6.95, 12}, {"Teapot", 18, 3}}
	sales, total := []int{5, 30, 10, 4}, 0.0 // units sold of each product
	for i := range shop {
		if err := shop[i].Sell(sales[i]); err != nil {
			fmt.Println("Error:", err)
		}
		p := shop[i]
		fmt.Printf("%-9s%6.2f%5d%9.2f\n", p.Name, p.Price, p.Stock, p.Value())
		total += p.Value()
	}
	fmt.Printf("Stock value: %.2f\n", total)
}
