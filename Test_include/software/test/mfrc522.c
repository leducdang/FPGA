/*
 * mfrc522.c
 *
 *  Created on: Oct 19, 2024
 *      Author: DELL
 */

/**
 * |----------------------------------------------------------------------
 * | Copyright (C) Tilen Majerle, 2014
 * |
 * | This program is free software: you can redistribute it and/or modify
 * | it under the terms of the GNU General Public License as published by
 * | the Free Software Foundation, either version 3 of the License, or
 * | any later version.
 * |
 * | This program is distributed in the hope that it will be useful,
 * | but WITHOUT ANY WARRANTY; without even the implied warranty of
 * | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * | GNU General Public License for more details.
 * |
 * | You should have received a copy of the GNU General Public License
 * | along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * |----------------------------------------------------------------------
 */
#include "mfrc522.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_spi.h"
#include "system.h"


/* MFRC522 Commands */
#define PCD_IDLE						0x00   //NO action; Cancel the current command
#define PCD_AUTHENT						0x0E   //Authentication Key
#define PCD_RECEIVE						0x08   //Receive Data
#define PCD_TRANSMIT					0x04   //Transmit data
#define PCD_TRANSCEIVE					0x0C   //Transmit and receive data,
#define PCD_RESETPHASE					0x0F   //Reset
#define PCD_CALCCRC						0x03   //CRC Calculate

/* Mifare_One card command word */
#define PICC_REQIDL						0x26   // find the antenna area does not enter hibernation
#define PICC_REQALL						0x52   // find all the cards antenna area
#define PICC_ANTICOLL					0x93   // anti-collision
#define PICC_SElECTTAG					0x93   // election card
#define PICC_AUTHENT1A					0x60   // authentication key A
#define PICC_AUTHENT1B					0x61   // authentication key B
#define PICC_READ						0x30   // Read Block
#define PICC_WRITE						0xA0   // write block
#define PICC_DECREMENT					0xC0   // debit
#define PICC_INCREMENT					0xC1   // recharge
#define PICC_RESTORE					0xC2   // transfer block data to the buffer
#define PICC_TRANSFER					0xB0   // save the data in the buffer
#define PICC_HALT						0x50   // Sleep

/* MFRC522 Registers */
//Page 0: Command and Status
#define MFRC522_REG_RESERVED00			0x00
#define MFRC522_REG_COMMAND				0x01
#define MFRC522_REG_COMM_IE_N			0x02
#define MFRC522_REG_DIV1_EN				0x03
#define MFRC522_REG_COMM_IRQ			0x04
#define MFRC522_REG_DIV_IRQ				0x05
#define MFRC522_REG_ERROR				0x06
#define MFRC522_REG_STATUS1				0x07
#define MFRC522_REG_STATUS2				0x08
#define MFRC522_REG_FIFO_DATA			0x09
#define MFRC522_REG_FIFO_LEVEL			0x0A
#define MFRC522_REG_WATER_LEVEL			0x0B
#define MFRC522_REG_CONTROL				0x0C
#define MFRC522_REG_BIT_FRAMING			0x0D
#define MFRC522_REG_COLL				0x0E
#define MFRC522_REG_RESERVED01			0x0F
//Page 1: Command
#define MFRC522_REG_RESERVED10			0x10
#define MFRC522_REG_MODE				0x11
#define MFRC522_REG_TX_MODE				0x12
#define MFRC522_REG_RX_MODE				0x13
#define MFRC522_REG_TX_CONTROL			0x14
#define MFRC522_REG_TX_AUTO				0x15
#define MFRC522_REG_TX_SELL				0x16
#define MFRC522_REG_RX_SELL				0x17
#define MFRC522_REG_RX_THRESHOLD		0x18
#define MFRC522_REG_DEMOD				0x19
#define MFRC522_REG_RESERVED11			0x1A
#define MFRC522_REG_RESERVED12			0x1B
#define MFRC522_REG_MIFARE				0x1C
#define MFRC522_REG_RESERVED13			0x1D
#define MFRC522_REG_RESERVED14			0x1E
#define MFRC522_REG_SERIALSPEED			0x1F
//Page 2: CFG
#define MFRC522_REG_RESERVED20			0x20
#define MFRC522_REG_CRC_RESULT_M		0x21
#define MFRC522_REG_CRC_RESULT_L		0x22
#define MFRC522_REG_RESERVED21			0x23
#define MFRC522_REG_MOD_WIDTH			0x24
#define MFRC522_REG_RESERVED22			0x25
#define MFRC522_REG_RF_CFG				0x26
#define MFRC522_REG_GS_N				0x27
#define MFRC522_REG_CWGS_PREG			0x28
#define MFRC522_REG__MODGS_PREG			0x29
#define MFRC522_REG_T_MODE				0x2A
#define MFRC522_REG_T_PRESCALER			0x2B
#define MFRC522_REG_T_RELOAD_H			0x2C
#define MFRC522_REG_T_RELOAD_L			0x2D
#define MFRC522_REG_T_COUNTER_VALUE_H	0x2E
#define MFRC522_REG_T_COUNTER_VALUE_L	0x2F
//Page 3:TestRegister
#define MFRC522_REG_RESERVED30			0x30
#define MFRC522_REG_TEST_SEL1			0x31
#define MFRC522_REG_TEST_SEL2			0x32
#define MFRC522_REG_TEST_PIN_EN			0x33
#define MFRC522_REG_TEST_PIN_VALUE		0x34
#define MFRC522_REG_TEST_BUS			0x35
#define MFRC522_REG_AUTO_TEST			0x36
#define MFRC522_REG_VERSION				0x37
#define MFRC522_REG_ANALOG_TEST			0x38
#define MFRC522_REG_TEST_ADC1			0x39
#define MFRC522_REG_TEST_ADC2			0x3A
#define MFRC522_REG_TEST_ADC0			0x3B
#define MFRC522_REG_RESERVED31			0x3C
#define MFRC522_REG_RESERVED32			0x3D
#define MFRC522_REG_RESERVED33			0x3E
#define MFRC522_REG_RESERVED34			0x3F
//Dummy byte
#define MFRC522_DUMMY					0x00

#define MFRC522_MAX_LEN					16






void TM_MFRC522_Init(void) {
//	TM_MFRC522_InitPins();
//	TM_SPI_Init();

	TM_MFRC522_Reset();

	TM_MFRC522_WriteRegister(MFRC522_REG_T_MODE, 0x8D);
	TM_MFRC522_WriteRegister(MFRC522_REG_T_PRESCALER, 0x3E);
	TM_MFRC522_WriteRegister(MFRC522_REG_T_RELOAD_L, 30);
	TM_MFRC522_WriteRegister(MFRC522_REG_T_RELOAD_H, 0);

	/* 48dB gain */
	TM_MFRC522_WriteRegister(MFRC522_REG_RF_CFG, 0x70);

	TM_MFRC522_WriteRegister(MFRC522_REG_TX_AUTO, 0x40);
	TM_MFRC522_WriteRegister(MFRC522_REG_MODE, 0x3D);

	TM_MFRC522_AntennaOn();		//Open the antenna
}

TM_MFRC522_Status_t TM_MFRC522_Check(char* id) {
	TM_MFRC522_Status_t status;
	//Find cards, return card type
	status = TM_MFRC522_Request(PICC_REQIDL, id);
	if (status == MI_OK) {
		//Card detected
		//Anti-collision, return card serial number 4 bytes
		status = TM_MFRC522_Anticoll(id);
	}
	TM_MFRC522_Halt();			//Command card into hibernation

	return status;
}

TM_MFRC522_Status_t TM_MFRC522_Compare(char* CardID, char* CompareID) {
	char i;
	for (i = 0; i < 5; i++) {
		if (CardID[i] != CompareID[i]) {
			return MI_ERR;
		}
	}
	return MI_OK;
}

//==================================================
//ham nay can thay doi vi cau truc F1 khac F4

void TM_MFRC522_WriteRegister(char addr, char val) {
//	//CS low
//	MFRC522_CS_LOW;
//	//Send address
//	TM_SPI_Send((addr << 1) & 0x7E);
//	//Send data
//	TM_SPI_Send(val);
//	//CS high
//	MFRC522_CS_HIGH;
	IOWR_ALTERA_AVALON_SPI_TXDATA(SPI_BASE, (addr << 1) & 0x7E);
	IOWR_ALTERA_AVALON_SPI_TXDATA(SPI_BASE, val);
}

char TM_MFRC522_ReadRegister(char addr) {
	char val;
//	//CS low
//	MFRC522_CS_LOW;
//
//	TM_SPI_Send(((addr << 1) & 0x7E) | 0x80);
//	val = TM_SPI_Send(MFRC522_DUMMY);
//	//CS high
//	MFRC522_CS_HIGH;
	IOWR_ALTERA_AVALON_SPI_TXDATA(SPI_BASE, ((addr << 1) & 0x7E) | 0x80);
	val = IORD_ALTERA_AVALON_SPI_RXDATA(SPI_BASE);
	return val;
}

void TM_MFRC522_SetBitMask(char reg, char mask) {
	TM_MFRC522_WriteRegister(reg, TM_MFRC522_ReadRegister(reg) | mask);
}

void TM_MFRC522_ClearBitMask(char reg, char mask){
	TM_MFRC522_WriteRegister(reg, TM_MFRC522_ReadRegister(reg) & (~mask));
}

void TM_MFRC522_AntennaOn(void) {
	char temp;

	temp = TM_MFRC522_ReadRegister(MFRC522_REG_TX_CONTROL);
	if (!(temp & 0x03)) {
		TM_MFRC522_SetBitMask(MFRC522_REG_TX_CONTROL, 0x03);
	}
}

void TM_MFRC522_AntennaOff(void) {
	TM_MFRC522_ClearBitMask(MFRC522_REG_TX_CONTROL, 0x03);
}

void TM_MFRC522_Reset(void) {
	TM_MFRC522_WriteRegister(MFRC522_REG_COMMAND, PCD_RESETPHASE);
}

TM_MFRC522_Status_t TM_MFRC522_Request(char reqMode, char* TagType) {
	TM_MFRC522_Status_t status;
	int backBits;			//The received data bits

	TM_MFRC522_WriteRegister(MFRC522_REG_BIT_FRAMING, 0x07);		//TxLastBists = BitFramingReg[2..0]	???

	TagType[0] = reqMode;
	status = TM_MFRC522_ToCard(PCD_TRANSCEIVE, TagType, 1, TagType, &backBits);

	if ((status != MI_OK) || (backBits != 0x10)) {
		status = MI_ERR;
	}

	return status;
}

TM_MFRC522_Status_t TM_MFRC522_ToCard(char command, char* sendData, char sendLen, char* backData, int* backLen) {
	TM_MFRC522_Status_t status = MI_ERR;
	char irqEn = 0x00;
	char waitIRq = 0x00;
	char lastBits;
	char n;
	int i;

	switch (command) {
		case PCD_AUTHENT: {
			irqEn = 0x12;
			waitIRq = 0x10;
			break;
		}
		case PCD_TRANSCEIVE: {
			irqEn = 0x77;
			waitIRq = 0x30;
			break;
		}
		default:
			break;
	}

	TM_MFRC522_WriteRegister(MFRC522_REG_COMM_IE_N, irqEn | 0x80);
	TM_MFRC522_ClearBitMask(MFRC522_REG_COMM_IRQ, 0x80);
	TM_MFRC522_SetBitMask(MFRC522_REG_FIFO_LEVEL, 0x80);

	TM_MFRC522_WriteRegister(MFRC522_REG_COMMAND, PCD_IDLE);

	//Writing data to the FIFO
	for (i = 0; i < sendLen; i++) {
		TM_MFRC522_WriteRegister(MFRC522_REG_FIFO_DATA, sendData[i]);
	}

	//Execute the command
	TM_MFRC522_WriteRegister(MFRC522_REG_COMMAND, command);
	if (command == PCD_TRANSCEIVE) {
		TM_MFRC522_SetBitMask(MFRC522_REG_BIT_FRAMING, 0x80);		//StartSend=1,transmission of data starts
	}

	//Waiting to receive data to complete
	i = 2000;	//i according to the clock frequency adjustment, the operator M1 card maximum waiting time 25ms???
	do {
		//CommIrqReg[7..0]
		//Set1 TxIRq RxIRq IdleIRq HiAlerIRq LoAlertIRq ErrIRq TimerIRq
		n = TM_MFRC522_ReadRegister(MFRC522_REG_COMM_IRQ);
		i--;
	} while ((i!=0) && !(n&0x01) && !(n&waitIRq));

	TM_MFRC522_ClearBitMask(MFRC522_REG_BIT_FRAMING, 0x80);			//StartSend=0

	if (i != 0)  {
		if (!(TM_MFRC522_ReadRegister(MFRC522_REG_ERROR) & 0x1B)) {
			status = MI_OK;
			if (n & irqEn & 0x01) {
				status = MI_NOTAGERR;
			}

			if (command == PCD_TRANSCEIVE) {
				n = TM_MFRC522_ReadRegister(MFRC522_REG_FIFO_LEVEL);
				lastBits = TM_MFRC522_ReadRegister(MFRC522_REG_CONTROL) & 0x07;
				if (lastBits) {
					*backLen = (n - 1) * 8 + lastBits;
				} else {
					*backLen = n * 8;
				}

				if (n == 0) {
					n = 1;
				}
				if (n > MFRC522_MAX_LEN) {
					n = MFRC522_MAX_LEN;
				}

				//Reading the received data in FIFO
				for (i = 0; i < n; i++) {
					backData[i] = TM_MFRC522_ReadRegister(MFRC522_REG_FIFO_DATA);
				}
			}
		} else {
			status = MI_ERR;
		}
	}

	return status;
}

TM_MFRC522_Status_t TM_MFRC522_Anticoll(char* serNum) {
	TM_MFRC522_Status_t status;
	char i;
	char serNumCheck = 0;
	int unLen;

	TM_MFRC522_WriteRegister(MFRC522_REG_BIT_FRAMING, 0x00);		//TxLastBists = BitFramingReg[2..0]

	serNum[0] = PICC_ANTICOLL;
	serNum[1] = 0x20;
	status = TM_MFRC522_ToCard(PCD_TRANSCEIVE, serNum, 2, serNum, &unLen);

	if (status == MI_OK) {
		//Check card serial number
		for (i = 0; i < 4; i++) {
			serNumCheck ^= serNum[i];
		}
		if (serNumCheck != serNum[i]) {
			status = MI_ERR;
		}
	}
	return status;
}

void TM_MFRC522_CalculateCRC(char*  pIndata, char len, char* pOutData) {
	char i, n;

	TM_MFRC522_ClearBitMask(MFRC522_REG_DIV_IRQ, 0x04);			//CRCIrq = 0
	TM_MFRC522_SetBitMask(MFRC522_REG_FIFO_LEVEL, 0x80);			//Clear the FIFO pointer
	//Write_MFRC522(CommandReg, PCD_IDLE);

	//Writing data to the FIFO
	for (i = 0; i < len; i++) {
		TM_MFRC522_WriteRegister(MFRC522_REG_FIFO_DATA, *(pIndata+i));
	}
	TM_MFRC522_WriteRegister(MFRC522_REG_COMMAND, PCD_CALCCRC);

	//Wait CRC calculation is complete
	i = 0xFF;
	do {
		n = TM_MFRC522_ReadRegister(MFRC522_REG_DIV_IRQ);
		i--;
	} while ((i!=0) && !(n&0x04));			//CRCIrq = 1

	//Read CRC calculation result
	pOutData[0] = TM_MFRC522_ReadRegister(MFRC522_REG_CRC_RESULT_L);
	pOutData[1] = TM_MFRC522_ReadRegister(MFRC522_REG_CRC_RESULT_M);
}

char TM_MFRC522_SelectTag(char* serNum) {
	char i;
	TM_MFRC522_Status_t status;
	char size;
	int recvBits;
	char buffer[9];

	buffer[0] = PICC_SElECTTAG;
	buffer[1] = 0x70;
	for (i = 0; i < 5; i++) {
		buffer[i+2] = *(serNum+i);
	}
	TM_MFRC522_CalculateCRC(buffer, 7, &buffer[7]);		//??
	status = TM_MFRC522_ToCard(PCD_TRANSCEIVE, buffer, 9, buffer, &recvBits);

	if ((status == MI_OK) && (recvBits == 0x18)) {
		size = buffer[0];
	} else {
		size = 0;
	}

	return size;
}

TM_MFRC522_Status_t TM_MFRC522_Auth(char authMode, char BlockAddr, char* Sectorkey, char* serNum) {
	TM_MFRC522_Status_t status;
	int recvBits;
	char i;
	char buff[12];

	//Verify the command block address + sector + password + card serial number
	buff[0] = authMode;
	buff[1] = BlockAddr;
	for (i = 0; i < 6; i++) {
		buff[i+2] = *(Sectorkey+i);
	}
	for (i=0; i<4; i++) {
		buff[i+8] = *(serNum+i);
	}
	status = TM_MFRC522_ToCard(PCD_AUTHENT, buff, 12, buff, &recvBits);

	if ((status != MI_OK) || (!(TM_MFRC522_ReadRegister(MFRC522_REG_STATUS2) & 0x08))) {
		status = MI_ERR;
	}

	return status;
}

TM_MFRC522_Status_t TM_MFRC522_Read(char blockAddr, char* recvData) {
	TM_MFRC522_Status_t status;
	int unLen;

	recvData[0] = PICC_READ;
	recvData[1] = blockAddr;
	TM_MFRC522_CalculateCRC(recvData,2, &recvData[2]);
	status = TM_MFRC522_ToCard(PCD_TRANSCEIVE, recvData, 4, recvData, &unLen);

	if ((status != MI_OK) || (unLen != 0x90)) {
		status = MI_ERR;
	}

	return status;
}

TM_MFRC522_Status_t TM_MFRC522_Write(char blockAddr, char* writeData) {
	TM_MFRC522_Status_t status;
	int recvBits;
	char i;
	char buff[18];

	buff[0] = PICC_WRITE;
	buff[1] = blockAddr;
	TM_MFRC522_CalculateCRC(buff, 2, &buff[2]);
	status = TM_MFRC522_ToCard(PCD_TRANSCEIVE, buff, 4, buff, &recvBits);

	if ((status != MI_OK) || (recvBits != 4) || ((buff[0] & 0x0F) != 0x0A)) {
		status = MI_ERR;
	}

	if (status == MI_OK) {
		//Data to the FIFO write 16Byte
		for (i = 0; i < 16; i++) {
			buff[i] = *(writeData+i);
		}
		TM_MFRC522_CalculateCRC(buff, 16, &buff[16]);
		status = TM_MFRC522_ToCard(PCD_TRANSCEIVE, buff, 18, buff, &recvBits);

		if ((status != MI_OK) || (recvBits != 4) || ((buff[0] & 0x0F) != 0x0A)) {
			status = MI_ERR;
		}
	}

	return status;
}

void TM_MFRC522_Halt(void) {
	int unLen;
	char buff[4];

	buff[0] = PICC_HALT;
	buff[1] = 0;
	TM_MFRC522_CalculateCRC(buff, 2, &buff[2]);

	TM_MFRC522_ToCard(PCD_TRANSCEIVE, buff, 4, buff, &unLen);
}




