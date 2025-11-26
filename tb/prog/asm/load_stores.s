    .globl _start

    .section .text
_start:
    
    auipc  x5, 0x5         # x5 = base address of .data section (0x5000)
    li x1, 2                # x1 = 2
    sw x1, 0(x5)            # mem[0x5000] = x1
    lw x3, 0(x5)            # x3 = mem[0x5000]
    
    
    .section .data
my_data:
    .word 0                 # reserve 4 bytes for x4





