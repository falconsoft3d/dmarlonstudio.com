package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

// Gets a copy of the number: the change is lost.
func bonusCopy(score int) { score += 50 }

// Gets the address: *score is the original variable.
func bonus(score *int) { *score += 50 }

// With a pointer to a struct, p.Score is enough (no * needed).
func levelUp(p *Player) { p.Score += 100 }

func main() {
	score := 120
	ptr := &score // & gives the address of the variable
	fmt.Println("score:", score, "| *ptr:", *ptr)
	*ptr = 150 // * reaches the value behind the address
	fmt.Println("After *ptr = 150:", score)
	bonusCopy(score)
	fmt.Println("After bonusCopy:", score)
	bonus(&score)
	fmt.Println("After bonus:", score)
	ana := &Player{Name: "Ana", Score: 10}
	levelUp(ana)
	fmt.Println(ana.Name, "now has", ana.Score, "points")
	var nobody *Player // a pointer starts as nil
	fmt.Println("nobody == nil:", nobody == nil)
}
