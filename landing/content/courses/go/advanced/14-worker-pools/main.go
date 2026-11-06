package main

import (
	"fmt"
	"sort"
)

func worker(nets map[int]float64, jobs <-chan int, results chan<- string) {
	for id := range jobs { // takes invoice IDs until jobs is closed
		results <- fmt.Sprintf("#%d %7.2f -> %7.2f", id, nets[id], nets[id]*1.21)
	}
}

func main() {
	nets := map[int]float64{101: 120, 102: 80, 103: 45.5, 104: 300, 105: 19.99, 106: 64}
	jobs := make(chan int, len(nets))
	results := make(chan string, len(nets))
	for w := 1; w <= 3; w++ { // a pool of three workers shares the jobs
		go worker(nets, jobs, results)
	}
	for id := range nets { // map order is random, and so is the order of results
		jobs <- id
	}
	close(jobs) // no more work: the workers' loops end
	var lines []string
	for range nets { // exactly one result per job
		lines = append(lines, <-results)
	}
	sort.Strings(lines) // sort before printing: the same output every run
	for _, line := range lines {
		fmt.Println(line)
	}
	fmt.Println(len(lines), "invoices, VAT added by 3 workers")
}
