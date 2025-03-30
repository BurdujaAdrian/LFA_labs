package main

import "core:fmt"

import "core:io"
import bio"core:bufio"
import "core:os"

import str"core:strings"
//import "core:bytes"
//import small"core:container/small_array"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else when ODIN_TEST {
	print  :: log.info
	printf :: log.infof
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {}}


main :: proc(){
	fmt.println(size_of(Token))
	args := os.args
	prog_name,source_dir := args[0],args[1]
	fmt.println(prog_name,source_dir)

	fd,o_err := os.open(source_dir)
	if o_err != nil{
		print("Error opening file: ",o_err)
		os.exit(1)
	}
	defer os.close(fd)
	

	fs := os.stream_from_handle(fd)
	size,_ := io.size(fs)
	print("size of file:",size)
	buffer = make([]u8,size)


	// get a buffered io reader
	fstream :bio.Reader
	bio.reader_init_with_buf(&fstream, fs,buffer)

	loop: for start := 0 ; true ; {
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

	print_tokens()
}


//@parse

token_stream :[dynamic]Token
curr_n :int
curr_line:int
parse_state:Parse_state = .NONE
//last_state :Parse_state = parse_state
buffer:[]byte

Parse_state :: enum {
	NONE,
	EOF,
	// symbols
	IDENTIFIER,
	DELIMITER,
	NUMERIC,

	// literal
	STRING,
}

Token :: struct{
	str: string, 
	line: int,
	n:int,
	type: Token_type,
}

parse_delm :: #force_inline proc(stream:^bio.Reader)->int{
	token_type:Token_type
	local_state:= Parse_state.NONE

	switch string(stream.buf[stream.r-1:stream.r]){
	case "{" : token_type = .OPEN_BRACE
	case "}" : token_type = .CLOSE_BRACE
	case "(" : token_type = .OPEN_PAREN
	case ")" : token_type = .CLOSE_PAREN
	case "[" : token_type = .OPEN_BRACKET
	case "]" : token_type = .CLOSE_BRACKET
	case ":" : token_type = .COLON
	case "\"": token_type = .DOUBLE_QUOTE//; local_state = .STRING
	case "," : token_type = .COMMA
	case "|" : token_type = .PIPE
	case "/" : token_type = .SLASH
	case "=" : token_type = .EQUAL
	case "#" : token_type = .HASH
	case "'" : token_type = .SINGLE_QUOTE
	case "." : token_type = .DOT
	case "-" : token_type = .DASH
	case ">" : token_type = .GREATER_THAN
	case "<" : token_type = .LESS_THAN
	case "*" : token_type = .ASTERISK
	case ";" : token_type = .SEMICOLON
	case "+" : token_type = .PLUS
	case     : 
		fmt.printf(
			"unknown symbol: %v, at pos:%v", 
			string(stream.buf[stream.r-1:stream.r]),
			curr_line,
		)
		//os.exit(1)
	}


	append(&token_stream, Token{
		str = string(stream.buf[stream.r-1:stream.r]),
		line= curr_line,
		n   = curr_n,
		type= token_type,
	})

	print(token_stream[len(token_stream) -1])

	parse_state = local_state
	return stream.r

}

parse_strl :: #force_inline proc(stream:^bio.Reader)->(start:int){
	panic("implement parse strl")
}

parse_numr :: #force_inline proc(stream:^bio.Reader)->(start:int){
	start = stream.r
	num_len := 1
	local_state := Parse_state.NONE

	loop: for {
		curr,n,_ := bio.reader_read_rune(stream)
		curr_n   +=1

		switch curr {
		case '\n' : curr_line+=1; curr_n = 0; break loop
		case ' ','\t', '\r': num_len-=1; break loop
		case '0'..='9': continue
		case 'm' : 
			if string(stream.buf[stream.r-1:stream.r+n]) == "ms"{
				stream.r+=1
			}
		}
		
		if is_delim(string(stream.buf[stream.r-1:stream.r+n-1])){
			local_state= .DELIMITER
			num_len-=1
			break loop
		}

		if n == 0 {local_state= .EOF; break loop}
		num_len+=1
	}
	append(&token_stream, Token{
		str = string(stream.buf[start-1:start+num_len]),
		line= curr_line,
		n   = curr_n,
		type= .NUM,
	})

	print(token_stream[len(token_stream) -1])

	parse_state = local_state
	return
}

parse_iden :: #force_inline proc(stream:^bio.Reader)->(start:int){
	start = stream.r
	iden_len := 1
	local_state := Parse_state.NONE


	loop: for {
		curr,n,_ := bio.reader_read_rune(stream)
		curr_n   +=1

		switch curr {
		case '\n' : curr_line+=1; curr_n = 0; break loop
		case ' ','\t','\r': iden_len-=1; break loop
		}
		
		if is_delim(string(stream.buf[stream.r-1:stream.r+n-1])){
			local_state= .DELIMITER
			iden_len-=1
			break loop
		}

		if n == 0 {local_state= .EOF; break loop}
		iden_len+=1
	}

	if is_keyword(stream,start-1,start+iden_len){
		// is_keyword already appends to the token_stream
		parse_state = local_state
		print(token_stream[len(token_stream)-1])
		return
	}

	append(&token_stream, Token{
		str = string(stream.buf[start-1:start+iden_len]),
		line= curr_line,
		n   = curr_n,
		type= .ALPHANUM,
	})

	print(token_stream[len(token_stream) -1])

	parse_state = local_state
	return
}
parse_none :: #force_inline proc(stream:^bio.Reader)->(start:int){
	//last_state = parse_state
	start = stream.r
	
	for i:= 0 ; true ; i+=1{
		curr,n,_ := bio.reader_read_rune(stream)
		curr_n   +=1

		switch curr {
		case '\n'    : curr_line+=1; curr_n = 0; fallthrough
		case ' ','\t','\r':  continue

		case 'a'..='z', 'A'..='Z', '_' : parse_state= .IDENTIFIER; return

		case '0'..='9' : parse_state = .NUMERIC; return
		
		//case '"' :  parse_state = .STRING; return
		}

		if is_delim(string(stream.buf[start+i:start+n+i])){
			parse_state= .DELIMITER
			return 
		}

		if n == 0 {parse_state= .EOF; return}

		}

	fmt.printf(
		"Unsuported character for identifiers: %s",
		stream.buf[stream.r:stream.r+1],
	)
	panic("how did I get here?")
}


// @delim
delimiters :: "{" + "}" + "(" + ")" + "[" + "]" + ":" + "\"" + "," + "/" + "=" + "#" + "'" + "." + "-" + "+" + ">" + "<" + "*" + " " + "\n" + "\t" + ";" + "|"

is_delim :: #force_inline proc(str:string)->bool{
	switch str{
	case "{" , "}" , "(" , ")" , "[" , "]" , ":" , "\"" , "," , "/" , "=" , "#" , "'" , "."  , "-" , "+" , ">" , "<" , "*", ";", "|": return true
	case : return false
	}
}

is_keyword :: proc(stream: ^bio.Reader, start,end:int)->bool{

	keyword_type:Token_type
	text := string(stream.buf[start:end])
	switch text {
	case "with"          : keyword_type = .KW_WITH 
	case "title"         : keyword_type = .KW_TITLE 
	case "key"           : keyword_type = .KW_KEY 
	case "tempo"         : keyword_type = .KW_TEMPO 
	case "b"             : keyword_type = .KW_B 
	case "s"             : keyword_type = .KW_S 
	case "octave"        : keyword_type = .KW_OCTAVE 
	case "time_signature": keyword_type = .KW_TIME_SIGNATURE 
	case "time_sig"      : keyword_type = .KW_TIME_SIG
	case : return false
	}

	append(&token_stream, Token{
		str = text,
		line= curr_line,
		n   = curr_n,
		type= keyword_type,
	})

	return true
}

// @token
Token_type :: enum u8{
	// Delimiters
	OPEN_BRACE,
	CLOSE_BRACE,
	OPEN_PAREN,
	CLOSE_PAREN,
	OPEN_BRACKET,
	CLOSE_BRACKET,
	COLON,
	DOUBLE_QUOTE,
	COMMA,
	PIPE,
	SLASH,
	EQUAL,
	HASH,
	SINGLE_QUOTE,
	DOT,
	DASH,
	PLUS,
	GREATER_THAN,
	LESS_THAN,
	ASTERISK,
	SEMICOLON,

	DELIM_N,

	// literals
	ALPHANUM,
	NUM,
	STRING,

	// keywords
	KW_WITH, 
	KW_TITLE, 
	KW_KEY, 
	KW_TEMPO, 
	KW_B, 
	KW_S, 
	KW_OCTAVE, 
	KW_TIME_SIGNATURE, 
	KW_TIME_SIG,
}


print_tokens :: proc(){
	last_line := token_stream[0].line

	for token in token_stream {
		for last_line != token.line {
			fmt.println()
			last_line +=1
		}
		fmt.printf("<%v> ",token.str)

	}
}
