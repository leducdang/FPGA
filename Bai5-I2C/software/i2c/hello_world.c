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
#include "altera_avalon_i2c_regs.h"
#include "altera_avalon_i2c.h"

//Address of RTC DS3231 and the Temp Register
const alt_u8 DS3231_ADDR = 0b1101000;
const alt_u8 RegisterAddr = 0x00;

void delay_ms(int ms)
{
	unsigned int x,y;
	for(x =0; x<ms; x++)
	{	for(y =0; y<1000; y++);}
}

int main(){

 alt_u8 ReadTempbuf[3];
 alt_u8 TxBuffer[1]= { RegisterAddr };
 char second = 0;
 char hour = 0;
 char minutes = 0;

 char finaloutput[5];

// chuoi du lieu cai dat thoi gian
// alt_u8 settime[4]= { RegisterAddr,0x20,0x44,0x01 };
 ALT_AVALON_I2C_STATUS_CODE status;

 ALT_AVALON_I2C_DEV_t *my_i2c;
 ALT_AVALON_I2C_MASTER_CONFIG_t cfg;

 cfg.addr_mode = 0;

 my_i2c = alt_avalon_i2c_open(I2C_NAME);
 if(my_i2c == NULL){
 printf("Failed to open I2C port\n");
 return 1;
 }
 alt_avalon_i2c_master_target_set(my_i2c, DS3231_ADDR); 		//pointing to the TMP102 address
 alt_avalon_i2c_master_config_speed_set(my_i2c, &cfg,100000 ); //Set the speed
 alt_avalon_i2c_master_config_set(my_i2c, &cfg);				//configure
 alt_avalon_i2c_init(my_i2c);

 // cau lenh set thoi gian
// status = alt_avalon_i2c_master_tx(my_i2c,settime,sizeof(settime),ALT_AVALON_I2C_NO_INTERRUPTS);
 while(1)
 {
	 status = alt_avalon_i2c_master_tx_rx(my_i2c, TxBuffer, 1, ReadTempbuf, sizeof(ReadTempbuf),ALT_AVALON_I2C_NO_INTERRUPTS);
	 if (status!=ALT_AVALON_I2C_SUCCESS){
	 printf("Read Failure\n");
	 return 1; //FAIL
	 }
	 second 	= (ReadTempbuf[0]>>4 &0x0f)*10 + (ReadTempbuf[0] &0x0f);
	 minutes 	= (ReadTempbuf[1]>>4 &0x0f)*10 + (ReadTempbuf[1] &0x0f);
	 hour 		= (ReadTempbuf[2]>>4 &0x0f)*10 + (ReadTempbuf[2] &0x0f);
	 sprintf(finaloutput, "%d:%d:%d", hour, minutes, second);
	 printf(finaloutput);
	 printf("\n");
	 delay_ms(1000);
 }
 return 0;
 }
