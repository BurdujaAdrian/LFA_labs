# The title of the work

### Course: Formal Languages & Finite Automata
### Author: Burduja Adrian

----

## Theory
Parsing is needed to translate human readable code into something the computer can 
reason about. For this multiple steps need to happen, like tokenization

## Objectives:
1. Understand what lexical analysis [1] is.
2. Get familiar with the inner workings of a lexer/scanner/tokenizer.
3. Implement a sample lexer and show how it works. 


## Implementation description

I have inplemented the tokenizer for my dsl. It differentiates between primitives 
like integers, strings and parses identifiers(like names of variables) and keyword.

I used a stream pattern to parse the inputed file rune by rune(a rune is a utf8 encoded character). I also used a global state to remember what the parser is parsing:
```Odin
	fstream :bio.Reader
	bio.reader_init_with_buf(&fstream, fs,buffer)

	for start := 0 ; true ; {
		switch parse_state {
		case .NONE	: start = parse_none(&fstream); continue 
		case .IDENTIFIER: start = parse_iden(&fstream)
		case .DELIMITER	: start = parse_delm(&fstream)
		case .NUMERIC	: start = parse_numr(&fstream)
		case .STRING	: start = parse_strl(&fstream)
		case .EOF	: break
		}

		if fstream.r == 0 {print("end of file"); break}

	}
```

the function parse_none kickstarts the parsing process and decides what needs to be parsed next.

parse_iden parses identifiers and pushes a new token into a global token_stream, 
which is a dynamic array:
```token_stream :[dynamic]Token``` which contains all the important information about the token:
```odin
Token :: struct{
	str: string, 
	line: int,
	n:int,
	type: Token_type,
}
```

All functions use a tagged loop to ensure proper exiting/breaking from the loop
within the switch statement. The fallowing code snippet is from the parse_strl 
function which parses string literals.
```odin
	loop: for {
		curr,n,_ := bio.reader_read_rune(stream)
		curr_n   +=1

		switch curr {
		case '\n' : curr_line+=1; curr_n = 0
		case '\\' : escaped = true
		case '"'  : 
			if escaped{
				escaped = false
				break
			}
			break loop
		}

	//...
```
For convenience, all the delimiters are parsed using a function:
```odin
is_delim :: #force_inline proc(str:string)->bool{
	switch str{
	case "{" , "}" , "(" , ")" , "[" , "]" , ":" , "\"" , "," , "/" , "=" , "#" , "'" , "."  , "-" , "+" , ">" , "<" , "*", ";", "|": return true
	case : return false
	}
}
```
The parser also records the line and position of tokens for errors that will be 
implemented.

A ```Token``` is a struct 
## Conclusions / Screenshots / Results

I used the program to parse lab3/demo.mtex and got the result that is in result.txt

## References
[1] [A sample of a lexer implementation](https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/LangImpl01.html)

[2] [Lexical analysis](https://en.wikipedia.org/wiki/Lexical_analysis)
