package main

import (
	"fmt"
	"sort"
)

func main() {
	// Over a slice: the index and a copy of each value.
	temps, sum := []float64{18.5, 21, 19.5, 23}, 0.0
	for i, t := range temps {
		fmt.Printf("Day %d: %.1f\n", i+1, t)
		sum += t
	}
	fmt.Printf("Average: %.2f\n", sum/float64(len(temps)))

	// Over a map: key and value, in random order, so sort the keys.
	capitals := map[string]string{"Spain": "Madrid", "Italy": "Rome", "France": "Paris"}
	countries := make([]string, 0, len(capitals))
	for country := range capitals {
		countries = append(countries, country)
	}
	sort.Strings(countries)
	for _, country := range countries {
		fmt.Println(country, "->", capitals[country])
	}

	// Over a string: the byte position and each rune (character).
	city := "Málaga"
	for pos, r := range city {
		fmt.Printf("%d:%c ", pos, r)
	}
	fmt.Println("| bytes:", len(city), "runes:", len([]rune(city)))
}
