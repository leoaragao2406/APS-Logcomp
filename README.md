# LAVA - Linguagem de Programação para Lavadora

## Visão Geral

LAVA é uma linguagem de programação de alto nível desenvolvida especificamente para controlar uma máquina virtual (VM) de lavadora. A linguagem permite programar ciclos de lavagem de forma intuitiva, utilizando estruturas de controle familiares como condicionais e loops.

## Estrutura do Projeto

```
APS-Logcomp/
├── scanner.l              # Analisador léxico (Flex)
├── parser.y               # Analisador sintático (Bison)
├── Linguagem.txt          # Gramática EBNF
├── Makefile               # Build automation
├── lavadora_vm/
│   └── vm.c              # Máquina Virtual da Lavadora
├── exemplos/
│   └── teste1_variaveis.lava
└── README.md
```

## Compilação

### Pré-requisitos
- Flex (analisador léxico)
- Bison (analisador sintático)
- GCC (compilador C)
- Make

### Build
```bash
make
```

Isso irá:
1. Gerar o compilador `lavacomp` a partir de `scanner.l` e `parser.y`
2. Compilar a VM `lavadora_vm/vm`

### Testes
```bash
make test
```

## Uso

### Compilar um programa LAVA
```bash
./lavacomp programa.lava saida.asm
```

### Executar o assembly na VM
```bash
./lavadora_vm/vm saida.asm
```

## Características da Linguagem

### Variáveis
```lava
LET x = 10;
LET y = x + 5;
```

### Condicionais
```lava
IF (READ(water_level) > 80) {
    EMIT valvula_agua OFF;
}
```

### Loops
```lava
LOOP 5 TIMES {
    EMIT motor ON;
    WAIT 10 TICKS;
}
```

### Sensores (readonly)
- `water_level`: Nível de água (0-100)
- `temperature`: Temperatura em graus Celsius
- `door_closed`: Porta fechada (1) ou aberta (0)
- `weight`: Peso da carga em kg

### Atuadores
- `motor`: Motor da lavadora
- `valvula_agua`: Válvula de entrada de água
- `bomba_agua`: Bomba de drenagem
- `resistor`: Resistor de aquecimento

## VM - Máquina Virtual

A LavadoraVM possui:
- **2 Registradores**: R0 e R1
- **Memória**: Sistema de variáveis dinâmico
- **Pilha**: Para avaliação de expressões
- **Sensores**: Variáveis readonly para leitura de estado
- **Instruções Turing-completas**: JMP, JZ, operações aritméticas

## Exemplos

Veja a pasta `exemplos/` para programas de exemplo completos.
