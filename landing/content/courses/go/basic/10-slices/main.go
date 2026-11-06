package main

import "fmt"

func main() {
	// A slice is a list that can grow: [] without a length.
	playlist := []string{"Intro", "Sunrise", "Rain"}
	fmt.Println(playlist, "len:", len(playlist))

	// append returns the new slice: assign it back.
	playlist = append(playlist, "Harbour", "Night Drive")
	fmt.Println(playlist, "len:", len(playlist))

	// s[from:to] goes from 'from' up to, not including, 'to'.
	fmt.Println("First two:", playlist[:2])
	fmt.Println("From the third:", playlist[2:])
	fmt.Println("Middle:", playlist[1:4])

	// make creates an empty slice with room (cap) for 4.
	ratings := make([]int, 0, 4)
	for i := 1; i <= 6; i++ {
		ratings = append(ratings, i*10)
		fmt.Printf("len=%d cap=%d %v\n", len(ratings), cap(ratings), ratings)
	}

	// A sub-slice shares memory with the original.
	firstTwo := playlist[:2]
	firstTwo[0] = "Overture"
	fmt.Println("Changed through the sub-slice:", playlist[0])
}
