#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <program>"
    exit 1
fi

PROG="$1"

cd metric_tests

riscv32-unknown-elf-gcc   -march=rv32i -mabi=ilp32 -mstrict-align   -ffreestanding -fno-builtin   -nostdlib -nostartfiles   -T ../scripts/link.ld   asm/start.s tests/"$PROG".c   -O0   -o output_files/"$PROG".elf
riscv32-unknown-elf-objcopy -O binary output_files/"$PROG".elf output_files/"$PROG".bin
hexdump -v -e '1/4 "%08X\n"' output_files/"$PROG".bin > hex/"$PROG".hex