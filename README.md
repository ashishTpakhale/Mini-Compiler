# Mini Compiler

![C Language](https://img.shields.io/badge/C-Language-blue.svg)
![Flex](https://img.shields.io/badge/Lexer-Flex-orange.svg)
![Bison](https://img.shields.io/badge/Parser-Bison-purple.svg)
![Compiler Design](https://img.shields.io/badge/Domain-Compiler%20Design-brightgreen.svg)

A simple compiler built using **Flex**, **Bison**, and **C** for a small C-like language.
It performs lexical analysis, syntax analysis, semantic checking, symbol table construction, and three-address code generation.

The compiler is designed to report **multiple errors in one run** instead of stopping at the first error, making it closer to how real compilers provide diagnostics.

---

## Compiler Pipeline

```text
Source Code
     ↓
Lexical Analysis (Flex)
     ↓
Syntax Analysis (Bison)
     ↓
Semantic Analysis
     ↓
Symbol Table Construction
     ↓
Three Address Code Generation
```

---

## Features

- A Flex-based lexical analyzer for keywords, identifiers, numbers, operators, comments, and symbols
- A Bison-based parser for declarations, assignments, expressions, `if` statements, and `while` loops
- A symbol table for declared variables and their data types
- Semantic checks for undeclared variables, multiple declarations, type mismatches, invalid assignments, and invalid relational conditions
- Three-address code generation using temporary variables and labels
- Error recovery so the compiler can continue after an error and report more issues
- A user-friendly CLI with input file support, output file support, quiet mode, and help text

---

## Supported Language Features

- Variable declarations
- Arithmetic expressions
- Assignment statements
- Relational operators
- `if` statements
- `while` loops
- Integer and float data types
- Comments

---

## How It Works

The compiler follows a classic front-end compiler architecture. **Flex** tokenizes the source program into meaningful tokens such as identifiers, keywords, numbers, and operators. **Bison** then validates the token stream against the grammar of the language.

After parsing, semantic analysis checks whether variables are declared before use, whether declarations are repeated, and whether expressions and assignments use compatible types. The symbol table stores identifiers and their associated data types. If the program is valid, the compiler generates **three-address code (TAC)** using temporary variables and labels.

Diagnostics are collected together where recovery is possible, allowing the compiler to report multiple lexical, syntax, and semantic errors in a single run.

---

## Project Structure

```text
.
|-- src/
|   |-- compiler.l      # Lexical analyzer
|   `-- compiler.y      # Parser, semantic analysis, TAC generation, CLI
|-- examples/
|   |-- valid.txt
|   |-- type_error.txt
|   `-- multiple_errors.txt
|-- Makefile
|-- LICENSE
|-- .gitignore
`-- README.md
```

---

## Requirements

You need:

- Flex
- Bison
- GCC
- Make, optional but recommended

On Windows, the easiest setup is **MSYS2 UCRT64**.

---

## Complete Setup on Windows

Open the **MSYS2 UCRT64** terminal and install the required tools:

```sh
pacman -Syu
pacman -S mingw-w64-ucrt-x86_64-gcc flex bison make
```

Go to the project folder:

```sh
cd "/d/coder/Compiler/Lab/Lab 5"
```

Create the build folder:

```sh
mkdir -p build
```

Generate the parser using Bison:

```sh
bison -d -o build/compiler.tab.c src/compiler.y
```

Generate the scanner using Flex:

```sh
flex -o build/lexer.yy.c src/compiler.l
```

Compile the final executable:

```sh
gcc -Wall -Wextra -std=gnu11 -Ibuild build/compiler.tab.c build/lexer.yy.c -o build/minic.exe
```

---

## Makefile Commands

The project includes a professional `Makefile` to automate the complete build process.

Build the compiler:

```sh
make
```

Run the compiler on the valid example program:

```sh
make run
```

Remove generated files:

```sh
make clean
```

---

## Running the Compiler

Run the compiler on a valid input program:

```sh
./build/minic.exe examples/valid.txt
```

Run it on a file with a type error:

```sh
./build/minic.exe examples/type_error.txt
```

Run it on a file with multiple errors:

```sh
./build/minic.exe examples/multiple_errors.txt
```

Write the compiler output to a file:

```sh
./build/minic.exe -o build/output.tac examples/valid.txt
```

Only show diagnostics and the final summary:

```sh
./build/minic.exe -q examples/valid.txt
```

Show help:

```sh
./build/minic.exe --help
```

---

## Example Input Program

```c
int a, b, c;
float x, y;

a = 10;
b = 20;
x = 1.5;
y = 2.5;

c = (a + b) * 2;

if (c >= 60) {
    a = c - 5;
}

while (a < 100) {
    a = a + 10;
}
```

---

## Example Output

For a valid program, the compiler prints:

```text
========================================================================
Mini Compiler Report
Source: examples/valid.txt
========================================================================

========================================================================
Symbol Table
========================================================================
+------+------------------------------+----------+
| No.  | Identifier                   | Type     |
+------+------------------------------+----------+
| 1    | a                            | int      |
| 2    | b                            | int      |
+------+------------------------------+----------+

========================================================================
Intermediate Code (Three-Address Code)
========================================================================
  1 | a = 10
  2 | b = 20
  3 | t1 = a + b
```

For an invalid program, it reports diagnostics like:

```text
------------------------------------------------------------------------
[SYNTAX ERROR] examples/multiple_errors.txt:2
Message: syntax error
Source :    2 | float b;
------------------------------------------------------------------------

------------------------------------------------------------------------
[SEMANTIC ERROR] examples/multiple_errors.txt:7
Message: Type mismatch in relational expression: int < float
Source :    7 | if (a < b) {
------------------------------------------------------------------------

------------------------------------------------------------------------
[LEXICAL ERROR] examples/multiple_errors.txt:11
Message: unexpected character '$'
Source :   11 | $bad = 4;
------------------------------------------------------------------------

========================================================================
Diagnostic Summary
========================================================================
Status   : FAILED
Total    : 5
Lexical  : 1
Syntax   : 1
Semantic : 3
========================================================================
```

---

## Clean Generated Files

Generated files are stored inside `build/`. To clean them:

```sh
rm -rf build
```

The `build/` folder is ignored by Git because generated files and executables should not be pushed to GitHub.

---

## Learning Outcomes

This project strengthened practical understanding of:

- Compiler design
- Lexical analysis
- Parsing
- Semantic analysis
- Intermediate code generation
- Error recovery
- Systems programming in C

---

## Future Improvements

- Add support for more data types
- Add `else` support for conditional statements
- Improve syntax error messages with more specific suggestions
- Add more test programs for valid and invalid inputs
- Support nested scopes using an improved symbol table
- Generate cleaner and more optimized three-address code
- Add function declarations and function calls

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
