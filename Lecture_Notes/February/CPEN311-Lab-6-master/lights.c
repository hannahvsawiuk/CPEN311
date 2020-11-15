#define switches (volatile char *) 0x0002010 
#define leds (char *) 0x0002000
#define ledin (char *) 0x0002100

void main()
{ 
   while (1) {
		*leds = *switches;
		int switch1 = *switches >> 4;
		switch1 = switch1 & 0b00001111;
		int switch0 = *switches & 0b00001111;
		int addition = switch0 + switch1;
		int hex0 = addition % 10;
		int hex1 = addition / 10;
		*ledin = hex0 + hex1*16;
	}
}
