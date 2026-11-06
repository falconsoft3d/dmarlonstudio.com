package main

import "fmt"

// shipping returns the delivery cost in cents: orders from 50.00 ship free.
func shipping(total int) int {
	if total > 5000 { // bug: an order of exactly 50.00 should also ship free
		return 0
	}
	return 495
}

func main() {
	tests := []struct {
		name        string
		total, want int // in cents
	}{
		{"small order", 2000, 495},
		{"one cent short", 4999, 495},
		{"exactly 50.00", 5000, 0},
		{"large order", 12000, 0},
		{"empty cart", 0, 495},
	}
	failed := 0
	for _, tc := range tests {
		got := shipping(tc.total)
		status := "ok  "
		if got != tc.want {
			status, failed = "FAIL", failed+1
		}
		fmt.Printf("%s %-15s shipping(%5d) = %3d, want %3d\n", status, tc.name, tc.total, got, tc.want)
	}
	fmt.Printf("%d passed, %d failed\n", len(tests)-failed, failed)
}
