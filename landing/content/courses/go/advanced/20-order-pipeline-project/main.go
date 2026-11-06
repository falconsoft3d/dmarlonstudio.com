package main

import (
	"encoding/json"
	"fmt"
)

type Order struct {
	ID    int     `json:"id"`
	Net   float64 `json:"net"`
	Total float64 `json:"total"`
}

func (o Order) String() string { return fmt.Sprintf("#%d %6.2f -> %6.2f", o.ID, o.Net, o.Total) }
func ParallelMap[T, U any](in []T, f func(T) U) []U { // one goroutine per item, order kept
	out, done := make([]U, len(in)), make(chan bool)
	for i := range in {
		go func(i int) { out[i] = f(in[i]); done <- true }(i)
	}
	for range in {
		<-done // wait for one signal per goroutine
	}
	return out
}

func main() {
	var orders []Order
	err := json.Unmarshal([]byte(`[{"id":101,"net":120},{"id":102,"net":80},{"id":103,"net":45.5}]`), &orders)
	fmt.Println("decoded", len(orders), "orders, error:", err)
	billed := ParallelMap(orders, func(o Order) Order { o.Total = o.Net * 1.21; return o })
	for _, o := range billed {
		fmt.Println(o) // fmt finds the String method: Order is a fmt.Stringer
	}
}
