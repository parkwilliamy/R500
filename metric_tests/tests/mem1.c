int main() {

    volatile unsigned char *p = (unsigned char*)0x6000;
    p[0] = 1;
    p[1] = 2;
    p[2] = 3;
    p[3] = 4;

    int* CLK_CYCLE_ADDR = (int*)0x00004F00;
    int* INVALID_CLK_CYCLE_ADDR = (int*)0x00004F04;
    int* RETIRED_INSTRUCTIONS_ADDR = (int*)0x00004F08;
    int* CORRECT_PREDICTIONS_ADDR = (int*)0x00004F0C;
    int* TOTAL_PREDICTIONS_ADDR = (int*)0x00004F10;
    

    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    

    while(1);

}