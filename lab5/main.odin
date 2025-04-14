#+feature dynamic-literals

package main

import "core:fmt"
import "core:math/rand"
import "core:unicode/utf8"
import uni "core:unicode"
import str"core:strings"


when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}

void :: struct{}


main :: proc(){
	gr := init_grammar(
		patterns  = {
			{"S","A"},
			{"A","d"},
			{"A","dS"},
			{"A","aBdB"},
			{"B","a"},
			{"B","AC"},
			{"D","AB"},
			{"C","bC"},
			{"C",""},
		}, 
		terminals={"a","b","d"},
		non_term={"S","A","B","C","D"}, 
		start = "S")
	printf("%#v",gr)
	print_gr(&gr)



	new_gr := normalize(&gr)
	print_gr(&new_gr)

}

Grammar :: struct{
	patterns    : map[string]map[string]void,
	non_term    : [dynamic]string,
	terminals   : []string,
	start       : string, 
}

normalize :: proc(gr:^Grammar)->(new_gr:Grammar){
	// assume lowercase = terminal
	// assume 1 char = [non ]terminal

	new_gr = Grammar{
		nil,
		nil,
		gr.terminals,
		gr.start,
		
	}
	new_gr.patterns = make(map[string]map[string]void)
	new_gr.non_term = make([dynamic]string)

	// adds all productive patterns recursivly
	get_patterns_and_non_term(gr.start,gr, &new_gr)

	// fix start symbol
	fix_start(&new_gr)

	// remove non-solitary prods
	remove_nons(&new_gr)

	// remove prods with multiple non-term
	remove_mult(&new_gr)

	// remove "" productions
	remove_empty(&new_gr)

	// remove productions of form N_a -> N_b
	remove_unit(&new_gr)
	return
}

remove_unit :: #force_inline proc(gr:^Grammar){
	finished := false

for !finished{
	
	finished = true
	copy := ptrn_copy(gr.patterns)
	for nonterm,prods in copy{
	for prod in prods{
		if len(prod) == 1 && uni.is_upper(auto_cast prod[0]){
			finished = false
			curr := &gr.patterns[nonterm]
			delete_key(curr,prod)

			for unit_prod in copy[prod]{
				curr[unit_prod] = {}
			}
		}

	}}
}

}

remove_mult :: #force_inline proc(gr:^Grammar){
	finished := false

for !finished{
	
	finished = true

first:	for nonterm,prods in ptrn_copy(gr.patterns){
second:	for prod in prods{
		if len(prod) > 2 {
			// make new non_term
			finished = false
			new_nont := new_unit(gr.non_term)
			append(&gr.non_term, new_nont)
			
			gr.patterns[new_nont] = map[string]void{prod[0:2] = {}}

			curr := &gr.patterns[nonterm]
			delete_key(curr,prod)

			new_prod,_ :=str.replace_all(prod,prod[0:2],new_nont)
			curr[new_prod] = {}
		}
	}}
}

}
new_unit :: proc(set:[dynamic]string)->string{
	for true{
		rand_i :=u8(rand.uint64() % ('Z' - 'A'))
		new_char := rand_i + 'A'
		found :=true
		for nont in set{
			if nont[0] == auto_cast new_char{
				found = false
			}
		}

		if found {
			temp := make([]u8,1)
			temp[0] = new_char
			unit :string=  auto_cast temp
			print("new unit created:",unit)
			return unit
		}
	}
	// mandatory return statement despite being inaccesable
	return ""
}

remove_nons :: #force_inline proc(gr:^Grammar){
	finished := false

for !finished{
	
	finished = true

first:	for nonterm,prods in ptrn_copy(gr.patterns){
second:	for prod in prods{
	for char,i in prod{
		if uni.is_lower(char){
			if len(prod) < 2 {
				continue
			}
			unit := new_unit(gr.non_term)
			append(&gr.non_term, unit)
			gr.patterns[unit] = map[string]void{prod[i:i+1] = {}}

			curr := &gr.patterns[nonterm]
			print("prod to be delete:", prod)
			delete_key(curr, prod)
			new_prod,_ := str.replace_all(prod,prod[i:i+1],unit)
			curr[new_prod] = {}
			finished = false
			break second
		}
	}}}
}

}




remove_empty :: #force_inline proc(gr:^Grammar){
	finished := false
	tbr := make([dynamic]string)

for !finished{
	finished = true


	for nonterm,prods in ptrn_copy(gr.patterns){
	for prod in prods{
	for char,i in prod{
		// if the current production goes to a non term
		if curr,ok := gr.patterns[prod[i:i+1]]; ok{

			// if that nonterm produces ""
			if _,ok2 := curr[""]; ok2{
				printf("%v",curr)
				append(&tbr,prod[i:i+1])
				finished = false
				// removes the non terminal that produces "" by splitting the production using that non terminal
				curr := &gr.patterns[nonterm] 
				curr[str.concatenate(str.split(prod,prod[i:i+1]))] = {}
				print("added key:", str.concatenate(str.split(prod,prod[i:i+1])), " to ", nonterm)

			}
		}
		
	}}}

	for nonterm in tbr{
		curr := &gr.patterns[nonterm]
		delete_key(curr,"")

	}
}
}

ptrn_copy :: #force_inline proc(ptrn:map[string]map[string]void )->map[string]map[string]void{
	new_ptrn := make(map[string]map[string]void)
	for key,val in ptrn{
		new_ptrn[key] = new_clone(val)^
		assert(&new_ptrn[key] != &ptrn[key])
	}
	
	return new_ptrn
}

fix_start :: #force_inline proc(gr:^Grammar){
	new_start:string = fmt.aprintf("%s'", gr.start)
	occurs:bool = false
	
	gr.patterns[new_start] = map[string]void{gr.start = {}}

	for _,prods in gr.patterns{
		for prod in prods{
			occurs ||= str.contains(prod,gr.start)
		}
	}

	if occurs{
		print("it occured")
		gr.start = new_start
		printf("curr non terms: %v\n", gr.non_term)
		append(&gr.non_term, new_start)
		printf("non terms after append: %v\n\n", gr.non_term)
		return
	}

	delete_key(&gr.patterns, new_start)
}


get_patterns_and_non_term :: proc(
	nt:string,
	gr : ^Grammar, 
	new_gr : ^Grammar,
){
	// if the non terminal is already in the map, just return
	if _,ok := new_gr.patterns[nt]; ok{return}
	prods := gr.patterns[nt]
	new_gr.patterns[nt] = prods
	
	has_dup:=false
	for nonterm in new_gr.non_term{
		if nt == nonterm{
			has_dup = true
		}
	}

	if !has_dup{
		append(&new_gr.non_term,nt)
	}


	for prod in prods{
		for char,i in prod{
			if uni.is_upper(char){
				get_patterns_and_non_term(prod[i:i+1], gr, new_gr)
			}
		}
	}
}


init_grammar :: proc(
	patterns:[][2]string, 
	terminals:[]string, 
	non_term:[dynamic]string, 
	start:string,
)->(gr : Grammar){
	gr.terminals = terminals
	gr.non_term = non_term
	gr.start = start
	gr.patterns = make(map[string]map[string]void)
	for pattern in patterns{
		if pattern[0] in gr.patterns {
			curr := &gr.patterns[pattern[0]]
			curr[pattern[1]] = {}
			continue
		}
		gr.patterns[pattern[0]] = make(map[string]void)
		curr:=&gr.patterns[pattern[0]]
		curr[pattern[1]] = {}
	}
	return
}

print_gr :: proc(gr:^Grammar){
	fmt.println("Grammar = {")
	fmt.printfln("\tstart: %v,",gr.start)
	fmt.println("	patterns: [")

	alph := make(map[rune]void)

	for key,list in gr.patterns{
		for item in list{
			fmt.printf("\t\t%s -> %s,\n",key, item)
			for char in item{
				if uni.is_lower(char){alph[char] = {}}
			}
		}
	}

	fmt.println("\t],")

	fmt.println("\tterminals: [")
	
	for terminal in gr.terminals{
		fmt.printf("\t\t%s,\n",terminal)
	}
	fmt.println("\t],")


	fmt.println("\tnon-terminals: [")
	
	for non_term in gr.non_term{
		fmt.printf("\t\t%s,\n",non_term)
	}
	fmt.println("\t],")

	fmt.println("}")
}

