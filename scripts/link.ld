OUTPUT_ARCH( "riscv" )

SECTIONS
{
  . = 0x00000000;
  .text : { *(.text) }
  . = 0x00005000;
  .data : { *(.data) }
}

