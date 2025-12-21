int main() {

    volatile unsigned char* RESULT_ADDR = (unsigned char*)0x6000;

    RESULT_ADDR[0] = 1;
    RESULT_ADDR[1] = 2;
    RESULT_ADDR[2] = 3;
    RESULT_ADDR[3] = 4;

    volatile int* CLK_CYCLE_ADDR = (int*)0x00007000;
    volatile int* INVALID_CLK_CYCLE_ADDR = (int*)0x00007004;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (int*)0x00007008;
    volatile int* CORRECT_PREDICTIONS_ADDR = (int*)0x0000700C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (int*)0x00007010;
    
    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    

    while(1);

}