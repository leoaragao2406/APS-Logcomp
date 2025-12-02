#!/bin/bash
# Script de teste para Linux/Mac/WSL

echo "========================================"
echo "Compilando o projeto LAVA"
echo "========================================"

# Compilar o compilador
echo ""
echo "[1/4] Gerando parser..."
bison -d parser.y || exit 1

echo "[2/4] Gerando scanner..."
flex scanner.l || exit 1

echo "[3/4] Compilando compilador..."
gcc -o lavacomp lex.yy.c parser.tab.c -lfl || exit 1

echo "[4/4] Compilando VM..."
gcc -o lavadora_vm/vm lavadora_vm/vm.c || exit 1

echo ""
echo "========================================"
echo "Executando testes"
echo "========================================"

echo ""
echo "Teste 1: Variáveis"
./lavacomp exemplos/teste1_variaveis.lava teste1.asm
./lavadora_vm/vm teste1.asm

echo ""
echo "Teste 2: Condicionais"
./lavacomp exemplos/teste2_condicional.lava teste2.asm
./lavadora_vm/vm teste2.asm

echo ""
echo "Teste 3: Loops"
./lavacomp exemplos/teste3_loop.lava teste3.asm
./lavadora_vm/vm teste3.asm

echo ""
echo "Teste 4: Programa Completo"
./lavacomp exemplos/teste4_completo.lava teste4.asm
./lavadora_vm/vm teste4.asm

echo ""
echo "========================================"
echo "Testes concluídos!"
echo "========================================"

