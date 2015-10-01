#include <stdio.h>

void func1();
void func2();

int main()
{
    char p1 = 0;
    char p2 = 0;
    char p3 = 0;
    char p4 = 0;

    printf( "main  p1: val->%c   address->%p\n", p1, &p1 );
    printf( "main  p2: val->%c   address->%p\n", p2, &p2 );
    printf( "main  p3: val->%c   address->%p\n", p3, &p3 );
    printf( "main  p4: val->%c   address->%p\n", p4, &p4 );

    func1();
    func2();

    return 0;
}

void func1()
{
    char p1 = 0;
    char p2 = 0;
    char p3 = 0;
    char p4 = 0;

    printf( "func1 p1: val->%c   address->%p\n", p1, &p1 );
    printf( "func1 p2: val->%c   address->%p\n", p2, &p2 );
    printf( "func1 p3: val->%c   address->%p\n", p3, &p3 );
    printf( "func1 p4: val->%c   address->%p\n", p4, &p4 );

}

void func2()
{
    char p1 = 0;
    char p2 = 0;
    char p3 = 0;
    char p4 = 0;

    printf( "func2 p1: val->%c   address->%p\n", p1, &p1 );
    printf( "func2 p2: val->%c   address->%p\n", p2, &p2 );
    printf( "func2 p3: val->%c   address->%p\n", p3, &p3 );
    printf( "func2 p4: val->%c   address->%p\n", p4, &p4 );
}
