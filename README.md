# Mini Compiler

![C](https://img.shields.io/badge/C-Language-blue.svg)
![Flex](https://img.shields.io/badge/Flex-Lexical%20Analysis-orange.svg)
![Bison](https://img.shields.io/badge/Bison-Parser-purple.svg)
![Compiler](https://img.shields.io/badge/Compiler-Design-brightgreen.svg)

A compact compiler front end built with **Flex**, **Bison**, and **C** for a small C-like language. It performs lexical analysis, parsing, semantic analysis, symbol table construction, and three-address code generation.

The compiler includes diagnostic recovery, so it can report multiple lexical, syntax, and semantic errors in a single run.

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

- Flex-based lexer for keywords, identifiers, numbers, operators, comments, and symbols
- Bison-based parser for declarations, assignments, expressions, `if`, and `while`
- Symbol table for declared identifiers and their data types
- Semantic analysis for undeclared variables, duplicate declarations, type mismatches, invalid assignments, and invalid relational conditions
- Three-address code generation using temporary variables and labels
- Error recovery for reporting multiple diagnostics in one compilation pass
- CLI support for input files, output files, quiet mode, and help text

---

## Supported Language Features

- Variable declarations
- Integer and float data types
- Arithmetic expressions
- Assignment statements
- Relational operators
- `if` statements
- `while` loops
- Single-line and multi-line comments

---

## How It Works

- **Flex** tokenizes the source code.
- **Bison** validates the token stream using grammar rules.
- **Semantic analysis** checks declarations, assignments, and type compatibility.
- **Symbol table construction** stores identifiers and their data types.
- **TAC generation** emits intermediate code using temporaries and labels.
- **Diagnostics** are collected and displayed together where recovery is possible.

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

- Flex
- Bison
- GCC
- Make

On Windows, use the **MSYS2 UCRT64** terminal for the smoothest setup.

---

## Setup

Install dependencies in MSYS2 UCRT64:

```sh
pacman -Syu
pacman -S mingw-w64-ucrt-x86_64-gcc flex bison make
```

Clone and enter the project:

```sh
git clone https://github.com/ashishTpakhale/Mini-Compiler.git
cd Mini-Compiler
```

Build the compiler:

```sh
make
```

---

## Makefile Commands

```sh
make        # Build the compiler
make run    # Build and run examples/valid.txt
make clean  # Remove generated build files
```

---

## Running the Compiler

Run a valid program:

```sh
./build/minic.exe examples/valid.txt
```

Run a program with a type error:

```sh
./build/minic.exe examples/type_error.txt
```

Run a program with multiple errors:

```sh
./build/minic.exe examples/multiple_errors.txt
```

Write compiler output to a file:

```sh
./build/minic.exe -o build/output.tac examples/valid.txt
```

Only show diagnostics and summary:

```sh
./build/minic.exe -q examples/valid.txt
```

Show CLI help:

```sh
./build/minic.exe --help
```

---

## Example Input Program

```c
int a, b;
float x;

a = 10;
b = 20;
x = 2.5;

if (a < b) {
    a = a + 1;
}
```

---

## Example Output

For a valid program, the compiler prints a formatted report:

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

For an invalid program, diagnostics include the error type, file, line number, message, and source line:

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

## Learning Outcomes

- Compiler design fundamentals
- Lexical analysis using Flex
- Parsing using Bison
- Semantic analysis and type checking
- Symbol table management
- Intermediate code generation
- Error recovery and diagnostics
- Systems programming in C

---

## Future Improvements

- AST generation
- Function support
- Optimization passes
- Assembly code generation

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
