    .globl _start

    .section .text
_start:
    
    la x5, my_data             # x5 = base address of .data section (0x5000)
    li    x1, 0xfee1dead       # x1 = 0xfee1dead
    li    x6, 0xdeadbeef       # x6 = 0xdeadbeef
    li    x7, 0xbaadf00d       # x7 = 0xbaadf00d
    li    x8, 0xbabecafe       # x8 = 0xbabecafe
    sw    x1, 0(x5)            # mem[0x5000] = x1
    lw    x3, 0(x5)            # x3 = mem[0x5000]
    sw    x6, 4(x5)            # mem[0x5004] = x6
    sh    x7, 8(x5)            # mem[0x5008] = x7[15:0]
    sh    x8, 10(x5)           # mem[0x5010] = x8[15:0]
    
    
    .section .data
my_data:
    .word 0                 # reserve 4 bytes for x4
    .word 0                 # reserve 4 bytes for x6
    .hword 0                 # reserve 2 bytes for x7
    .hword 0                 # reserve 2 bytes for x8





