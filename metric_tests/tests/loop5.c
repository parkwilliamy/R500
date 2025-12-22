#include <stdint.h>

static inline uint32_t xorshift32(uint32_t* s) {
    uint32_t x = *s;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    *s = x;
    return x;
}

int main() {
    volatile uint32_t* OUT = (uint32_t*)0x6000;

    uint32_t seed = 0x12345678;
    uint32_t iters = 100000;
    uint32_t a_taken = 0, b_taken = 0;

    for (uint32_t i = 0; i < iters; i++) {
        uint32_t a = xorshift32(&seed) & 1;

        if (a) a_taken++;        // Branch A (random)
        //if (!a) b_taken++;        // Branch B (perfectly correlated)
    }

    *OUT = b_taken;

    volatile int* CLK_CYCLE_ADDR = (volatile int*)0x00005000;
    volatile int* INVALID_CLK_CYCLE_ADDR = (volatile int*)0x00005004;
    volatile int* RETIRED_INSTRUCTIONS_ADDR = (volatile int*)0x00005008;
    volatile int* CORRECT_PREDICTIONS_ADDR = (volatile int*)0x0000500C;
    volatile int* TOTAL_PREDICTIONS_ADDR = (volatile int*)0x00005010;
    
    *CLK_CYCLE_ADDR = 0;
    *INVALID_CLK_CYCLE_ADDR = 0;
    *RETIRED_INSTRUCTIONS_ADDR = 0;
    *CORRECT_PREDICTIONS_ADDR = 0;
    *TOTAL_PREDICTIONS_ADDR = 0;
    
    while (1);
}
