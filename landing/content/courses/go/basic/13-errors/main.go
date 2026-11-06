package main

import (
	"errors"
	"fmt"
)

// errors.New creates an error value that can be recognised later.
var ErrNoFunds = errors.New("insufficient funds")

// The error goes last; nil means that everything went well.
func withdraw(balance, amount float64) (float64, error) {
	switch {
	case amount <= 0:
		return balance, fmt.Errorf("invalid amount %.2f", amount)
	case amount > balance:
		return balance, fmt.Errorf("withdraw %.2f: %w", amount, ErrNoFunds) // %w wraps it
	}
	return balance - amount, nil
}

func main() {
	balance, amounts := 100.0, []float64{30, -5, 90, 45}
	for i := 0; i < len(amounts); i++ {
		newBalance, err := withdraw(balance, amounts[i])
		if err != nil {
			fmt.Println("Error:", err)
			fmt.Println("  is ErrNoFunds?", errors.Is(err, ErrNoFunds))
			continue
		}
		balance = newBalance
		fmt.Printf("Took %.2f, balance %.2f\n", amounts[i], balance)
	}
}
