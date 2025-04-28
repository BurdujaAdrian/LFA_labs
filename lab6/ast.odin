package main

import "core:fmt"

parse_stack : [dynamic]ParseState
parse :: proc(tokens: []Token) -> (ast:Ast){
	ast.tracks = make([dynamic]Track)
	ast.macros = make([dynamic]Macro)

	parse_stack = make([dynamic]ParseState)
	
	append(&parse_stack, ParseState.None)
	
	id : int = 0

	loop: for {
		switch pop(&parse_stack){
		case .None		: id = none(&ast,id,tokens)

		case .ParseStatement	: id = statement(&ast, id,tokens)
		case .Parse_Track	: id = track(&ast, id,tokens)
		case .Parse_Macro	: id = macro(&ast, id,tokens)

		case .ParseExpr		: id = expr(&ast, id,tokens)
		case .Parse_Note	: id = note(&ast, id,tokens)
		case .Parse_MacroInl	: id = macro_inl(&ast, id,tokens)
		case .Parse_MacroAppl	: id = macro_appl(&ast, id,tokens)
		case .Parse_ExprGroup	: id = expr_group(&ast, id,tokens)
		case .Parse_Rep		: id = rep(&ast, id,tokens)
		case .Parse_SetOctaveU	: id = set_ocvt_u(&ast, id,tokens)
		case .Parse_SetOctaveD	: id = set_octv_d(&ast, id,tokens)
		case .Parse_SetDur	: id = set_dur(&ast, id,tokens)
		case .Parse_SetTempo	: id = set_tempo(&ast, id,tokens)
		
		case .EOF		: break loop
		}
	}

	return ast
}

none :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	fmt.printf("%v",tokens[id].str)
	#partial switch tokens[id].type {
	case .EOF : append(&parse_stack, ParseState.EOF)
	case      : append(&parse_stack, ParseState.ParseStatement)
	}

	return  id
}

statement :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	
	append(&parse_stack, ParseState.None )
	
	return id+1
}
track :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
macro :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
expr :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
note :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
macro_inl :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
macro_appl :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
expr_group :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
rep :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
set_ocvt_u :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
set_octv_d :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
set_dur :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}
set_tempo :: #force_inline proc(ast:^Ast, id:int, tokens:[]Token)->(new_id:int){
	#partial switch tokens[id].type{}
	append(&parse_stack, ParseState.None )
	return id+1 
}




ParseState :: enum {
	None,

	ParseStatement,
	Parse_Track,
	Parse_Macro,

	ParseExpr,

	Parse_Note,
	Parse_MacroInl,
	Parse_MacroAppl,
	Parse_ExprGroup,
	Parse_Rep,
	Parse_SetOctaveU, 
	Parse_SetOctaveD,
	Parse_SetDur ,
	Parse_SetTempo,
	
	EOF,
}

// @token
// Token_type :: enum u8{
// 	// Delimiters
// 	OPEN_BRACE,
// 	CLOSE_BRACE,
// 	OPEN_PAREN,
// 	CLOSE_PAREN,
// 	OPEN_BRACKET,
// 	CLOSE_BRACKET,
// 	COLON,
// 	DOUBLE_QUOTE,
// 	COMMA,
// 	PIPE,
// 	SLASH,
// 	EQUAL,
// 	HASH,
// 	SINGLE_QUOTE,
// 	DOT,
// 	DASH,
// 	PLUS,
// 	GREATER_THAN,
// 	LESS_THAN,
// 	ASTERISK,
// 	SEMICOLON,
//
// 	DELIM_N,
//
// 	// literals
// 	ALPHANUM,
// 	NUM,
// 	STRING,
//
// 	// keywords
// 	KW_WITH, 
// 	KW_TITLE, 
// 	KW_KEY, 
// 	KW_TEMPO, 
// 	KW_B, 
// 	KW_S, 
// 	KW_OCTAVE, 
// 	KW_TIME_SIGNATURE, 
// 	KW_TIME_SIG,
// }




// tree head
Ast :: struct{
	tracks : [dynamic]Track,
	macros : [dynamic]Macro,
}

// tree head
Track :: struct{
	name : string,
	movements : [dynamic]Movement,
}

// tree head
Macro :: struct{
	name : string,
	args : [dynamic]Arg,
	body : ^Expr,
}

Arg :: struct{
	ident : string,
	uses: [dynamic]^Expr,
}

Movement :: struct{
	name : string,
	body : ^Expr,
}

Expr :: struct{
	source: ^Token,
	next: ^Expr,

	is: enum{
		Note,
		MacroInl,
		MacroAppl,
		ExprGroup,
		Rep,
		SetOctaveU, 
		SetOctaveD,
		SetDur ,
		SetTempo,
	}
}


Note :: struct{
	pitch	    : int,

	pitch_offset: int,
	octave      : int,
	duration    : int,
}

MacroInl :: struct{source : ^Macro}

MacroAppl :: struct{
	source: ^Macro,
	args  : [dynamic]^Expr,
}

ExprGroup :: struct{body : ^Expr}

Rep :: struct{
	body : ^Expr,
	times: int,
}

SetOctaveU :: struct{by : int}
SetOctaveD :: struct{by : int}
SetDur :: struct{by:int}
SetTempo :: struct{by:int}







