# LavadoraVM Assembly gerado pelo compilador Flex/Bison
ALLOC x
    PUSHI 10
    POP R0
    STORE x, R0
ALLOC y
    PUSHI 5
    POP R0
    STORE y, R0
ALLOC resultado
    PUSHV x
    PUSHV y
    PUSHI 2
    POP R1
    POP R0
    MUL R0, R1
    PUSH R0
    POP R1
    POP R0
    ADD R0, R1
    PUSH R0
    POP R0
    STORE resultado, R0
ALLOC divisao
    PUSHV resultado
    PUSHI 3
    POP R1
    POP R0
    DIV R0, R1
    PUSH R0
    POP R0
    STORE divisao, R0
