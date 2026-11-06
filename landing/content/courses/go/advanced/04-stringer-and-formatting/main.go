package main

import "fmt"

type Status int

const (
	Pending Status = iota
	Shipped
	Delivered
)

// String makes Status a fmt.Stringer: %v and %s call it.
func (s Status) String() string { return [...]string{"pending", "shipped", "delivered"}[s] }

type Money int64 // amount in cents

func (m Money) String() string { return fmt.Sprintf("%d.%02d EUR", m/100, m%100) }

type Order struct {
	ID     int
	Total  Money
	Status Status
}

func main() {
	o := Order{ID: 1042, Total: 25999, Status: Shipped}
	fmt.Println("status:", o.Status, "| total:", o.Total)
	fmt.Printf("%v\n", o)
	fmt.Printf("%+v\n", o)
	fmt.Printf("%#v\n", o)                           // Go syntax: String is not used
	fmt.Printf("%d %d\n", o.Status, o.Total)         // %d prints the plain number
	fmt.Printf("|%-12s|%12v|\n", Delivered, o.Total) // width and alignment
}
