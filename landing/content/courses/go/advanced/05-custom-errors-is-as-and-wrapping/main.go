package main

import (
	"errors"
	"fmt"
)

var ErrUnknown = errors.New("unknown product") // a sentinel error
var stock = map[string]int{"KB-01": 5, "MS-02": 1}

type StockError struct{ Want, Have int } // a custom error type that carries data

func (e *StockError) Error() string { return fmt.Sprintf("want %d, have %d", e.Want, e.Have) }

func reserve(sku string, qty int) error {
	if have, ok := stock[sku]; !ok {
		return fmt.Errorf("reserve: %w", ErrUnknown) // %w wraps the error
	} else if qty > have {
		return fmt.Errorf("reserve: %w", &StockError{qty, have})
	}
	return nil
}

func main() {
	for _, sku := range []string{"KB-01", "MS-02", "XX-99"} {
		var se *StockError
		switch err := reserve(sku, 3); {
		case errors.As(err, &se): // is there a *StockError in the chain?
			fmt.Printf("%s: %v (short by %d)\n", sku, err, se.Want-se.Have)
		default: // errors.Is: is ErrUnknown anywhere in the chain?
			fmt.Printf("%s: %v (unknown: %t)\n", sku, err, errors.Is(err, ErrUnknown))
		}
	}
}
