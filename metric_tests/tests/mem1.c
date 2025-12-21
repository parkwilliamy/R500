int main() {

    volatile int* CLK_CYCLE_ADDR = (volatile int*)0x00007000;
    volatile int* INVALID_CLK_CYCLE_ADDR = (volatile int*)0x00007004;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (volatile int*)0x00007008;
    volatile int* CORRECT_PREDICTIONS_ADDR = (volatile int*)0x0000700C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (volatile int*)0x00007010;
    volatile int* RESULT_ADDR = (volatile int*)0x00006000;

    RESULT_ADDR[0] = 1;
    RESULT_ADDR[1] = 2;
    RESULT_ADDR[2] = 3;
    RESULT_ADDR[3] = 4;
    
    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    

    while(1);

}