
#include "string.h"

#define RXD2 16
#define TXD2 17


char data[50];
char cnt = 0;
// String dataReciver;
int count = 0;
unsigned long timeMillis = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);

}

void loop() {
  // put your main code here, to run repeatedly:
  if(Serial2.available() > 0)
  {
    char dataReciver = Serial2.read();
    if(dataReciver != '\n') 
    { 
      data[cnt] = dataReciver;
      cnt++;
    }
    else
    {
      data[cnt] = 0;
      Serial.println(data);
      cnt = 0;
    }
  }
  
  if( (millis() - timeMillis) > 500)
  {
    Serial2.print(count);
    Serial2.print("\n");
    count ++;
    if(count > 1000) count = 0;
    timeMillis = millis();
  }
}
