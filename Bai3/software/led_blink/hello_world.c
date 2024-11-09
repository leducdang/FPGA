/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "altera_up_avalon_character_lcd.h"

void delay(unsigned int ms)
{
	int x, y;
	for(x = 0; x< ms; x++ )
	{
		for(y = 0; y<1000;y++);
	}
}

int main()
{

  int count = 0;
  printf("Hello from Nios II!\n");
  alt_up_character_lcd_dev* lcd1602;
  lcd1602 = alt_up_character_lcd_open_dev("/dev/lcd");
  alt_up_character_lcd_init(lcd1602);

  alt_up_character_lcd_set_cursor_pos(lcd1602, 3, 0);
  alt_up_character_lcd_string(lcd1602,"Hello World");
  alt_up_character_lcd_set_cursor_pos(lcd1602, 0, 1);
  alt_up_character_lcd_string(lcd1602,"Tuyen Xinh Gai");

  while (1)
  {
	 if(IORD_ALTERA_AVALON_PIO_DATA(0x81000) == 0)
	 {
		 delay(10);
		 if(IORD_ALTERA_AVALON_PIO_DATA(0x81000)==0)
		 while(IORD_ALTERA_AVALON_PIO_DATA(0x81000) == 0);
		 count++;
	 }
	 IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE,count);
}
  return 0;
}


