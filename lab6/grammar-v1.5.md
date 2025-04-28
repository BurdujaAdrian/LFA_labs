< non terminal >


\[ zero of one occurrences ]

(zero or more occurences)*

(comma separated list)+

{grouping} = produs_1_from_grouping | produs\_2_from_grouping | ... | last_produs_from_grouping

{group1} - {group1} = {group1 without any elements from group2} 

terminal simbols:   '(', ')', '.', '=', ':', ']', '[', '{', '}', '|'

| alternaives

If there is space between 2 terminals/non_terminals, then there can be any < white space > between those 2.

---

### 1. Program structure 
```
1.         <program>    --->     [[<title>] [<copyright notice>] '---'] [<statement>]

2.       <statement>    --->    (<macro definition> | <track> | <global setting> | <set definition> | <movement>) ("\n" | ";")
```

### 2. Header section 
```
1.     <c.r. notice>    --->    copy_right ':' <string>

2.           <title>    --->    title ':' <string_literal>
```

### 3. Statements
```
1.      <macro def.>    --->    <identifier> [with <capture group>] '=' <expr>*

2.           <track>    --->    'track' [<string_literal>] '{' <statement> <statement>* '}'

3.        <movement>    --->    <instrument> [<string literal>] ':' <expr>*

4.        <set def.>    --->    <identifier> <set group>

5.  <global setting>    --->    tempo ':' <int_literal>
                        |       ( measure | m )':'<measure_signature>
                        |       // to be added
```

### 4. Groups
```
                // Note: Used for arguments to macro definitions and macro applications
1.   <capture group>    --->    '(' <arg>+ ')'

                // Note: used for repetitions and defining a multiline expresion
2.  <semantic group>    --->    '{' <token> <token>* '}'
                
                // Equivalent to the mathematal notion of a set. Is used to define restrictions on arguments. Set operations can be performed
3.       <set group>    --->    '{' <expr>+ '}'

                // Note: used for multiline expresions
4. <expresion group>    --->    '[' <expr> <expr>* ']'


```

### 5. Symbols
```
1.     <white space>    --->    (" " | "\n" | "\t" )(" " | "\n" | "\t" )*

2.           <token>    --->    <alpha numeric> | <number> | <delimiter>

3.           <alpha>    --->    ("a" ... "z" | "A" ... "Z")
4.         <numeric>    --->    ("0" ... "9")

5.   <alpha numeric>    --->    <alpha>(<alpha> | <numeric | "_")*
6.          <number>    --->    <numeric><numeric>*

7.       <delimiter>    --->    ("{" | "}" | "(" | ")" | "[" | "]" | ":" | "\"" | "," | "|"  | "/" | "=" | "#" | "'" | "." | "-" | "+" | ">" | "<" | "*" | ";" | "\n")

8.         <keyword>    --->    ("with" | "title" | "copy_right" |"tempo" | "b" | "s" | "r" | "octave" | "m" | "measure")

9.      <identifier>    --->    {<alpha numeric>} - {<keyword>}
10.  <escaped_chars>    --->    {<char>} - {'"'} | "\n" | "\r" | "\t" | "\""

11.     <instrument>    --->    <identifier>

12.   <measure_sig.>    --->    <numeric>'\'<numeric>
```

### 6. Literals
```
1.    <note literal>    --->    ("do" ... "si") |("A" ... "G" )

2.     <int_literal>    --->    <numeric>*[ms]

3.  <string_literal>    --->    '"'<escaped_chars>*'"'
```

### 7. Expressions
```
1.            <expr>    --->    ['(']<note> ['|']
                        |       <note>[')'] ['|']
                        |       <macro inlining>
                        |       <macro application>
                        |       <expression group>
                        |       <semantic group>
                        |       <expr>'*'<NUMERIC>
                        |       <setting>


2.  <macro inlining>    --->    <identifier>

3.     <macro appl.>    --->    <identifier>'('<expr>+')'

4.            <note>    --->    <note literal>['-'<int_literal>]['^'<int_literal>]"b"*"s"*
                        |       'r'['-'<int_literal>]
                        |       <note>['/'<note>]

5.         <setting>    --->    ('<' | '>')[<numeric>]
``` 

```

           <comment>    --->    '#'<text>'\n'
```


## Explications

### 1. Program

1. Denifes generally how a program can be structured

2. Defines the fundamental the complete unit of code: the statement. If a file is not made up of whole statements then it's invalid.

### 2. Header section

1. Defines the structure of writing the copyright notice for a given file

2. Defines the structure of explicitly writing the title of the file.

Both of these are optional, but must be fallowed by '---' in order to show the end of header
More items to the header might be added later.

### 3. Statements

1. "< macro def. >" defines a macro. It's composed of the name of the macro, an
< identifier >, optional arguments, '=', and a number of expressions.

The 'with' keyword is used to make it easier to distiguish between macro definitions 
and applications. 

The tokens provided in the capture group serve as names to the arguments that will be
provided when the macro is called.

Macros work by theri contents being essentially inlined in the place where they are 
called, the arguments being replaced in the body of the macro definitions with whatever
the user provides.

2. "< track >" defines a distinct track which maps directly to tracks in midi. A track contains one or more statements.

If a track isnt defined, the global scope is considered the one and only track.

3. "< movements >" defines a set of notes played by an instrument. 
All movements are considered to be played at the same time within a track.

If a movement is named( has the optional string literal) then any other instance of
a movement with the same name is considered the continuation of that movement, in the 
order that they are written.

4. "< set def. >" defines a mathematical set for items in the languege. For now doesn't 
have a usecase, but was originally designed to allow the user to restrict arguments to
a macro.
 
5. "< global setting >" allows the user to set defaults for the entire file/track such as
tempo, measure or others.

### 4. Groups

1. "< capture group >" a series of comma separated expressions. Used for defining macro
arguments and for providing arguments when calling macros.

2. "< semantic group >" a series of tokens surrounded by curly braces. Serves to 
transofrm a series of tokens into expressions that can be repeated or passed to macros.

If no repetition is applied and isn't passed to a macro, they do nothing.

3. "< set group >" a comma separated list of expressions that can be used to define a set
.

4. "< expresion group >" a list of expressions between square braces. Used to define 
expresions across mustiple lines without ending a statement.

### 5. Symbols

1. "< white space >" defines non visible characters that are allowed and generally 
ignored if are in series of more than one.

2. "< token >" the semantical atom of code.

3. 4. 5. 6. Defines different building blocks for tokens and literals.

7. Defines delimiters, these separate tokens and are themselves tokens

8. Defines keywords, they are reserved names which can't be used as identifiers

9. Defines identifiers, alphanumeric tokens that can be used to name macros,sets etc.

10. Defines escaped characters. Relevant for string literals to resolve ambiguity for 
symbols within the string and in the code itself.

11. Instrument is a subset of identifiers

12. Defines the notation for measure signature. It's made up of 2 numeric tokens(and 
not any number).

### 6. Literals

1. Defines the set of acceptable notations for notes(without any information about 
duration octave or accidentals)

2. Defines numbers and also allows for denoting time in miliseconds.

3. Defines a string literal

### 7. Expressions

1. "< expr >" defines the fundamental values of a program. 

    1. ```['(']<note> ['|']``` | ```<note>[')'] ['|']``` defines notes as expressions.
    the '|' and has the same usage and meaning as the bar in sheet music.

    2. "< macro inlining >" defines the application of a macro without specifying any 
    arguments. In this case, the body of the macro is essentially "copy pasted" in the
    location of the call

    3. "< macro application >" defines the calling of a macro with arguments.

    4. 5.  States that these groups are an expression.

    6. defines the syntax for repeating an expression. Is equivalent to copy pasting
    the given expresion n times.

    7. Defines the syntax for specifying a setting at a limited scope: within a 
    composition.

2. "< macro inlining >" describes the syntax of inlining a macro by simply writing it's
name/identifier.

3. "< macro appl. >" describes the syntax of applying a macro while providing arguments.

These last 2 are separate expressions for parsing reasons(inlining macros is simply easier then applaying them)

4. "< note >" defines the syntax for writing a note and how to specify it's properites
    
    1. ```['-'<int_literal>]``` allows the specification of duration
    2. ```['^'<int_literal>]``` allows the specification of octave
    3. ```b"*"s"``` describes the syntax to denote semitones. There can be an arbitrar
    number of bemols and sharp's, which all add up to a single note. 

    4. Describes the notation for silent notes:rests.

    5. Describes the notations for notes with 0 time interval between them, so chords.
    This definition is recursive

5. Describes local settings

    1. '>' '<' defines raising or lowering the octave by one or the number specified.

"< comment >" describes the syntax for comments. They end with new line and are 
completly ingored.

