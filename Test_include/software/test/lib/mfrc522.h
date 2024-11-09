/*
 * mfrc522.h
 *
 *  Created on: Oct 19, 2024
 *      Author: DELL
 */

#ifndef LIB_MFRC522_H_
#define LIB_MFRC522_H_
/**
 * Status enumeration
 *
 * Used with most functions
 */
typedef enum {
	MI_OK = 0,
	MI_NOTAGERR,
	MI_ERR
} TM_MFRC522_Status_t;
/**
 * Public functions
 */
/**
 * Initialize MFRC522 RFID reader
 *
 * Prepare MFRC522 to work with RFIDs
 *
 */
extern void TM_MFRC522_Init(void);

/**
 * Check for RFID card existance
 *
 * Parameters:
 * 	- char* id:
 * 		Pointer to 5bytes long memory to store valid card id in.
 * 		ID is valid only if card is detected, so when function returns MI_OK
 *
 * Returns MI_OK if card is detected
 */
extern TM_MFRC522_Status_t TM_MFRC522_Check(char * id);

/**
 * Compare 2 RFID ID's
 * Useful if you have known ID (database with allowed IDs), to compare detected card with with your ID
 *
 * Parameters:
 * 	- char* CardID:
 * 		Pointer to 5bytes detected card ID
 * 	- char* CompareID:
 * 		Pointer to 5bytes your ID
 *
 * Returns MI_OK if IDs are the same, or MI_ERR if not
 */
extern TM_MFRC522_Status_t TM_MFRC522_Compare(char* CardID, char* CompareID);
/**
 * Private functions
 */
extern void TM_MFRC522_WriteRegister(char addr, char val);
extern char TM_MFRC522_ReadRegister(char addr);
extern void TM_MFRC522_SetBitMask(char reg, char mask);
extern void TM_MFRC522_ClearBitMask(char reg, char mask);
extern void TM_MFRC522_AntennaOn(void);
extern void TM_MFRC522_AntennaOff(void);
extern void TM_MFRC522_Reset(void);
extern TM_MFRC522_Status_t TM_MFRC522_Request(char reqMode, char* TagType);
extern TM_MFRC522_Status_t TM_MFRC522_ToCard(char command, char* sendData, char sendLen, char* backData, int* backLen);
extern TM_MFRC522_Status_t TM_MFRC522_Anticoll(char* serNum);
extern void TM_MFRC522_CalculateCRC(char* pIndata, char len, char* pOutData);
extern char TM_MFRC522_SelectTag(char* serNum);
extern TM_MFRC522_Status_t TM_MFRC522_Auth(char authMode, char BlockAddr, char* Sectorkey, char* serNum);
extern TM_MFRC522_Status_t TM_MFRC522_Read(char blockAddr, char* recvData);
extern TM_MFRC522_Status_t TM_MFRC522_Write(char blockAddr, char* writeData);
extern void TM_MFRC522_Halt(void);





#endif /* LIB_MFRC522_H_ */