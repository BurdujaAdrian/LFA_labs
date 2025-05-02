package main


import "core:fmt"
import "base:runtime"
import "core:os"
import str"core:strings"

ParseState :: enum {
	// general
	STATEMENT, EOF,
	// statements
	S_MACRO_DEF, S_MOVEMENT, S_TAGGED_M, S_TRACK,
	// collections
	C_ARGS,	
	
	// Expressions
	E_MACRO_APL,E_MACRO_INL,

	// Error states
	ERR,
}

output : str.Builder


parse_stack :[dynamic]ParseState



print_ast :: proc(ast:^Ast){
	fmt.println("Statements:")
	for statement in ast.statements{
		fmt.println(statement)
	}
	fmt.println()
	fmt.println("Definitions:")
	fmt.printf("%#v",ast.definitions)
}

parse :: proc(tokens:[]Token)->(ast:Ast){
	str.builder_init(&output)
	print("\nParsing")
	ast.errors	= make([dynamic]ParseError)
	ast.statements  = make([dynamic]Statement)
	ast.definitions = make(map[string]Identifier)

	iter := Iter{tokens,0}


	loop: for  {
		printf("\n\n\n============\n")
		print("stack: ",parse_stack)
		print("curr token: ", peek(&iter,0))
		print("output: ", str.to_string(output),"\n")
		
		switch peek_stack(&parse_stack){
		// general
		case .STATEMENT    : parse_statement(&iter,&ast); 

		// statements
		case .S_MACRO_DEF  : parse_macro_def(&iter,&ast); 
		case .S_MOVEMENT   : parse_movement(&iter,&ast); 
		case .S_TAGGED_M   : parse_tagged_m(&iter,&ast); 
		case .S_TRACK	   : parse_track(&iter,&ast); 

		// collections
		case .C_ARGS       : parse_args(&iter,&ast); 

		// Expressions
		case .E_MACRO_APL  : parse_macro_apl(&iter,&ast); 
		case .E_MACRO_INL  : parse_macro_inl(&iter,&ast); 
		// Error states
		case .ERR	   : parse_err(&iter,&ast); 

		case .EOF          : break loop
		}
		print("stack: ",parse_stack)
		print("curr token: ", peek(&iter,0))
		print("output: ", str.to_string(output))
		print("\n============\n")
		wait_enter()
	}

	return
}

Ast :: struct {
	statements  : [dynamic]Statement,
	definitions : map[string]Identifier,
	no_header   : bool,

	errors	    : [dynamic]ParseError
}

Identifier :: struct{
	def  : ^Statement,
	type : IdentType,
}


IdentType :: enum{
	macro,
	track,
	set,
	keyword,
	note,
	instrument,
}

// @statement
Statement :: union{
	Macro_def,
	Track,
	Movement,
	Tagged_movement,
}

parse_statement :: proc(iter: ^Iter, ast: ^Ast){
	curr_t := peek(iter,0)

	#partial switch curr_t.type {

	case .START:
		next(iter)
		write("progrm {")
		fallthrough

	case .ALPHANUM: 
		print("found ident", curr_t)
		next_t := peek(iter,1).type
		if next_t == .COLON{
			print("Found movement")
			append(&parse_stack, ParseState.S_MOVEMENT)
			write("\nmov:")
			return
		}

		if next_t == .STRING{
			if peek(iter,2).type == .COLON{
				print("Found tagged movement")
				append(&parse_stack, ParseState.S_MOVEMENT)
				write("\nmov:")
				return
			}
		}

		if next_t == .OPEN_PAREN || next_t == .EQUAL{
			append(&parse_stack, ParseState.S_MACRO_DEF)

			print("found macro")
			write("\nmacro:")
		}
		

	case .KW_TRACK:
		#partial switch peek(iter,1).type{
		case .COLON: 
			append(&parse_stack, ParseState.S_TRACK)
			return
		case .STRING: 
			expect(iter, .COLON)
			append(&parse_stack, ParseState.S_TRACK)
			return
		}

	case .EOF: 
		append(&parse_stack, ParseState.EOF)
		print("end of file")
		write("}")
	
	case .NL: 
		print("just a new line, skip")
		write("\n")
		_ = next(iter) // skipping the token
	case : fmt.assertf(false, "expected kw_track for track, alphanum for movement or macro or eof, got: %v ",peek(iter,0).str) 
		write(";")
		
	}

}
// @end_statement

// @expr

Expr :: struct{
	this : Any_expr,
	next : ^Expr,
}

parse_expr :: proc(iter: ^Iter, ast: ^Ast){
	print("\tparsing expression: ", peek(iter,0))
	#partial switch peek(iter,0).type{
	// case .SEMICOLON : 
	//
	// 	str.write_string(&output, ">")
	case .OPEN_BRACKET : 
		write("[")
		print("\tnow try parsing expr group")
		parse_expr_group(iter,ast)
		return
	case .CLOSE_BRACKET:
		print("\tshouldnt get here")
		os.exit(1)

	case .NOTE_DO ..= .NOTE_SI : 
		print("\tnow try parsing note")
		parse_note(iter,ast)
		return
	case .NL , .SEMICOLON:
		print("\tnot an expression: ", peek(iter,0) )
		os.exit(1)
	case :
		print("\tparsing unnacounted token in parse_expr: ", peek(iter,0))
		write(next(iter).str)
	}
}
Any_expr :: union{
	Note,
	Macro,
	Expr_group,
	// NOTE: These exist only at the parsing step, they are unpacked within the ast
	// Sem_group, 
	// repetition,
}
//{
	Note :: struct{
		note     : string,
		octave   : u8,
		duration : u64,
		mode	 : Note_mode,
	}
	//{
		Note_mode :: enum{
			neutral,
			hold   ,
			release,
		}
	//}
parse_note :: proc(iter: ^Iter, ast: ^Ast){
	write("$")
	write(next(iter).str)
	curr : Token_type = next(iter).type

	for curr == .PLUS  || curr == .DASH {
		write(peek(iter,0).str)
		curr = next(iter).type
	}

	if peek(iter,0).type == .NUM{
		print("\t\tfound octave", next(iter))
		str.write_string(&output, peek(iter,0).str )
	}
	
	if peek(iter,0).type == .COLON{
		_ = next(iter)
		print("\t\tparsing duration")
		str.write_string(&output, ":")
		if peek(iter,0).type == .NUM{
			print("\t\tfound duration")
			str.write_string(&output, peek(iter,0).str)
		} else {
			print("\t\texpected numeric")
		}
	}

}


	Macro :: struct{
		name : string,
		args : Maybe([dynamic]string),
	}
parse_macro_apl :: proc(iter: ^Iter, ast: ^Ast){
	assert(false)
}
parse_macro_inl :: proc(iter: ^Iter, ast: ^Ast){assert(false)}

	Expr_group :: struct{
		exprs : [dynamic]Expr,
	}

parse_expr_group :: proc(iter: ^Iter, ast: ^Ast){
	fmt.assertf(next(iter).type == .OPEN_BRACKET, "Internal error: expected [ when calling parse_expr_group, found %v instead", peek(iter,0)) // consume [
	
	for  {
		for peek(iter,0).type == .NL{next(iter); print("consumed 1 nl"); write("\n")} // consume all newlines within []
		if peek(iter,0).type == .CLOSE_BRACKET {print("ended expr group"); break}
		print("\t\tnew iter in group loop", peek(iter,0))
		parse_expr(iter,ast)
	}
	// consume ] token
	write(next(iter).str)
}

	
//}
// @end_expr

// @track

Track	   :: struct{
	name	   : string,
	body	   : [dynamic]Statement,

}

parse_track :: proc(iter: ^Iter, ast: ^Ast){assert(false)}

// @end_track

// @movement

Movement :: struct{
	instrument : string,

}

parse_movement :: proc(iter: ^Iter, ast: ^Ast){

	print("\t")
	instrument := next(iter)
	print("\t","found instrument ", instrument)
	write(instrument.str)
	#partial switch next(iter).type{
	case .STRING :
		print("\t","found tag for movement: ", peek(iter,-1))
		fmt.assertf( next(iter).type == .COLON,  "Expected token colon after string in movement, got %v instead\n", peek(iter,-1))
		next_t :=peek(iter, 0).type
		for  next_t != .NL && next_t != .SEMICOLON{
			parse_expr(iter,ast)
		}
		write(";")
	case .COLON :
		print("just movement body")
		next_t :=peek(iter, 0).type
		for  next_t :=peek(iter, 0).type; next_t != .NL && next_t != .SEMICOLON; next_t = peek(iter, 0).type{
			print("start parsing expr in movement")
			parse_expr(iter,ast)
			
		}
		write(";")

	case .NL :
		print("just nl")
		_ = next(iter)
	case :
		print("shouldn't be this token:", peek(iter,0))
	}

	pop_stack(&parse_stack)

}

Tagged_movement :: struct{
	instrument : string,
	tag	   : string,
}

parse_tagged_m :: proc(iter: ^Iter, ast: ^Ast){assert(false)}

// @end_movement


// @macro
Macro_def :: struct{
	identifier : string,
	args	   : Maybe([dynamic]string),
	body	   : [dynamic]^Expr,
}
parse_macro_def :: proc(iter: ^Iter, ast: ^Ast){
	name := next(iter)
	write(name.str)
	
	#partial switch next(iter).type{
	case .EQUAL: // there are no arguments
		print("found equal, no arguments")
		write("= ")

		parse_expr(iter,ast)
		write(";")
	case .OPEN_PAREN: // there are argumetns
		write("(")
		parse_args(iter,ast)
		write(") = ")
		fmt.assertf(next(iter).type == .EQUAL , "Expected equal after macro definition arguments, got %v indead",peek(iter,-1))
	case : 
		fmt.assertf(false, "Expected equal or open_paren after macro name, got %v instead", peek(iter,-1))
	}
}

// @end_macro





// @Groups

CapGroup :: struct{

}

parse_args :: proc(iter: ^Iter, ast: ^Ast){assert(false)}



// @Literals

Literal :: union{}


parse_err :: proc(iter: ^Iter, ast: ^Ast){assert(false)}



// @utils


pop_stack :: proc(stack:^[dynamic]$T)->T{
	if state,ok:=pop_safe(stack); ok{
		print("Popped:" ,state)
		return state
	}
	return cast(T)0
}

peek_stack :: proc(stack: ^[dynamic]$T)->T{
	if len(stack^) == 0{
		return cast(T)0
	}
	print("Peeked: ", stack[len(stack)-1])
	return stack[len(stack)-1]
}

Iter :: struct{
	tokens:[]Token,
	i:int,
}

next :: #force_inline proc(iter:^Iter,loc:= #caller_location)->Token{
	iter.i += 1
	if iter.i == len(iter.tokens)+1{
		runtime.print_caller_location(loc)
		os.exit(1)
	}
	return iter.tokens[iter.i-1]
}

peek :: #force_inline proc(iter:^Iter,n:int = 0)->Token{
	if iter.i + n >= len(iter.tokens) {
		return iter.tokens[len(iter.tokens) -1]
	}
	return iter.tokens[iter.i+n]
}

back :: #force_inline proc(iter:^Iter){
	switch iter.i{
	case 0: return
	case : iter.i -=1
	}
}

wait_enter :: proc(){
	when ODIN_DEBUG {
		no_buff :[10]u8
		_,_ = os.read(os.stdin, no_buff[:])
	} else {

	}
}


// @errors

ParseError :: struct{
	token : Token,
}


expect :: #force_inline proc(iter:^Iter,tk_type: Token_type)->bool{
	return next(iter).type == tk_type 
}

// @end_errors

write :: #force_inline proc(_str:string){
	_str := _str
	if _str == "\r"{
		_str = "\n"	
	}
	print("\nwriting \"", _str, "\"")
	n := str.write_string(&output, _str)
	fmt.assertf(n == len(_str), "write didnt write enough bytes, only %d",n)
	print("buff after writing: ```\n", str.to_string(output),"\n```\n")
}
