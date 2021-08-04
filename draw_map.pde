

import processing.serial.*;

Serial myPort;    // The serial port


float I_length = 0;
float I_angle = -radians(90);


float A_length = 1.8;
float A_angle = radians(0);

float D_length = 0;
float D_angle = radians(90);

float mine_radius = 15;
float mine_distance = 10;

int D_cnt = 0;
int I_cnt = 0;

color red = color(255, 0, 0);
color green = color(0, 255, 0);
color blue = color(0, 0, 255);

float startPointX;
float startPointY;

int direction;
int buffer_length = 20;
byte [] map_info = new byte [buffer_length];
boolean update = false;

void setup() {
  // List all the available serial ports:
  printArray(Serial.list());
  // Open the port you are using at the rate you want:
  myPort = new Serial(this, "/dev/tty.Explorer2-ESP32SPP", 115200);//Serial.list()[7]
  myPort.buffer(buffer_length);
  size(800, 900);
  startPointX = width/2;
  startPointY = height*0.6;
  background(255);
  stroke(0);
  strokeWeight(2);
  translate(startPointX, startPointY);
  pushMatrix();
}

void draw() {
  if (update) {
    for (int i = 0; i<buffer_length; i++) {
      draw_map_info(map_info[i] & 0xff);
    }
    update = false;
  }
}

void serialEvent(Serial p) {
  p.readBytes(map_info);
  update = true;
}


void keyPressed() {
  if (key == ENTER) {
    background(255);
    resetMatrix();
    translate(startPointX, startPointY);
    pushMatrix();
  }
}

void draw_map_info(int info) {
  switch(info) {
  case 'D': 
    D_cnt ++;
    I_cnt = 0;
    if (D_cnt >=10){
      draw_segment(D_length, D_angle);
      D_cnt = -100;
    }
    break;
  case 'A': 
    D_cnt = 0;
    I_cnt = 0;
    draw_segment(A_length, A_angle);
    break;
  case 'I': 
    I_cnt ++;
    D_cnt = 0;
    if (I_cnt >=1){
      draw_segment(I_length, I_angle);
      I_cnt = -100;
    }
    break;
  case 'R':
    popMatrix();
    draw_mine(red);
    pushMatrix();
    break;
  case 'G':
    popMatrix();
    draw_mine(green);
    pushMatrix();
    break;
  case 'B': 
    popMatrix();
    draw_mine(blue);
    pushMatrix();
    break;
  default:
    break;
  }
}

void draw_segment(float len, float angle) {
  popMatrix();
  rotate(angle);
  line(0, 0, 0, -len);
  translate(0, -len);
  pushMatrix();
}

void draw_mine(color c) {
  fill(c);
  strokeWeight(1);
  circle(mine_distance, 0, mine_radius);
  strokeWeight(2);
}
