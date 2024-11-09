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
#include "sys/alt_stdio.h"
#include "stdio.h"
#include "system.h"
#include "Altera_UP_SD_Card_Avalon_Interface.h"
#include "unistd.h"


int pixel;
	int main(void)
	{
	    alt_up_sd_card_dev *device_reference = NULL;
	    int connected = 0;

	    device_reference = alt_up_sd_card_open_dev("/dev/SDCard");
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
			        while ((readCharacter = alt_up_sd_card_read(fileHandle)) != -1)
			        {
			        	pixel = readCharacter;
			        	readCharacter1 = alt_up_sd_card_read(fileHandle);
			        	pixel = (pixel<<8)|readCharacter1;
			            printf("%x\n", pixel);
			            ++contentCount;

			        }
			        printf("\nContent size: %i", contentCount);
			        printf("\n===========================\n\n");
			    }
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
	    else
	    {
		printf("Initialization failed.\n");
	    }
	}
