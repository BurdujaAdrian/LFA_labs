< non terminal >

*terminal*

\[ zero of one occurrences ]

(zero or more occurences)*

(comma separated list)+

{grouping} = produs_1_from_grouping | produs\_2_from_grouping | ... | last_produs_from_grouping

{group1} - {group1} = {group1 without any elements from group2} 

terminal simbols:   '(', ')', '.', '=', ':', ']', '[', '{', '}', '|'

| alternaives

If there is space between 2 terminals/non_terminals, then there can be any < white space > between those 2.

---

## Program structure
```
           <program>    --->    [<program header>] '---' <code section>


      <code section>    --->    [<statement>]

      <prog. header>    --->  [<title>] [<global set prop.>] [<copyright notice>]

```
### Header section
```
       <c.r. notice>    --->    //TODO
```
### Code section
```
     <global set prop.>    --->    tempo ':' <int_literal>
                        |       (time_signature | time_sig) ':' <int_literal>'/'<int_literal>
                        |       title ':' <string_literal>
                        |       key ':' <key_signature>
                        |       // to be added

         <statement>    --->    (<macro definition> | <track>) ("\n" | ";")

```

## Groups
```
                // Note: Used for arguments to macro definitions and macro applications
     <capture group>    --->    '(' <arg>+ ')'

                // Note: used for repetitions and defining a multiline expresion
    <semantic group>    --->    '{' <token> <token>* '}'
                
                // Equivalent to the mathematal notion of a set. Is used to define restrictions on arguments. Set operations can be performed
         <set group>    --->    '{' <token>+ '}'

                // Note: used for multiline expresions
   <expresion group>    --->    '[' <expr> <expr>* ']'

       <composition>    --->    '|' [(<int_literal> | <macro aplication> | <macro inline>) ',' ] [ <int_literal>'/'<int_literal> ] [ ',' <major/minor notes>] ':' <expr> ':|'

```
## Sybols
```
       <white space>    --->    (" " | "\n" | "\t" )(" " | "\n" | "\t" )*

             <token>    --->    <alpha numeric> | <number> | <delimiter>

             <alpha>    --->    ("a" ... "z" | "A" ... "Z")
           <numeric>    --->    ("0" ... "9")

     <alpha numeric>    --->    <alpha>(<alpha> | <numeric | "_")*
            <number>    --->    <numeric><numeric>*

         <delimiter>    --->    ("{" | "}" | "(" | ")" | "[" | "]" | ":" | "\"" | "," | "|"  | "/" | "=" | "#" | "'" | "." | "-" | "+" | ">" | "<" | "*")

           <keyword>    --->    ("with" | "title" | "key" | "tempo" | "b" | "s" | "octave" | "time_signature" | "time_sig")

        <identifier>    --->    {<alpha numeric>} - {<keyword>}
     <escaped_chars>    --->    {<char>} - {'"'} | "\n" | "\r" | "\t" | "\""
```
## Literals
```
      <note literal>    --->    ("do" ... "si") |("A" ... "G" )
       <int_literal>    --->    <numeric>*[ms]
    <string_literal>    --->    '"'<escaped_chars>*'"'
```
## Statements
```

        <macro def.>    --->    <identifier> [with <capture group>] '=' (<expr>* | <composition>


             <track>    --->    <identifier> <string literal> ':' (<composition> | <note>*)

          <set def.>    --->    <identifier> <set group>
```
## Expressions
```
              <expr>    --->    (<note> )
                        |       <macro inlining>
                        |       <macro application>
                        |       <expression group>
                        |       <semantic group>
                        |       <expr>'*'<NUMERIC>

    <macro inlining>    --->    <identifier>

 <macro application>    --->    <identifier>'('<expr>+')'

              <note>    --->    <note literal>['-'<int_literal>]['^'<int_literal>]"b"*"s"*


``` 
