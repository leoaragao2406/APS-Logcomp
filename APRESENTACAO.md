# LAVA - Linguagem de Programação para Lavadora
## Apresentação do Projeto

---

## 1. Motivação

### Por que criar uma linguagem para lavadora?

- **Domínio Específico**: Lavadoras são dispositivos complexos que requerem controle preciso de múltiplos componentes (motor, válvulas, bomba, resistor)
- **Abstração de Baixo Nível**: A VM simula instruções de assembly, mas a linguagem LAVA oferece uma interface de alto nível mais intuitiva
- **Aprendizado**: Desenvolver um compilador completo (lexer, parser, codegen, VM) é uma excelente forma de entender como linguagens funcionam

### Contexto do Projeto

Este projeto foi desenvolvido como parte da disciplina de Supercompiladores, utilizando as ferramentas padrão da indústria:
- **Flex**: Análise léxica
- **Bison**: Análise sintática
- **C**: Linguagem de implementação

---

## 2. Características da Linguagem

### 2.1 Estruturas Básicas

#### Variáveis
```lava
LET nivel_agua = 50;
LET temperatura = 30;
LET ciclos = 3;
```

#### Atribuição
```lava
nivel_agua = nivel_agua + 10;
```

#### Expressões Aritméticas
```lava
LET resultado = (x + y) * 2 - z / 3;
```

### 2.2 Estruturas de Controle

#### Condicionais
```lava
IF (READ(water_level) > 80) {
    EMIT valvula_agua OFF;
}

IF (READ(door_closed) == 0) {
    HALT;
}
```

#### Loops
```lava
LOOP 5 TIMES {
    EMIT motor ON;
    WAIT 10 TICKS;
    EMIT motor OFF;
}
```

#### Condições Complexas
```lava
IF (READ(water_level) > 50 AND READ(temperature) < 40) {
    EMIT resistor ON;
}

IF (NOT (READ(door_closed) == 1)) {
    HALT;
}
```

### 2.3 Interação com Hardware

#### Leitura de Sensores
```lava
LET nivel = READ(water_level);
LET temp = READ(temperature);
LET porta_fechada = READ(door_closed);
```

#### Controle de Atuadores
```lava
EMIT motor ON;        // Liga o motor
EMIT motor OFF;       // Desliga o motor
EMIT valvula_agua ON; // Abre válvula
EMIT resistor 1;      // Liga resistor com valor 1
```

#### Controle de Tempo
```lava
WAIT 10 TICKS;  // Aguarda 10 unidades de tempo
```

#### Finalização
```lava
HALT;  // Encerra o programa
```

---

## 3. Arquitetura do Sistema

### 3.1 Pipeline de Compilação

```
programa.lava  →  [Flex]  →  Tokens  →  [Bison]  →  AST  →  CodeGen  →  lavadora.asm
                                                                              ↓
                                                                        [VM]  →  Execução
```

### 3.2 Componentes

1. **Scanner (Flex)**: Analisa o código fonte e gera tokens
2. **Parser (Bison)**: Valida a sintaxe e gera código assembly
3. **Code Generator**: Emite instruções da LavadoraVM
4. **VM**: Interpreta o assembly e executa o programa

### 3.3 Máquina Virtual (LavadoraVM)

#### Registradores
- **R0**: Registrador principal
- **R1**: Registrador auxiliar

#### Memória
- Sistema de variáveis dinâmico
- Alocação automática via `ALLOC`

#### Pilha
- Usada para avaliação de expressões
- Operações: `PUSH`, `POP`

#### Sensores (Readonly)
- `water_level`: Nível de água (0-100)
- `temperature`: Temperatura (°C)
- `door_closed`: Estado da porta (0/1)
- `weight`: Peso da carga (kg)

#### Instruções Principais
- **Aritméticas**: ADD, SUB, MUL, DIV
- **Comparação**: CMP, SETGT, SETLT, SETEQ, SETNE, SETGE, SETLE
- **Lógica**: AND, OR, NOT
- **Controle**: JMP, JZ, JLE
- **I/O**: READ, EMIT, WAIT, HALT
- **Memória**: LOAD, STORE, PUSHI, PUSHV, POP, PUSH

---

## 4. Gramática (EBNF)

```ebnf
PROGRAM        = { STATEMENT } ;

STATEMENT      = VAR_DECL
               | ASSIGN
               | CONDITIONAL
               | LOOP
               | EMIT_STMT
               | WAIT_STMT
               | HALT_STMT ;

VAR_DECL       = "LET", IDENT, "=", EXPR, ";" ;
ASSIGN         = IDENT, "=", EXPR, ";" ;

CONDITIONAL    = "IF", "(", CONDITION, ")", "{", { STATEMENT }, "}" ;

LOOP           = "LOOP", EXPR, "TIMES", "{", { STATEMENT }, "}" ;

EMIT_STMT      = "EMIT", TARGET, PARAM, ";" ;
WAIT_STMT      = "WAIT", EXPR, "TICKS", ";" ;
HALT_STMT      = "HALT", ";" ;

CONDITION      = EXPR, COMP_OP, EXPR
               | "NOT", "(", CONDITION, ")"
               | CONDITION, LOGIC_OP, CONDITION ;

EXPR           = TERM, { ("+" | "-"), TERM } ;
TERM           = FACTOR, { ("*" | "/"), FACTOR } ;
FACTOR         = NUMBER
               | IDENT
               | "READ", "(", IDENT, ")"
               | "(", EXPR, ")" ;
```

---

## 5. Exemplos de Uso

### Exemplo 1: Controle de Nível de Água

```lava
LET nivel_desejado = 70;
LET nivel_atual = READ(water_level);

IF (nivel_atual < nivel_desejado) {
    EMIT valvula_agua ON;
    
    LOOP 10 TIMES {
        nivel_atual = READ(water_level);
        IF (nivel_atual >= nivel_desejado) {
            EMIT valvula_agua OFF;
        }
        WAIT 1 TICKS;
    }
}
```

### Exemplo 2: Ciclo de Lavagem Completo

```lava
// Verifica porta
IF (READ(door_closed) == 0) {
    HALT;
}

// Enche com água
EMIT valvula_agua ON;
WAIT 20 TICKS;
EMIT valvula_agua OFF;

// Aquece
EMIT resistor ON;
WAIT 30 TICKS;
EMIT resistor OFF;

// Lava
LOOP 3 TIMES {
    EMIT motor ON;
    WAIT 30 TICKS;
    EMIT motor OFF;
    WAIT 5 TICKS;
}

// Enxágue
EMIT bomba_agua ON;
WAIT 15 TICKS;
EMIT bomba_agua OFF;

HALT;
```

---

## 6. Curiosidades e Diferenciais

### 6.1 Turing-Completude

A LavadoraVM é Turing-completa através de:
- **JMP**: Saltos incondicionais
- **JZ**: Saltos condicionais
- **Operações aritméticas**: Permitem manipulação de dados
- **Memória**: Permite armazenamento de estado

### 6.2 Design Decisions

1. **Sintaxe Simples**: Palavras-chave em inglês, mas conceitos familiares
2. **Tipagem Implícita**: Apenas inteiros, simplificando a implementação
3. **Sensores Readonly**: Garantem que o programa não modifique o estado dos sensores
4. **Sistema de Ticks**: Abstração de tempo para controle de duração

### 6.3 Extensibilidade

A arquitetura permite fácil adição de:
- Novos sensores
- Novos atuadores
- Novas instruções na VM
- Novas estruturas de controle na linguagem

---

## 7. Resultados e Testes

### Testes Implementados

1. **teste1_variaveis.lava**: Demonstra declaração e uso de variáveis
2. **teste2_condicional.lava**: Demonstra estruturas condicionais
3. **teste3_loop.lava**: Demonstra loops e iterações
4. **teste4_completo.lava**: Programa completo de ciclo de lavagem

### Execução

```bash
make test
```

Todos os testes compilam e executam corretamente na VM.

---

## 8. Conclusão

### Objetivos Alcançados

✅ EBNF estruturada e documentada  
✅ Flex/Bison implementados e funcionais  
✅ VM completa com registradores, memória, sensores e instruções Turing-completas  
✅ Exemplos de teste demonstrando todas as características  
✅ Documentação completa  

### Aprendizados

- Processo completo de compilação (lexer → parser → codegen)
- Implementação de máquinas virtuais
- Design de linguagens de domínio específico
- Uso de ferramentas profissionais (Flex/Bison)

---

## Referências

- [Flex Manual](https://www.gnu.org/software/flex/)
- [Bison Manual](https://www.gnu.org/software/bison/)
- [Minsky Machines](https://en.wikipedia.org/wiki/Counter_machine)
- [MicrowaveVM Example](https://github.com/example/microwavevm)

---

**Desenvolvido para APS de Supercompiladores - INSPER 2025.2**

