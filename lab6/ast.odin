package main


import "core:fmt"
import "base:runtime"
import "core:os"
import str"core:strings"
import "core:strconv"
import "core:slice"

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


print_ast :: proc(ast:^Ast){
	
	fmt.println("Statements:")
	for statement in ast.sments{
		fmt.printf("%#v",statement)
	}
	fmt.println()
	fmt.println("Definitions:")
	fmt.printf("%#v",ast.def)
}


IdentType :: enum{
	unresolved,
	macro,
	track,
	mov,
	note,
	instrument,
}
Idt :: struct{
	def  : int, // index in statements
	type : IdentType,
}


Ast :: struct {
	sments  : [dynamic]Statement,
	def : map[string]Idt,

	errors	    : [dynamic]ParseError,

	last_track_id : int,
}

parse :: proc(tokens:[]Token)->(ast:Ast){
	str.builder_init(&output)
	print("\nParsing")
	ast.errors	= make([dynamic]ParseError)
	ast.sments  = make([dynamic]Statement)
	ast.def = make(map[string]Idt)

	iter := Iter{tokens,0}


	loop: for  {
		printf("\n\n\n============\n")
		print("stack: ",parse_stack)
		print("curr token: ", peek(&iter))
		print("output: ", str.to_string(output),"\n")
		
		switch peek_stack(&parse_stack){
		// general
		case .STATEMENT    :
			parse_statement(&iter,&ast)
			

		// statements
		case .S_MACRO_DEF  : 
			new_mac,new_name := parse_macro_def(&iter,&ast)
			
			decl, declared := ast.def[new_name]
			fmt.assertf(!declared, "Redeclaration of identifier: %v, previously: %v",new_mac,decl)
			
			append(&ast.sments, new_mac)
			ast.def[new_name] = Idt{len(ast.sments) -1, .macro }

		case .S_MOVEMENT   : 
			new_mov, new_name := parse_movement(&iter,&ast)
			
			decl, declared := ast.def[new_name]
			fmt.assertf(!declared,"Redeclaration of identifier: %v, previously:%v",new_mov, decl)

			// append new movement
			append(&ast.sments, new_mov)
			ast.def[new_name] = Idt{len(ast.sments) -1, .mov}

			// append new id of movement
			last_track: ^Track = &(&ast.sments[ast.last_track_id]).(Track)
			append(&last_track.body, len(ast.sments) - 1)
		case .S_TRACK	   : 
			new_track, new_name := parse_track(&iter,&ast)

			decl, declared := ast.def[new_name]
			fmt.assertf(!declared, "REdeclaration of track name: %v, prev %v", new_track, decl)

			append(&ast.sments, new_track)
			id:=len(ast.sments) - 1
			ast.def[new_name] = Idt{id, .track}
			ast.last_track_id = id


		// Error states
		case .ERR	   : parse_err(&iter,&ast)

		case .EOF          : break loop
		}
		print("stack: ",parse_stack)
		print("curr token: ", peek(&iter))
		print("output: ", str.to_string(output))
		print("\n============\n")
		wait_enter()
		assert(len(parse_stack) < 2)
	}

	return
}





// @statement
Statement :: union{
	Macro_def,
	Track,
	Movement,
}

parse_statement :: proc(iter: ^Iter, ast: ^Ast){
	curr_t := peek(iter)

	#partial switch curr_t.type {

	case .START:
		next(iter)
		write("progrm {")

	case .ALPHANUM: 
		print("found ident", curr_t)
		next_t := peek(iter,1).type
		print("next token:",next_t)
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
			return
		}

		fmt.assertf(false, "next token doesn't correspond to the syntax of anything: %v", next_t)
		

	case .KW_TRACK:
		#partial switch peek(iter,1).type{
		case .COLON: 
			append(&parse_stack, ParseState.S_TRACK)
		case .STRING: 
			fmt.assertf(peek(iter,1).type != .COLON, "Expected : token after string when defining track, got %v instead", peek(iter,1))
			append(&parse_stack, ParseState.S_TRACK)
		}

	case .EOF: 
		append(&parse_stack, ParseState.EOF)
		print("end of file")
		write("}")
	
	case .NL: 
		print("just a new line, skip")
		write("\n")
		_ = next(iter) // skipping the token
	case : 
		fmt.assertf(false, "expected kw_track for track, alphanum for movement or macro or eof, got: %v ",peek(iter).str) 
		
	}
}
// @end_statement

// @expr

Ch_oct :: struct{source:Token,val:int}
Pipe :: struct{source:Token}

Ident :: struct{
	source: Token,
}
Expr :: union{
	Ident,
	Note,
	Macro,
	Expr_group,
	Pipe,
	Ch_oct,
}

parse_expr :: proc(iter: ^Iter, ast: ^Ast)->(expr: Expr){
	

	print("\tparsing expression: ", peek(iter))
	#partial switch peek(iter).type{
	case .OPEN_BRACKET : 
		write("[")
		print("\tnow try parsing expr group")
		expr = parse_expr_group(iter,ast)
	case .CLOSE_BRACKET:
		print("\tshouldnt get here")
		os.exit(1)

	case .NOTE_DO ..= .NOTE_SI : 
		print("\tnow try parsing note: ", peek(iter).type)
		fmt.assertf(peek(iter).type != .NL, "a nl isnt a note")
		expr = parse_note(iter,ast)
	case .NL , .SEMICOLON:
		print("\tnot an expression: ", peek(iter) )
		os.exit(1)
	case .ALPHANUM, .NUM:
		print("\tprobably an expression: ",peek(iter))
		expr = Ident{peek(iter)}

		if peek(iter,1).type == .OPEN_PAREN{
			return parse_macro_apl(iter,ast)
		} 
		write(next(iter).str)
		write(" ")
	case .LESS_THAN, .GREATER_THAN :
		print("\tthis is an expression: ",peek(iter).str)

		expr = Ch_oct{
			peek(iter),
			cast(int)(peek(iter).type == .GREATER_THAN)*2 - 1,
		}
		write(next(iter).str)
		write(" ")
	case .PIPE:
		print("\tjust a pipe")
		expr = Pipe{peek(iter)}
		write(fmt.aprintf(" %v ",next(iter).str))

	case :
		print("\tparsing unnacounted token in parse_expr: ", peek(iter))
		fmt.assertf(false, "Unexpected token for expression: %v ", peek(iter))
	}

	write(" ")

	return
}

//{
	Note :: struct{
		duration : u64,
		note     : string,
		pitch	 : i8,
		octave   : u8,
	}

parse_note :: proc(iter: ^Iter, ast: ^Ast)->(note:Note){
	write("$")
	print("note: ", peek(iter))
	note.note = peek(iter).str
	write(next(iter).str)

	for curr := peek(iter); 
	    curr.type == .PLUS  || curr.type == .DASH; 
	    curr = peek(iter)  {
		if curr.type == .PLUS{
			note.pitch +=1
		} else {
			note.pitch -=1
		}
		write(next(iter).str)
	}


	if peek(iter).type == .DOT{
		write(next(iter).str) // consume and write .
		fmt.assertf(peek(iter).type == .NUM, "Expected number after . in note literals, got : %v instead", peek(iter).str)
		print("\n\t\tfound octave", peek(iter).str )
		note.octave = auto_cast strconv.atoi(peek(iter).str)
		write(next(iter).str)
	}
	
	if peek(iter).type == .COLON{
		print("\n\t\tparsing duration")
		write(next(iter).str)
		if peek(iter).type == .NUM{
			print("\n\t\tfound duration")
			note.duration = auto_cast strconv.atoi(peek(iter).str)
			write(next(iter).str)
		} else {
			print("\t\texpected numeric")
			os.exit(1)
		}
	}
	return
}


Macro :: struct{
	name : string,
	args : [dynamic]Expr,
}
parse_macro_apl :: proc(iter: ^Iter, ast: ^Ast)-> (macro:Macro){
	macro.args = make([dynamic]Expr)
	macro.name = next(iter).str

	argv,_:= parse_args(iter,ast)
	macro.args = argv

	return
}

	Expr_group :: struct{
		exprs : [dynamic]Expr,
	}

parse_expr_group :: proc(iter: ^Iter, ast: ^Ast)->(group: Expr_group){
	group.exprs = make([dynamic]Expr)

	fmt.assertf(next(iter).type == .OPEN_BRACKET, "Internal error: expected [ when calling parse_expr_group, found %v instead", peek(iter)) // consume [
	
	for  {
		for peek(iter).type == .NL{next(iter); print("consumed 1 nl"); write("\n")} // consume all newlines within []
		if peek(iter).type == .CLOSE_BRACKET {print("ended expr group"); break}
		print("\t\tnew iter in group loop", peek(iter))
		append_elem(&group.exprs,parse_expr(iter,ast))
	}
	// consume ] token
	write(next(iter).str)

	return
}

	
//}



// @end_expr

// @track

Track	   :: struct{
	name	   : string,
	body	   : [dynamic]int,//ids of movements

}

parse_track :: proc(iter: ^Iter, ast: ^Ast)->(track:Track, name:string){
	track.body = make([dynamic]int)
	track.name = "global"
	_ = next(iter) // consume track token
	write("\ntrack ")
	if peek(iter).type == .STRING{
		track.name = peek(iter).str

		write(fmt.aprintf("\"%v\"",next(iter).str ))
	}

	fmt.assertf(peek(iter).type == .COLON, "Expected colon after track declaration, got <%v> instead", peek(iter))
	_ = next(iter)
	write(":")

	name = track.name
	pop_stack(&parse_stack)

	return
}

// @end_track

// @movement

Movement :: struct{
	instrument : string,
	tag : string,
	expr: [dynamic]Expr,
}

parse_movement :: proc(iter: ^Iter, ast: ^Ast)->(mov:Movement,name:string){
	mov.expr = make([dynamic]Expr)

	mov.instrument = peek(iter).str
	mov.tag = mov.instrument

	instrument := next(iter)
	print("\t","found instrument ", instrument)
	write(instrument.str)
	#partial switch peek(iter).type{
	case .STRING :
		print("\t","found tag for movement: ", peek(iter))
		mov.tag = peek(iter).str
		write(fmt.aprintf("\"%v\"", next(iter).str) )

		fmt.assertf( peek(iter).type == .COLON,  "Expected token colon after string in movement, got %v instead\n", peek(iter))
		write(next(iter).str)
		for next_t :=peek(iter, 0).type; next_t != .NL && next_t != .SEMICOLON; next_t = peek(iter, 0).type{
			print("start parsing expr in movement")
			append(&mov.expr,parse_expr(iter,ast))
			
		}
		write(";")
	case .COLON :
		print("just movement body")
		write(next(iter).str)
		for  next_t :=peek(iter, 0).type; next_t != .NL && next_t != .SEMICOLON; next_t = peek(iter, 0).type{
			print("start parsing expr in movement")
			parse_expr(iter,ast)
			
		}
		write(";")
	case :
		print("shouldn't be this token:", peek(iter))
		os.exit(1)
	}

	// namespacing the mov to the track
	last_track := ast.sments[ast.last_track_id].(Track).name
	mov.tag = fmt.aprintf("%v_%v",last_track,mov.tag)
	name = mov.tag

	pop_stack(&parse_stack)

	return

}



// @end_movement


// @macro

Macro_def :: struct{
	iden : string,
	args	   : map[string][dynamic]int,
	body	   : [dynamic]Expr,
}
parse_macro_def :: proc(iter: ^Iter, ast: ^Ast) -> (macro: Macro_def, name:string){
	macro.args = make(map[string][dynamic]int)
	macro.body = make([dynamic]Expr)

	name = peek(iter).str
	macro.iden = name
	
	write(fmt.aprintf("macro %v:",next(iter).str))
	
	
	#partial switch peek(iter).type{
	case .EQUAL: // there are no arguments
		print("found equal, no arguments")
		write("= ")
		_ = next(iter) // consume token
	
	case .OPEN_PAREN: // there are argumetns
		_, macro.args = parse_args(iter,ast)
		fmt.assertf(peek(iter).type == .EQUAL , "Expected equal after macro definition arguments, got %v indead",peek(iter))
		write("= ")
		_ = next(iter) // consume open paren
	case : 
		fmt.assertf(false, "Expected equal or open_paren after macro name, got %v instead", peek(iter))
	}

	keys,_:= slice.map_keys(macro.args)
	has_keys:= len(keys) > 0
	
	for next_t :=peek(iter, 0).type; next_t != .NL && next_t != .SEMICOLON; next_t =peek(iter, 0).type{
		append(&macro.body,parse_expr(iter,ast))
		if !has_keys {continue}

		curr_expr:= macro.body[len(macro.body)-1]
		if ident,ok := curr_expr.(Ident); ok{
			if _,ok := macro.args[ident.source.str]; ok{
				
			} else {
				macro.args[ident.source.str] = make([dynamic]int)
				pos := &macro.args[ident.source.str]
				append(pos, len(macro.body) - 1)
			}
		}
	}

	write(";")
	pop_stack(&parse_stack)

	return
}

// @end_macro





// @Groups

CapGroup :: struct{

}

parse_args :: proc(iter: ^Iter, ast: ^Ast)->(argv:[dynamic]Expr,args:map[string][dynamic]int){
	args = make(map[string][dynamic]int)
	argv = make([dynamic]Expr)

	fmt.assertf(peek(iter).type == .OPEN_PAREN, "[Internal error]: called parse_args without args, token: ",peek(iter).type )
	write(next(iter).str) // consume open paren

	for {
		if peek(iter).type == .CLOSE_PAREN {
			// if found close paren
			write(next(iter).str)
			break
		}

		argx := parse_expr(iter,ast)
		if ident,ok := argx.(Ident); ok{
			arg_name := ident.source.str
			args[arg_name] = make([dynamic]int)
		}

		append(&argv,argx)

		if peek(iter).type == .COMMA{
			write(next(iter).str) // consume token
			continue
		} 
		fmt.assertf(peek(iter).type == .CLOSE_PAREN, "Arguments must be separated by , not : %v", peek(iter))
	}
	
	return
}




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
	when ODIN_DEBUG{
		_str := _str
		if _str == "\r"{
			_str = "\n"	
		}
		print("\nwriting \"", _str, "\"")
		n := str.write_string(&output, _str)
		fmt.assertf(n == len(_str), "write didnt write enough bytes, only %d",n)
		print("buff after writing: ```\n", str.to_string(output),"\n```\n")
	}
}

todo :: #force_inline proc($msg:string)->!{
	fmt.print(msg)
	os.exit(1)
}
