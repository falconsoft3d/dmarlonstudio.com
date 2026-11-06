package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	// A Scanner reads the keyboard (standard input) line by line.
	scanner := bufio.NewScanner(os.Stdin)

	fmt.Print("What is your name? ")
	scanner.Scan()
	name := scanner.Text()
	fmt.Printf("Nice to meet you, %s!\n", name)

	// Text() is always a string: convert it to do maths.
	fmt.Print("How old are you? ")
	scanner.Scan()
	age, err := strconv.Atoi(scanner.Text())
	if err != nil {
		fmt.Println("That is not a whole number.")
		return
	}
	fmt.Printf("In 10 years you will be %d.\n", age+10)

	fmt.Print("Price of a cinema ticket? ")
	scanner.Scan()
	price, _ := strconv.ParseFloat(scanner.Text(), 64)
	fmt.Printf("Three tickets cost %.2f euros.\n", price*3)
}
