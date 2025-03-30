package main

import "core:fmt"
import "core:math/rand"
main :: proc(){
	expr1()
	expr2()
	expr3()
}


gen_rand_str :: proc(_regx:^Regex){
	switch regx in _regx{	
	case Group  : // unwrap the groupe, all information is already stored within the structure
		gen_rand_str(regx.ex)
	case Rstring: 
		fmt.print(regx.str)
	case Choice : 
		choice := rand.choice([]^Regex{regx.rhs, regx.lhs})
		gen_rand_str(choice)
	case Optional:
		if rand.uint64() & 2 == 0 {gen_rand_str(regx.ex)}
	case Seq:
		gen_rand_str(regx.lhs)
		gen_rand_str(regx.rhs)
	case Star:
		for i:= rand.uint64(); (i%5) > 0; i+=1{
			gen_rand_str(regx.ex)
		}
	case Plus:
		gen_rand_str(regx.ex)
		for i:= rand.uint64(); (i%5) > 0; i+=1{
			gen_rand_str(regx.ex)
		}
	case Power:
		for i in 0..<regx.n{
			gen_rand_str(regx.ex)
		}
	}
}

print_r :: proc(_regx:^Regex){

	switch regx in _regx{
	case Rstring: 
		fmt.print(regx.str)
	case Group  :
		fmt.print("(")
		print_r(regx.ex)
		fmt.print(")")
	case Choice : 
		print_r(regx.lhs)
		fmt.print("|")
		print_r(regx.rhs)
	case Optional:
		print_r(regx.ex)
		fmt.print("?")
	case Seq:
		print_r(regx.lhs)
		print_r(regx.rhs)
	case Star:
		print_r(regx.ex)
		fmt.print("*")
	case Plus:
		print_r(regx.ex)
		fmt.print("+")
	case Power:
		print_r(regx.ex)
		fmt.print("^")
		fmt.print(regx.n)
	}
}

Regex :: union{
	Rstring,
	Choice,
	Optional,
	Seq,
	Star,
	Plus,
	Power,
	Group,
}

Rstring :: struct{str:string}
Choice  :: struct{lhs:^Regex, rhs:^Regex}
Optional:: struct{ex:^Regex}
Seq     :: struct{lhs:^Regex,rhs:^Regex}
Star    :: struct{ex:^Regex}
Plus    :: struct{ex:^Regex}
Power   :: struct{ex:^Regex,n:int}
Group	:: struct{ex:^Regex}



expr1 :: proc(){

	// (a|b)(c|d)E+G?
	a:Regex = Rstring{"a"}
	b:Regex = Rstring{"b"}
	ab:Regex = Choice{&a,&b}
	gab:Regex = Group{&ab}

	c:Regex = Rstring{"c"}
	d:Regex = Rstring{"d"}
	cd:Regex = Choice{&c,&d}
	gcd:Regex = Group{&cd}
	
	abcd:Regex = Seq{&gab,&gcd}

	E:Regex = Rstring{"E"}
	eplus:Regex = Plus{&E}

	abcde:Regex = Seq{&abcd,&eplus}
	
	G:Regex = Rstring{"G"}
	gopt:Regex = Optional{&G}

	expr:Regex = Seq{&abcde,&gopt}

	print_r(&expr)
	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()
	gen_rand_str(&expr)
	fmt.println()
	fmt.println()
}


expr2 :: proc(){
	//P(Q|R|S)T(UV|W|X)*Z+
	P:Regex = Rstring{"P"}
	Q:Regex = Rstring{"Q"}
	R:Regex = Rstring{"R"}
	S:Regex = Rstring{"S"}
	T:Regex = Rstring{"T"}
	U:Regex = Rstring{"U"}
	V:Regex = Rstring{"V"}	
	W:Regex = Rstring{"W"}
	X:Regex = Rstring{"X"}
	Z:Regex = Rstring{"Z"}

	QR:Regex = Choice{&Q,&R}
	QRS:Regex= Choice{&QR,&S}
	QS:Regex = Group{&QRS}
	PS:Regex = Seq{&P,&QS}
	PT:Regex = Seq{&PS,&T}

	UV:Regex = Seq{&U,&V}
	UVW:Regex = Choice{&UV,&W}
	UVWX:Regex = Choice{&UVW,&X}
	UX:Regex = Group{&UVWX}
	UXSTAR:Regex = Star{&UX}

	PX:Regex = Seq{&PT,&UXSTAR}

	ZPLUS:Regex = Plus{&Z}

	expr:Regex = Seq{&PX,&ZPLUS} 

	print_r(&expr)
	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()

}

expr3 :: proc(){
	one:Regex = Rstring{"1"}
	two:Regex = Rstring{"2"}
	three:Regex = Rstring{"3"}
	four:Regex = Rstring{"4"}
	six:Regex = Rstring{"6"}
	zero:Regex = Rstring{"0"}

	zeroone:Regex = Choice{&zero,&one}
	zerooneg:Regex = Group{&zeroone}
	zeroones:Regex = Star{&zerooneg}
	
	oneone:Regex = Seq{&one,&zeroones}
	onetwo:Regex = Seq{&oneone,&two}

	threefor:Regex = Choice{&three,&four}
	threeforg:Regex = Group{&threefor}
	threefourp:Regex = Power{&threeforg,5}


	onefour:Regex = Seq{&onetwo,&threefourp}
	onethree:Regex = Seq{&onefour,&three}

	expr:Regex = Seq{&onethree,&six}

	print_r(&expr)
	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()
	gen_rand_str(&expr)
	fmt.println()

	fmt.println()

}
