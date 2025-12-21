int main() {

    int count = 0;
    
    for (int i = 0; i < 1000; i++) {
        count++;
    }

    volatile int* CLK_CYCLE_ADDR = (int*)0x00007000;
    volatile int* INVALID_CLK_CYCLE_ADDR = (int*)0x00007004;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (int*)0x00007008;
    volatile int* CORRECT_PREDICTIONS_ADDR = (int*)0x0000700C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (int*)0x00007014;
    volatile int* RESULT_ADDR = (int*)0x00006000;

    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    *RESULT_ADDR = count;

    while(1);

}