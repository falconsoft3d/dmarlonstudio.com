package main

import (
	"fmt"
	"strings"
	"sync"
)

func main() {
	names := []string{"intro.txt", "setup.txt", "faq.txt"}
	texts := []string{
		"Go runs functions concurrently with goroutines",
		"install the toolchain, then build and run the program",
		"why share memory by communicating instead of communicating by sharing memory",
	}
	counts := make([]int, len(texts)) // one slot per goroutine: nothing is shared
	var wg sync.WaitGroup
	for i := range texts {
		wg.Add(1)        // one more goroutine to wait for
		go func(i int) { // i is passed as an argument: each goroutine has its own copy
			defer wg.Done()
			counts[i] = len(strings.Fields(texts[i]))
		}(i)
	}
	wg.Wait() // blocks until every goroutine has called Done
	total := 0
	for i, n := range counts { // printed in order, whatever order they finished in
		fmt.Printf("%-10s %2d words\n", names[i], n)
		total += n
	}
	fmt.Println("total:", total, "words in", len(texts), "documents")
}
