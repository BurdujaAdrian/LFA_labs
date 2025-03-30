# Regular expressions

### Course: Formal Languages & Finite Automata
### Author: Burduja Adrian

----

## Theory

Regular expressions, aka regex, is a sequence of characters that specifies a match pattern in text. Regex is most 
often used to validate the format of a certain string. Based on this validations many operations can be 
facilitated like searching a wide variaty of text based on a pattern for finding either specific files, "find and
replace" opperations and other use cases.

## Objectives:

Write and cover what regular expressions are, what they are used for;

Below you will find 3 complex regular expressions per each variant. Take a variant depending on your number in the list of students and do the following:

a. Write a code that will generate valid combinations of symbols conform given regular expressions (examples will be shown).

b. In case you have an example, where symbol may be written undefined number of times, take a limit of 5 times (to evade generation of extremely long combinations);

c. Bonus point: write a function that will show sequence of processing regular expression (like, what you do first, second and so on)



## Implementation description

Varient 1: 

1. (a|b)(c|d)E+G?
2. P(Q|R|S)T(UV|W|X)*Z+
3. 1(0|1)*2(3|4)^5 36

In order to implement these tasks I started by implementing a way represent regular
expressions in code, for that I created a enum/union of all the relevant operators
and collections of a regular expression:
```Odin
Regex :: union{
	Rstring,
	Choice,
	Optional,
	Seq,
	Star,
	Plus,
	Wild,
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
```
This recursive data structure can represent a regular expression in a very simplex
way. 

Note: I decided to use a branching structure instead of a list for representing 
Sequences and Options of expressions only for the sake of easier later construction.

To make sure my representation of the regex was correct, I also created a function
that can print and the regex from the given structure,recursivly, to better represen
it's recursive,branching nature:
```Odin
print_r :: proc(_regx:^Regex){
	switch regx in _regx{
	case Rstring: fmt.print(regx.str)
	case Group  : fmt.print("("); print_r(regx.ex); fmt.print(")")
	case Choice : print_r(regx.lhs); fmt.print("|"); print_r(regx.rhs)
	case Optional: print_r(regx.ex); fmt.print("?")
	case Seq: print_r(regx.lhs); print_r(regx.rhs)
	case Star:print_r(regx.ex);fmt.print("*")
	case Plus:print_r(regx.ex);fmt.print("+")
	case Power:print_r(regx.ex);fmt.print("^");fmt.print(regx.n)
	}
}
```

A similar structure is used for the function that randomly creates valid strings for 
the given regex.

Initially I tried implementing a regex interpretor, however, after multiple failed 
attempts, I found out this wasn't necessary.

To evaluate the expressions I was given, I simply created the corresponding data 
structure by hand:
```Odin
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
```
Similarly for the other expressions

## Conclusions / Screenshots / Results
For this laboratory I had to study what regular expressions are and write code to 
work with them.

In order to execute the second objective, I could write a program that can generate
text based on a given regex.

First, I created a datatype that can describe a regular expression. For this I used
an union of the possible types of simple regex(string,options,sequence etc.) and a 
Seq type which describes a sequene of regex.

To test my code, I wrote one of the examples by hand with the Regex type and printed
it using a custom function, and it printed the exact expression.


## References
