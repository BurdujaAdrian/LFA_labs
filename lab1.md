# Laboratory Work #1: Regular Grammars & Finite Automata

### Course: Formal Languages & Finite Automata
### Author: Burduja Adrian

----

## Theory
If needed, but it should be written by the author in her/his words.


##  Objectives:

1. Discover what a language is and what it needs to have in order to be considered a formal one;

2. Provide the initial setup for the evolving project that you will work on during this semester. You can deal with each laboratory work as a separate task or project to demonstrate your understanding of the given themes, but you also can deal with labs as stages of making your own big solution, your own project. Do the following:

    a. Create GitHub repository to deal with storing and updating your project;

    b. Choose a programming language. Pick one that will be easiest for dealing with your tasks, you need to learn how to solve the problem itself, not everything around the problem (like setting up the project, launching it correctly and etc.);

    c. Store reports separately in a way to make verification of your work simpler (duh)

3. According to your variant number, get the grammar definition and do the following:

    a. Implement a type/class for your grammar;

    b. Add one function that would generate 5 valid strings from the language expressed by your given grammar;

    c. Implement some functionality that would convert and object of type Grammar to one of type Finite Automaton;

    d. For the Finite Automaton, please add a method that checks if an input string can be obtained via the state transition from it;


## Implementation description

```Odin

string_bool :: struct{str:string,b:bool}// tuple of string and bool
Grammar :: struct{
	patterns    : map[string][dynamic]string_bool,// a map from key:str to val:array(slice) of strings with flag for if they have a non_term
	non_term    : []string,
	terminals   : []string,
	start       : string, 
}
```
To increase efficiency, a hash_map [[1]] from string to an dynamic array was used since one symbol can have many different associated outputs. It's dynamic purely for convenience purpose, it could have been a normal array(a slice).

The struct string_bool exists to store both the string that the key must be replaced with, and whether it contains another non terminal.Caching [[2]] this bool removes the need to make more iterations over the string to find this inforamtion latter.


```Odin
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
```

This functions takes as input the usual parts of a regular grammer, and places the values in the struct accordingly

```Odin
generate_string :: proc(gr:^Grammar)->[]string{
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

Syl :: struct{
	txt	: string,
	left	: ^Syl,
	right	: ^Syl,
	has_vn	: bool,
}
```
The Syl struct was an early idea, to use a double linked list-like structure for more optimal inserting. However, since this is a regular right grammer, it's unnecesary yet still working. Because of the functions already created for this type, I decided to leave it be.

The function generates random strings by choosing one of the possible outputs for the current pattern/non terminal in the string.

I'll leave the other auxilary functions used here out of the raport as they are self-explanatory, for more details please check the source code.

```Odin
AutErr :: enum {
	INVALID_INPUT,
	// other possible errors, if needed
}
Automaton :: struct{
	// state data
	curr_state  :u8,

	// metadata
	states      : u8,//n of states, 
	transitions : []map[string]u8, // array of states, each state having a map from string to another state
	//alphabet    : []string, // is not needed, it's fully contained within transitions
	initial     : u8, // initial state
	finals      : bit_set[0..<16;u16], // bit-flags for if (state in finals), assume at most 16 different states
}
```

Automaton structs contains the information necesarry for an automaton. To increase efficiency of retrieving data, the different states are encoded as numbers(u8), final state being = states

The different state transitions are encoded as an array(where the index is the current state) of hash maps from string(input) to resulting state.

The set of final states are recorded as a bit set [[3]] where each nth bit represents whether the state n is final. The Odin programming language provides convenient syntax to create and utilise such bit sets. It could be removed as it's never used.

The struct went through a few iterations before getting to this form.

```Odin
automaton_from_grammar :: proc(gr:^Grammar)->(aut:Automaton){
	// allocate memory for the array of arrays of state transitions
	aut.states = auto_cast len(gr.terminals)
	aut.transitions = make_slice([]map[string]u8, aut.states-1 )// there are no transitions from final state = aut.stetes
	
	// construct a mapping from non_terminals(string) to states(u8)
	stoi_map := make(map[string]u8)
	defer delete(stoi_map)

	for str,i in gr.non_term{
		stoi_map[str] = auto_cast i
	}
	
	// maps empty string to Final state, 
	// when the pattern doesn't contain a non_term, the non_term string is ""
	stoi_map[""] = aut.states-1
	
	print("current mapping: ",stoi_map)

	for &trans,state in &aut.transitions{
		
		trans = make(map[string]u8)
		
		print("\ngenerating trans for :",state)
		key:=gr.non_term[state]
		value:= gr.patterns[key]
		print("	key:",key, " value:",value)
		for ptrn in value{
			// if pattern has a non_t, set the corresponding bit in the bit_set
			if ptrn.b {aut.finals += {int(stoi_map[key])}}
			// assume terminal is on the left
			trans[ptrn.str[0:1]] = stoi_map[ ptrn.str[1:len(ptrn.str)]]
		}
		print("transitions for ", state, trans)
	}
	
	when ODIN_DEBUG { //compile time directive
		for state in gr.non_term{
			print("state :",state, stoi_map[state])
			print("	maps :",aut.transitions[stoi_map[state]])
		}
	}
	return
}
```
For more convenience, a map from strings to states is used, for the reverse, indexing the input grammar's field "states" with the correct state number is possible.

```Odin
run :: proc(aut:^Automaton, inputs: string)->AutErr{
	aut.curr_state = aut.initial 
	for i := 0 ; i < len(inputs); i+=1  {
		input := inputs[i:i+1]
		fmt.println("	current input: ", input)
		if aut.curr_state == aut.states - 1 {
			fmt.println("	reached final state, exiting")
			return nil
		}
		next_state, ok := aut.transitions[aut.curr_state][input]
		if !ok {// input isnt a key in map, so it's an error
			fmt.println("	",input," is invalid")
			return .INVALID_INPUT
		}
		aut.curr_state = next_state
	}
	return nil
}
```

## Conclusions / Screenshots / Results

Output of running the code:
```
PS C:\Users\eu\Desktop\lfa\LFA_labs\lab1> .\main.exe
generated grammer structure: Grammar{      
        patterns = map[
                L = [
                        string_bool{       
                                str = "aL",
                                b = true,  
                        },
                        string_bool{       
                                str = "c", 
                                b = true,  
                        },
                ],
                S = [
                        string_bool{       
                                str = "bS",
                                b = true,  
                        },
                        string_bool{       
                                str = "d", 
                                b = true,  
                        },
                        string_bool{       
                                str = "aF",
                                b = true,  
                        },
                ],
                F = [
                        string_bool{       
                                str = "dF",
                                b = true,
                        },
                        string_bool{
                                str = "cF",
                                b = true,
                        },
                        string_bool{
                                str = "aL",
                                b = true,
                        },
                        string_bool{
                                str = "b",
                                b = true,
                        },
                ],
        ],
        non_term = [
                "S",
                "F",
                "L",
        ],
        terminals = [
                "a",
                "b",
                "c",
                "d",
        ],
        start = "S",
}
["ab", "ab", "d", "adb", "badcac"]

 Automaton{
        curr_state = 0,
        states = 4,
        transitions = [
                map[
                        a = 1,
                        b = 0,
                        d = 3,
                ],
                map[
                        b = 3,
                        a = 2,
                        d = 1,
                        c = 1,
                ],
                map[
                        a = 2,
                        c = 3,
                ],
        ],
        initial = 0,
        finals = bit_set[0..=15; u16]{0, 1, 2},
}

attempting to run input:  ab
        current input:  a
        current input:  b
attempting to run input:  ab
        current input:  a
        current input:  b
attempting to run input:  d
        current input:  d
attempting to run input:  adb
        current input:  a
        current input:  d
        current input:  b
attempting to run input:  badcac
        current input:  b
        current input:  a
        current input:  d
        current input:  c
        current input:  a
        current input:  c
```

## References

[Official Odin documentation](https://odin-lang.org/docs/)
Additional resources:

[Regular grammar](https://www.geeksforgeeks.org/regular-grammar-model-regular-grammars/)
[Introduction of Finite Automata](https://www.geeksforgeeks.org/introduction-of-finite-automata/)
[1](https://en.wikipedia.org/wiki/Hash_table)
[2](https://www.geeksforgeeks.org/caching-system-design-concept-for-beginners/)
[3](https://en.wikipedia.org/wiki/Bit_array)


