    .globl _start

    .section .text
_start:
    addi x1, x0, 1          # x1 = 1
    addi x2, x0, 2          # x2 = 2
    jal  x10, 20            # x10 = pc+20
    addi x3, x0, 3          # x3 = 3
    addi x4, x0, 4          # x4 = 4
    addi x5, x0, 5          # x5 = 5
    addi x6, x0, 6          # x6 = 6
    sub  x7, x5, x2         # x7 = x5 - x2
    slli x3, x3, 5          # x3 = x3 << 5
    xor  x1, x1, x6         # x1 = x1 ^ x6