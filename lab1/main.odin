#+feature !dynamic-literals

package main

import "core:fmt"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}

import str"core:strings"


main :: proc(){
	//panic("TODO: rearange grammer; implement init_grammer")
	gr := init_grammer(
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

Grammer :: struct{
	patterns    : map[string][dynamic]string,// a map from key:str to val:array(slice) of strings
	non_term    : []string,
	terminals   : []string,
	start       : string, 
}

init_grammer :: proc(
	patterns:[][2]string, 
	terminals:[]string, 
	non_term:[]string, 
	start:string,
)->(gr : Grammer){
	gr.terminals = terminals
	gr.non_term = non_term
	gr.start = start
	gr.patterns = make(map[string][dynamic]string)
	for pattern in patterns{
		if pattern[0] in gr.patterns {
			append(&gr.patterns[pattern[0]],pattern[1])
			continue
		}
		// pattern is missing
		gr.patterns[pattern[0]] = make([dynamic]string)
		append(&gr.patterns[pattern[0]], pattern[1])
	}
	return
}

print_dll :: proc(hello:^Syl){
	for curr := hello; curr != nil; curr=curr.right {


		printf("%#v \n at adr:%v\n\n",curr, cast(^uintptr)curr )

		if curr.right != nil {
			if curr != curr.right.left {
				printf("next is: %#v \n at adr:%v\n\n",curr.right, cast(^uintptr)curr.right )
				assert(false)
			}
		}
	}
}

import "core:math/rand"

generate_string :: proc(gr:^Grammer)->[]string{
	strings := make_slice([]string,5)
	
	start := new_clone(Syl{txt = gr.start, has_vn = true})

	for &string in &strings {
		string = "bruh"
		//matches := make([dynamic]^map[]string)
		//defer delete(matches)

		// iterate through the dll
		//for curr := start; curr !=nil; curr = curr.right{
		//	for i:=0; i<len(gr.terminals);{
		//		ptrn:=gr.terminals[i]
		//		if str.contains(curr.txt, ptrn) {
		//			choice := rand.choice(gr.term_indices[ptrn])
		//			apply_rule(ptrn, gr.patterns[choice],start)
		//			break
		//		}
		//		i+=1
		//	}
		//}

	}

	return strings
}



//Automaton :: struct{
//	states : [dynamic]u8,//dynamic array of char's
//	transitions : map[string]string,
//	initial: string,
//	final  : []string,
//}

Syl :: struct{
	txt	: string,
	left	: ^Syl,
	right	: ^Syl,
	has_vn	: bool,
}

insert :: proc(left,right:^Syl){
	old_right:= left.right
	left.right = right
	right.left = left
	right.right = old_right
	if old_right != nil {
		old_right.left = right
	}
	return
}

apply_rule :: proc(pattern,expands:string , syl:^Syl){
	for curr := syl; curr != nil; {
		scratch := make([dynamic]string)
		defer delete(scratch)
		list := str.split(curr.txt, pattern)

		for txt,i in list[:len(list)-1]{
			
			builder := str.builder_make()
			defer str.builder_destroy(&builder)

			str.write_string(&builder,txt)
			str.write_string(&builder,expands)
			if i == len(list)-2 { // if it's last segment, append the last part that was split
				str.write_string(&builder,list[i+1])
			}

			append(&scratch,str.clone(str.to_string(builder)))
		}
		if len(scratch) == 0 {break}
		curr.txt = scratch[0]
		curr  = insert_list(curr, scratch[1:])

	}
}

fuse :: proc(start:^Syl)->string{
	builder := str.builder_make()

	for curr:=start; curr!=nil; curr = curr.right {
		str.write_string(&builder, curr.txt)
	}
	return str.to_string(builder)
}

insert_list :: proc(start:^Syl, list:[]string)->(last:^Syl){
	curr := start
	for txt in list{
		new_Syl := new_clone(Syl{})
		new_Syl.txt = txt
		insert(curr,new_Syl)
		curr = curr.right

	}
	return curr.right
}

