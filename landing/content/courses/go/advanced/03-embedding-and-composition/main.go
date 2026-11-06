package main

import "fmt"

type Contact struct{ Name, Email string }

func (c Contact) Label() string { return c.Name + " <" + c.Email + ">" }

type Address struct{ City, Country string }

func (a Address) Line() string { return a.City + ", " + a.Country }

// Customer embeds Contact and Address: their fields and methods are promoted.
type Customer struct {
	Contact
	Address
	Points int
}

type VIP struct { // embeds Customer and overrides its Label method
	Customer
	Tier string
}

func (v VIP) Label() string { return "[" + v.Tier + "] " + v.Customer.Label() }

func main() {
	c := Customer{Contact{"Ana Ruiz", "ana@shop.es"}, Address{"Seville", "Spain"}, 120}
	fmt.Println(c.Name, "|", c.Label(), "|", c.Line(), "|", c.Points, "points")
	v := VIP{Customer: c, Tier: "gold"}
	v.Points += 50 // promoted through two levels: v.Customer.Points
	fmt.Println(v.Label(), "|", v.Points, "points")
	fmt.Println(v.Customer.Label(), "|", v.Contact.Email, "|", v.Line())
}
