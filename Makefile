# Makefile para o compilador da linguagem LAVA (Lavadora)

# Compiladores
FLEX = flex
BISON = bison
CC = gcc
CFLAGS = -Wall -Wextra -std=c99

# Arquivos
SCANNER = scanner.l
PARSER = parser.y
COMPILER = lavacomp
VM = lavadora_vm/vm
VM_SRC = lavadora_vm/vm.c

# Arquivos gerados
LEX_OUT = lex.yy.c
PARSER_OUT = parser.tab.c parser.tab.h

.PHONY: all clean test

all: $(COMPILER) $(VM)

# Compilar o compilador
$(COMPILER): $(LEX_OUT) $(PARSER_OUT)
	$(CC) $(CFLAGS) -o $(COMPILER) $(LEX_OUT) $(PARSER_OUT) -lfl

# Gerar código do scanner (Flex)
$(LEX_OUT): $(SCANNER) $(PARSER_OUT)
	$(FLEX) $(SCANNER)

# Gerar código do parser (Bison)
$(PARSER_OUT): $(PARSER)
	$(BISON) -d $(PARSER)

# Compilar a VM
$(VM): $(VM_SRC)
	$(CC) $(CFLAGS) -o $(VM) $(VM_SRC)

# Testar com exemplos
test: $(COMPILER) $(VM)
	@echo "=== Teste 1: Variáveis ==="
	./$(COMPILER) exemplos/teste1_variaveis.lava teste1.asm
	./$(VM) teste1.asm
	@echo ""
	@echo "=== Teste 2: Condicionais ==="
	./$(COMPILER) exemplos/teste2_condicional.lava teste2.asm
	./$(VM) teste2.asm
	@echo ""
	@echo "=== Teste 3: Loops ==="
	./$(COMPILER) exemplos/teste3_loop.lava teste3.asm
	./$(VM) teste3.asm
	@echo ""
	@echo "=== Teste 4: Programa Completo ==="
	./$(COMPILER) exemplos/teste4_completo.lava teste4.asm
	./$(VM) teste4.asm

# Limpar arquivos gerados
clean:
	rm -f $(LEX_OUT) $(PARSER_OUT) $(COMPILER) $(VM)
	rm -f *.asm
	rm -f lavadora.asm

# Recompilar tudo
rebuild: clean all

