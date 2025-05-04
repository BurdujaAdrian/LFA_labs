# The title of the work

### Course: Formal Languages & Finite Automata
### Author: Burduja Adrian

----

## Theory
An Abstract syntax tree is a data structure that can be used to describe the syntax 
of some programming languege.

It's useful for more complicated programs because it's easier to modify than an array
of characters.

## Objectives:
1. Get familiar with parsing, what it is and how it can be programmed [1].
2. Get familiar with the concept of AST [2].
3. In addition to what has been done in the 3rd lab work do the following:
   1. In case you didn't have a type that denotes the possible types of tokens you need to:
      1. Have a type __*TokenType*__ (like an enum) that can be used in the lexical analysis to categorize the tokens. 
      2. Please use regular expressions to identify the type of the token.
   2. Implement the necessary data structures for an AST that could be used for the text you have processed in the 3rd lab work.
   3. Implement a simple parser program that could extract the syntactic information from the input text.

## Implementation description

My implementation of the tokenizer already contained all the information needed about
the tokens so I didn't have a need for using regular expressions.

The parser is based on the grammar for the DSL we are working on for writing music.

The Ast is an struct with different fields that contain the necesarry information to
reconstruct the program it has parsed and also feed it to the next step of the 
compilation pipeline for assembling into the binary format.

```Odin
Ast :: struct {
	sments  : [dynamic]Statement,
	def : map[string]Idt,

	errors	    : [dynamic]ParseError,

	last_track_id : int,
}
```
The parser also does syntax checks and return error code at the first instance where
it finds one.

The parsing itself is linear with minimal function nesting thanks to the parse_state
stack that allows to flatten the function call graph of the main loop.
```Odin
ParseState :: enum {
	// general
	STATEMENT, EOF,
	// statements
	S_MACRO_DEF, S_MOVEMENT, S_TRACK,

	// Error states
	ERR,
}

output : str.Builder


parse_stack :[dynamic]ParseState
```

The stack is managed by custom functions to pop and peek it, also some functions 
append and pop from it.

Statement is an union of the possible statements in the languege:
```Odin
Statement :: union{
	Macro_def,
	Track,
	Movement,
}
```

Each varient has as it's children a list of Expr (a union of different types of expressions)

Initially I wanted to use a tree-like structure by utilising linked lists, however I
quickly realised that there's no actual need for them. The most obvious use case is
for inserting the body of macros where they are called, however that can be done by
simply creating a new list and inserting there. The difference in performance is hard
to judge without testing both approaches, however that would itself cost quite a bit
of time.


To navigate the array of tokens, I have created an iterator abstraction:
```Odin
Iter :: struct{
	tokens:[]Token,
	i:int,
}
```
and the functions requried to operate it: peek, next
Next "consumes" the current token and moves the index by one
Peek shows the token that will be consumed by next.

Because of that I found that calling the function in this order: "peek* next" is very
reliable.

I went thorugh many iterations with minor tweeks before I settled on this design.


Parsing the different types of statements is done by corresponding functions, for 
example this is the signature of the function that parses definitions of macros:
```Odin
parse_macro_def :: proc(iter: ^Iter, ast: ^Ast) -> (macro: Macro_def, name:string)
```

Other statement functions have a similar structure

This function will call the function that parses expressions until it find the end of
the statement: a new line or ";"
```Odin
	for	next_t :=peek(iter, 0).type; 
		next_t != .NL && next_t != .SEMICOLON; 
		next_t =peek(iter, 0).type
	{
		append(&macro.body,parse_expr(iter,ast))
		if !has_keys {continue}

		curr_expr:= macro.body[len(macro.body)-1]
		if ident,ok := curr_expr.(Ident); ok{
			if _,ok2:= macro.args[ident.source.str]; ok2{
				pos := &macro.args[ident.source.str]
				append(pos, len(macro.body) - 1)
			} else {
				macro.args[ident.source.str] = make([dynamic]int)
				pos := &macro.args[ident.source.str]
				append(pos, len(macro.body) - 1)
			}
		}
	}
```

In different parts of the Ast expressions or statements need to be referenced. Since
they all are stored in dynamic arrays, it's not a good idea to store a pointer to 
their value, instead I opted to store the index. This has it's own downsides: it 
doesn't get updated on insertions. However this can be trivialy fixed by updating
the indices during insertion operations.

```Odin
Ch_oct :: struct{source:Token,val:int}
Pipe :: struct{source:Token}
Ident :: struct{source: Token}

Expr :: union{
	Ident,
	Note,
	Macro,
	Expr_group,
	Pipe,
	Ch_oct,
}
```
Some variations of Expr are just wrappers around tokens, others store more 
information.

Often times I had to ensure that in a given state the next token was of a particular
type. In those situation I used asserts to ensure the proper state of the parser
and the correctness of the syntax.
```Odin
	case .KW_TRACK:
		#partial switch peek(iter,1).type{
		case .COLON: 
			append(&parse_stack, ParseState.S_TRACK)
		case .STRING: 
			fmt.assertf(peek(iter,2).type == .COLON, "Expected \":\" token after string when defining track, got %v instead", peek(iter,2))
			append(&parse_stack, ParseState.S_TRACK)
		case :
			fmt.assertf(false, "Expected \":\" or string, found: %v instead ",peek(iter,1))

		}
```

For debugging purposes I have a few debug print statements and a string builder into
which I write the values I would put into the ast. These functions are no-op's 
outside debug builds.


## Conclusions / Screenshots / Results

For this laboratory I had to study ast and how to write them. Ast's are a data 
structure that can be used to describe the syntax of text, like programming langueges
. 

While working on this laboratory I have iterated over different designs for the 
parser until I found a suitable one. The parser is made up of a main loop that will
call different functions based on the top of the stack and will halt only when the
state on top of the stack is EOF(end of file).

The functions that can be called from the loop are determined by a switch statement.
All of these function have in common the fact that they parse statements. The 
resulting statement is then added to the ast.

Each function that parses statemenets fallows a similar pattern on iterating through
expected token types to ensure the correctness of the syntax then entering a 
different loop.

This loop calls a function that parses expressions until the next token to be parsed
denotes the end of the statement.

The function that parses expressions doesn't actually parse them itself, instead it 
looks at the tokens and calls the appropriate function for the expression varient.

Initially I wanted this function to perform the loop, however some expressions( like
arguments and groups) are made up of other expressions but have different parsing 
rules from statements.

The current implementation can be improved by adding a queue of parsing errors 
instead of exiting at the first one, fixing bugs that were not found yet(if any),
adding more features to the grammar and some other minor tweaks.

I tried compiling this source code:
```mtex
london_bridge_is (arg1, arg2)=  sol la+.7:4  < sol.6 si 
falling_down = mi fa sol:4
falling_down2 = re mi fa:4 
my_fair = re:4 si:4
lady = mi do:4

track "london bridge" :

piano "main": [
    london_bridge_is(do, re) | falling_down | falling_down2 | falling_down |
    #london_bridge_is | falling_down |    my_fair    |      lady    |
]

```

and the ast is printed as such:
```
Statements:
Macro_def{iden = "london_bridge_is",
        args = map[arg2 = [],arg1 = [],],
        body = [Note{duration = 0,note = "sol",pitch = 0,octave = 0,},
                Note{duration = 4,note = "la",pitch = 1,octave = 7,},
                Ch_oct{source = 
			Token{str = "<",line = 0,n = 46,type = "LESS_THAN",},val = -1,},
                Note{duration = 0,note = "sol",pitch = 0,octave = 6,},
                Note{duration = 0,note = "si",pitch = 0,octave = 0,},],}
Macro_def{iden = "falling_down",args = map[],
        body = [
                Note{duration = 0,note = "mi",pitch = 0,octave = 0,},
                Note{duration = 0,note = "fa",pitch = 0,octave = 0,},
                Note{duration = 4,note = "sol",pitch = 0,octave = 0,},],}
Macro_def{
	iden = "falling_down2",args = map[],
        body = [Note{duration = 0,note = "re",pitch = 0,octave = 0,},
                Note{duration = 0,note = "mi",pitch = 0,octave = 0,},
                Note{duration = 4,note = "fa",pitch = 0,octave = 0,},],}
Macro_def{
        iden = "my_fair",args = map[],
        body = [Note{duration = 4,note = "re",pitch = 0,octave = 0,},
                Note{duration = 4,note = "si",pitch = 0,octave = 0,},],}
Macro_def{
        iden = "lady",args = map[],
        body = [Note{duration = 0,note = "mi",pitch = 0,octave = 0,},
                Note{duration = 4,note = "do",pitch = 0,octave = 0,},],}
Track{name = "london bridge",body = [6,],}
Movement{
        instrument = "piano",tag = "london bridge_main",
        expr = [
Expr_group{exprs = [
	Macro{name = "london_bridge_is",
		args = [Note{duration = 0,note = "do",pitch = 0,octave = 0,},
			Note{duration = 0,note = "re",pitch = 0,octave = 0,},],},
	Pipe{source = Token{str = "|",line = 9,n = 30,type = "PIPE",},},
	Ident{source = Token{str = "falling_down",line = 9,n = 44,type = "ALPHANUM",},},
	Pipe{source = Token{str = "|",line = 9,n = 45,type = "PIPE",},},
	Ident{
		source = Token{str = "falling_down2",line = 9,n = 60,
			type = "ALPHANUM",},},
	Pipe{
		source = Token{str = "|",line = 9,n = 61,type = "PIPE",},},
	Ident{source = Token{str = "falling_down",line = 9,n = 75,type = "ALPHANUM",},},
	Pipe{source = Token{str = "|",line = 9,n = 76,type = "PIPE",},},
],},],}
Definitions:
map[	london_bridge_is = Idt{def = 0,type = "macro",},
        my_fair = Idt{def = 3,type = "macro",},
        london bridge_main = Idt{def = 6,type = "mov",},
        lady = Idt{def = 4,type = "macro",},
        falling_down2 = Idt{def = 2,type = "macro",},
        london bridge = Idt{def = 5,type = "track",},
        falling_down = Idt{def = 1,type = "macro",},]
```


## References
