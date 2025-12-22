static inline int mod(int a, int b) {

    while (a >= b) a-=b;
    return a;

}

int main() {

    int count = 0;
    
    for (int i = 0; i < 1000; i++) {
        if (mod(i,2) == 0 || mod(i,3) == 0 || mod(i,5) == 0) count++;
    }

    volatile int* RESULT_ADDR = (volatile int*)0x00006000;

    *RESULT_ADDR = count;

    while(1);

}

