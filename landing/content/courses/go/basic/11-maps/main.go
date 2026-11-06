package main

import (
	"fmt"
	"sort"
)

func main() {
	// A map links keys to values: map[keyType]valueType.
	stock := map[string]int{"apples": 12, "pears": 5, "plums": 0}
	fmt.Println("Apples:", stock["apples"])

	// Assigning changes a value or adds a new key.
	stock["pears"] = 8
	stock["kiwis"] = 20

	// A missing key gives the zero value; ok says if it exists.
	fmt.Println("Bananas:", stock["bananas"])
	if _, ok := stock["bananas"]; !ok {
		fmt.Println("We do not sell bananas")
	}
	delete(stock, "plums")
	fmt.Println("Kinds of fruit:", len(stock))

	// The order of a map is random: sort the keys first.
	keys := make([]string, 0, len(stock))
	for key := range stock {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for i := 0; i < len(keys); i++ {
		fmt.Printf("%-8s%4d\n", keys[i], stock[keys[i]])
	}
}
