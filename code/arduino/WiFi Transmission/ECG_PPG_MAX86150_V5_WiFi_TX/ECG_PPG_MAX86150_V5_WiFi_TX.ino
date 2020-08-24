// ###################################################################################
// # Project: ECG Health Sensor
// # Engineer:  Mic.Tsai
// # Date:  30 July 2020
// # Objective: Dev.board
// # Usage: ESP8266
// # Modified: Mode Select with filter / ECG / PPG
// ###################################################################################

// ########################
#include <ESP8266WiFi.h>
#include <espnow.h>
// ########################

#include <Wire.h>
#include "max86150.h"

// # LCD install
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
Adafruit_SSD1306 display(128, 64, &Wire, -1);


byte TestledBrightness = 255; //Options: 0=Off to 255=50mA //0x1F

// # ECG sensor
int16_t ecgsigned16;
int16_t redunsigned16;
uint16_t ppgunsigned16;

MAX86150 max86150Sensor;

int TimerLast=0;
int TimerNow=0;
int Time=0;

int Filter_Value;
int Filter_Value2;
int Value;
int Value2;

// # BTN Mode Select
const int  buttonPin = 16;    // the pin that the pushbutton is attached to

// Variables will change:
int buttonPushCounter = 0;   // counter for the number of button presses
int buttonState = 0;         // current state of the button
int lastButtonState = 0;     // previous state of the button

/*
// PPG
// # Plot 變數宣告區
int a=0;
int lasta=0;
int lastb=0;
int LastTime=0;
int ThisTime;
bool BPMTiming=false;
bool BeatComplete=false;
int BPM=0;
*/

// # 上限下限
#define UpperThreshold 520  
#define LowerThreshold 450

// # Bias
int LevelSea = 0;

// # 平均心跳
const byte RATE_SIZE = 36; //Increase this for more averaging. 18 is good.
byte rates[RATE_SIZE]; //Array of heart rates
byte rateSpot = 0;
long lastBeat = 0; //Time at which the last beat occurred

float beatsPerMinute;
int beatAvg;
int PPGAVG;


// ########################


// REPLACE WITH RECEIVER MAC Address
uint8_t broadcastAddress[] = {0xF4, 0xCF, 0xA2, 0x6D, 0x2E, 0xDF};
//uint8_t broadcastAddress[] = {0x5C, 0xCF, 0x7F, 0xB9, 0x8A, 0x6A};
// uint8_t broadcastAddress[] = {0xF4, 0xCF, 0xA2, 0x6D, 0x2E, 0xDF};
// uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

// Structure example to send data
// Must match the receiver structure
typedef struct struct_message {
  int a;
  int b;
  int c;
  int d;

/*
  char a[32];
  int b;
  float c;
  String d;
  bool e;
*/
  
} struct_message;

// Create a struct_message called myData
struct_message myData;

unsigned long lastTime = 0;  
unsigned long timerDelay = 1;  // send readings timer

// Callback when data is sent
void OnDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
  Serial.print("Last Packet Send Status: ");
  if (sendStatus == 0){
    Serial.println("Delivery success");
  }
  else{
    Serial.println("Delivery fail");
  }
}

// ########################

void setup()
{
    pinMode(buttonPin, INPUT);
    Serial.begin(38400);
    Serial.println("MAX86150 Basic Readings Example");

    // Initialize sensor
    if (max86150Sensor.begin(Wire, I2C_SPEED_FAST) == false)
    {
        Serial.println("MAX86150 was not found. Please check wiring/power. ");
        while (1);
    }

    //Setup to sense a nice looking saw tooth on the plotter
    byte ledBrightness = 255; //Options: 0=Off to 255=50mA
    byte sampleAverage = 1; //Options: 1, 2, 4, 8, 16, 32
    byte ledMode = 2; //Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
    int sampleRate = 50; //Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
    int pulseWidth = 69; //Options: 69, 118, 215, 411
    int adcRange = 2048; //Options: 2048, 4096, 8192, 16384
  
    max86150Sensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange); //Configure sensor with these settings

    //Setup LED register (0x00 0mA, 0xFF 100mA)
//    max86150Sensor.writeRegister8(0x5E,0x11,0xFF);
//    max86150Sensor.writeRegister8(0x5E,0x12,0xFF);

/*
//-----------------------------------------------------------------

    Serial.println("Read");  
    Serial.println(max86150Sensor.readRegister8(0x5E,0x11));
    Serial.println(max86150Sensor.readRegister8(0x5E,0x12));
    delay(1000);  
    Serial.println("OK");

    delay(1000);  
    Serial.println("Write");
    max86150Sensor.writeRegister8(0x5E,0x11,0x00);
    max86150Sensor.writeRegister8(0x5E,0x12,0x00);
    delay(1000);  
    Serial.println("OK");

    Serial.println("Read");  
    Serial.println(max86150Sensor.readRegister8(0x5E,0x11));
    Serial.println(max86150Sensor.readRegister8(0x5E,0x12));
    delay(1000);  
    Serial.println("OK");

//-----------------------------------------------------------------
*/  

    //Display show...
    // initialize with the I2C addr 0x3C
    Serial.print("Initializing...Display");
    if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { // Address 0x3D for 128x64
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
    }
      
    // Clear the buffer.
    display.clearDisplay();
    display.setTextSize(2);
  
      // Display "8WA - ECG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("ECG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.display();
      delay(1000);
  
      // Display "By Mic.Tsai - BU8"
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(73,45); display.println("Engineer:");
      display.setCursor(80,55); display.println("Mic.Tsai");
      display.display();
      delay(1000);

      Serial.println("OK!");

      display.clearDisplay();
      display.display();


// ########################

  // Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Init ESP-NOW
  if (esp_now_init() != 0) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Once ESPNow is successfully Init, we will register for Send CB to
  // get the status of Trasnmitted packet
  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(OnDataSent);
  
  // Register peer
  esp_now_add_peer(broadcastAddress, ESP_NOW_ROLE_SLAVE, 1, NULL, 0);

// ########################


      
}

void loop()
{
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  // Status change

  buttonState = digitalRead(buttonPin);

  if (buttonState != lastButtonState) {
    if (buttonState == HIGH) {
      buttonPushCounter++;
    }
    delay(100);
  } 
  lastButtonState = buttonState;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if (buttonPushCounter > 11) {
    buttonPushCounter = 0;
  }
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//>>>>>>>>>>>>>>>>>>>>>>>> Mode 0 >>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>  Plot Demo = TIME + ECG + PPG >>>>>>>>>>>>>>>
  if (buttonPushCounter == 0) {

      display.clearDisplay();

      // Display "8WA - ECG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("ECG/PPG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(2,55); display.println("Ploting...");

      // Mode Demo
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(90,5); display.println("Demo");
      display.display();
      delay(100); 

      buttonPushCounter++;
  }

  if (buttonPushCounter == 1) {

    ECG();
    Filter_Value = Filter();
    
    ppgunsigned16 = (uint16_t) (max86150Sensor.getFIFORed()>>2);
    Filter_Value2 = Filter2();

    Serial.print(millis());
    Serial.print(",");
    Serial.print(ecgsigned16 - Filter_Value);
    Serial.print(",");
    Serial.print(ppgunsigned16 - Filter_Value2);
    Serial.println(",");


// ########################

    // Set values to send
    myData.a = ecgsigned16;
    myData.b = Filter_Value;
    myData.c = ppgunsigned16;
    myData.d = Filter_Value2;

    // Send message via ESP-NOW
    esp_now_send(broadcastAddress, (uint8_t *) &myData, sizeof(myData));
  
// ########################

  }

  if (buttonPushCounter == 2) {

      display.clearDisplay();

      // Display "8WA - ECG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("ECG/PPG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(2,55); display.println("Ploting...");

      // Mode Demo
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(90,5); display.println("Demo2");
      display.display();
      delay(100); 

      buttonPushCounter++;
  } 
        
  if (buttonPushCounter == 3) {

    ECG();
    Filter_Value = Filter();
    
    ppgunsigned16 = (uint16_t) (max86150Sensor.getFIFORed()>>2);
    Filter_Value2 = Filter2();

    Serial.print(ecgsigned16 - Filter_Value);
    Serial.print(",");
    Serial.println(ppgunsigned16 - Filter_Value2);
    
 //   Serial.print(ecgsigned16 - Filter_Value);
 //   Serial.print(",");
 //   Serial.println(ppgunsigned16 - Filter_Value2);
  }

  if (buttonPushCounter == 4) {

      display.clearDisplay();

      // Display "8WA - ECG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("ECG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(2,55); display.println("Ploting...");

      // Mode Demo
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(60,5); display.println("Raw ECG");
      display.display();
      delay(100); 

      buttonPushCounter++;
  } 
          
//>>>>>>>>>>>>>>>>>>>>>>>> Mode 2 >>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>  Raw ECG >>>>>>>>>>>>>>>>>>>>>>>>>>

  if (buttonPushCounter == 5) {
    ECG();
    Filter_Value = Filter();
    ppgunsigned16 = (uint16_t) (max86150Sensor.getFIFORed()>>2);
    Serial.print(ecgsigned16);
    Serial.print(",");
    Serial.println(Filter_Value);  
        PlotShow();
  }
  
   if (buttonPushCounter == 6) {

      display.clearDisplay();

      // Display "8WA - ECG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("ECG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(2,55); display.println("Ploting...");

      // Mode Demo
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(60,5); display.println("Filter ECG");
      display.display();
      delay(100); 

      buttonPushCounter++;
   }

//>>>>>>>>>>>>>>>>>>>>>>>> Mode 3 >>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>  Filter ECG >>>>>>>>>>>>>>>>>>>>>>>>>>

  if (buttonPushCounter == 7) {
    
    ECG();
    ECGFilter();
    PlotShow();
  }
  
  if (buttonPushCounter == 8) {

      display.clearDisplay();

      // Display "8WA - ECG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("PPG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(2,55); display.println("Ploting...");

      // Mode Demo
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(60,5); display.println("Raw PPG");
      display.display();
      delay(100); 

      buttonPushCounter++;
   }

//>>>>>>>>>>>>>>>>>>>>>>>> Mode 4 >>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>  Raw PPG >>>>>>>>>>>>>>>>>>>>>>>>>>>

   if (buttonPushCounter == 9) {

    ECG();
    Filter_Value = Filter();
    ppgunsigned16 = (uint16_t) (max86150Sensor.getFIFORed()>>2);
    Filter_Value2 = Filter2(); 
    Serial.print(ppgunsigned16);
    Serial.print(",");
    Serial.println(Filter_Value2); 
    PlotShow();
   }

  if (buttonPushCounter == 10) {

      display.clearDisplay();

      // Display "8WA - PPG"
      display.setTextSize(2); display.setTextColor(WHITE); display.setCursor(0,0); display.println("PPG");
      display.setTextSize(1); display.setCursor(0,20); display.println("ECG Health Senser_v1");
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(2,55); display.println("Ploting...");

      // Mode Demo
      display.setTextSize(1); display.setTextColor(WHITE); 
      display.setCursor(60,5); display.println("Filter PPG");
      display.display();
      delay(100); 

      buttonPushCounter++;
  }

//>>>>>>>>>>>>>>>>>>>>>>>> Mode 3 >>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>  Filter PPG >>>>>>>>>>>>>>>>>>>>>>>>>>

  if (buttonPushCounter == 11) {

    ECG();
    Filter_Value = Filter();
    ppgunsigned16 = (uint16_t) (max86150Sensor.getFIFORed()>>2);
    Filter_Value2 = Filter2();
    Serial.println(ppgunsigned16 - Filter_Value2);
    PlotShow();
  }

}
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>> Get ECG Data >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
void ECG()
{ 
      ecgsigned16 = (int16_t) (max86150Sensor.getECG()>>2);
}
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>> Get ECG Data >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>> Get PPG Data >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
void PPG()
{ 
     ppgunsigned16 = (uint16_t) (max86150Sensor.getFIFORed()>>2);
}
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>> Get PPG Data >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
void ECGFilter()
{ 
    Filter_Value = Filter();
    Serial.println(ecgsigned16 - Filter_Value); 
}
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>> Plot Timer Check  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
void PlotShow()
{
    TimerNow = millis();
    Time = TimerNow - TimerLast;
    
    if (Time < 42)
    {
      display.writeFillRect(0,53,60,20,BLACK);
      
          if (buttonPushCounter == 0) {
          display.writeFillRect(0,40,60,10,BLACK);
          }
          
      display.display();
    } 
    if (Time < 5000 && Time > 4950)
    {
      display.writeFillRect(0,53,60,20,WHITE);
      display.setTextSize(1); display.setTextColor(BLACK); 
      display.setCursor(2,55); display.println("Ploting...");
      
          if (buttonPushCounter == 0) {
          display.writeFillRect(0,40,40,10,WHITE);
          display.setTextSize(1); display.setTextColor(BLACK); 
          display.setCursor(2,42); display.println("Filter");
          }

      
      display.display();
    }    
    if (Time > 10000)
    {
      display.writeFillRect(0,53,60,20,BLACK);

          if (buttonPushCounter == 0) {
          display.writeFillRect(0,40,60,10,BLACK);
          }
      
      display.display();
      TimerLast = TimerNow;
    }
    //  Serial.print("   , "); 
    //  Serial.println(Time); 
}   
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>> Plot Timer Check  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


// ecg data in
int Get_AD() {
  return ecgsigned16;
}

// 一階滯後濾波法
#define FILTER_A 0.01
int Filter() {
  int NewValue;
  NewValue = Get_AD();
  Value = (int)((float)NewValue * FILTER_A + (1.0 - FILTER_A) * (float)Value);
  return Value;
}

//>>>>>>>>>>>>>>>>>>>>>>>>>>>> PPG  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// ecg data in
int Get_AD2() {
  return ppgunsigned16;
}

// 一階滯後濾波法
#define FILTER_A2 0.01
int Filter2() {
  int NewValue2;
  NewValue2 = Get_AD2();
  Value2 = (int)((float)NewValue2 * FILTER_A2 + (1.0 - FILTER_A2) * (float)Value2);
  return Value2;
}

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
