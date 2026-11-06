package main

import (
	"bufio"
	"fmt"
	"os"
)

// check stops the program if something went wrong.
func check(err error) {
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}
}

func main() {
	// WriteFile creates (or replaces) a file in the current folder.
	notes := "Buy bread\nCall the plumber\nWater the plants\n"
	check(os.WriteFile("notes.txt", []byte(notes), 0644))
	// OpenFile with O_APPEND adds lines at the end.
	f, err := os.OpenFile("notes.txt", os.O_APPEND|os.O_WRONLY, 0644)
	check(err)
	fmt.Fprintln(f, "Pay the electricity bill")
	f.Close()
	// Open + bufio.Scanner reads it back line by line.
	file, err := os.Open("notes.txt")
	check(err)
	defer file.Close() // runs when main ends
	scanner := bufio.NewScanner(file)
	for n := 1; scanner.Scan(); n++ {
		fmt.Printf("%d. %s\n", n, scanner.Text())
	}
}
