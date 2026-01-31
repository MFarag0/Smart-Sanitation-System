//Admin
#include <map>
#include <string>
#include <SPI.h>
#include <LoRa.h>
#include <WiFi.h>
#include <WebServer.h>


#define SS 18
#define RST 14
#define DIO0 26
#define SCK 5
#define MISO 19
#define MOSI 27
#define LORA_BAND 868E6

const char* ssid = "Admin";
const char* password = "12345678";
String receivedPacket;
String receivedMessageFromApp;
String receivedMessageFromFacility;

WebServer server(80);

void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "*");
  server.sendHeader("Access-Control-Allow-Private-Network", "true");
}
void handleSensorsOptions() {
  sendCorsHeaders();
  server.send(204); 
}

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
    server.on("/facilitydata", HTTP_GET, handleToApp);
    server.on("/sendtofacility", HTTP_POST, handleAdminMessage) ; //From app to esp
    server.on("/fromfacility", HTTP_GET, handleFacilityMessage);
    server.on("/facilitydata", HTTP_OPTIONS, handleSensorsOptions);
    server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      sendCorsHeaders();
      server.send(204);
      return;
    }
    sendCorsHeaders();
    server.send(404, "text/plain", "Not found");
      });
    server.begin();

}
void loop() {
  server.handleClient();
  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    receivedPacket = LoRa.readString();
    Serial.println(receivedPacket);
    int sepIndex = receivedPacket.indexOf('|');

    if (sepIndex != -1) {
      String type = receivedPacket.substring(0, sepIndex);
      String payload = receivedPacket.substring(sepIndex + 1);
      if (type=="FCLTYMSG"){
        receivedMessageFromFacility=payload;
        Serial.println(receivedMessageFromFacility);
      }
  }

 
  }

}
void handleToApp(){
  server.send(200, "text/plain", receivedPacket);
}
void handleAdminMessage(){
  sendCorsHeaders();

  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Missing body");
    return;
  }

  receivedMessageFromApp = server.arg("plain");
  receivedMessageFromApp.trim();

  if (receivedMessageFromApp.length() == 0) {
    server.send(400, "text/plain", "Empty body");
    return;
  }
  String finalmsg = String("ADMINMSG")+"|"+receivedMessageFromApp;
  Serial.print("Sending over LoRa: ");
  Serial.println(finalmsg);
  server.send(200, "text/plain", "OK");
  LoRa.beginPacket();
  LoRa.print(finalmsg);
  LoRa.endPacket();

}
void handleFacilityMessage(){
  server.send(200, "text/plain", receivedMessageFromFacility);
  receivedMessageFromFacility= "";
}


