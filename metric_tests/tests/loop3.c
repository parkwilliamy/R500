int mod(int a, int b);

int main() {

    int count = 0;
    int flag = 0;
    
    for (int i = 0; i < 1000; i++) {
        if (mod(flag,2) == 0 || mod(flag,3) == 0 || mod(flag,5) == 0) count++;
        flag++;
    }

    volatile int* RESULT_ADDR = (volatile int*)0x00006000;

    *RESULT_ADDR = count;

    while(1);

}

int mod(int a, int b) {

    while (a >= b) a-=b;
    return a;

}