package main

import "core:fmt"
import str"core:strings"
source := #load("demo.mtex")

main :: proc(){
	tokens := tokenize(source)
	print_tokens(false)
	ast := parse(tokens[:])

	print_ast(&ast)
	fmt.println("output", str.to_string(output))
}
