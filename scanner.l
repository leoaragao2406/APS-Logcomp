%option noyywrap yylineno nodefault

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
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

{ID}            { yylval.str = strdup(yytext); return IDENT; }
{DIGIT}+        { yylval.str = strdup(yytext); return NUMBER; }

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
