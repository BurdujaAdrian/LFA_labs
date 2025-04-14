# Regular expressions

### Course: Formal Languages & Finite Automata
### Author: Burduja Adrian

----

## Theory

In formal language theory, a context-free grammar, G, is said to be in Chomsky normal
form (first described by Noam Chomsky) if all of its production rules are of the 
form:

A → BC,	or
A → a,	or
S → ε,

where A, B, and C are nonterminal symbols, the letter a is a terminal symbol (a 
symbolthat represents a constant value), S is the start symbol, and ε denotes the
empty string. Also, neither B nor C may be the start symbol, and the third
production rule can only appear if ε is in L(G), the language produced by the context
-free grammar G.
Every grammar in Chomsky normal form is context-free, and conversely, every
context-free grammar can be transformed into an equivalent one[note 1] which is in
Chomsky normal form and has a size no larger than the square of the original 
grammar's size.

## Objectives:

1. Learn about Chomsky Normal Form (CNF) [1].
2. Get familiar with the approaches of normalizing a grammar.
3. Implement a method for normalizing an input grammar by the rules of CNF.
    1. The implementation needs to be encapsulated in a method with an appropriate signature (also ideally in an appropriate class/type).
    2. The implemented functionality needs executed and tested.
    3. Also, another **BONUS point** would be given if the student will make the aforementioned function to accept any grammar, not only the one from the student's variant.

## Implementation description

To be able to convert a grammar to CNF, I first must be able to represent grammar as
data in the code. To do this, I reused the struct created in previous labs, with some
tweaks.

```odin
Grammar :: struct{
	// a map from string to maps from string to nothing(a set)
// this allows for writing less code to find the correct entry, 
	// for smaller data, this is less efficient than a simply array
	patterns    : map[string]map[string]void,

	// dynamic list of strings. It's dynamic as opposed to a simply slice simply
	// for ease of use
	non_term    : [dynamic]string,
	terminals   : []string,
	start       : string, 
}
```


The function that does the "normalization is this:"

```odin
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
```

I have used this sequence of transformation to be able to convert the grammar in one
pass.

```get_patterns_and_non_term``` is a function that recursivly checks the productions 
from a given simbol to find which non terminal it leads to, this way it eliminates
non-productive symbols.


```fix_start``` adds a new start non terminal that simply produces the old symbol.


```remove_nons``` finds all the productions that contain a non-solitary terminal.
It then creates a new non-terminal, substitutes it for the terminal in the production
and adds the corresponding production for that new non terminal.

```remove_mult``` removes all productions of length 3 or more by creating a new non
terminal that produces the 1st 2 symbols, substituting them with it and creating
the new production. This process is repeated until no more changes are made.

```remove_empty``` finds all the productions that yield a non terminal, then checks 
if that symbol also has a "" production, if it does, it adds a new production to the
current non terminal that does't contain the empty nonterminal, then it adds the non
terminal to a list to be deleted later. This is repeased until no changes are made in
one of the iterations.

```remove_unit``` removes all unit productions by adding a new production to the 
current non terminal for every production that unit had. This process is repeated 
untill no changes are made.


```odin
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
```

Most function fallow the same logic of looping over all the productions within an 
infinite loop and setting the finished flag to flase if a modification was made ->
there might be more needed.

To be able to modify the grammar while iterating it, to avoid bugs rolated to 
invalidation of memory and other undefined behaviour, I've written a function to create
a deep copy of the patterns(productions) of the grammer:
```odin
ptrn_copy :: #force_inline proc(ptrn:map[string]map[string]void )->
map[string]map[string]void{
	new_ptrn := make(map[string]map[string]void)
	for key,val in ptrn{
		new_ptrn[key] = new_clone(val)^
		assert(&new_ptrn[key] != &ptrn[key])
	}
	return new_ptrn
}
```

Some operations require to create new non terminals, for that I've created a helper 
function that randomly picks a number between 'A' and 'Z' and checks if it's already 
in the list of non terminals. This loops until a suitable value is found. This, of 
course, assumes there won't be a grammer that requires more than 'Z' - 'A' symbols.
```odin
new_unit :: proc(set:[dynamic]string)->string{
	for true{
		rand_i :=u8(rand.uint64() % ('Z' - 'A'))
		new_char := rand_i + 'A'
		found :=true
		for nont in set{
			if nont[0] == auto_cast new_char{found = false}
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
```

Since (hash-)maps are not deterministic when they are iterated over, the resulting 
grammar is unique and might not be the most optimal.

## Conclusions / Screenshots / Results

The laboratory provided practical insights into grammar normalization, reinforcing 
theoretical concepts through implementation. The resulting CNF grammar, though not 
always minimal, adheres to the formal requirements, validating the approach. Future 
enhancements could include optimizing non-terminal selection and supporting 
multi-character symbols. Overall, the project successfully bridges theory and 
application, deepening understanding of context-free grammars and their 
normalization.

Result:
```
PS C:\Users\eu\Desktop\lfa\LFA_labs\lab5> .\run.bat
Grammar = {
        start: S,
        patterns: [       
                S -> A,   
                C -> bC,  
                C -> ,    
                D -> AB,  
                A -> aBdB,
                A -> d,   
                A -> dS,  
                B -> AC,  
                B -> a,   
        ],
        terminals: [      
                a,        
                b,        
                d,        
        ],
        non-terminals: [  
                S,        
                A,        
                B,        
                C,        
                D,        
        ],
}
Grammar = {
        start: S',
        patterns: [
                S -> UB,
                S -> d,
                S -> MS,
                C -> b,
                C -> EC,
                M -> d,
                B -> AC,
                B -> a,
                B -> d,
                B -> MS,
                B -> UB,
                G -> a,
                S' -> MS,
                S' -> d,
                S' -> UB,
                A -> UB,
                A -> d,
                A -> MS,
                Q -> GB,
                F -> d,
                E -> b,
                U -> QF,
        ],
        terminals: [
                a,
                b,
                d,
        ],
        non-terminals: [
                S,
                A,
                B,
                C,
                S',
                G,
                E,
                F,
                M,
                Q,
                U,
        ],
}
```
## References
[1] [Chomsky Normal Form Wiki](https://en.wikipedia.org/wiki/Chomsky_normal_form)
