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
           <program>    --->    [<program header> '---'] <code section>


      <code section>    --->  <track>* | <macro definition>* 
// NOTE: since macros can be defined within or outside tracks, they are namespaced, either global or specific to a track
// namespaced macros get the prefix "<track name>_" internally

      <prog. header>    --->  [<title>] [<copyright notice>]

```
### Header section
```
       <c.r. notice>    --->    //TODO
```
### Code section
```

         <track>        --->    track [<string_literal>] : <statement>*

         <statement>    --->    (<macro definition> | <track> | <movement>) ("\n" | ";")

```

## Groups
```
                // Note: Used for arguments to macro definitions and macro applications
     <capture group>    --->    '(' <arg>+ ')'

                // Note: used for repetitions and defining a multiline expresion
    <semantic group>    --->    '{' <token> <token>* '}'
                

                // Note: used for multiline expresions
   <expresion group>    --->    '[' <expr> <expr>* ']'


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

           <keyword>    --->    ("title" | "key" | "tempo" | "b" | "s" | "octave" )

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

        <macro def.>    --->    <identifier> [<capture group>] '=' <expr>


             <movement>    --->    <identifier> <string literal> ':'  <expr>
```
## Expressions
```
              <expr>    --->    <note> 
                        |       <macro inlining>
                        |       <macro application>
                        |       <expression group>
                        |       <semantic group>
                        |       <expr>'*'<numeric> // repeating the expression
                        |       ('<' | '>')[<numeric>] // setting octave for the track 
                        |       ':'<numeric> // setting note length/duration for the track
                        |       '!'<number>  // setting tempo for the track

    <macro inlining>    --->    <identifier>

 <macro application>    --->    <identifier>'('<expr>+')'

              <note>    --->    <note literal>('+' | '-')*[<numeric>][':'<numeric>]
                                            // pitch ^     octave ^   duration ^


``` 
