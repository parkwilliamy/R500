int main() {

    volatile int a,b,c,d,e,f,g,h,i,j,k,l;

    a = 20;
    b = 5;
    c = a ^ b;
    
    d = 1;
    e = 2;
    f = d-e;
    
    g = 5;
    h = 1;
    i = 5<<1;
    
    j = 2;
    k = 15;
    l = j | k;
    
    volatile int* RESULT_ADDR = (volatile int*)0x6000;

    RESULT_ADDR[0] = c;
    RESULT_ADDR[1] = f;
    RESULT_ADDR[2] = i;
    RESULT_ADDR[3] = l;
    
    while(1);

}