package main

import "core:fmt"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}

import str"core:strings"


main :: proc(){
	hello := new_clone(Syl{txt = "hello ", left = nil, right = nil, has_vn = true})
	world := new_clone(Syl{txt = "world o", left = nil, right = nil, has_vn = true})
	insert(hello,world)
	insert_list(hello,[]string{"one ","two "})
	apply_rule("o","oho",hello)
	fmt.println(fuse(hello))
}


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
	return
}

apply_rule :: proc(pattern,expands:string , syl:^Syl){
	for curr := syl; curr != nil; {
		scratch := make([dynamic]string)
		defer delete(scratch)
		list := str.split(curr.txt, pattern)
		print("list: ",list)

		for txt,i in list[:len(list)-1]{
			print("processing: ",txt)
			
			builder := str.builder_make()
			defer str.builder_destroy(&builder)

			str.write_string(&builder,txt)
			str.write_string(&builder,expands)
			if i == len(list)-2 { // if it's last segment, append the last part that was split
				print("got it")
				str.write_string(&builder,list[i+1])
			}

			append(&scratch,str.to_string(builder))
		}
		curr.txt = scratch[0]
		curr  = insert_list(curr, scratch[1:])

		clear(&scratch)
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
	old_right:^Syl
	curr := start
	for txt in list{
		new_Syl := new(Syl)
		new_Syl.txt = txt
		insert(curr,new_Syl)
		curr = new_Syl
	}
	return curr.right
}

