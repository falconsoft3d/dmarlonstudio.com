package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
)

func priceHandler(w http.ResponseWriter, r *http.Request) { // GET /api/price?sku=...
	prices := map[string]float64{"KB-01": 49.9, "MS-02": 19.5}
	sku := r.URL.Query().Get("sku")
	price, ok := prices[sku]
	switch {
	case r.Method != http.MethodGet:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	case !ok:
		http.Error(w, "unknown sku", http.StatusNotFound)
	default:
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"sku": sku, "price": price})
	}
}

func main() {
	handler := http.HandlerFunc(priceHandler) // the adapter that makes it an http.Handler
	requests := [][2]string{{"GET", "/api/price?sku=KB-01"}, {"GET", "/api/price?sku=ZZ-09"},
		{"POST", "/api/price?sku=KB-01"}, {"GET", "/api/price?sku=MS-02"}}
	for _, req := range requests {
		rec := httptest.NewRecorder() // records status, headers and body: no network
		handler.ServeHTTP(rec, httptest.NewRequest(req[0], req[1], nil))
		fmt.Printf("%-4s %-21s -> %d %s", req[0], req[1], rec.Code, rec.Body)
	}
}
