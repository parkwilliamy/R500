int main() {

    int count = 0;
    
    for (int i = 0; i < 1000; i++) {
        count++;
    }

    volatile int* CLK_CYCLE_ADDR = (volatile int*)0x00004F00;
    volatile int* INVALID_CLK_CYCLE_ADDR = (volatile int*)0x00004F04;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (volatile int*)0x00004F08;
    volatile int* CORRECT_PREDICTIONS_ADDR = (volatile int*)0x00004F0C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (volatile int*)0x00004F10;
    volatile int* RESULT_ADDR = (volatile int*)0x00006000;

    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 100;
    *RESULT_ADDR = count;

    while(1);

}