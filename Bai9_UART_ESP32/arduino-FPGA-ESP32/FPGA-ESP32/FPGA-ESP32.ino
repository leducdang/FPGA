#include <WiFiManager.h> // https://github.com/tzapu/WiFiManager
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>
#include <math.h>
#include "string.h"

#define RXD2 16
#define TXD2 17

#define ledConnect 32
// #define relay3 27
// #define relay2 26
// #define relay1 25
const char* mqtt_server = "62f81097fb3f47c8a8c4822b3d2d506d.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_username = "ledang"; //User
const char* mqtt_password = "Abcd1234*"; //Password

WiFiClientSecure espClient;
PubSubClient client(espClient);
WiFiManager wm;


// int voltage;
// int current;
// int power;
// int energy;
// int frequency;
// int pf;
char buffer[10];
char dataReciver[10];
int led1, led2, led3,cnt;

unsigned long timeUpdata=millis();

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientID =  "ESPClient-";
    clientID += String(random(0xffff),HEX);
    if (client.connect(clientID.c_str(), mqtt_username, mqtt_password)) {
      Serial.println("connected");
      client.subscribe("esp32/pTroSub");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  String incommingMessage = "";
  for(int i=0; i<length;i++) incommingMessage += (char)payload[i];
  Serial.println("Massage arived ["+String(topic)+"]"+incommingMessage);

  DynamicJsonDocument doc(100);
  DeserializationError error = deserializeJson(doc, incommingMessage);
  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.c_str());
    return;
  }
  JsonObject obj = doc.as<JsonObject>();
  if(obj.containsKey("ledConnect")){
    int p = obj["ledConnect"];
    digitalWrite(ledConnect,p);
    // Serial2.println(1);
  }

  if(obj.containsKey("relay1")){
    int reciver = obj["relay1"];
    // digitalWrite(relay1, reciver);
    if(reciver)
    {
      Serial2.print("on1");
      Serial2.print("\n");
    }
    else
    {
      Serial2.print("off1");
      Serial2.print("\n");
    }
  }

  if(obj.containsKey("relay2")){
    int reciver = obj["relay2"];
    // digitalWrite(relay2, reciver);
    if(reciver)
    {
      Serial2.print("on2");
      Serial2.print("\n");
    }
    else
    {
      Serial2.print("off2");
      Serial2.print("\n");
    }
  }

  if(obj.containsKey("relay3")){
    int reciver = obj["relay3"];
    // digitalWrite(relay3, reciver);
    if(reciver)
    {
      Serial2.print("on3");
      Serial2.print("\n");
    }
    else
    {
      Serial2.print("off3");
      Serial2.print("\n");
    }
  }
}

void publishMessage(const char* topic, String payload, boolean retained){
  if(client.publish(topic,payload.c_str(),true))
    Serial.println("Message published ["+String(topic)+"]: "+payload);
}

void setup() {
    Serial.begin(115200);
    Serial2.begin(9600, SERIAL_8N1, RXD2, TXD2);
    bool res;
    res = wm.autoConnect("WifiBan1DTCB");
    wm.setWiFiAutoReconnect(true);
    if(!res) {
      Serial.println("Failed to connect");
      ESP.restart();
    }
    else {
      //if you get here you have connected to the WiFi    
      Serial.println("connected...yeey :)");
      // setup_wifi();
      espClient.setInsecure();
      client.setServer(mqtt_server, mqtt_port);
      client.setCallback(callback);
      }
      pinMode(ledConnect, OUTPUT);
      // pinMode(relay1, OUTPUT);
      // pinMode(relay2, OUTPUT);
      // pinMode(relay3, OUTPUT);
}

void loop() {
    if (!client.connected()) {
    reconnect();
    }
    client.loop();

    if(Serial2.available() > 0)
    {
        char data = Serial2.read();
        if(data != '\n') 
      { 
        buffer[cnt] = data;
        cnt++;
      }
        else
      {
        buffer[cnt] = 0;
        cnt = 0;
        if(strstr(buffer,"on1"))  led1 = 1;
        if(strstr(buffer,"off1")) led1 = 0;
        if(strstr(buffer,"on2"))  led2 = 1;
        if(strstr(buffer,"off2")) led2 = 0;
        if(strstr(buffer,"on3"))  led3 = 1;
        if(strstr(buffer,"off3")) led3 = 0;
      }
    }
    
    
    if(millis()-timeUpdata>500){
    DynamicJsonDocument doc(1024);
    
    doc["relay1"] = led1;
    doc["relay2"] = led2;
    doc["relay3"] = led3;
    
    char mqtt_message[256];
    serializeJson(doc,mqtt_message);
    publishMessage("esp32/pTroPub", mqtt_message, true);
    timeUpdata = millis();
}
}
