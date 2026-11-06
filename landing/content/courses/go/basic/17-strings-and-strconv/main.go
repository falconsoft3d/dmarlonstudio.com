package main

import (
	"fmt"
	"strconv"
	"strings"
)

func main() {
	line := "  milk, eggs ,bread,  olive oil  "

	// Split cuts at each comma; TrimSpace removes the spaces around.
	parts := strings.Split(line, ",")
	for i := 0; i < len(parts); i++ {
		parts[i] = strings.TrimSpace(parts[i])
	}
	fmt.Printf("%d items: %q\n", len(parts), parts)
	fmt.Println(strings.Join(parts, " | "))
	fmt.Println("Upper:", strings.ToUpper(parts[0]), "| has eggs:", strings.Contains(line, "eggs"))
	fmt.Println("Replace:", strings.Replace(parts[3], "olive", "sunflower", 1), "| commas:", strings.Count(line, ","))
	fmt.Println(strings.Repeat("-", 24))

	// strconv turns text into numbers and numbers into text.
	units, err := strconv.Atoi("12")
	fmt.Println("12 units x 2 =", units*2, "error:", err)
	price, _ := strconv.ParseFloat("2.75", 64)
	fmt.Println("Price x 2 =", price*2)
	if _, err := strconv.Atoi("twelve"); err != nil {
		fmt.Println("Error:", err)
	}
	label := "Pack of " + strconv.Itoa(units) + ": " + strconv.FormatFloat(price*float64(units), 'f', 2, 64)
	fmt.Println(label)
}
