#include <map>
#include <string>
#include <SPI.h>
#include <LoRa.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

#define SS 18
#define RST 14
#define DIO0 26
#define SCK 5
#define MISO 19
#define MOSI 27
#define LORA_BAND 868E6

const char* SSID = "FacilityA";
const char* PASS = "12345678";

WebServer server(80);

void setup() {
    Serial.begin(115200); 
    SPI.begin(SCK, MISO, MOSI, SS);
    LoRa.setPins(SS, RST, DIO0);
    if (!LoRa.begin(LORA_BAND)) {
        Serial.println("LoRa failed to start!");
        while (1);
    }
    WiFi.mode(WIFI_AP);
    WiFi.softAP(ssid, password);
    server.on("/facilitydata", HTTP_POST, handleToApp); //From esp to app
    server.on("/reply",)
    server.begin();
    


void loop() {
  server.handleClient();
  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    String receivedPacket = LoRa.readString();
    handleToApp(receivedPacket);
  }
void handleToApp(String receivedPacket){
  server.send(200, "text/plain", receivedPacket);
}

