package main

import "fmt"

// describe uses a type switch: in each case, v already has that concrete type.
func describe(v interface{}) string {
	switch v := v.(type) {
	case nil:
		return "nil: the setting is missing"
	case int:
		return fmt.Sprintf("int %d", v)
	case float64:
		return fmt.Sprintf("float64 %.2f", v)
	case string:
		return fmt.Sprintf("string %q (%d bytes)", v, len(v))
	case []string:
		return fmt.Sprintf("[]string with %d items: %v", len(v), v)
	default:
		return fmt.Sprintf("something else: %T", v)
	}
}

func main() {
	// any is another name for interface{}: it can hold a value of any type.
	values := []any{8080, 0.75, "shop.local", []string{"api", "eu"}, true, nil}
	for _, v := range values {
		fmt.Println(describe(v))
	}
	var port any = "8080"
	n, ok := port.(int) // comma-ok form: never panics
	fmt.Println("port as int:", n, ok)
	fmt.Println("first value doubled:", values[0].(int)*2) // panics if wrong
}
