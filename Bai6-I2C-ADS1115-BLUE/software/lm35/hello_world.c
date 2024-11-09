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
#include "altera_avalon_i2c_regs.h"
#include "altera_avalon_i2c.h"
#include <altera_up_avalon_rs232.h>

int rs232_read_str (alt_fd* fd, char* ptr, int len);
void rs232_write_str(alt_fd* fd, char *ptr, int len);


//Address of RTC DS3231 and the Temp Register
const alt_u8 ADS1115_ADDR = 0b1001000;
const alt_u8 RegisterAddr = 0x00;
// config = 0xC180         channel 1 - tần số lấy mẫu 128 - chế độ Single
// config = 0XD180         channel 2 - tần số lấy mẫu 128 - chế độ Single
// config = 0XE180         channel 3 - tần số lấy mẫu 128 - chế độ Single
// config = 0XF180         channel 4 - tần số lấy mẫu 128 - chế độ Single
const alt_u8 config_A0[] = {0x01, 0xC1, 0x80};
const alt_u8 config_A1[] = {0x01, 0xD1, 0x80};
const alt_u8 config_A2[] = {0x01, 0xE1, 0x80};
const alt_u8 config_A3[] = {0x01, 0xF1, 0x80};

const alt_u8 config_8BIT_HIGH[] = {0x03, 0x80, 0x00};
const alt_u8 config_8BIT_LOW[] =  {0x02, 0x00, 0x00};

const float multiplier = 0.1875f;
alt_u16 data;
float ADC_A0;
char led7_seg[] = {
					 0b1000000,
					 0b1111001,
					 0b0100100,
					 0b0110000,
					 0b0011001,
					 0b0010010,
					 0b0000010,
					 0b1111000,
					 0b0000000,
					 0b0010000,
					 0b0011100,
					 0b1000110
};
void delay_ms(int ms)
{
	unsigned int x,y;
	for(x =0; x<ms; x++)
	{	for(y =0; y<1000; y++);}
}

int status;
char chuoi[5]; // = "HELLO";
char cnt = 0;
char reciver[100];
alt_up_rs232_dev* rs232_dev;




int main(){

 alt_u8 ReadDatabuf[2];
 alt_u8 TxBuffer[1]= { RegisterAddr };

 char finaloutput[5];

 ALT_AVALON_I2C_STATUS_CODE status;
 ALT_AVALON_I2C_DEV_t *my_i2c;
 ALT_AVALON_I2C_MASTER_CONFIG_t cfg;

 cfg.addr_mode = 0;

 my_i2c = alt_avalon_i2c_open(I2C_NAME);
 rs232_dev = alt_up_rs232_open_dev("/dev/RS232");
 if(my_i2c == NULL){
 printf("Failed to open I2C port\n");
 return 1;
 }
 alt_avalon_i2c_master_target_set(my_i2c, ADS1115_ADDR); 		//pointing to the TMP102 address
 alt_avalon_i2c_master_config_speed_set(my_i2c, &cfg,100000 ); //Set the speed
 alt_avalon_i2c_master_config_set(my_i2c, &cfg);				//configure
 alt_avalon_i2c_init(my_i2c);

 while(1)
 {

	 // doc kenh A0.

	 status = alt_avalon_i2c_master_tx(my_i2c,config_A0,sizeof(config_A0),ALT_AVALON_I2C_NO_INTERRUPTS);
	 status = alt_avalon_i2c_master_tx(my_i2c,config_8BIT_HIGH,sizeof(config_8BIT_HIGH),ALT_AVALON_I2C_NO_INTERRUPTS);
	 status = alt_avalon_i2c_master_tx(my_i2c,config_8BIT_LOW, sizeof(config_8BIT_LOW), ALT_AVALON_I2C_NO_INTERRUPTS);
	 status = alt_avalon_i2c_master_tx_rx(my_i2c, TxBuffer, 1, ReadDatabuf, sizeof(ReadDatabuf),ALT_AVALON_I2C_NO_INTERRUPTS);

	 if (status!=ALT_AVALON_I2C_SUCCESS){
	 printf("Read Failure\n");
	 return 1; //FAIL
	 }

	 data = ( ReadDatabuf[0] << 8) | ReadDatabuf[1];
	 ADC_A0 = data * multiplier;

	 int ADC_CV = ADC_A0;
	 IOWR_ALTERA_AVALON_PIO_DATA(LED1_BASE,led7_seg[ADC_CV/1000]);  //hang chuc - hour
	 IOWR_ALTERA_AVALON_PIO_DATA(LED2_BASE,led7_seg[ADC_CV/100%10]); 	//hang don vi - hour

	 IOWR_ALTERA_AVALON_PIO_DATA(LED3_BASE,led7_seg[ADC_CV/10%10]);  //hang chuc - minute
	 IOWR_ALTERA_AVALON_PIO_DATA(LED4_BASE,led7_seg[ADC_CV%10]); 	//hang don vi - minute

	 IOWR_ALTERA_AVALON_PIO_DATA(LED5_BASE,led7_seg[10]);  //hang chuc - second
	 IOWR_ALTERA_AVALON_PIO_DATA(LED6_BASE,led7_seg[11]); 	//hang don vi - second

	 sprintf(finaloutput, "%.1f*C\n", (ADC_A0/10));
	 rs232_write_str(rs232_dev, finaloutput, 8);

	 printf(finaloutput);
	 printf("\n");
	 delay_ms(500);
 }
 return 0;
 }

int rs232_read_str (alt_fd* fd, char* ptr, int len)
{
	int count = 0;
	alt_u8 parity_error;
	while(len--)
	{
		if (alt_up_rs232_read_data(fd, (alt_u8 *)ptr++, &parity_error)==0)
			{
				count++;
//				len--;
			}
		else
			break;
	}
	return count;
}



void rs232_write_str(alt_fd* fd, char *ptr, int len)
{
	int count = 0;
	while(len--)
	{
		if (alt_up_rs232_write_data(fd, *ptr)==0)
				{
					count++;
					ptr++;
				}
	}
}




