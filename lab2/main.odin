#+feature dynamic-literals

package main

import "core:fmt"
import "core:math/rand"
import "core:unicode/utf8"
import str"core:strings"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else when ODIN_TEST {
	print  :: log.info
	printf :: log.infof
}
else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}


main :: proc(){
	//fmt.printf("generated grammer structure: %#v\n",gr)
	
	aut,_:= init_aut(4,{
		{"q0","b","q0"},
		{"q1","a","q2"},
		{"q1","a","q3"},
		{"q0","a","q1"},
		{"q2","b","q0"},
		{"q2","a","q3"},

	}, {"q3"})
	fmt.printf("\n %#v\n\n",aut)
	
	//aut_type := det_aut_type(&aut)
	//fmt.println(aut_type)

	//test_type_inference2(nil)
	//empty,_ := init_aut(0,{},{})
	//fmt.println(empty)

	dfa := nfa_to_dfa(&aut)
	fmt.printf("\n %#v\n\n",dfa)
}




AutErr :: enum {
	INVALID_INPUT,
	CANNOT_CONVERT,
	// other possible errors, if needed
}
Automaton :: struct{
	// metadata
	states      : u8,//n of states, 
	transitions : []map[string][dynamic]u8, // array of states, each state having a map from string to a list of possible states
	alphabet    : map[string]struct{}, // set of strings
	i     : u8, // initial state
	finals      : bit_set[0..<64;u64], // bit-flags for if (state in finals), assume at most 64 different states
}


init_aut :: proc(
	n_states:u8,
	transitions:[]struct{i:string, input:string, r:string},
	finals:[]string,
)->(aut:Automaton,err:AutErr){

	aut.transitions = make([]map[string][dynamic]u8,auto_cast n_states)
	aut.states = n_states
	aut.alphabet = make(map[string]struct{})

	stoi_map := make(map[string]u8) // map from string to state id
	i:u8=0
	for trans in transitions{
		
		if !(trans.i in stoi_map){
			stoi_map[trans.i] = i
			i+=1
		}
		if !(trans.r in stoi_map){
			stoi_map[trans.r] = i
			i+=1
		}

		state := stoi_map[trans.i]
		if aut.transitions[state][trans.input] == nil{
			aut.transitions[state][trans.input] = make([dynamic]u8)
		}

		append(&aut.transitions[state][trans.input],stoi_map[trans.r])
		aut.alphabet[trans.input] = {}
	}


	print(stoi_map)
	for final in finals{
		aut.finals += {auto_cast stoi_map[final]}
	}
	return
}

Aut_type :: enum{
	deter,
	non_deter,
	epsilon,
}

det_aut_type :: proc(aut:^Automaton)->(aut_type:Aut_type){

	for trans,state in aut.transitions{
		if len(trans) > len(aut.alphabet){
			print("has more transitions then strings in alphabet")
			aut_type = .non_deter
		}
		for input,outputs in trans{

			if input == ""{ // the only short-circuiting case
				print(" has epsilon as transition")
				return .epsilon
			}
			if len(outputs) != 1{
				print(" has non-deterministic output")
				aut_type = .non_deter
			}
		}

		has_all := true

		for input,_ in aut.alphabet{
			has_all &&= input in trans
		}

		if !has_all{
			print("state ",state, " doesn't have all strings in alphabet:",has_all)
			aut_type = .non_deter
		}

	}

	return 
}


nfa_to_dfa :: proc(nfa:^Automaton)->(dfa:Automaton){


	dfa.alphabet = nfa.alphabet
	dfa.states = nfa.states
	dfa.finals = nfa.finals
	
	trans := make([dynamic]map[string][dynamic]u8,nfa.states)
	dead_state :u8= ~u8(0)
	comp_states := make(map[u64]u8)
	defer {delete(comp_states)}
	// iterate through states of nfa
	for state in 0..<nfa.states{
		curr_trans := nfa.transitions[state]
		print("=======================\ncurr trams:",curr_trans, " state=",state)
		// iterate through the alphabet
		for str in nfa.alphabet{
			switch states_list:= curr_trans[str]; len(states_list){
			
			case 1: 
				print("\tall good, added ", curr_trans, " dirrectly to ", state)
				trans[state] =curr_trans

			case 0: // needs to create a dead state
				print("\tnot good, have a dead state")
				if dead_state == ~u8(0){
					print("\t\tmaking a new dead state = ",dfa.states)
				// make new dead_state
					dead_state = dfa.states
					dfa.states +=1
					append_elem(&trans, map[string][dynamic]u8{
						str = new_clone([dynamic]u8{dead_state})^
					})
					trans[state][str] = {dead_state}
					continue
				}
				print("\t\tappending the dead state")
				trans[state][str] = {dead_state}

			case  : // more than 1 state, needs to create hybrid state
				print("\tnot good, have non-deter state")
				state_bit_set:bit_set[0..<64;u64]
				for state in states_list{
					state_bit_set += {auto_cast state}
				}
				val := transmute(u64) state_bit_set
				
				if val not_in comp_states{ // register new composite state
					
					comp_states[val] = dfa.states
					dfa.states +=1
					print("\t\tappendig new comp state ", comp_states[val]," at ",state," for str=",str)
					append(&trans, make(map[string][dynamic]u8))

					trans[state][str] = new_clone([dynamic]u8{
						comp_states[val]
					})^

					// check if anything in the bitset is an accepting state
					for accpt in nfa.finals{
						if accpt in state_bit_set{
							dfa.finals += {auto_cast comp_states[val]}
						}
					}
					
					//printf("%#v",trans)
					continue
				}
				assert(len(trans[state][str]) > 0)
				print("\t\tappending the comp state")
				append(&trans[state][str],comp_states[val])
			}
		}
	}
	//printf("curr trans: %#v",trans)

	// add the transitions of the dead state
	trans[dead_state] = make(map[string][dynamic]u8)
	for str in nfa.alphabet{
		trans[dead_state][str] = new_clone([dynamic]u8{dead_state})^
	}
	
	print(comp_states)
	
	for len(comp_states) != 0 { // while there are composite states
		print("\nstart processing composite states")
		// add the transitions of composite sates
		old_comp_states := new_clone(comp_states)^
		print(old_comp_states)
		defer {delete(comp_states); comp_states = make(map[u64]u8)}

		for states,res in old_comp_states{
			print("	start iterating old_states")
			bit_states := transmute(bit_set[0..<64;u64])states
			for str in dfa.alphabet{
				
				print("		iterating through alphabet")
				// bit set of all the transitions for input str
				trans_bit_set :bit_set[0..<64;u64]
				
				for state in bit_states{
					print("			iterating though bit_states ",nfa.transitions[state][str])
					
					if len(nfa.transitions[state][str]) < 1 {continue}
					for new_state in nfa.transitions[state][str]{
						trans_bit_set +=  {auto_cast new_state}
					}
				}
				print("\t\t================")
				print("\t\tfor ", str, "found ", trans_bit_set, " ", transmute(u64)trans_bit_set)
				
				val := transmute(u64) trans_bit_set
				if card(trans_bit_set) == 1{

					for bit in trans_bit_set{
						trans[res][str] = new_clone([dynamic]u8{auto_cast bit})^
					}
					continue
				}
				if card(trans_bit_set) == 0 {
					trans[res][str] = new_clone([dynamic]u8{dead_state})^
				}
				if val not_in comp_states { // register new composite state
					comp_states[val] = dfa.states
					dfa.states +=1
					continue
				}
			}
		}
	}

	printf("\n\n========\ndead state: %v , %v\n============\n\n", trans[dead_state], dead_state)

	printf("\n\n========\ncomp state: %v , %v\n============\n\n", trans[4], 4)

	
	// copying the results
	dfa.transitions = trans[:]
	print("transformation succesfull")
	return
}


deinit_aut :: proc(aut:^Automaton){
	panic("TODO:implement deinit for automaton")
}

Gr_type :: enum{
	type3,
	type2,
	type1,
	type0,
}

det_gr_type :: proc(gr:^Grammar)->(gr_type:Gr_type){
	gr_type = .type3 // assume it's type 3
	
	left_regular := false // assume it's not left_regular type 3 grammer
	right_regular:= false // assume it's not also right_regular, if both then it's type 2

	ctx_sens := false // flag that remebers if the grammer is context sensitive

	for key,value in gr.patterns{
		for ptrn in value{
			// check if it's context dependant, assuming only one char per simbol
			type2_l : {
				if len(key) > 1 || ctx_sens {
					break type2_l 
				}
				
				ensure(!ctx_sens)

				print()
				print(ptrn)
				if ptrn.b { // if has non-terms
					assert(len(ptrn.str) != 1)
					print("value = ",ptrn.str)
					// if first is a non terminal, it's left_regular
					print("trying for ",ptrn.str[0:1] )
					left_regular ||= contains_any_from_list(ptrn.str[0:1], gr.non_term) != ""
					strlen := len(ptrn.str)
					print(left_regular)

					print("\ntrying for ",ptrn.str[strlen-1:strlen] )
					right_regular ||= contains_any_from_list(ptrn.str[strlen-1:strlen], gr.non_term) != ""
					print(right_regular)
					
					if right_regular == left_regular {
						print("type 3 can't be both")
						gr_type = .type2
						break
					}
				}
				continue
			}
			// check if it's context free or rec. enumerable
			ctx_sens = true
			if len(key) > len(ptrn.str){
				print("it's type 0")
				return .type0
			}
			print("probably type 1")
		}
	}

	print(left_regular,right_regular)
	if left_regular != right_regular && !ctx_sens{
		print("it's ", gr_type)
		return
	}
	print("it's not type3")


	//	// check if it's type 3
	if ctx_sens {
		print("def type1")
		return .type1
	}

	print("it's type3 or type2")
	return
}

string_bool :: struct{str:string,b:bool}
Grammar :: struct{
	patterns    : map[string][dynamic]string_bool,// a map from key:str to val:array(slice) of strings with flag for if they have a non_term
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
	gr.patterns = make(map[string][dynamic]string_bool)
	for pattern in patterns{
		if pattern[0] in gr.patterns {
			append(
				&gr.patterns[pattern[0]],
				string_bool{
					pattern[1],
					(contains_any_from_list(pattern[1],non_term)!=""),
				},
			)
			continue
		}
		// pattern is missing
		gr.patterns[pattern[0]] = make([dynamic]string_bool)
		append(
			&gr.patterns[pattern[0]],
			string_bool{pattern[1],(contains_any_from_list(pattern[1],non_term)!="")},
		)
	}
	return
}

destroy_grammer::proc(gr:Grammar){
	for key,value in gr.patterns{delete(value)}
	delete(gr.patterns)
}

//@auxiliarry functions

Syl :: struct{
	txt	: string,
	left	: ^Syl,
	right	: ^Syl,
	has_vn	: bool,
}

contains_any_from_list :: proc(s:string, list:[]string)->string{
	for substr in list{
		print("substr: ",substr)
		if str.contains(s,substr) {
			print("matches")
			return substr
		}
	}
	print("miss")
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

import "core:testing"
import "core:log"

@(test)
test_type_inference1 :: proc(t: ^testing.T){
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
	defer destroy_grammer(gr)

	print("checking type3")
	gr_type3 := det_gr_type(&gr)
	print(gr_type3)
	assert( gr_type3 == .type3)

	gr2 := init_grammar(
		patterns  = {
			{"S","bS"},
			{"S","d"},
			{"S","aF"},
			{"F","dF"},
			{"F","Fc"},
			{"F","aL"},
			{"L","aL"},
			{"L","c"},
			{"F","b"},
		}, 
		terminals={"a","b","c","d"},
		non_term={"S","F","L"}, 
		start = "S")
	defer destroy_grammer(gr2)

	print("checking type2")
	gr_type2 := det_gr_type(&gr2)
	print(gr_type2)
	assert( gr_type2 == .type2)

	gr3 := init_grammar(
		patterns = {
			{"S",  "aSBC"},    
			{"S",  "aBC"},     
			{"CB", "BC"},      
			{"aB", "ab"},      
			{"bB", "bb"},      
			{"bC", "bc"},      
			{"cC", "cc"},      
		},
		terminals = {"a", "b", "c"},
		non_term = {"S", "B", "C"},
		start = "S")
	defer destroy_grammer(gr3)

	print("checking type 1")
	gr_type1 := det_gr_type(&gr3)
	print(gr_type1)
	assert( gr_type1 == .type1)

	gr4 := init_grammar(
		patterns = {
			{"S", "aSa"},     
			{"S", "bSb"},     
			{"S", "c"},       
			{"aS", "Sa"},     
			{"aSa", "bSb"},   
			{"Sb", "ε"},      
			{"bSb", "a"},     
			{"ε", "S"},       
		},
		terminals = {"a", "b", "c"},
		non_term = {"S"},
		start = "S")
	defer destroy_grammer(gr4)

	print("checking type 0")
	gr_type0 := det_gr_type(&gr4)
	print(gr_type0)
	assert(gr_type0 == .type0)
}

q0 :: "q0"
q1 :: "q1"
q2 :: "q2"
q3 :: "q3"

a :: "a"
b :: "b"
c :: "c"
d :: "d"

e :: ""

@(test)
test_type_inference2::proc(t:^testing.T){
	aut_type:Aut_type
	



	aut_d,_ := init_aut(2,{
		{q0,a,q1},
		{q1,a,q1},
	},{q1})

	fmt.printf("\n %#v \n\n",aut_d)
	
	aut_type = det_aut_type(&aut_d)

	log.info("expected deter, found: ",aut_type)
	assert(aut_type == .deter)

	aut_non_d,_:= init_aut(4,{
		{q2,a,q3},
		{q0,b,q0},
		{q1,a,q2},
		{q1,a,q3},
		{q0,a,q1},
		{q2,b,q0},
	}, {q3})
	fmt.printf("\n %#v\n\n",aut_non_d)
	
	aut_type = det_aut_type(&aut_non_d)
	log.info("expecting non_deter, found: ",aut_type)
	assert(aut_type == .non_deter)

	aut_epsilon,_:= init_aut(2,{
		{q1,e,q2}
	}, {q2}	)
	fmt.printf("\n %#v\n\n",aut_epsilon)

	aut_type = det_aut_type(&aut_epsilon)
	log.info("expecting epsilon non-deter. , found:", aut_type)
	assert(aut_type == .epsilon)
}

@(test)
test_conv :: proc(t:^testing.T){
	nfa,_:= init_aut(4,{
		{q2,a,q3},
		{q0,b,q0},
		{q1,a,q2},
		{q1,a,q3},
		{q0,a,q1},
		{q2,b,q0},
	}, {q3})
	aut_type := det_aut_type(&nfa)
	assert(aut_type == .non_deter)
	dfa := nfa_to_dfa(&nfa)
	
	aut_type = det_aut_type(&dfa)
	assert(aut_type == .deter)
}
