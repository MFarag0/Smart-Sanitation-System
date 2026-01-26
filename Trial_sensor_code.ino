#include <SPI.h>
#include <LoRa.h>

// ---------- Ultrasonic Pins ----------
#define TRIG1 4
#define ECHO1 17
#define TRIG2 2
#define ECHO2 12

// ---------- LoRa Pins ----------
#define SS   18   // SPI CS
#define RST  14
#define DIO0 26
#define SCK  5
#define MISO 19
#define MOSI 27

#define ir 22

#define SOUND_SPEED 0.0346   // cm per microsecond


#define LORA_BAND 868E6

unsigned long lastSampleTime = 0;
const unsigned long sampleInterval = 1000;  // 1 second

int sampleCount = 0;
const int totalSamples = 10;

float sum1 = 0.0;
float sum2 = 0.0;

void setup()
{
  Serial.begin(9600);

  pinMode(TRIG1, OUTPUT);
  pinMode(ECHO1, INPUT);
  pinMode(TRIG2, OUTPUT);
  pinMode(ECHO2, INPUT);

  // Initializing the serial monitor for debugging purposes
  Serial.begin(115200);
  // Setting the LoRa module pins
  SPI.begin(SCK, MISO, MOSI, SS);
  LoRa.setPins(SS, RST, DIO0);
  if (!LoRa.begin(LORA_BAND)) {
    Serial.println("LoRa failed to start!");
    while (1);
    }

  digitalWrite(TRIG1, LOW);
  digitalWrite(TRIG2, LOW);
}

float readUltrasonic(int trigPin, int echoPin)
{
  long duration;

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH, 30000);

  if (duration == 0) return -1;  // invalid reading

  return (duration * 0.5) * SOUND_SPEED;
}

void loop()
{
  if (millis() - lastSampleTime >= sampleInterval)
  {
    lastSampleTime = millis();

    float d1 = readUltrasonic(TRIG1, ECHO1);
    delay(50);  // avoid cross-talk
    float d2 = readUltrasonic(TRIG2, ECHO2);

    if (d1 > 0 && d2 > 0) {
      sum1 += d1;
      sum2 += d2;
      sampleCount++;
    }

    // After 10 seconds (10 samples)
    if (sampleCount >= totalSamples)
    {
      float avg1 = sum1 / sampleCount;
      float avg2 = sum2 / sampleCount;

      String message = "10-sec avg sensor 1: " + String(avg1) + " cm\n" + "10-sec avg sensor 2: " + String(avg2) + " cm\n";

      LoRa.beginPacket();
      LoRa.print(message);
      LoRa.endPacket();
      delay(300);

     

      // Reset for next 10-sec window
      sum1 = 0.0;
      sum2 = 0.0;
      sampleCount = 0;
    }
  }
}
