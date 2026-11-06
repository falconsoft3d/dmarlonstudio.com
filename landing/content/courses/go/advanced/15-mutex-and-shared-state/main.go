package main

import (
	"fmt"
	"sync"
)

type BoxOffice struct { // shared by many goroutines: mu protects the fields below
	mu      sync.Mutex
	tickets map[string]int
	sold    int
}

func (b *BoxOffice) Buy(show string) {
	b.mu.Lock()              // only one goroutine at a time gets past Lock
	defer b.mu.Unlock()      // released when Buy returns
	if b.tickets[show] > 0 { // check and update together: no ticket is sold twice
		b.tickets[show]--
		b.sold++
	}
}

func main() {
	office := &BoxOffice{tickets: map[string]int{"jazz night": 40}}
	var wg sync.WaitGroup
	for i := 0; i < 55; i++ { // 55 buyers arrive at the same time
		wg.Add(1)
		go func() { defer wg.Done(); office.Buy("jazz night") }()
	}
	wg.Wait()
	fmt.Println("buyers: 55 | sold:", office.sold, "| turned away:", 55-office.sold)
	fmt.Println("tickets left:", office.tickets["jazz night"])
}
