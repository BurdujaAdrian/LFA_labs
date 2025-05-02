package main

import "core:fmt"
import str"core:strings"
source := #load("demo.mtex")

main :: proc(){
	tokens := tokenize(source)
	print_tokens(false)
	ast := parse(tokens[:])
	fmt.println("output", str.to_string(output))
}
