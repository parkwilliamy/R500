# R500
## Features
- R500 is a 32-bit processor based on the RISC-V architecture
- R500 has an average CPI of 1.23*, branch predictor accuracy of 96.5%**, and a throughput of 46.3 million instructions per second*
- Implemented on the Xilinx Artix-7 FPGA with 20KB of instruction memory and 12KB of data memory
- Utilizes a 5-stage pipeline with global branch prediction
- Designed a 2-way set associative branch target buffer to eliminate penalties for taken branch instructions

**Average CPI and throughput were calculated on the average results of loop1.c, loop2.c, loop3.c, loop4.c, loop5.c, fib.c, and mem2.c*

***Average branch predictor accuracy was calculated on the average result of loop1.c, loop2.c, loop3.c, loop4.c, loop5.c*

## Repository Structure
- main branch only contains the files for the synthesized R500
- pipelined branch contains both the files for the simulated R500 and testbenches
- single_cycle branch contains the files for the simulated single cycle R500 and testbenches (this was the original version before I pipelined the design)

## R500 Architecture
<p align="center">
  <img width="610" height="500" alt="R500_Architecture" src="https://github.com/user-attachments/assets/cc8a34cd-d99a-4182-861c-e690406e79ee" />
</p>

## System Architecture
<p align="center">
  <img width="10892" height="5760" alt="image" src="https://github.com/user-attachments/assets/add98f81-4c2a-4165-946f-8fa9f47eb2f7" />
</p>



## Memory Interface
- Memory is in the form of True Dual-Port BRAM
- To interact with BRAM, I designed a UART based interface that accepts read and write messages (interface assumes little-endian behaviour)
- To see how I used this interface, go to scripts/mem_access.py
  
NOTE: Write enable bits select which bytes in a word to write (i.e., we = 0010 will only write the second least significant byte)
### Read Message Format
- When reading from RAM, you must provide ADDR_LOW and ADDR_HIGH to define the region of memory you want to read from
  
1) Send a READ_START byte (0xFF)
2) Send 2 ADDR_HIGH bytes
3) Send 2 ADDR_LOW bytes

<p align="center">
  <img width="3724" height="204" alt="image" src="https://github.com/user-attachments/assets/80d1e4b7-9b17-48ea-8adb-dda0450695d4" />
</p>


### Write Message Format
- When writing to RAM, you must provide the address to write, the write enable bits, and the data word

1) Send a WRITE_START byte (0x0F)
2) Send 2 address bytes
3) Send 1 write enable byte
4) Send 4 data bytes

<p align="center">
  <img width="5284" height="204" alt="image" src="https://github.com/user-attachments/assets/4b2c9079-56f7-4da7-af6e-c609415f0a5a" />
</p>


   
## Verification
- Wrote testbenches in SystemVerilog that implemented constraint random verification along with directed tests
- Debugged waveforms with Vivado's xsim tool
- Wrote a shell script to simplify compilation, elaboration, and simulation into one command
- Utilized Verilator to quickly compile tests that required large amounts of memory (1MB+)
- For more system-wide tests, I wrote assembly and C programs to test basic instructions as well as hazards

## Performance Testing

NOTE: Performance tests located in metric_tests/tests
- These tests are only meant to give a reasonable estimate of the R500's performance

### Loop Tests
- loop1.c tests a basic for loop to provide a baseline for performance 
- loop2.c tests an alternating loop (i.e., branch not taken, branch taken) to test the predictor's ability to recognize a simple pattern
- loop3.c tests a condition based on divisibility by 2,3, or 5 for a large range of numbers; this test provides a more difficult pattern for the predictor
- loop4.c tests a "3 out of 4 taken" pattern; similar to loop3.c, this test provides a moderately difficult pattern to stress test the predictor
- loop5.c tests correlation between 2 branches, provides a different type of pattern from the previous ones to see how to predictor adapts to it
  
| Test     | loop1.c | loop2.c | loop3.c | loop4.c | loop5.c | 
|:----------:|:----------:|:----------:|:----------:|:----------:|:----------:|
| CPI  | 1.2  | 1.16  | 1.28  | 1.21  | 1.28  | 
| Accuracy  | 99.9%  | 99.9%  | 99.3%  | 99.9%  | 83.3%  |

### General Tests
- fib.c tests recursion and processors' ability to handle multiple stack frames
- mem2.c stress tests the processors' load and store instructions

| Test | fib.c | mem2.c |
|:----:|:----:|:----:|
| CPI  | 1.13  | 1.32  |
| Accuracy  | 92.2%  | 97.4%  |


## Compliance Test Procedure 

- This project uses the official RISC-V compliance tests with the RISCOF framework for the RV32I ISA
- For more details on the tests, visit https://github.com/riscv-non-isa/riscv-arch-test

<p align="center">
  <img width="730" height="631" alt="RV500_Compliance_Diagram drawio" src="https://github.com/user-attachments/assets/58eba543-c916-4858-a574-bf4facae63a0" />
</p>

