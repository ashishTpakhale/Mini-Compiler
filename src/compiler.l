%{
struct expr_attr {
    char *code;
    char *place;
    char *type;
    int line;
};

#include "compiler.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_number = 1;
void report_error(const char *kind, int line, const char *fmt, ...);
#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = line_number;

static char *copy_string(const char *value) {
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
%}

%option never-interactive noinput nounput noyywrap

%%
"int"        { return INT; }
"float"      { return FLOAT; }
"if"         { return IF; }
"while"      { return WHILE; }

"//".*       ;
"/*"([^*]|\*+[^*/])*\*+"/" {
    for (int i = 0; yytext[i] != '\0'; i++) {
        if (yytext[i] == '\n') {
            line_number++;
        }
    }
}

[0-9]+\.[0-9]+ { yylval.str = copy_string(yytext); return FLOAT_NUM; }
[0-9]+          { yylval.str = copy_string(yytext); return INT_NUM; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = copy_string(yytext);
    return ID;
}

"=="|"<="|">="|"!="|"<"|">" {
    yylval.str = copy_string(yytext);
    return RELOP;
}

"+" { return '+'; }
"-" { return '-'; }
"*" { return '*'; }
"/" { return '/'; }

"="    { return '='; }
";"    { return ';'; }
","    { return ','; }
"("    { return '('; }
")"    { return ')'; }
"{"    { return '{'; }
"}"    { return '}'; }

[ \t\r] ;
\n       { line_number++; }
.        {
             report_error("lexical", line_number, "unexpected character '%s'", yytext);
         }

%%
