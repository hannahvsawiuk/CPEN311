/* NOTE: this file must be self-contained */

//==============================//
//        Definitions           //
//==============================//
// multiplier address
#define MULT_N 0x00
// counter addresses
#define count_pre   (volatile unsigned long long *)0x1500 // address for the count value before the multiplication
#define count       (volatile unsigned long long *)0x1510 // final count value address
#define product     (volatile unsigned long *)0x1520      // result of multiplication
#define ADDR_BASE   (volatile unsigned long *)0x4100
#define ADDR_HIGH   (volatile unsigned long *)0x4104
// custom instruction function
#define MULT(x,y) __builtin_custom_inii(MULT_N, (x), (y));

//==============================//
//      Function Prototypes     //
//==============================//
int __builtint_custom_inii(int, int, int);      // custom instruction
extern inline unsigned long long hw_counter();  // count

//******************************//
//        Main function         //
//******************************//
int main (void) {
    hw_counter();
    return 0;
}

//******************************//
//     HW Counter function      //
//******************************//
inline unsigned long long hw_counter() {

  unsigned long temp_base; 
  temp_base = *ADDR_BASE;
  unsigned long long temp_high;
  temp_high = *ADDR_HIGH; 

  if (*ADDR_HIGH == temp_high) {
    (*count_pre) = (temp_high << 32) | temp_base;
  } else {
    (*count_pre) = (temp_high << 32) | 0xffffffff;
  }


  // multiplication loop
  for (int i = 0; i < 1000; i++) {
    (*product) = MULT(i,i);
  }

  // corner cases
  temp_base = *ADDR_BASE;
  temp_high = *ADDR_HIGH;
  
  if (*ADDR_HIGH == temp_high) {
    (*count) = (temp_high << 32) | temp_base;
  } else {
    (*count) = (temp_high << 32) | 0xffffffff;
  }

  // compute the actual count value by subtracting the starting and final count values
  // then dividing by the no. of iterations
  (*count) = (*count) - (*count_pre);
  (*count) = (*count) / 1000;

  return (*count);
}
