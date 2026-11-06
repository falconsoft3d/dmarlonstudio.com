package main

import (
	"fmt"
	"time"
)

func main() {
	queue := make(chan string, 3) // buffered: holds 3 messages without a receiver
	for _, msg := range []string{"welcome email", "invoice 17", "password reset", "newsletter", "survey"} {
		select {
		case queue <- msg:
			fmt.Printf("queued %-15s len=%d cap=%d\n", msg, len(queue), cap(queue))
		default: // the buffer is full: do not block, drop the message
			fmt.Println("full, dropped", msg)
		}
	}
	close(queue)
	for msg := range queue { // the buffered values are still delivered after close
		fmt.Println("sending", msg)
	}

	report := make(chan string, 1) // buffer 1: the sender never gets stuck
	go func() {
		time.Sleep(300 * time.Millisecond) // a slow job
		report <- "sales report ready"
	}()
	select { // waits for whichever case is ready first
	case r := <-report:
		fmt.Println(r)
	case <-time.After(50 * time.Millisecond):
		fmt.Println("timeout: report not ready after 50ms")
	}
}
