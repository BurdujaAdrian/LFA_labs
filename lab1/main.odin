#+feature !dynamic-literals

package main

import "core:fmt"
import "core:math/rand"
import str"core:strings"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}


main :: proc(){
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

	//tests()
	strings := generate_string(&gr)
	fmt.println(strings)


}

string_bool :: struct{str:string,b:bool}
Grammer :: struct{
	patterns    : map[string][dynamic]string_bool,// a map from key:str to val:array(slice) of strings with flag for if they have a non_term
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
	gr.patterns = make(map[string][dynamic]string_bool)
	for pattern in patterns{
		if pattern[0] in gr.patterns {
			append(
				&gr.patterns[pattern[0]],
				string_bool{
					pattern[1],
					(contains_any_from_list(pattern[1],terminals)!=""),
				},
			)
			continue
		}
		// pattern is missing
		gr.patterns[pattern[0]] = make([dynamic]string_bool)
		append(
			&gr.patterns[pattern[0]],
			string_bool{pattern[1],(contains_any_from_list(pattern[1],terminals)!="")},
		)	
	}
	return
}

generate_string :: proc(gr:^Grammer)->[]string{
	strings := make_slice([]string,5)
	
	for &string in &strings {
		start := new_clone(Syl{txt = gr.start, has_vn = true})
		print(
			"\nstart of outer loop\n",
			"start:",start,"\n",
		)

		// iterate through the dll
		for curr := start; curr !=nil; curr = curr.right{
		print("	start of dll loop")
		print("	curr: ",curr)
			for ptrn := contains_any_from_list(curr.txt, gr.non_term); ptrn != ""; ptrn = contains_any_from_list(curr.txt, gr.non_term)  {
				print("	ptrn = ",ptrn)
				choice := rand.choice(gr.patterns[ptrn][:])
				apply_rule(ptrn,choice.str,curr)
				print("	curr after applying ptrn:",curr.txt, "start is",start.txt)
				curr.has_vn = choice.b // if pattern has non_term, then the entire syl has one

				if !curr.has_vn {break} // if no more patterns to apply
			
			}

			
			if curr.left != nil && !curr.has_vn && !curr.left.has_vn {
				curr = curr.left
				merge_with_next(curr)
				print("	curr after merge:",curr)
			}
		}
		print("after autor loop")
		string = fuse(start,true)
		print("output string:",string)
		print("from list: ",strings)
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

			str.write_string(&builder,txt)
			str.write_string(&builder,expands)
			if i == len(list)-2 { // if it's last segment, append the last part that was split
				str.write_string(&builder,list[i+1])
			}

			append(&scratch,str.to_string(builder))
		}
		if len(scratch) == 0 {break}
		curr.txt = scratch[0]
		curr  = insert_list(curr, scratch[1:])

	}
}

merge_with_next :: proc(curr:^Syl){
	curr :=curr // make the argument mutable
	if curr.right == nil{
		return
	}

	builder :=str.builder_make()

	str.write_string(&builder,curr.txt)
	str.write_string(&builder,curr.right.txt)

	// curr <--> curr.right <--> curr.right.right --
	
	// curr <--> curr.right <--> curr.right.right --
	//        right -^
	right := curr.right

	//        /-------------------v
	// curr <-- curr.right --> curr.right.right --
	//   A    right -^           /
	//    \---------------------/
	curr.right = right.right
	right.right.left = curr

	delete(curr.txt)
	curr.txt = str.to_string(builder)

	// clean up
	delete(right.txt)
	free(right)
}

fuse :: proc(start:^Syl, $free_dll:bool)->string{
	builder := str.builder_make()

	for curr:=start; curr!=nil; {
		str.write_string(&builder, curr.txt)
		when free_dll { // compile-time directive
			if curr.right == nil{//last syl
				delete(curr.txt)
				free(curr)
				break
			}
			// else, free up the previous node
			curr = curr.right
			delete(curr.left.txt)
			free(curr.left)
		} else {
			curr = curr.right
		}
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


//@auxiliarry functions

contains_any_from_list :: proc(s:string, list:[]string)->string{
	for substr in list{if str.contains(s,substr) {return substr}}

	return ""
}

print_dll :: proc(hello:^Syl){
	for curr := hello; curr != nil; curr=curr.right {
		printf("%#v \n at adr:%v\n\n",curr, cast(^uintptr)curr )
		if curr.right != nil && curr != curr.right.left{
			printf("next is: %#v \n at adr:%v\n\n",curr.right, cast(^uintptr)curr.right )
			assert(false)
		}
	}
}

tests :: proc(){
	hello := new_clone(Syl{txt = "hello ", left = nil, right = nil, has_vn = true})
	world := new_clone(Syl{txt = "world o", left = nil, right = nil, has_vn = true})
	insert(hello,world)
	insert_list(hello,[]string{"one ","two "})
	apply_rule("o","oho",hello)
	
	merge_with_next(hello)
	print("printing dll\n")
	print_dll(hello)


	fmt.println(fuse(hello,true))
}

