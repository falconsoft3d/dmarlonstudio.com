package main

import "fmt"

type Room struct {
	Name          string
	Width, Length float64
}

// A method has a receiver before its name: (r Room).
func (r Room) Area() float64 {
	return r.Width * r.Length
}

// A pointer receiver (*Room) can change the original room.
func (r *Room) Extend(meters float64) {
	r.Length += meters
}

// String() decides how fmt prints a Room.
func (r Room) String() string {
	return fmt.Sprintf("%-8s %.1f x %.1f m", r.Name, r.Width, r.Length)
}

func main() {
	flat := []Room{{"Kitchen", 3, 4.5}, {"Bedroom", 3.5, 4}, {"Bath", 2, 2.5}}
	flat[2].Extend(1) // Go passes &flat[2] for us
	total := 0.0
	for i := 0; i < len(flat); i++ {
		fmt.Printf("%v -> %5.2f m2\n", flat[i], flat[i].Area())
		total += flat[i].Area()
	}
	fmt.Printf("Whole flat: %.2f m2\n", total)
}
