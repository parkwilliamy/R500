int main() {

    int count = 0;
    
    for (int i = 0; i < 20; i++) {
        count++;
    }

    int* CLK_CYCLE_ADDR = (int*)0x00004F00;
    int* INVALID_CLK_CYCLE_ADDR = (int*)0x00004F04;
    int* RETIRED_INSTRUCTIONS_ADDR = (int*)0x00004F08;
    int* CORRECT_PREDICTIONS_ADDR = (int*)0x00004F0C;
    int* TOTAL_PREDICTIONS_ADDR = (int*)0x00004F10;
    int* RESULT_ADDR = (int*)0x00006000;

    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    *RESULT_ADDR = count;

    while(1);

}