OUTPUT_ARCH("riscv")

/* Two regions inside one 32KB RAM space */
MEMORY
{
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 0x5000  /* [0x0000, 0x5000) */
  DMEM (rwx) : ORIGIN = 0x00005000, LENGTH = 0x3000  /* [0x5000, 0x8000) */
}

SECTIONS
{
  /* -------- IMEM -------- */
  . = ORIGIN(IMEM);

  .text :
  {
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > IMEM

  /* Hard rule: nothing in IMEM may cross 0x5000 */
  ASSERT(. <= ORIGIN(IMEM) + LENGTH(IMEM),
         "ERROR: .text/.rodata exceed 0x5000")

  /* -------- DMEM -------- */
  . = ORIGIN(DMEM);

  .data :
  {
    *(.data .data.*)
  } > DMEM

  .bss (NOLOAD) :
  {
    *(.bss .bss.*)
    *(COMMON)
  } > DMEM

  /* Hard rule: .data + .bss must fit under 0x8000 */
  ASSERT(. <= ORIGIN(DMEM) + LENGTH(DMEM),
         "ERROR: .data/.bss exceed 0x8000")

  /* Helpful symbols */
  PROVIDE(__imem_start = ORIGIN(IMEM));
  PROVIDE(__imem_end   = ORIGIN(IMEM) + LENGTH(IMEM));  /* 0x5000 */
  PROVIDE(__dmem_start = ORIGIN(DMEM));                  /* 0x5000 */
  PROVIDE(__dmem_end   = ORIGIN(DMEM) + LENGTH(DMEM));   /* 0x8000 */
  PROVIDE(_stack_top   = __dmem_end);                    /* optional */
}
