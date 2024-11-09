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
#include "altera_up_avalon_video_pixel_buffer_dma.h"
#include <unistd.h>
#include "system.h"
#include "unistd.h"
#include "Altera_UP_SD_Card_Avalon_Interface.h"

int pixel,pixel1=0,i=0,j=0;
int count = 0;
int main()
{
  printf("Hello from Nios II!\n");
  alt_up_pixel_buffer_dma_dev * pixel_buf_dma_dev;
  pixel_buf_dma_dev = alt_up_pixel_buffer_dma_open_dev ("/dev/video_pixel_buffer_dma_0");

  if ( pixel_buf_dma_dev == NULL)
  printf ("Error: could not open pixel buffer device \n");
  else
  printf ("Opened pixel buffer device \n");

  alt_up_pixel_buffer_dma_clear_screen (pixel_buf_dma_dev, 0);
  usleep(1000000);// 1sec

  alt_up_sd_card_dev *device_reference = NULL;
  int connected = 0;

  	    device_reference = alt_up_sd_card_open_dev("/dev/Altera_UP_SD_Card_Avalon_Interface_0");
  	    if (device_reference != NULL)
  	    {
  		printf("Initialized. Waiting for SD card...\n");
  		while(1)
  			{
  			    if ((connected == 0) && (alt_up_sd_card_is_Present()))
  			    {
  			        printf("Card connected.\n");
  			        if (alt_up_sd_card_is_FAT16())
  			        {
  				    printf("FAT16 file system detected.\n");

  				    printf("Looking for first file.\n");
  				    char * firstFile = "filenameunchanged";
  				    alt_up_sd_card_find_first(".", firstFile);
  				    printf("Volume Name: '%s'\n\n", firstFile);

  				    short file;
  				    while((file = alt_up_sd_card_find_next(firstFile)) != -1)
  				    {
  				        int contentCount = 0;
  				        printf("===========================\n");
  				        printf("Found file: '%s'\n", firstFile);

  				        short fileHandle = alt_up_sd_card_fopen(firstFile,false);
  				        printf("File handle: %i\n", fileHandle);

  				        printf("Contents:\n");
  				        short int readCharacter;
  				        short int readCharacter1;
  				        short int readCharacter2;

  				        while ((readCharacter = alt_up_sd_card_read(fileHandle)) != -1)
  				        {
  				        	if(count <100)
  				        		{
  				        		readCharacter1 = alt_up_sd_card_read(fileHandle);
  				        		readCharacter2 = alt_up_sd_card_read(fileHandle);
  				        		count ++;
  				        		}
  				        	else
  				        	{
  				        		readCharacter1 = alt_up_sd_card_read(fileHandle);
  				        		pixel1 =  readCharacter1;

  				        		readCharacter2 = alt_up_sd_card_read(fileHandle);

  				        		pixel = readCharacter2>>3;
  				        		pixel = (pixel<<11)|((pixel1>>2)<<5);
  				        		pixel = pixel | (readCharacter>>3);
  				        		++contentCount;
  				        		j++;
  				        		if(j>319){j = 0; i ++;}
  				        		if(i>239)i = 0;
  				        		alt_up_pixel_buffer_dma_draw_box (pixel_buf_dma_dev, j, i, j, i, pixel, 0);
  				        	}
  				        }
  				        printf("\nContent size: %i", contentCount);
  				        printf("\n===========================\n\n");
  				    }
  				    	printf("finish");
  			        }
  			        else
  			        {
  				    printf("Unknown file system.\n");
  			        }

  			        connected = 1;
  			    }
  			    else if ((connected == 1) && (alt_up_sd_card_is_Present() == false))
  			    {
  			        printf("Card disconnected.\n");
  			        connected = 0;
  			    }
  			}
  	    }

//  alt_up_pixel_buffer_dma_clear_screen (pixel_buf_dma_dev, 0);
//  usleep(1000000);// 1sec

//  alt_up_pixel_buffer_dma_draw_box (pixel_buf_dma_dev, 100, 50, 149, 99, 0xF800, 0);
//  alt_up_pixel_buffer_dma_draw_box (pixel_buf_dma_dev, 150, 100, 199, 149, 0x07E0, 0);
//  alt_up_pixel_buffer_dma_draw_box (pixel_buf_dma_dev, 200, 150, 249, 199, 0x001F, 0);
////  alt_up_pixel_buffer_dma_draw_rectangle(pixel_buf_dma_dev, 100,	220, 250, 230, 0xF800, 0);
//  alt_up_pixel_buffer_dma_draw_box(pixel_buf_dma_dev, 100,	220, 250, 230, 0xF81F, 0);


  return 0;
}