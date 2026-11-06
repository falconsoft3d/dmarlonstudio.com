package main

import (
	"encoding/json"
	"fmt"
)

type Item struct {
	SKU string `json:"sku"`
	Qty int    `json:"qty"`
}

type Order struct {
	ID       int    `json:"id"`
	Customer string `json:"customer"`
	Items    []Item `json:"items"`
	Note     string `json:"note,omitempty"` // left out when empty
	Margin   int    `json:"-"`              // never encoded
}

func main() {
	out := Order{ID: 7, Customer: "Ana Ruiz", Items: []Item{{"KB-01", 1}, {"MS-02", 2}}, Margin: 30}
	data, err := json.Marshal(out)
	fmt.Println(string(data), err)
	input := `{"id": 8, "customer": "Luis Gil", "items": [{"sku": "CB-03", "qty": 4}], "note": "gift", "coupon": "X"}`
	var in Order
	err = json.Unmarshal([]byte(input), &in) // pass a pointer so it can fill the struct
	fmt.Printf("%+v %v\n", in, err)          // unknown keys such as coupon are ignored
	err = json.Unmarshal([]byte(`{"id": "nine"}`), &in)
	fmt.Println("error:", err)
	pretty, _ := json.MarshalIndent(in.Items[0], "", "  ")
	fmt.Println(string(pretty))
}
