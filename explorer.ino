#include <analogWrite.h>
#define SIO_C 21
#define SIO_D 19
#define SIO_CLOCK_DELAY 100

#include "BluetoothSerial.h"

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

BluetoothSerial SerialBT;

byte Lectura; 
const int EchoRight = 27;//
const int TriggerRight = 14;//
const int EchoFront = 13;//
const int TriggerFront = 12;//
int PinIN3 = 32;
int PinIN4 = 33;
int ENB = 22;
int PinIN1 = 25;
int PinIN2 = 26;
int ENA = 23;
int state = 1;


const byte reset_registers [] = {0x12,0x80};     // Reset all registers

// FONDO BLANCO         //register addres , data
byte config_data [] = { 0x00, B11110000,   // GAIN: gain setting
                        0x01, 0x80,        // BLUE: blue gain for white balance
                        0x02, 0x80,        // RED: red gain for white balance
                        0x03, B01000011,   // VREF: gain setting
                        0x0F, B01000001,   // COM6: no reset timming when format changes??
                        0x11, B10011000,   // CLKRC: divide clk -> 1.5 fps
                        0x12, B00000100,   // COM7: RGB
                        0x13, B10001001,   // COM8: Disable automatic white balance and automatic gain
                        0x1E, B00110000,   // MVFP: verticla and horizontal flip
                        0x24, 0xf0,        // AEW: for setting exposure time, stabel upper limit
                        0x25, 0xdD,        // AEW: for setting exposure time, stabel lowwer limit
                        0x26, 0xFa,        // AEW: for setting exposure time, control zone
                        0x3E, B00010011,   // COM14: divide PCLK by 8
                        0x40, B10110000,   // COM15: output from [01] to [FE] and RGB555
                        0x70, B00101000,   // SCALING_XSC: scaling
                        0x71, B00101000,   // SCALING_YSC: scalinng
                        0x72, B00110011,   // SCALING_DCWCTR: down sampling by 8
                        0x73, B00000011,   // SCALING_PCLK_DIV: PCLK divide by 8
                        0x0C, B00001100,   // COM3: downsampling and zoom out eneble
                        0xA2, B00001001,   // SCALING_PCLK_DELAY: to fit number of pixels
                        0xB1, B00000100,   // ABLC1: enable black level calibration
                        0x6A, 0xCF,        // GGAIN: green gain for white balance
                        0x6F, B10011010,   // AWBCTR0: maximum color gain x2 
                        0x4F, 0x1A,        // MTX1  - colour conversion matrix
                        0x50, 0x44,        // MTX2  - colour conversion matrix
                        0x51, 0x62,        // MTX3  - colour conversion matrix
                        0x52, 0x42,        // MTX4  - colour conversion matrix
                        0x53, 0x40,        // MTX5  - colour conversion matrix
                        0x54, 0x00,        // MTX6  - colour conversion matrix
                        0x58, B10001100,   // MTXS  - Matrix sign and auto contrast
                        0x3D, 0xC0,        // COM13 - Turn on GAMMA and UV Auto adjust
                        0x3A, 0x04,        // TSLB   Set UV ordering,  do not auto-reset window
                        };



void setup() {
   Serial.begin(115200);
   SerialBT.begin("Explorer2"); //Bluetooth device name
   Serial.println("The device started, now you can pair it with bluetooth!");
   Serial.println("Start InitOV7670 test program");
   pinMode(TriggerRight, OUTPUT);
   pinMode(EchoRight, INPUT);
   pinMode(TriggerFront, OUTPUT);
   pinMode(EchoFront, INPUT);
   pinMode(PinIN1, OUTPUT);
   pinMode(PinIN2, OUTPUT);
   pinMode(PinIN3, OUTPUT);
   pinMode(PinIN4, OUTPUT);
   pinMode(ENA, OUTPUT);
   pinMode(ENB, OUTPUT);
   //delay(30000);

   if(InitOV7670())    
    Serial.println("InitOV7670 OK");
   else
    Serial.println("InitOV7670 NG");
   delay(5);

  for (int i = 0; i<sizeof(config_data); i = i+2){
    WriteOV7670(char(config_data[i]), char(config_data[i+1]));    
  }


   
}

void loop() {

   if(Serial.available()>0){
    Lectura=Serial.read();
    if (Lectura != 'N') SerialBT.write(Lectura);
   }
  
   int cmR = ping(TriggerRight, EchoRight);
   Serial.print("Distancia Derecha: ");
   Serial.println(cmR);
   int cmF = ping(TriggerFront, EchoFront);
   Serial.print("Distancia Frontal: ");
   Serial.println(cmF);

   switch (state) {
  case 1:
    if (cmF>35 && cmR>20 && cmR<30){
      state=2;
     break;
    }
    else if (cmR<=20 ){
      state=3;
    }
    else if (cmF<=35){
      state=4;
    }
    else if (cmR>=30){
      state=5;
    }
    break;
  case 2:
    Adelante();
    SerialBT.write('A');
    state=1;
    break;
  case 3:
    Izquierda_c();
    SerialBT.write('A');
    state=1;
    break;
  case 4:
    Izquierda();
    SerialBT.write('I');
    delay(800);
    state=1;
    break;
  case 5:
    Derecha();
    if(cmR > 45 && cmR < 200) { 
      SerialBT.write('D');
    }
    else {
      SerialBT.write('A');
    }
    state=1;
    break;
  default:
    Stop();
    break;
  }
}

int ping(int TriggerPin, int EchoPin) {
   long duration, distanceCm;
   
   digitalWrite(TriggerPin, LOW);  //para generar un pulso limpio ponemos a LOW 4us
   delayMicroseconds(4);
   digitalWrite(TriggerPin, HIGH);  //generamos Trigger (disparo) de 10us
   delayMicroseconds(10);
   digitalWrite(TriggerPin, LOW);
   
   duration = pulseIn(EchoPin, HIGH);  //medimos el tiempo entre pulsos, en microsegundos
   
   distanceCm = duration * 10 / 292/ 2;   //convertimos a distancia, en cm
   return distanceCm;
}


void Adelante()
{
  digitalWrite (PinIN1, LOW);
  digitalWrite (PinIN2, HIGH);
  digitalWrite (PinIN3, LOW);
  digitalWrite (PinIN4, HIGH);
  analogWrite (ENA, 255);
  analogWrite (ENB, 255);
}

void Derecha()
{
  digitalWrite (PinIN1, LOW);
  digitalWrite (PinIN2, HIGH);
  digitalWrite (PinIN3, LOW);
  digitalWrite (PinIN4, HIGH);
  analogWrite (ENA, 220);
  analogWrite (ENB, 255);
}

void Izquierda()
{
  digitalWrite (PinIN1, LOW);
  digitalWrite (PinIN2, HIGH);
  digitalWrite (PinIN3, LOW);
  digitalWrite (PinIN4, HIGH);
  analogWrite (ENA, 255);
  analogWrite (ENB, 0);
}
void Izquierda_c()
{
  digitalWrite (PinIN1, LOW);
  digitalWrite (PinIN2, HIGH);
  digitalWrite (PinIN3, LOW);
  digitalWrite (PinIN4, HIGH);
  analogWrite (ENA, 255);
  analogWrite (ENB, 220);
}

void Stop()
{
  digitalWrite (PinIN1, LOW);
  digitalWrite (PinIN2, LOW);
  digitalWrite (PinIN3, LOW);
  digitalWrite (PinIN4, LOW);
  analogWrite (ENA, 0);
  analogWrite (ENB, 0);
}
























//////////////////CAMARA CONFIGURATION AUXILIAR FUNCITIONS/////////////

void InitSCCB(void) //SCCB Initialization
{
  pinMode(SIO_C,OUTPUT);
  pinMode(SIO_D,OUTPUT);
  
  digitalWrite(SIO_C,HIGH);
  digitalWrite(SIO_D,HIGH);
  
  Serial.println("InitSCCB - Port Direction Set & Set High OK");
}
 
void StartSCCB(void) //SCCB Start
{
  Serial.println("StartSCCB");
 
  digitalWrite(SIO_D,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_D,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_C,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY);
}
 
void StopSCCB(void) //SCCB Stop
{
  //Serial.println("StopSCCB");
 
  digitalWrite(SIO_D,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_D,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
}
 
bool SCCBWrite(byte m_data)
{
  unsigned char j;
  bool success;

  for ( j = 0; j < 8; j++ ) //Loop transmit data 8 times
  {
    if( (m_data<<j) & 0x80 )
      digitalWrite(SIO_D,HIGH);
    else
      digitalWrite(SIO_D,LOW);
  
    delayMicroseconds(SIO_CLOCK_DELAY);
    
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
    
  digitalWrite(SIO_C,LOW);
    delayMicroseconds(SIO_CLOCK_DELAY);
  }
 

  
  pinMode(SIO_D,INPUT); // I pass a bus of SIO_D to slave (OV7670)
  digitalWrite(SIO_D,LOW); // Pull-up prevention  --this line is not present in embedded programmer lib
  delayMicroseconds(SIO_CLOCK_DELAY);
 
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
 
  
  if(digitalRead(SIO_D)==HIGH)
    success= false;
  else
    success= true; 

  digitalWrite(SIO_C,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY); 
  
  pinMode(SIO_D,OUTPUT); //Return the bus of SIO_D to master (Arduino)
  
  //delayMicroseconds(SIO_CLOCK_DELAY); 
  //digitalWrite(SIO_D,LOW);
  //delayMicroseconds(SIO_CLOCK_DELAY); 
 
  //pinMode(SIO_C,OUTPUT); //Return the bus of SIO_C to master (Arduino)
 
  return success;  
}
 
bool InitOV7670(void)
{
  char temp = 0x80;

  InitSCCB();
  
  if( ! WriteOV7670(0x12, temp) ) //Reset SCCB
  {
    Serial.println("Resetting SCCB Failed");
    return false;
  }

  return true; 
}  
 
////////////////////////////
//To write to the OV7660 register: 
// function Return value: Success = 1 failure = 0
bool WriteOV7670(char regID, char regDat)
{
  StartSCCB();
  if( ! SCCBWrite(0x42) )
  {
        Serial.println(" Write Error 0x42");
      StopSCCB();
    return false;
  }

  delayMicroseconds(SIO_CLOCK_DELAY);

    if( ! SCCBWrite(regID) )
  {
    StopSCCB();
    return false;
  }
  delayMicroseconds(SIO_CLOCK_DELAY);
    if( ! SCCBWrite(regDat) )
  {
    StopSCCB();
    return false;
  }
  
    StopSCCB();
    
    return true;
}
