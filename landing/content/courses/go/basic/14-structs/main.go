package main

import "fmt"

// A struct groups related fields into one type.
type Book struct {
	Title, Author string
	Pages         int
	Read          bool
}

func main() {
	// Fields by name; the missing ones take their zero value.
	novel := Book{Title: "Emma", Author: "Jane Austen", Pages: 474}
	tale := Book{"Matilda", "Roald Dahl", 240, true} // or all, in order

	novel.Read = true // the dot reads and changes fields
	fmt.Println(novel)
	fmt.Printf("%+v\n", tale) // %+v also shows the field names

	// Assigning a struct copies it.
	gift := tale
	gift.Title = "Matilda (gift)"
	fmt.Println(tale.Title, "|", gift.Title)

	// A slice of structs: a small bookshelf.
	shelf := []Book{novel, tale, {Title: "Dracula", Author: "Bram Stoker", Pages: 418}}
	total := 0
	for i := 0; i < len(shelf); i++ {
		fmt.Printf("%-8s %-12s %4d %v\n", shelf[i].Title, shelf[i].Author, shelf[i].Pages, shelf[i].Read)
		total += shelf[i].Pages
	}
	fmt.Println("Total pages:", total)
}
