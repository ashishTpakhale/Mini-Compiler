%{
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *message);
int yylex(void);
extern FILE *yyin;
extern int line_number;

#define MAX_SYMBOLS 100
#define MAX_NAME_LEN 63
#define MAX_TYPE_LEN 9
#define OUTPUT_WIDTH 72

struct sym {
    char name[MAX_NAME_LEN + 1];
    char type[MAX_TYPE_LEN + 1];
} symtab[MAX_SYMBOLS];

struct expr_attr {
    char *code;
    char *place;
    char *type;
    int line;
};

int symcount = 0;
char current_type[10];
int temp_count = 1;
int label_count = 1;
int diagnostic_count = 0;
int syntax_error_count = 0;
int semantic_error_count = 0;
int lexical_error_count = 0;
int suppress_output = 0;
const char *source_name = "<stdin>";
FILE *out = NULL;
char **source_lines = NULL;
int source_line_count = 0;

char *copy_string(const char *value) {
    char *copy;
    size_t size;

    if (value == NULL) {
        value = "";
    }

    size = strlen(value) + 1;
    copy = malloc(size);
    if (copy == NULL) {
        fprintf(stderr, "fatal: out of memory\n");
        exit(2);
    }

    memcpy(copy, value, size);
    return copy;
}

void print_usage(const char *program_name) {
    printf("Mini Compiler\n");
    printf("A Flex/Bison compiler with semantic diagnostics and TAC generation.\n\n");
    printf("Usage: %s [options] [source-file]\n", program_name);
    printf("\nOptions:\n");
    printf("  -o, --output <file>   Write symbol table and TAC to a file\n");
    printf("  -q, --quiet           Only print diagnostics and final summary\n");
    printf("  -h, --help            Show this help message\n");
    printf("\nIf no source file is given, input is read from standard input.\n");
}

void print_rule(FILE *stream, char ch) {
    for (int i = 0; i < OUTPUT_WIDTH; i++) {
        fputc(ch, stream);
    }
    fputc('\n', stream);
}

void print_section(FILE *stream, const char *title) {
    fprintf(stream, "\n");
    print_rule(stream, '=');
    fprintf(stream, "%s\n", title);
    print_rule(stream, '=');
}

void print_symbol_table(FILE *stream) {
    print_section(stream, "Symbol Table");
    fprintf(stream, "+------+------------------------------+----------+\n");
    fprintf(stream, "| No.  | Identifier                   | Type     |\n");
    fprintf(stream, "+------+------------------------------+----------+\n");

    if (symcount == 0) {
        fprintf(stream, "| %-4s | %-28s | %-8s |\n", "-", "No symbols declared", "-");
    } else {
        for (int i = 0; i < symcount; i++) {
            fprintf(stream, "| %-4d | %-28s | %-8s |\n", i + 1, symtab[i].name, symtab[i].type);
        }
    }

    fprintf(stream, "+------+------------------------------+----------+\n");
}

void print_tac(FILE *stream, const char *code) {
    char *copy;
    char *line;
    int instruction = 1;

    print_section(stream, "Intermediate Code (Three-Address Code)");

    if (code == NULL || strlen(code) == 0) {
        fprintf(stream, "No intermediate code generated.\n");
        return;
    }

    copy = copy_string(code);
    line = strtok(copy, "\n");

    while (line != NULL) {
        if (strlen(line) > 0) {
            fprintf(stream, "%3d | %s\n", instruction++, line);
        }
        line = strtok(NULL, "\n");
    }

    free(copy);
}

void print_compilation_output(const char *code) {
    print_rule(out, '=');
    fprintf(out, "Mini Compiler Report\n");
    fprintf(out, "Source: %s\n", source_name);
    print_rule(out, '=');
    print_symbol_table(out);
    print_tac(out, code);
    fprintf(out, "\n");
    print_rule(out, '=');
    fprintf(out, "End of Report\n");
    print_rule(out, '=');
}

const char *diagnostic_label(const char *kind) {
    if (strcmp(kind, "lexical") == 0) {
        return "LEXICAL";
    }
    if (strcmp(kind, "syntax") == 0) {
        return "SYNTAX";
    }
    if (strcmp(kind, "semantic") == 0) {
        return "SEMANTIC";
    }
    return "ERROR";
}

void load_source_lines(const char *path) {
    FILE *file;
    char buffer[1024];
    int capacity = 64;

    if (path == NULL) {
        return;
    }

    file = fopen(path, "r");
    if (file == NULL) {
        return;
    }

    source_lines = malloc(sizeof(char *) * capacity);
    if (source_lines == NULL) {
        fprintf(stderr, "fatal: out of memory\n");
        exit(2);
    }

    while (fgets(buffer, sizeof(buffer), file) != NULL) {
        size_t len = strlen(buffer);

        while (len > 0 && (buffer[len - 1] == '\n' || buffer[len - 1] == '\r')) {
            buffer[--len] = '\0';
        }

        if (source_line_count >= capacity) {
            char **grown;
            capacity *= 2;
            grown = realloc(source_lines, sizeof(char *) * capacity);
            if (grown == NULL) {
                fprintf(stderr, "fatal: out of memory\n");
                exit(2);
            }
            source_lines = grown;
        }

        source_lines[source_line_count++] = copy_string(buffer);
    }

    fclose(file);
}

const char *get_source_line(int line) {
    if (line <= 0 || line > source_line_count || source_lines == NULL) {
        return NULL;
    }
    return source_lines[line - 1];
}

void report_error(const char *kind, int line, const char *fmt, ...) {
    va_list args;
    char message[512];
    const char *source_line;

    if (line <= 0) {
        line = line_number;
    }

    va_start(args, fmt);
    vsnprintf(message, sizeof(message), fmt, args);
    va_end(args);

    fprintf(stderr, "\n");
    print_rule(stderr, '-');
    fprintf(stderr, "[%s ERROR] %s:%d\n", diagnostic_label(kind), source_name, line);
    fprintf(stderr, "Message: %s\n", message);

    source_line = get_source_line(line);
    if (source_line != NULL) {
        fprintf(stderr, "Source : %4d | %s\n", line, source_line);
    }

    print_rule(stderr, '-');
    diagnostic_count++;

    if (strcmp(kind, "syntax") == 0) {
        syntax_error_count++;
    } else if (strcmp(kind, "semantic") == 0) {
        semantic_error_count++;
    } else if (strcmp(kind, "lexical") == 0) {
        lexical_error_count++;
    }
}

char *new_temp(void) {
    char *temp = malloc(16);
    if (temp == NULL) {
        fprintf(stderr, "fatal: out of memory\n");
        exit(2);
    }
    snprintf(temp, 16, "t%d", temp_count++);
    return temp;
}

char *new_label(void) {
    char *label = malloc(16);
    if (label == NULL) {
        fprintf(stderr, "fatal: out of memory\n");
        exit(2);
    }
    snprintf(label, 16, "L%d", label_count++);
    return label;
}

int lookup(const char *name) {
    for (int i = 0; i < symcount; i++) {
        if (strcmp(symtab[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

char *get_type(const char *name) {
    int idx = lookup(name);
    if (idx == -1) {
        return NULL;
    }
    return symtab[idx].type;
}

void semantic_error_at(int line, const char *message) {
    report_error("semantic", line, "%s", message);
}

int insert_at(const char *name, const char *type, int line) {
    if (strlen(name) > MAX_NAME_LEN) {
        char message[160];
        snprintf(message, sizeof(message), "Identifier too long: %s", name);
        semantic_error_at(line, message);
        return 0;
    }

    if (symcount >= MAX_SYMBOLS) {
        semantic_error_at(line, "Symbol table overflow");
        return 0;
    }

    if (lookup(name) != -1) {
        char message[160];
        snprintf(message, sizeof(message), "Multiple declaration of %s", name);
        semantic_error_at(line, message);
        return 0;
    }

    strncpy(symtab[symcount].name, name, MAX_NAME_LEN);
    symtab[symcount].name[MAX_NAME_LEN] = '\0';
    strncpy(symtab[symcount].type, type, MAX_TYPE_LEN);
    symtab[symcount].type[MAX_TYPE_LEN] = '\0';
    symcount++;
    return 1;
}

char *concat(const char *a, const char *b) {
    char *result;

    if (a == NULL) {
        a = "";
    }
    if (b == NULL) {
        b = "";
    }

    if (strlen(a) == 0 && strlen(b) == 0) {
        return copy_string("");
    }
    if (strlen(a) == 0) {
        return copy_string(b);
    }
    if (strlen(b) == 0) {
        return copy_string(a);
    }

    result = malloc(strlen(a) + strlen(b) + 2);
    if (result == NULL) {
        fprintf(stderr, "fatal: out of memory\n");
        exit(2);
    }

    sprintf(result, "%s\n%s", a, b);
    return result;
}

char *merge_code(const char *a, const char *b) {
    return concat(a == NULL ? "" : a, b == NULL ? "" : b);
}

struct expr_attr make_expr(char *code, char *place, char *type, int line) {
    struct expr_attr expr;
    expr.code = code;
    expr.place = place;
    expr.type = type;
    expr.line = line;
    return expr;
}

struct expr_attr error_expr_at(int line) {
    return make_expr(copy_string(""), copy_string("<error>"), copy_string("error"), line);
}

int is_error_expr(struct expr_attr expr) {
    return expr.type == NULL || strcmp(expr.type, "error") == 0;
}

struct expr_attr build_binary_expr(struct expr_attr left, struct expr_attr right, const char *op) {
    char *temp;
    char *combined;
    char *line;
    char *code;
    char message[160];
    char result_type[10];
    int line_size;

    if (is_error_expr(left) || is_error_expr(right)) {
        return error_expr_at(left.line);
    }

    if (strcmp(left.type, right.type) != 0) {
        snprintf(message, sizeof(message), "Type mismatch in expression: %s %s %s", left.type, op, right.type);
        semantic_error_at(left.line, message);
        return error_expr_at(left.line);
    }

    strcpy(result_type, left.type);
    temp = new_temp();
    combined = merge_code(left.code, right.code);
    line_size = (int)(strlen(temp) + strlen(left.place) + strlen(op) + strlen(right.place) + 10);
    line = malloc(line_size);
    if (line == NULL) {
        fprintf(stderr, "fatal: out of memory\n");
        exit(2);
    }

    snprintf(line, line_size, "%s = %s %s %s", temp, left.place, op, right.place);
    code = concat(combined, line);

    return make_expr(code, temp, copy_string(result_type), left.line);
}

char *build_condition_code(struct expr_attr left, char *relop, struct expr_attr right) {
    char message[160];

    if (is_error_expr(left) || is_error_expr(right)) {
        return copy_string("");
    }

    if (strcmp(left.type, right.type) != 0) {
        snprintf(message, sizeof(message), "Type mismatch in relational expression: %s %s %s", left.type, relop, right.type);
        semantic_error_at(left.line, message);
        return copy_string("");
    }

    return merge_code(left.code, right.code);
}
%}

%union {
    struct expr_attr expr;
    char *str;
}

%token <str> ID INT_NUM FLOAT_NUM RELOP
%token INT FLOAT IF WHILE

%type <expr> EXPR
%type <str> STMT STMTS BLOCK ASSIGN IF_STMT WHILE_STMT

%left '+' '-'
%left '*' '/'
%locations

%%

PROGRAM:
    STMTS {
        if (diagnostic_count == 0 && !suppress_output) {
            print_compilation_output($1);
        }
    }
;

STMTS:
    STMTS STMT { $$ = concat($1, $2); }
  | STMT { $$ = $1; }
;

STMT:
    DECL { $$ = copy_string(""); }
  | ASSIGN { $$ = $1; }
  | IF_STMT { $$ = $1; }
  | WHILE_STMT { $$ = $1; }
  | error ';' { yyerrok; $$ = copy_string(""); }
;

DECL:
    TYPE VARLIST ';'
  | TYPE error ';' { yyerrok; }
  | TYPE VARLIST error { yyerrok; }
;

TYPE:
    INT { strcpy(current_type, "int"); }
  | FLOAT { strcpy(current_type, "float"); }
;

VARLIST:
    VARLIST ',' ID { insert_at($3, current_type, @3.first_line); }
  | ID { insert_at($1, current_type, @1.first_line); }
;

ASSIGN:
    ID '=' EXPR ';' {
        int idx;
        char *buf;
        char message[160];
        int bufsize;

        idx = lookup($1);
        if (idx == -1) {
            snprintf(message, sizeof(message), "Undeclared variable %s", $1);
            semantic_error_at(@1.first_line, message);
            $$ = copy_string("");
        } else if (is_error_expr($3)) {
            $$ = copy_string("");
        } else if (strcmp(symtab[idx].type, $3.type) != 0) {
            snprintf(message, sizeof(message), "Invalid assignment to %s: cannot assign %s to %s", $1, $3.type, symtab[idx].type);
            semantic_error_at(@1.first_line, message);
            $$ = copy_string("");
        } else {
            bufsize = (int)(strlen($3.code) + strlen($1) + strlen($3.place) + 50);
            buf = malloc(bufsize);
            if (buf == NULL) {
                fprintf(stderr, "fatal: out of memory\n");
                exit(2);
            }

            if (strlen($3.code) == 0) {
                snprintf(buf, bufsize, "%s = %s", $1, $3.place);
            } else {
                snprintf(buf, bufsize, "%s\n%s = %s", $3.code, $1, $3.place);
            }

            $$ = buf;
        }
    }
  | ID '=' error ';' { yyerrok; $$ = copy_string(""); }
  | ID '=' EXPR error { yyerrok; $$ = copy_string(""); }
;

EXPR:
    EXPR '+' EXPR { $$ = build_binary_expr($1, $3, "+"); }
  | EXPR '-' EXPR { $$ = build_binary_expr($1, $3, "-"); }
  | EXPR '*' EXPR { $$ = build_binary_expr($1, $3, "*"); }
  | EXPR '/' EXPR { $$ = build_binary_expr($1, $3, "/"); }
  | '(' EXPR ')' { $$ = $2; }
  | ID {
        char *type;
        char message[120];

        type = get_type($1);
        if (type == NULL) {
            snprintf(message, sizeof(message), "Undeclared variable %s", $1);
            semantic_error_at(@1.first_line, message);
            $$ = error_expr_at(@1.first_line);
        } else {
            $$ = make_expr("", $1, copy_string(type), @1.first_line);
        }
    }
  | INT_NUM {
        $$ = make_expr("", $1, copy_string("int"), @1.first_line);
    }
  | FLOAT_NUM {
        $$ = make_expr("", $1, copy_string("float"), @1.first_line);
    }
;

IF_STMT:
    IF '(' EXPR RELOP EXPR ')' BLOCK {
        char *L1 = new_label();
        char *L2 = new_label();
        char *cond = build_condition_code($3, $4, $5);
        char *buf;
        int bufsize;

        if (is_error_expr($3) || is_error_expr($5)) {
            $$ = copy_string("");
        } else {
            bufsize = (int)(strlen(cond) + strlen($3.place) + strlen($4) + strlen($5.place) +
                            strlen($7) + strlen(L1) + strlen(L2) + 200);
            buf = malloc(bufsize);
            if (buf == NULL) {
                fprintf(stderr, "fatal: out of memory\n");
                exit(2);
            }

            snprintf(buf, bufsize,
                "%s%sif %s %s %s goto %s\n"
                "goto %s\n"
                "%s: %s\n"
                "%s:",
                cond,
                strlen(cond) == 0 ? "" : "\n",
                $3.place, $4, $5.place, L1,
                L2,
                L1, $7,
                L2
            );

            $$ = buf;
        }

        free(L1);
        free(L2);
        free(cond);
    }
  | IF '(' error ')' BLOCK { yyerrok; $$ = copy_string(""); }
;

WHILE_STMT:
    WHILE '(' EXPR RELOP EXPR ')' BLOCK {
        char *L1 = new_label();
        char *L2 = new_label();
        char *L3 = new_label();
        char *cond = build_condition_code($3, $4, $5);
        char *buf;
        int bufsize;

        if (is_error_expr($3) || is_error_expr($5)) {
            $$ = copy_string("");
        } else {
            bufsize = (int)(strlen(L1) + strlen(cond) + strlen($3.place) + strlen($4) +
                            strlen($5.place) + strlen(L2) + strlen(L3) + strlen($7) + 200);
            buf = malloc(bufsize);
            if (buf == NULL) {
                fprintf(stderr, "fatal: out of memory\n");
                exit(2);
            }

            snprintf(buf, bufsize,
                "%s: %s%sif %s %s %s goto %s\n"
                "goto %s\n"
                "%s: %s\n"
                "goto %s\n"
                "%s:",
                L1,
                cond,
                strlen(cond) == 0 ? "" : "\n",
                $3.place, $4, $5.place, L2,
                L3,
                L2, $7,
                L1,
                L3
            );

            $$ = buf;
        }

        free(L1);
        free(L2);
        free(L3);
        free(cond);
    }
  | WHILE '(' error ')' BLOCK { yyerrok; $$ = copy_string(""); }
;

BLOCK:
    '{' STMTS '}' { $$ = $2; }
  | '{' '}' { $$ = copy_string(""); }
  | '{' STMTS error { yyerrok; $$ = $2; }
;

%%

void yyerror(const char *message) {
    report_error("syntax", line_number, "%s", message);
}

int main(int argc, char **argv) {
    const char *input_path = NULL;
    const char *output_path = NULL;
    int parse_result;

    out = stdout;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "-q") == 0 || strcmp(argv[i], "--quiet") == 0) {
            suppress_output = 1;
        } else if (strcmp(argv[i], "-o") == 0 || strcmp(argv[i], "--output") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "error: %s requires a file path\n", argv[i]);
                print_usage(argv[0]);
                return 2;
            }
            output_path = argv[++i];
        } else if (argv[i][0] == '-') {
            fprintf(stderr, "error: unknown option '%s'\n", argv[i]);
            print_usage(argv[0]);
            return 2;
        } else if (input_path == NULL) {
            input_path = argv[i];
        } else {
            fprintf(stderr, "error: only one source file can be compiled at a time\n");
            print_usage(argv[0]);
            return 2;
        }
    }

    if (input_path != NULL) {
        yyin = fopen(input_path, "r");
        if (yyin == NULL) {
            fprintf(stderr, "error: could not open input file '%s'\n", input_path);
            return 2;
        }
        source_name = input_path;
        load_source_lines(input_path);
    }

    if (output_path != NULL) {
        out = fopen(output_path, "w");
        if (out == NULL) {
            fprintf(stderr, "error: could not open output file '%s'\n", output_path);
            if (yyin != NULL) {
                fclose(yyin);
            }
            return 2;
        }
    }

    parse_result = yyparse();

    if (diagnostic_count > 0) {
        fprintf(stderr,
            "\n");
        print_rule(stderr, '=');
        fprintf(stderr, "Diagnostic Summary\n");
        print_rule(stderr, '=');
        fprintf(stderr, "Status   : FAILED\n");
        fprintf(stderr, "Total    : %d\n", diagnostic_count);
        fprintf(stderr, "Lexical  : %d\n", lexical_error_count);
        fprintf(stderr, "Syntax   : %d\n", syntax_error_count);
        fprintf(stderr, "Semantic : %d\n", semantic_error_count);
        print_rule(stderr, '=');
        fprintf(stderr, "\n");
    } else {
        fprintf(stderr, "\n");
        print_rule(stderr, '=');
        fprintf(stderr, "Diagnostic Summary\n");
        print_rule(stderr, '=');
        fprintf(stderr, "Status   : SUCCESS\n");
        fprintf(stderr, "Total    : 0\n");
        fprintf(stderr, "Message  : Compilation completed with no diagnostics.\n");
        print_rule(stderr, '=');
        fprintf(stderr, "\n");
        if (output_path != NULL && !suppress_output) {
            fprintf(stderr, "Wrote report to %s\n", output_path);
        }
    }

    for (int i = 0; i < source_line_count; i++) {
        free(source_lines[i]);
    }
    free(source_lines);

    if (yyin != NULL) {
        fclose(yyin);
    }
    if (out != NULL && out != stdout) {
        fclose(out);
    }

    return (parse_result == 0 && diagnostic_count == 0) ? 0 : 1;
}
