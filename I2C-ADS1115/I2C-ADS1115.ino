#include "Wire.h"

#define ADS1X15_ADDRESS (0x48) ///< 1001 000 (ADDR = GND)
/*=========================================================================*/

/*=========================================================================
    POINTER REGISTER
    -----------------------------------------------------------------------*/
#define ADS1X15_REG_POINTER_MASK (0x03)      ///< Point mask
#define ADS1X15_REG_POINTER_CONVERT (0x00)   ///< Conversion
#define ADS1X15_REG_POINTER_CONFIG (0x01)    ///< Configuration
#define ADS1X15_REG_POINTER_LOWTHRESH (0x02) ///< Low threshold
#define ADS1X15_REG_POINTER_HITHRESH (0x03)  ///< High threshold
/*=========================================================================*/

/*=========================================================================
    CONFIG REGISTER
    -----------------------------------------------------------------------*/
#define ADS1X15_REG_CONFIG_OS_MASK      (0x8000) ///< OS Mask
#define ADS1X15_REG_CONFIG_OS_SINGLE    (0x8000) ///< Write: Set to start a single-conversion
#define ADS1X15_REG_CONFIG_OS_BUSY      (0x0000) ///< Read: Bit = 0 when conversion is in progress
#define ADS1X15_REG_CONFIG_OS_NOTBUSY   (0x8000) ///< Read: Bit = 1 when device is not performing a conversion

#define ADS1X15_REG_CONFIG_MUX_MASK     (0x7000) ///< Mux Mask
#define ADS1X15_REG_CONFIG_MUX_DIFF_0_1 (0x0000) ///< Differential P = AIN0, N = AIN1 (default)
#define ADS1X15_REG_CONFIG_MUX_DIFF_0_3 (0x1000) ///< Differential P = AIN0, N = AIN3
#define ADS1X15_REG_CONFIG_MUX_DIFF_1_3 (0x2000) ///< Differential P = AIN1, N = AIN3
#define ADS1X15_REG_CONFIG_MUX_DIFF_2_3 (0x3000) ///< Differential P = AIN2, N = AIN3
#define ADS1X15_REG_CONFIG_MUX_SINGLE_0 (0x4000) ///< Single-ended AIN0
#define ADS1X15_REG_CONFIG_MUX_SINGLE_1 (0x5000) ///< Single-ended AIN1
#define ADS1X15_REG_CONFIG_MUX_SINGLE_2 (0x6000) ///< Single-ended AIN2
#define ADS1X15_REG_CONFIG_MUX_SINGLE_3 (0x7000) ///< Single-ended AIN3

constexpr uint16_t MUX_BY_CHANNEL[] = {
    ADS1X15_REG_CONFIG_MUX_SINGLE_0, ///< Single-ended AIN0
    ADS1X15_REG_CONFIG_MUX_SINGLE_1, ///< Single-ended AIN1
    ADS1X15_REG_CONFIG_MUX_SINGLE_2, ///< Single-ended AIN2
    ADS1X15_REG_CONFIG_MUX_SINGLE_3  ///< Single-ended AIN3
};                                   ///< MUX config by channel

#define ADS1X15_REG_CONFIG_PGA_MASK   (0x0E00)   ///< PGA Mask
#define ADS1X15_REG_CONFIG_PGA_6_144V (0x0000) ///< +/-6.144V range = Gain 2/3
#define ADS1X15_REG_CONFIG_PGA_4_096V (0x0200) ///< +/-4.096V range = Gain 1
#define ADS1X15_REG_CONFIG_PGA_2_048V (0x0400) ///< +/-2.048V range = Gain 2 (default)
#define ADS1X15_REG_CONFIG_PGA_1_024V (0x0600) ///< +/-1.024V range = Gain 4
#define ADS1X15_REG_CONFIG_PGA_0_512V (0x0800) ///< +/-0.512V range = Gain 8
#define ADS1X15_REG_CONFIG_PGA_0_256V (0x0A00) ///< +/-0.256V range = Gain 16

#define ADS1X15_REG_CONFIG_MODE_MASK   (0x0100)   ///< Mode Mask
#define ADS1X15_REG_CONFIG_MODE_CONTIN (0x0000) ///< Continuous conversion mode
#define ADS1X15_REG_CONFIG_MODE_SINGLE (0x0100) ///< Power-down single-shot mode (default)

#define ADS1X15_REG_CONFIG_RATE_MASK    (0x00E0) ///< Data Rate Mask

#define ADS1X15_REG_CONFIG_CMODE_MASK   (0x0010) ///< CMode Mask
#define ADS1X15_REG_CONFIG_CMODE_TRAD   (0x0000) ///< Traditional comparator with hysteresis (default)
#define ADS1X15_REG_CONFIG_CMODE_WINDOW (0x0010) ///< Window comparator

#define ADS1X15_REG_CONFIG_CPOL_MASK    (0x0008) ///< CPol Mask
#define ADS1X15_REG_CONFIG_CPOL_ACTVLOW (0x0000) ///< ALERT/RDY pin is low when active (default)
#define ADS1X15_REG_CONFIG_CPOL_ACTVHI  (0x0008) ///< ALERT/RDY pin is high when active

#define ADS1X15_REG_CONFIG_CLAT_MASK    (0x0004) ///< Determines if ALERT/RDY pin latches once asserted
#define ADS1X15_REG_CONFIG_CLAT_NONLAT  (0x0000) ///< Non-latching comparator (default)
#define ADS1X15_REG_CONFIG_CLAT_LATCH   (0x0004) ///< Latching comparator

#define ADS1X15_REG_CONFIG_CQUE_MASK    (0x0003) ///< CQue Mask
#define ADS1X15_REG_CONFIG_CQUE_1CONV   (0x0000) ///< Assert ALERT/RDY after one conversions
#define ADS1X15_REG_CONFIG_CQUE_2CONV   (0x0001) ///< Assert ALERT/RDY after two conversions
#define ADS1X15_REG_CONFIG_CQUE_4CONV   (0x0002) ///< Assert ALERT/RDY after four conversions
#define ADS1X15_REG_CONFIG_CQUE_NONE    (0x0003) ///< Disable the comparator and put ALERT/RDY in high state (default)
/*=========================================================================*/

/** Gain settings */
typedef enum {
  GAIN_TWOTHIRDS = ADS1X15_REG_CONFIG_PGA_6_144V,
  GAIN_ONE = ADS1X15_REG_CONFIG_PGA_4_096V,
  GAIN_TWO = ADS1X15_REG_CONFIG_PGA_2_048V,
  GAIN_FOUR = ADS1X15_REG_CONFIG_PGA_1_024V,
  GAIN_EIGHT = ADS1X15_REG_CONFIG_PGA_0_512V,
  GAIN_SIXTEEN = ADS1X15_REG_CONFIG_PGA_0_256V
} adsGain_t;

/** Data rates */
#define RATE_ADS1015_128SPS (0x0000)  ///< 128 samples per second
#define RATE_ADS1015_250SPS (0x0020)  ///< 250 samples per second
#define RATE_ADS1015_490SPS (0x0040)  ///< 490 samples per second
#define RATE_ADS1015_920SPS (0x0060)  ///< 920 samples per second
#define RATE_ADS1015_1600SPS (0x0080) ///< 1600 samples per second (default)
#define RATE_ADS1015_2400SPS (0x00A0) ///< 2400 samples per second
#define RATE_ADS1015_3300SPS (0x00C0) ///< 3300 samples per second

#define RATE_ADS1115_8SPS (0x0000)   ///< 8 samples per second
#define RATE_ADS1115_16SPS (0x0020)  ///< 16 samples per second
#define RATE_ADS1115_32SPS (0x0040)  ///< 32 samples per second
#define RATE_ADS1115_64SPS (0x0060)  ///< 64 samples per second
#define RATE_ADS1115_128SPS (0x0080) ///< 128 samples per second (default)
#define RATE_ADS1115_250SPS (0x00A0) ///< 250 samples per second
#define RATE_ADS1115_475SPS (0x00C0) ///< 475 samples per second
#define RATE_ADS1115_860SPS (0x00E0) ///< 860 samples per second

adsGain_t m_gain;              ///< ADC gain
uint16_t m_dataRate; 



void startADCReading(uint16_t mux, bool continuous) {
  // Start with default values
  uint16_t config =
      ADS1X15_REG_CONFIG_CQUE_1CONV |   // 0x0000   Set CQUE to any value other than   
      ADS1X15_REG_CONFIG_CLAT_NONLAT |  // 0x0000   Non-latching (default val)
      ADS1X15_REG_CONFIG_CPOL_ACTVLOW | // 0x0000   Alert/Rdy active low   (default val)
      ADS1X15_REG_CONFIG_CMODE_TRAD;    // 0x0000   Traditional comparator (default val)

// => config = 0x0000;

  if (continuous) {
    config |= ADS1X15_REG_CONFIG_MODE_CONTIN;     // 0x0000
  } else {
    config |= ADS1X15_REG_CONFIG_MODE_SINGLE;     // 0x0100
  }

  // Set PGA/voltage range
  config |= m_gain;                               // 0x0000 ADS1X15_REG_CONFIG_PGA_6_144V (0x0000)

  // Set data rate
  config |= m_dataRate;                           // 0x0080 RATE_ADS1115_128SPS (0x0080)

  // Set channels
  config |= mux;                                  // ADS1X15_REG_CONFIG_MUX_SINGLE_0 (0x4000) ///< Single-ended AIN0
                                                  // ADS1X15_REG_CONFIG_MUX_SINGLE_1 (0x5000) ///< Single-ended AIN1
                                                  // ADS1X15_REG_CONFIG_MUX_SINGLE_2 (0x6000) ///< Single-ended AIN2
                                                  // ADS1X15_REG_CONFIG_MUX_SINGLE_3 (0x7000) ///< Single-ended AIN3

  // Set 'start single-conversion' bit
  config |= ADS1X15_REG_CONFIG_OS_SINGLE;         // 0x8000

  // Write config register to the ADC
  // writeRegister(ADS1X15_REG_POINTER_CONFIG, config);

  // Set ALERT/RDY to RDY mode.

}


int16_t byte1, byte2;
int16_t Data;
const float multiplier = 0.1875F;

void setup() {
  // put your setup code here, to run once:
  Wire.begin();
  Serial.begin(9600);
}
//635.44

// config = 0xC080         channel 1 - tần số lấy mẫu 128 - chế độ Single
// config = 0XD180         channel 2 - tần số lấy mẫu 128 - chế độ Single
// config = 0XE180         channel 3 - tần số lấy mẫu 128 - chế độ Single
// config = 0XF180         channel 4 - tần số lấy mẫu 128 - chế độ Single
void loop() {
  // put your main code here, to run repeatedly:
  Wire.beginTransmission(0x48);
  Wire.write(0x01);

  //CHANNEL 1
  // Wire.write(0xC1);
  // Wire.write(0x80); 

  //CHANNEL 2
  // Wire.write(0xD1);
  // Wire.write(0x80); 

  //CHANNEL 3
  // Wire.write(0xE1);
  // Wire.write(0x80); 

  //CHANNEL 4
  Wire.write(0xF1);
  Wire.write(0x80); 
  Wire.endTransmission();

  // Set ALERT/RDY to RDY mode.
    // writeRegister(ADS1X15_REG_POINTER_HITHRESH, 0x8000);
    // writeRegister(ADS1X15_REG_POINTER_LOWTHRESH, 0x0000);
  Wire.beginTransmission(0x48);
  Wire.write(0x03);
  Wire.write(0x80);
  Wire.write(0x00); 
  Wire.endTransmission();

  Wire.beginTransmission(0x48);
  Wire.write(0x02);
  Wire.write(0x00);
  Wire.write(0x00); 
  Wire.endTransmission();

  delay(2);
  Wire.beginTransmission(0x48);
  Wire.write((byte)0x00);
  Wire.endTransmission();
  // Wire.requestFrom(DS1307, NumberOfFields);
  Wire.requestFrom(0x48, 2);
  byte1 = Wire.read();
  byte2 = Wire.read();
  Data = ( byte1 << 8) | byte2;

  Serial.println(Data * multiplier);
  delay(500);

}
