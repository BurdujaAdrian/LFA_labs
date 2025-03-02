# The title of the work

### Course: Formal Languages & Finite Automata
### Author: Burduja Adrian

----

## Theory


#### Chomsky hierarchy

Chomsky hierarchy is a way to categorize different grammars based on their properties.

Type 3 grammar, a.k.a. regular grammar, is the simplest. It can be of 2 types: right linear and 
left linear.
- Left Linear Regular Grammar: In this type of regular grammar, all the non-terminals on the left-hand side exist at the leftmost place, i.e; left ends.
- Right Linear Regular Grammar: In this type of regular grammar, all the non-terminals on the right-hand side exist at the rightmost place, i.e; right ends.

If a grammar has both left linear and right linear production rules then it's no longer type 3.

Type 2 grammar, a.k.a. context free grammar.
In formal language theory, a context-free grammar (CFG) is a formal grammar whose production 
rules can be applied to a nonterminal symbol regardless of its context.

If a grammar has production rules that are context dependent, clearly it is no longer context free

Type 1 grammar, a.k.a. context sensitive grammar.
A context-sensitive grammar (CSG) is a formal grammar in which the left-hand sides and right-hand sides of any production rules may be surrounded by a context of terminal and nonterminal symbols.

If a grammar has more symbols on the left-hand side then it's no longer type 1

Type 0 grammar, a.k.a unrestricted grammar are, as the name implies, unrestricted

#### Finite automata

There are 3 types of finite automata: deterministic, non-deterministic and epsilon non-deterministic

All f.a. describe a regular grammar

In order for an fa to be an dfa it must be: 
- deterministic: 
	any input to a state must have one and only one output
	must have no transitions on empty string
- complete : all states must have a transition function for each input symbol in it's alphabet

Any dfa is also a nfa.

In order for an fa to be an nfa it must only not have epsilon transitions(transitions with "" as input)

Any nfa is also an enfa.
Enfa have no requirements.

---

Steps to convert a nfa to a dfa:

1. Iterate though all the transition functions. 
	- If one of the functions has multiple outputs: register those outputs as a new state
		- If one of the outputs is a accpeting state, then this compund state is also accepting

	- If the function lacks an output for a given symbol from the alphabet: create a dead state if it doesnt exist already
2. Add the dead state and the transition function, which are all to itself regardless of input
3. Iterate through the registered comound states
	- Create transition functions for them, where the output is the set of the outputs of the states the compund state is made of. 
		- If the transition function has more than one state, register a new compound state
	- Remove this compund state from the list
	- Repeat 3. until the list is empty
## Objectives:

1. Understand what an automaton is and what it can be used for.

2. Continuing the work in the same repository and the same project, the following need to be added:
    a. Provide a function in your grammar type/class that could classify the grammar based on Chomsky hierarchy.

    b. For this you can use the variant from the previous lab.

3. According to your variant number (by universal convention it is register ID), get the finite automaton definition and do the following tasks:

    a. Implement conversion of a finite automaton to a regular grammar.

    b. Determine whether your FA is deterministic or non-deterministic.

    c. Implement some functionality that would convert an NDFA to a DFA.
    
    d. Represent the finite automaton graphically (Optional, and can be considered as a __*bonus point*__):
      
    - You can use external libraries, tools or APIs to generate the figures/diagrams.
        
    - Your program needs to gather and send the data about the automaton and the lib/tool/API return the visual representation.

Please consider that all elements of the task 3 can be done manually, writing a detailed report about how you've done the conversion and what changes have you introduced. In case if you'll be able to write a complete program that will take some finite automata and then convert it to the regular grammar - this will be **a good bonus point**.

#### Varient:



## Implementation description


To be able to properly describe a finite automata, the struct Automaton, the field transitions
more precisely, was modified:
```odin
transitions : []map[string][dynamic]u8, // array of states, each state having a map from string to a list of possible states
```

For ease of use, I have written an init function for creating an automaton:
```odin
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
```

The implementation executes the steps described in theory section to complete each task.
To check the correctness of the algorythm, I have written a few unit tests to test different 
cases. Some of the functions are very long and convoluted so I think it's fine to not copy paste tem here, you can check out the source code instead.


## Conclusions / Screenshots / Results

During the elaboration of this laboratory I have learned the different Chomsky types of grammars and how to distinguish between them, about the different types of finite automata, what rules and properties they have and how to convert from nfa to dfa. I have written and tested my code which I made as generic as I could to be able to execute the tasks for my specific varient and any other possible varient. 

I have gotten the fallowing results: 
- All the tests regarding identifying the Chopsky type of grammar have passed. 
- All the tests regarding identifying the type of the fa have passed.
- I have managed to convert my varient of fa( which more specifically a nfa) to a dfa, the output of the main program(slightly formatted) is:
```
 Automaton{
        states = 6,
        transitions = [
                map[ b = 0, a = 1],
                map[ a = 5, b = 4],
                map[ b = 0, a = 3],
                map[ b = 4, a = 4],
                map[ b = 4, a = 4],
                map[ b = 0, a = 3],
        ],
        alphabet = map[
                b = {},
                a = {},
        ],
        i = 0,
        finals = bit_set[0..=63; u64]{3, 5},
}
```
Where each index in the list of transitions is a state



## References

[Resources relatedd to linear Regular Grammars](https://www.geeksforgeeks.org/right-and-left-linear-regular-grammars/)

[Definition of context-free grammar](https://en.wikipedia.org/wiki/Context-free_grammar)
