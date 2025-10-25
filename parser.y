%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex(void);
%}

%union {
    char *str;
}

%token LET IF LOOP TIMES EMIT WAIT TICKS HALT READ ON OFF NOT AND OR
%token EQ "=="
%token NE "!="
%token GE ">="
%token LE "<="
%token <str> IDENT
%token <str> NUMBER

%left OR
%left AND
%left EQ NE
%left '>' '<' GE LE
%left '+' '-'
%left '*' '/'
%right NOT

%%
program
    : statement_list
    ;

statement_list
    : statement_list statement
    | /* empty */
    ;

statement
    : var_decl
    | assign
    | conditional
    | loop
    | emit_stmt
    | wait_stmt
    | halt_stmt
    ;

var_decl
    : LET IDENT '=' expr ';'
    ;

assign
    : IDENT '=' expr ';'
    ;

conditional
    : IF '(' condition ')' '{' statement_list '}'
    ;

loop
    : LOOP expr TIMES '{' statement_list '}'
    ;

emit_stmt
    : EMIT IDENT param ';'
    ;

wait_stmt
    : WAIT expr TICKS ';'
    ;

halt_stmt
    : HALT ';'
    ;

param
    : expr
    | ON
    | OFF
    ;

condition
    : expr comparison expr
    | NOT '(' condition ')'
    | condition AND condition
    | condition OR condition
    ;

comparison
    : '>'
    | '<'
    | EQ
    | GE
    | LE
    | NE
    ;

expr
    : expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | '(' expr ')'
    | NUMBER
    | IDENT
    | READ '(' IDENT ')'
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintatico: %s\n", s);
}

int main(int argc, char **argv) {
    if (yyparse() == 0) {
        printf("Parsing concluido com sucesso.\n");
    }
    return 0;
}
