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

#define TRIG 13
#define ECHO 12
#define SOUND_SPEED 0.0346 // In cm/microsecond 
#define IRSENSOR 22

const char charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
std::map<std::string, int> resources;
long t;
float distance;
float average;
bool sensed = true;
int counter = 0;
unsigned long sonicInterval = 5000;
unsigned long lastTime = 0;
unsigned long lastPacketSent = 0;
unsigned long IRHighStart = 0;
unsigned long IRDebounceTime = 200;
int currentIRState;
unsigned long now;
uint64_t chipid;

const char* SSID = "FacilityA";
const char* PASS = "12345678";

WebServer server(80);

void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "*");
  // Chrome Private Network Access (PNA) fix:
  server.sendHeader("Access-Control-Allow-Private-Network", "true");
}
void handleSensorsOptions() {
  sendCorsHeaders();
  server.send(204); // No Content for preflight
}
void setup() 
  {
    Serial.begin(115200); 
    pinMode(TRIG, OUTPUT); 
    pinMode(ECHO, INPUT);
    pinMode(IRSENSOR, INPUT);
    digitalWrite(TRIG, LOW); 
    SPI.begin(SCK, MISO, MOSI, SS);
    LoRa.setPins(SS, RST, DIO0);
    if (!LoRa.begin(LORA_BAND)) {
        Serial.println("LoRa failed to start!");
        while (1);
    }
    WiFi.mode(WIFI_AP);
    WiFi.softAP(SSID, PASS);
    server.on("/sensorsdata", HTTP_GET, handleToApp);   
    server.on("/sensorsdata", HTTP_OPTIONS, handleSensorsOptions);
    server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      sendCorsHeaders();
      server.send(204);
      return;
    }
    sendCorsHeaders();
    server.send(404, "text/plain", "Not found");
  });//From esp to app
    server.begin();
    

    }
void loop() {   
    server.handleClient();
    now = millis();
    average = 0;
    currentIRState = digitalRead(IRSENSOR);
    if (currentIRState == LOW && sensed){
        counter++;
        sensed = false;
        IRHighStart = 0;
        Serial.print("Sensor detected: ");
        Serial.println(counter);

    }
   
    if (!sensed) {
      if (currentIRState == HIGH) {
        if (IRHighStart == 0) IRHighStart = now;
        if (now - IRHighStart >= IRDebounceTime) {
          sensed = true;
          IRHighStart = 0;
        }
      } else {
        IRHighStart = 0; 
      }
  }
    
    if (now - lastTime >= sonicInterval){
      for (int i=0; i<5; i++){
        digitalWrite(TRIG, LOW);
        delayMicroseconds(10);
        digitalWrite(TRIG, HIGH);
        delayMicroseconds(10);
        digitalWrite(TRIG, LOW);
        t = pulseIn(ECHO , HIGH);
        distance = (t/2)*SOUND_SPEED ;
        average += distance;
        delay(10);
      }
      lastTime = now;
      average = average / 5;
      resources["Water"] = round(average);
      resources["Population"] = counter;
      sendToESP32();
    }
   
}
String generateID() {
  String id = "";

  for (int i = 0; i < 8; i++) {
    int index = random(0, sizeof(charset) - 1);
    id += charset[index];
  }

  return id;
}

void sendToESP32() {
    String packet;
      packet = String("FacilityA")+"|"+"Water"+"|"+resources["Water"]+"|"+"Population"+"|"+resources["Population"];
      Serial.println(packet);
      Serial.println(WiFi.softAPIP());
      LoRa.beginPacket();
      LoRa.print(packet);
      LoRa.endPacket();
      delay(10);
    
}
void handleToApp(){
  String msg = String("FacilityA")+"|"+String("Water")+"|"+resources["Water"]+"|"+"Population"+"|"+resources["Population"];
  server.send(200, "text/plain", msg);
}

