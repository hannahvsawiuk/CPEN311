/* NOTE: this file must be self-contained */
// inputs: counter low, counter high,

// I think you have the right idea, except you need to be careful about the 4 or 0 part. 
// Remember that the memory reads you will do in C are byte addressed (so every 4 bytes for a 32-bit int), 
// but the address received by the Avalon slave (your counter) is word-addressed (so every 1 word for a 32-bit int).
#include <stdlib.h>
#include <stdio.h>

#define ADDR_BASE   (volatile unsigned long *)0x0004100
#define ADDR_HIGH   (volatile unsigned long *)0x0004104
#define count_pre   (volatile unsigned long long *)0x0001500 // address for the count value before the multiplication
#define count       (volatile unsigned long long *)0x0001510 // final count value address
#define product     (volatile unsigned long *)0x0001520      // result of multiplication

extern inline unsigned long long hw_counter();

int main (void) {
    hw_counter();
    return 0;
}

inline unsigned long long hw_counter() {

    // store the value of the counter before multiplications
    (*count_pre) = (*ADDR_HIGH);
    (*count_pre) = ((*count_pre) << 32) | (*ADDR_BASE);

    // multiplication loop
    for (size_t i = 0; i < 1000; i++) {
        (*product)     = i*i;
    }

    // corner cases
    if ( *ADDR_HIGH == 0x00000002 || *ADDR_HIGH == 0x00000001) {
      if (*ADDR_BASE == 0x00000008) {
        (*count) = 0x00000001ffffffff;
      }
    } else { // concatenate the high and low counters using bitwise left shit
      (*count) = (*ADDR_HIGH);
      (*count) = ((*count) << 32) | (*ADDR_BASE);
    }

    // compute the actual count value by subtracting the starting and final count values and dividing by the no. of iterations
    (*count)   = (*count) - (*count_pre);
    (*count)   = (*count)/1000;

    return (*count);
}
