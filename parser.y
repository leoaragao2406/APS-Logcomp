%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
extern int yylineno;

static FILE *out;

typedef struct Symbol {
    char *name;
    struct Symbol *next;
} Symbol;

static Symbol *symbols = NULL;

static Symbol *find_symbol(const char *name) {
    for (Symbol *sym = symbols; sym != NULL; sym = sym->next) {
        if (strcmp(sym->name, name) == 0) {
            return sym;
        }
    }
    return NULL;
}

static void declare_symbol(const char *name) {
    if (find_symbol(name) != NULL) {
        fprintf(stderr, "Erro: variavel '%s' ja declarada (linha %d).\n", name, yylineno);
        exit(EXIT_FAILURE);
    }
    Symbol *sym = (Symbol *)malloc(sizeof(Symbol));
    if (!sym) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }
    sym->name = strdup(name);
    sym->next = symbols;
    symbols = sym;
    fprintf(out, "ALLOC %s\n", name);
}

static void ensure_symbol(const char *name) {
    if (find_symbol(name) == NULL) {
        fprintf(stderr, "Erro: variavel '%s' nao declarada (linha %d).\n", name, yylineno);
        exit(EXIT_FAILURE);
    }
}

static int next_label = 0;

static int generate_label(void) {
    return next_label++;
}

#define MAX_NESTING 128
static int if_stack[MAX_NESTING];
static int if_top = -1;
static int loop_stack[MAX_NESTING];
static int loop_top = -1;

static void push_if(int label) {
    if (if_top + 1 >= MAX_NESTING) {
        fprintf(stderr, "Erro: profundidade maxima de IF excedida.\n");
        exit(EXIT_FAILURE);
    }
    if_stack[++if_top] = label;
}

static int pop_if(void) {
    if (if_top < 0) {
        fprintf(stderr, "Erro interno: pilha de IF vazia.\n");
        exit(EXIT_FAILURE);
    }
    return if_stack[if_top--];
}

static void push_loop(int label) {
    if (loop_top + 1 >= MAX_NESTING) {
        fprintf(stderr, "Erro: profundidade maxima de LOOP excedida.\n");
        exit(EXIT_FAILURE);
    }
    loop_stack[++loop_top] = label;
}

static int pop_loop(void) {
    if (loop_top < 0) {
        fprintf(stderr, "Erro interno: pilha de LOOP vazia.\n");
        exit(EXIT_FAILURE);
    }
    return loop_stack[loop_top--];
}

static void emit_loop_prologue(int label) {
    fprintf(out, "ALLOC __loop_counter_%d\n", label);
    fprintf(out, "    POP R0\n");
    fprintf(out, "    STORE __loop_counter_%d, R0\n", label);
    fprintf(out, "LOOP_START_%d:\n", label);
    fprintf(out, "    LOAD R0, __loop_counter_%d\n", label);
    fprintf(out, "    CMP R0, 0\n");
    fprintf(out, "    JLE LOOP_END_%d\n", label);
}

static void emit_loop_epilogue(int label) {
    fprintf(out, "    LOAD R0, __loop_counter_%d\n", label);
    fprintf(out, "    SUBI R0, 1\n");
    fprintf(out, "    STORE __loop_counter_%d, R0\n", label);
    fprintf(out, "    JMP LOOP_START_%d\n", label);
    fprintf(out, "LOOP_END_%d:\n", label);
}
%}

%union {
    char *str;
    int ival;
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
%right NOT
%left EQ NE
%left '>' '<' GE LE
%left '+' '-'
%left '*' '/'

%type <ival> comparison

%%
program
    : statement_list
    ;

statement_list
    : statement_list statement
    | /* vazio */
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
    : LET IDENT '=' {
          declare_symbol($2);
      } expr ';'
      {
          fprintf(out, "    POP R0\n");
          fprintf(out, "    STORE %s, R0\n", $2);
          free($2);
      }
    ;

assign
    : IDENT '=' expr ';'
      {
          ensure_symbol($1);
          fprintf(out, "    POP R0\n");
          fprintf(out, "    STORE %s, R0\n", $1);
          free($1);
      }
    ;

conditional
    : IF '(' condition ')' {
          int label = generate_label();
          fprintf(out, "    POP R0\n");
          fprintf(out, "    JZ R0, IF_END_%d\n", label);
          push_if(label);
      } '{' statement_list '}'
      {
          int label = pop_if();
          fprintf(out, "IF_END_%d:\n", label);
      }
    ;

loop
    : LOOP expr TIMES {
          int label = generate_label();
          emit_loop_prologue(label);
          push_loop(label);
      } '{' statement_list '}'
      {
          int label = pop_loop();
          emit_loop_epilogue(label);
      }
    ;

emit_stmt
    : EMIT IDENT param ';'
      {
          fprintf(out, "    POP R0\n");
          fprintf(out, "    EMIT %s, R0\n", $2);
          free($2);
      }
    ;

wait_stmt
    : WAIT expr TICKS ';'
      {
          fprintf(out, "    POP R0\n");
          fprintf(out, "    WAIT R0\n");
      }
    ;

halt_stmt
    : HALT ';'
      {
          fprintf(out, "    HALT\n");
      }
    ;

param
    : expr
    | ON
      {
          fprintf(out, "    PUSHI 1\n");
      }
    | OFF
      {
          fprintf(out, "    PUSHI 0\n");
      }
    ;

condition
    : expr comparison expr
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    CMP R0, R1\n");
          switch ($2) {
              case '>':
                  fprintf(out, "    SETGT R0\n");
                  break;
              case '<':
                  fprintf(out, "    SETLT R0\n");
                  break;
              case EQ:
                  fprintf(out, "    SETEQ R0\n");
                  break;
              case NE:
                  fprintf(out, "    SETNE R0\n");
                  break;
              case GE:
                  fprintf(out, "    SETGE R0\n");
                  break;
              case LE:
                  fprintf(out, "    SETLE R0\n");
                  break;
          }
          fprintf(out, "    PUSH R0\n");
      }
    | NOT '(' condition ')'
      {
          fprintf(out, "    POP R0\n");
          fprintf(out, "    NOT R0\n");
          fprintf(out, "    PUSH R0\n");
      }
    | condition AND condition
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    AND R0, R1\n");
          fprintf(out, "    PUSH R0\n");
      }
    | condition OR condition
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    OR R0, R1\n");
          fprintf(out, "    PUSH R0\n");
      }
    ;

comparison
    : '>' { $$ = '>'; }
    | '<' { $$ = '<'; }
    | EQ  { $$ = EQ; }
    | GE  { $$ = GE; }
    | LE  { $$ = LE; }
    | NE  { $$ = NE; }
    ;

expr
    : expr '+' expr
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    ADD R0, R1\n");
          fprintf(out, "    PUSH R0\n");
      }
    | expr '-' expr
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    SUB R0, R1\n");
          fprintf(out, "    PUSH R0\n");
      }
    | expr '*' expr
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    MUL R0, R1\n");
          fprintf(out, "    PUSH R0\n");
      }
    | expr '/' expr
      {
          fprintf(out, "    POP R1\n");
          fprintf(out, "    POP R0\n");
          fprintf(out, "    DIV R0, R1\n");
          fprintf(out, "    PUSH R0\n");
      }
    | '(' expr ')'
      {
          /* nada a emitir */
      }
    | NUMBER
      {
          fprintf(out, "    PUSHI %s\n", $1);
          free($1);
      }
    | IDENT
      {
          ensure_symbol($1);
          fprintf(out, "    PUSHV %s\n", $1);
          free($1);
      }
    | READ '(' IDENT ')'
      {
          fprintf(out, "    READ R0, %s\n", $3);
          fprintf(out, "    PUSH R0\n");
          free($3);
      }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintatico na linha %d: %s\n", yylineno, s);
}

extern FILE *yyin;

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo.lava> [saida.asm]\n", argv[0]);
        return EXIT_FAILURE;
    }
    
    const char *input_path = argv[1];
    const char *output_path = (argc > 2) ? argv[2] : "lavadora.asm";
    
    // Abrir arquivo de entrada
    yyin = fopen(input_path, "r");
    if (!yyin) {
        perror("Erro ao abrir arquivo de entrada");
        return EXIT_FAILURE;
    }
    
    // Abrir arquivo de saída
    out = fopen(output_path, "w");
    if (!out) {
        perror("Erro ao abrir arquivo de saida");
        fclose(yyin);
        return EXIT_FAILURE;
    }

    fprintf(out, "# LavadoraVM Assembly gerado pelo compilador Flex/Bison\n");

    int parse_status = yyparse();

    fclose(yyin);
    fclose(out);
    return parse_status == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}