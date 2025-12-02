#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_MEMORY 1024
#define MAX_STACK 256
#define MAX_LABELS 128
#define MAX_SYMBOLS 256

// Registradores
typedef struct {
    int R0;
    int R1;
} Registers;

// Memória
typedef struct {
    char name[64];
    int value;
} MemoryCell;

// Pilha
typedef struct {
    int stack[MAX_STACK];
    int top;
} Stack;

// Labels
typedef struct {
    char name[64];
    int address;
} Label;

// Sensores (readonly)
typedef struct {
    char name[64];
    int value;
} Sensor;

// VM State
typedef struct {
    Registers regs;
    MemoryCell memory[MAX_MEMORY];
    int memory_count;
    Stack stack;
    Label labels[MAX_LABELS];
    int label_count;
    Sensor sensors[MAX_SYMBOLS];
    int sensor_count;
    int pc;  // Program counter
    bool halted;
    int tick_count;
} VM;

// Instruções do programa
typedef struct {
    char opcode[32];
    char arg1[64];
    char arg2[64];
    int line_num;
} Instruction;

Instruction program[1024];
int program_size = 0;

// Labels globais para primeira passada
Label global_labels[MAX_LABELS];
int global_label_count = 0;

// Funções auxiliares
void init_vm(VM *vm) {
    vm->regs.R0 = 0;
    vm->regs.R1 = 0;
    vm->memory_count = 0;
    vm->stack.top = -1;
    vm->label_count = 0;
    vm->sensor_count = 0;
    vm->pc = 0;
    vm->halted = false;
    vm->tick_count = 0;
    
    // Inicializar sensores padrão da lavadora
    strcpy(vm->sensors[vm->sensor_count].name, "water_level");
    vm->sensors[vm->sensor_count].value = 50;  // 0-100
    vm->sensor_count++;
    
    strcpy(vm->sensors[vm->sensor_count].name, "temperature");
    vm->sensors[vm->sensor_count].value = 20;  // graus Celsius
    vm->sensor_count++;
    
    strcpy(vm->sensors[vm->sensor_count].name, "door_closed");
    vm->sensors[vm->sensor_count].value = 1;  // 1 = fechada, 0 = aberta
    vm->sensor_count++;
    
    strcpy(vm->sensors[vm->sensor_count].name, "weight");
    vm->sensors[vm->sensor_count].value = 5;  // kg
    vm->sensor_count++;
}

MemoryCell* find_memory(VM *vm, const char *name) {
    for (int i = 0; i < vm->memory_count; i++) {
        if (strcmp(vm->memory[i].name, name) == 0) {
            return &vm->memory[i];
        }
    }
    return NULL;
}

MemoryCell* alloc_memory(VM *vm, const char *name) {
    MemoryCell *cell = find_memory(vm, name);
    if (cell == NULL) {
        if (vm->memory_count >= MAX_MEMORY) {
            fprintf(stderr, "Erro: memoria esgotada\n");
            return NULL;
        }
        strcpy(vm->memory[vm->memory_count].name, name);
        vm->memory[vm->memory_count].value = 0;
        cell = &vm->memory[vm->memory_count];
        vm->memory_count++;
    }
    return cell;
}

Sensor* find_sensor(VM *vm, const char *name) {
    for (int i = 0; i < vm->sensor_count; i++) {
        if (strcmp(vm->sensors[i].name, name) == 0) {
            return &vm->sensors[i];
        }
    }
    return NULL;
}

Label* find_label(VM *vm, const char *name) {
    // Usar labels globais da primeira passada
    for (int i = 0; i < global_label_count; i++) {
        if (strcmp(global_labels[i].name, name) == 0) {
            return &global_labels[i];
        }
    }
    return NULL;
}

void push(VM *vm, int value) {
    if (vm->stack.top >= MAX_STACK - 1) {
        fprintf(stderr, "Erro: estouro de pilha\n");
        vm->halted = true;
        return;
    }
    vm->stack.stack[++vm->stack.top] = value;
}

int pop(VM *vm) {
    if (vm->stack.top < 0) {
        fprintf(stderr, "Erro: pilha vazia\n");
        vm->halted = true;
        return 0;
    }
    return vm->stack.stack[vm->stack.top--];
}

int parse_int(const char *str) {
    return atoi(str);
}

// Execução de instruções
void execute_instruction(VM *vm, Instruction *inst) {
    if (strcmp(inst->opcode, "PUSHI") == 0) {
        int value = parse_int(inst->arg1);
        push(vm, value);
    }
    else if (strcmp(inst->opcode, "PUSHV") == 0) {
        MemoryCell *cell = find_memory(vm, inst->arg1);
        if (cell == NULL) {
            fprintf(stderr, "Erro: variavel '%s' nao encontrada\n", inst->arg1);
            vm->halted = true;
            return;
        }
        push(vm, cell->value);
    }
    else if (strcmp(inst->opcode, "POP") == 0) {
        if (strcmp(inst->arg1, "R0") == 0) {
            vm->regs.R0 = pop(vm);
        } else if (strcmp(inst->arg1, "R1") == 0) {
            vm->regs.R1 = pop(vm);
        }
    }
    else if (strcmp(inst->opcode, "PUSH") == 0) {
        if (strcmp(inst->arg1, "R0") == 0) {
            push(vm, vm->regs.R0);
        } else if (strcmp(inst->arg1, "R1") == 0) {
            push(vm, vm->regs.R1);
        }
    }
    else if (strcmp(inst->opcode, "LOAD") == 0) {
        MemoryCell *cell = find_memory(vm, inst->arg2);
        if (cell == NULL) {
            fprintf(stderr, "Erro: variavel '%s' nao encontrada\n", inst->arg2);
            vm->halted = true;
            return;
        }
        if (strcmp(inst->arg1, "R0") == 0) {
            vm->regs.R0 = cell->value;
        } else if (strcmp(inst->arg1, "R1") == 0) {
            vm->regs.R1 = cell->value;
        }
    }
    else if (strcmp(inst->opcode, "STORE") == 0) {
        int value;
        if (strcmp(inst->arg2, "R0") == 0) {
            value = vm->regs.R0;
        } else if (strcmp(inst->arg2, "R1") == 0) {
            value = vm->regs.R1;
        } else {
            value = parse_int(inst->arg2);
        }
        MemoryCell *cell = alloc_memory(vm, inst->arg1);
        if (cell) {
            cell->value = value;
        }
    }
    else if (strcmp(inst->opcode, "ADD") == 0) {
        if (strcmp(inst->arg1, "R0") == 0 && strcmp(inst->arg2, "R1") == 0) {
            vm->regs.R0 = vm->regs.R0 + vm->regs.R1;
        }
    }
    else if (strcmp(inst->opcode, "SUB") == 0) {
        if (strcmp(inst->arg1, "R0") == 0 && strcmp(inst->arg2, "R1") == 0) {
            vm->regs.R0 = vm->regs.R0 - vm->regs.R1;
        }
    }
    else if (strcmp(inst->opcode, "SUBI") == 0) {
        if (strcmp(inst->arg1, "R0") == 0) {
            int imm = parse_int(inst->arg2);
            vm->regs.R0 = vm->regs.R0 - imm;
        }
    }
    else if (strcmp(inst->opcode, "MUL") == 0) {
        if (strcmp(inst->arg1, "R0") == 0 && strcmp(inst->arg2, "R1") == 0) {
            vm->regs.R0 = vm->regs.R0 * vm->regs.R1;
        }
    }
    else if (strcmp(inst->opcode, "DIV") == 0) {
        if (strcmp(inst->arg1, "R0") == 0 && strcmp(inst->arg2, "R1") == 0) {
            if (vm->regs.R1 == 0) {
                fprintf(stderr, "Erro: divisao por zero\n");
                vm->halted = true;
                return;
            }
            vm->regs.R0 = vm->regs.R0 / vm->regs.R1;
        }
    }
    else if (strcmp(inst->opcode, "CMP") == 0) {
        int val1, val2;
        if (strcmp(inst->arg1, "R0") == 0) {
            val1 = vm->regs.R0;
        } else {
            val1 = parse_int(inst->arg1);
        }
        if (strcmp(inst->arg2, "R1") == 0) {
            val2 = vm->regs.R1;
        } else {
            val2 = parse_int(inst->arg2);
        }
        // Resultado da comparação fica em R0: 1 se val1 > val2, -1 se val1 < val2, 0 se igual
        if (val1 > val2) {
            vm->regs.R0 = 1;
        } else if (val1 < val2) {
            vm->regs.R0 = -1;
        } else {
            vm->regs.R0 = 0;
        }
    }
    else if (strcmp(inst->opcode, "SETGT") == 0) {
        vm->regs.R0 = (vm->regs.R0 > 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "SETLT") == 0) {
        vm->regs.R0 = (vm->regs.R0 < 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "SETEQ") == 0) {
        vm->regs.R0 = (vm->regs.R0 == 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "SETNE") == 0) {
        vm->regs.R0 = (vm->regs.R0 != 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "SETGE") == 0) {
        vm->regs.R0 = (vm->regs.R0 >= 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "SETLE") == 0) {
        vm->regs.R0 = (vm->regs.R0 <= 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "AND") == 0) {
        vm->regs.R0 = (vm->regs.R0 != 0 && vm->regs.R1 != 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "OR") == 0) {
        vm->regs.R0 = (vm->regs.R0 != 0 || vm->regs.R1 != 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "NOT") == 0) {
        vm->regs.R0 = (vm->regs.R0 == 0) ? 1 : 0;
    }
    else if (strcmp(inst->opcode, "JZ") == 0) {
        if (vm->regs.R0 == 0) {
            Label *label = find_label(vm, inst->arg1);
            if (label == NULL) {
                fprintf(stderr, "Erro: label '%s' nao encontrado\n", inst->arg1);
                vm->halted = true;
                return;
            }
            vm->pc = label->address;
            return;  // Não incrementar PC
        }
    }
    else if (strcmp(inst->opcode, "JLE") == 0) {
        if (vm->regs.R0 <= 0) {
            Label *label = find_label(vm, inst->arg1);
            if (label == NULL) {
                fprintf(stderr, "Erro: label '%s' nao encontrado\n", inst->arg1);
                vm->halted = true;
                return;
            }
            vm->pc = label->address;
            return;
        }
    }
    else if (strcmp(inst->opcode, "JMP") == 0) {
        Label *label = find_label(vm, inst->arg1);
        if (label == NULL) {
            fprintf(stderr, "Erro: label '%s' nao encontrado\n", inst->arg1);
            vm->halted = true;
            return;
        }
        vm->pc = label->address;
        return;
    }
    else if (strcmp(inst->opcode, "ALLOC") == 0) {
        alloc_memory(vm, inst->arg1);
    }
    else if (strcmp(inst->opcode, "READ") == 0) {
        Sensor *sensor = find_sensor(vm, inst->arg2);
        if (sensor == NULL) {
            fprintf(stderr, "Erro: sensor '%s' nao encontrado\n", inst->arg2);
            vm->halted = true;
            return;
        }
        if (strcmp(inst->arg1, "R0") == 0) {
            vm->regs.R0 = sensor->value;
        } else if (strcmp(inst->arg1, "R1") == 0) {
            vm->regs.R1 = sensor->value;
        }
    }
    else if (strcmp(inst->opcode, "EMIT") == 0) {
        int value = vm->regs.R0;
        printf("[EMIT] %s = %d\n", inst->arg1, value);
        // Simulação de atuadores da lavadora
        if (strcmp(inst->arg1, "motor") == 0) {
            printf("  -> Motor: %s\n", value ? "LIGADO" : "DESLIGADO");
        } else if (strcmp(inst->arg1, "valvula_agua") == 0) {
            printf("  -> Valvula de agua: %s\n", value ? "ABERTA" : "FECHADA");
        } else if (strcmp(inst->arg1, "bomba_agua") == 0) {
            printf("  -> Bomba de agua: %s\n", value ? "LIGADA" : "DESLIGADA");
        } else if (strcmp(inst->arg1, "resistor") == 0) {
            printf("  -> Resistor (aquecimento): %s\n", value ? "LIGADO" : "DESLIGADO");
        } else {
            printf("  -> Atuador '%s': %d\n", inst->arg1, value);
        }
    }
    else if (strcmp(inst->opcode, "WAIT") == 0) {
        int ticks = vm->regs.R0;
        vm->tick_count += ticks;
        printf("[WAIT] Aguardando %d ticks (total: %d)\n", ticks, vm->tick_count);
    }
    else if (strcmp(inst->opcode, "HALT") == 0) {
        vm->halted = true;
        printf("[HALT] Programa finalizado\n");
    }
    else if (inst->opcode[0] != '\0' && inst->opcode[strlen(inst->opcode)-1] == ':') {
        // Label - já processado na primeira passada
    }
    else if (inst->opcode[0] == '#') {
        // Comentário - ignorar
    }
    else {
        fprintf(stderr, "Erro: instrucao desconhecida '%s'\n", inst->opcode);
        vm->halted = true;
    }
}

// Parser do assembly
void parse_assembly(const char *filename) {
    FILE *f = fopen(filename, "r");
    if (!f) {
        fprintf(stderr, "Erro ao abrir arquivo: %s\n", filename);
        exit(1);
    }
    
    char line[256];
    int inst_count = 0;
    
    // Primeira passada: encontrar labels
    while (fgets(line, sizeof(line), f)) {
        // Remover newline
        line[strcspn(line, "\n")] = 0;
        
        // Ignorar linhas vazias e comentários
        if (line[0] == '\0' || line[0] == '#') {
            continue;
        }
        
        // Verificar se é label
        char *colon = strchr(line, ':');
        if (colon) {
            *colon = '\0';
            char label_name[64];
            // Remover espaços
            char *start = line;
            while (*start == ' ' || *start == '\t') start++;
            sscanf(start, "%s", label_name);
            if (global_label_count < MAX_LABELS) {
                strcpy(global_labels[global_label_count].name, label_name);
                global_labels[global_label_count].address = inst_count;
                global_label_count++;
            }
            continue;
        }
        
        inst_count++;
    }
    
    // Segunda passada: parsear instruções
    rewind(f);
    program_size = 0;
    
    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        
        if (line[0] == '\0' || line[0] == '#') {
            continue;
        }
        
        // Verificar se é label
        char *colon = strchr(line, ':');
        if (colon) {
            continue;  // Já processado na primeira passada
        }
        
        Instruction *inst = &program[program_size];
        inst->line_num = program_size + 1;
        
        // Limpar espaços iniciais
        char *start = line;
        while (*start == ' ' || *start == '\t') start++;
        
        // Parsear instrução
        inst->arg1[0] = '\0';
        inst->arg2[0] = '\0';
        int n = sscanf(start, "%s %s %s", inst->opcode, inst->arg1, inst->arg2);
        if (n == 0) continue;
        
        program_size++;
    }
    
    fclose(f);
}

void run_vm(VM *vm) {
    // Copiar labels globais para a VM
    vm->label_count = global_label_count;
    for (int i = 0; i < global_label_count; i++) {
        vm->labels[i] = global_labels[i];
    }
    
    printf("=== Executando LavadoraVM ===\n\n");
    
    while (vm->pc < program_size && !vm->halted) {
        Instruction *inst = &program[vm->pc];
        //printf("[PC=%d] %s %s %s\n", vm->pc, inst->opcode, inst->arg1, inst->arg2);
        execute_instruction(vm, inst);
        if (!vm->halted) {
            vm->pc++;
        }
    }
    
    printf("\n=== Estado Final ===\n");
    printf("R0 = %d\n", vm->regs.R0);
    printf("R1 = %d\n", vm->regs.R1);
    printf("Ticks totais: %d\n", vm->tick_count);
    printf("Memoria alocada: %d variaveis\n", vm->memory_count);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo.asm>\n", argv[0]);
        return 1;
    }
    
    parse_assembly(argv[1]);
    
    VM vm;
    init_vm(&vm);
    run_vm(&vm);
    
    return 0;
}

