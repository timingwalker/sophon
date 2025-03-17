
#include <stdint.h>

extern volatile uint64_t fromhost;

int main()
{

    while( fromhost!=1 );
	return 0;

}

