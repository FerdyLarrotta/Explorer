import processing.serial.*;

Serial myPort;    // The serial port
byte [] image = new byte [8145];
int end_frame = 0xFF;      // frame end flag

float newWidth = 64;
float newHeight = 48;
float dx,dy;
boolean update = false;



void setup() {
  // List all the available serial ports:
  printArray(Serial.list());
  // Open the port you are using at the rate you want:
  myPort = new Serial(this,"/dev/tty.usbserial-A4030NL7", 230400);// Serial.list()[8]
  myPort.bufferUntil(end_frame);
  
  size(640, 480);
  dx = width/newWidth;
  dy = height/newHeight;
  background(0);
  noStroke();
}

void draw() {
  if (update){
    if (image!=null){
      display(image);
      update = false;
    }
  }
}

void serialEvent(Serial p) {
  p.readBytes(image);
  update = true;
}

void display(byte[] image) {
  
  int px = 0;
  int FB,SB,pixel_Data;
  float R,G,B;
  for (int i=0; i<newHeight; i++) {
    for (int j=0; j<newWidth; j++) {
      FB = image[px] & 0xff; 
      SB = image[px+1] & 0xff; 
      pixel_Data = (FB<<8) + SB;
      R = (pixel_Data>>10) & 0x0000001F;
      R = map(R,0,31,0,255);
      G = (pixel_Data>>5)  & 0x0000001F;
      G = map(G,0,31,0,255);
      B = (pixel_Data>>0)  & 0x0000001F;
      B = map(B,0,31,0,255);
      fill(R,G,B);
      rect(j*width/newWidth, i*height/newHeight, dx, dy);
      px += 2;
    }
  }
}
