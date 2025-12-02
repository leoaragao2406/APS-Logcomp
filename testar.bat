@echo off
REM Script de teste para Windows

echo ========================================
echo Compilando o projeto LAVA
echo ========================================

REM Compilar o compilador
echo.
echo [1/4] Gerando parser...
bison -d parser.y
if errorlevel 1 (
    echo ERRO: Falha ao gerar parser
    exit /b 1
)

echo [2/4] Gerando scanner...
flex scanner.l
if errorlevel 1 (
    echo ERRO: Falha ao gerar scanner
    exit /b 1
)

echo [3/4] Compilando compilador...
gcc -o lavacomp.exe lex.yy.c parser.tab.c
if errorlevel 1 (
    echo ERRO: Falha ao compilar
    exit /b 1
)

echo [4/4] Compilando VM...
gcc -o lavadora_vm\vm.exe lavadora_vm\vm.c
if errorlevel 1 (
    echo ERRO: Falha ao compilar VM
    exit /b 1
)

echo.
echo ========================================
echo Executando testes
echo ========================================

echo.
echo Teste 1: Variáveis
lavacomp.exe exemplos\teste1_variaveis.lava teste1.asm
lavadora_vm\vm.exe teste1.asm

echo.
echo Teste 2: Condicionais
lavacomp.exe exemplos\teste2_condicional.lava teste2.asm
lavadora_vm\vm.exe teste2.asm

echo.
echo Teste 3: Loops
lavacomp.exe exemplos\teste3_loop.lava teste3.asm
lavadora_vm\vm.exe teste3.asm

echo.
echo Teste 4: Programa Completo
lavacomp.exe exemplos\teste4_completo.lava teste4.asm
lavadora_vm\vm.exe teste4.asm

echo.
echo ========================================
echo Testes concluidos!
echo ========================================

