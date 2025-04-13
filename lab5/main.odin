#+feature dynamic-literals

package main

import "core:fmt"
import "core:math/rand"
import "core:unicode/utf8"
import str"core:strings"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}


main :: proc(){
	gr := init_grammar(
		patterns  = {
			{"S","bS"},
			{"S","d"},
			{"S","aF"},
			{"F","dF"},
			{"F","cF"},
			{"F","aL"},
			{"L","aL"},
			{"L","c"},
			{"F","b"},
		}, 
		terminals={"a","b","c","d"},
		non_term={"S","F","L"}, 
		start = "S")
	printf("%#v",gr)


}

Grammar :: struct{
	patterns    : map[string][dynamic]string,
	non_term    : []string,
	terminals   : []string,
	start       : string, 
}
init_grammar :: proc(
	patterns:[][2]string, 
	terminals:[]string, 
	non_term:[]string, 
	start:string,
)->(gr : Grammar){
	gr.terminals = terminals
	gr.non_term = non_term
	gr.start = start
	gr.patterns = make(map[string][dynamic]string)
	for pattern in patterns{
		if pattern[0] in gr.patterns {
			append(
				&gr.patterns[pattern[0]],
				pattern[1],
			)
			continue
		}
		// pattern is missing
		gr.patterns[pattern[0]] = make([dynamic]string)
		append(
			&gr.patterns[pattern[0]],
			pattern[1],
		)	
	}
	return
}

print_gr :: proc(gr:^Grammar){
	//
	fmt.println("patters:")
	for key,list in gr.patterns{
		for item in list{
			fmt.printf("	%s -> %s\n",key, item)
		}
	}
}
