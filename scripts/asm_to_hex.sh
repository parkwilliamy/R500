#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <program>"
    exit 1
fi

PROG="$1"

cd tb/prog

riscv32-unknown-elf-as -march=rv32i -mabi=ilp32 asm/"$PROG".s -o obj/"$PROG".o
#riscv32-unknown-elf-ld obj/"$PROG".o -o elf/"$PROG".elf
riscv32-unknown-elf-ld -T ../../scripts/link.ld obj/"$PROG".o -o elf/"$PROG".elf
riscv32-unknown-elf-objcopy -O binary elf/"$PROG".elf bin/"$PROG".bin
hexdump -v -e '1/4 "%08X\n"' bin/"$PROG".bin > hex/"$PROG".hex
