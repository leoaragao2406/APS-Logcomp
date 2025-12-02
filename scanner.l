%option noyywrap yylineno nodefault
%option noinput

%{
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

// Helper function for string duplication
static char* safe_strdup(const char *s) {
    if (s == NULL) return NULL;
    char *result = (char *)malloc(strlen(s) + 1);
    if (result) strcpy(result, s);
    return result;
}
%}

DIGIT   [0-9]
LETTER  [a-zA-Z_]
ID      {LETTER}({LETTER}|{DIGIT})*
WS      [ \t\r\n]+

%%
"LET"           { return LET; }
"IF"            { return IF; }
"LOOP"          { return LOOP; }
"TIMES"         { return TIMES; }
"EMIT"          { return EMIT; }
"WAIT"          { return WAIT; }
"TICKS"         { return TICKS; }
"HALT"          { return HALT; }
"READ"          { return READ; }
"ON"            { return ON; }
"OFF"           { return OFF; }
"NOT"           { return NOT; }
"AND"           { return AND; }
"OR"            { return OR; }

">="            { return GE; }
"<="            { return LE; }
"=="            { return EQ; }
"!="            { return NE; }

{WS}            { /* ignora espacos */ }
"//"[^\n]*     { /* comentario de linha */ }

{ID}            { yylval.str = safe_strdup(yytext); return IDENT; }
{DIGIT}+        { yylval.str = safe_strdup(yytext); return NUMBER; }

"{"            { return '{'; }
"}"            { return '}'; }
"("            { return '('; }
")"            { return ')'; }
";"            { return ';'; }
","            { return ','; }
"="            { return '='; }
"+"            { return '+'; }
"-"            { return '-'; }
"*"            { return '*'; }
"/"            { return '/'; }
">"            { return '>'; }
"<"            { return '<'; }

.               { fprintf(stderr, "Caractere inesperado: %s\n", yytext); }

%%
