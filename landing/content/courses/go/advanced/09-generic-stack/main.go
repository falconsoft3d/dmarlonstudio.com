package main

import "fmt"

// Stack is a generic type: Stack[string], Stack[int]... one implementation.
type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }
func (s *Stack[T]) Len() int { return len(s.items) }

// Pop returns the zero value of T and false when the stack is empty.
func (s *Stack[T]) Pop() (top T, ok bool) {
	if len(s.items) == 0 {
		return top, false // top still holds the zero value of T
	}
	top = s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return top, true
}

func main() {
	var history Stack[string] // the zero value is ready to use
	for _, edit := range []string{"type 'Dear Ana'", "bold title", "insert logo"} {
		history.Push(edit)
	}
	fmt.Println("edits in history:", history.Len())
	for i := 0; i < 4; i++ {
		edit, ok := history.Pop()
		fmt.Printf("undo %q ok=%t\n", edit, ok)
	}
	pages := &Stack[int]{items: []int{1, 4, 9}} // the same code, now with ints
	page, _ := pages.Pop()
	fmt.Println("back from page", page, "| pages left:", pages.Len())
}
