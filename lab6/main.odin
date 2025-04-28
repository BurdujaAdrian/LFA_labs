package main


source := #load("demo.mtex")

main :: proc(){
	tokens := tokenize(source)

	ast := parse(tokens[:])
}
