package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// fetchQuote simulates a supplier that answers after delay, unless ctx ends first.
func fetchQuote(ctx context.Context, supplier string, delay time.Duration) (string, error) {
	select {
	case <-time.After(delay):
		return supplier + " quotes 42.50 EUR", nil
	case <-ctx.Done(): // closed on timeout or on cancel
		return "", fmt.Errorf("%s: %w", supplier, ctx.Err())
	}
}

func main() {
	delays := map[string]time.Duration{"FastParts": 10 * time.Millisecond, "SlowSupply": time.Second}
	for _, supplier := range []string{"FastParts", "SlowSupply"} {
		ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
		quote, err := fetchQuote(ctx, supplier, delays[supplier])
		cancel() // always release the context, even if it was not needed
		fmt.Printf("%-28q err=%v timeout=%t\n", quote, err, errors.Is(err, context.DeadlineExceeded))
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel() // e.g. the customer closed the page before we asked
	_, err := fetchQuote(ctx, "FastParts", 10*time.Millisecond)
	fmt.Println("err:", err, "| canceled:", errors.Is(err, context.Canceled))
}
