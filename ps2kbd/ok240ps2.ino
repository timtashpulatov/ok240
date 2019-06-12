#include <PS2Keyboard.h>

const int DataPin = 4;
const int IRQpin =  3;
const byte ACKpin = 2;
const int nSTB = 5;

PS2Keyboard keyboard;


void setup() {
  
  // PD5 is low active out strobe
  pinMode (nSTB, OUTPUT);
  digitalWrite (nSTB, HIGH);


  // PD6, PD7 map to Ok240's PA6 and PA7
  pinMode (6, OUTPUT);
  pinMode (7, OUTPUT);


  // PB0-PB5 map to Ok240's PA0-PA5
  pinMode (8, OUTPUT);
  pinMode (9, OUTPUT);
  pinMode (10, OUTPUT);
  pinMode (11, OUTPUT);
  pinMode (12, OUTPUT);
  pinMode (13, OUTPUT);


  // PD2 ACK strobe from OK240's PC7
  pinMode(ACKpin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(ACKpin), ClearSTB, RISING);


  // A0 pin as nRESET output
  pinMode (A0, OUTPUT);
  digitalWrite (A0, HIGH);

  keyboard.begin (DataPin, IRQpin);

  // Reset
  digitalWrite (A0, LOW);
  delay (1);
  digitalWrite (A0, HIGH);
}


void loop() {


  if (keyboard.available()) {
    
    // read the next key
    char c = keyboard.read();
  
    if (c & 0x01) {digitalWrite (8, HIGH);} else {digitalWrite (8, LOW);}
    if (c & 0x02) {digitalWrite (9, HIGH);} else {digitalWrite (9, LOW);}
    if (c & 0x04) {digitalWrite (10, HIGH);} else {digitalWrite (10, LOW);}
    if (c & 0x08) {digitalWrite (11, HIGH);} else {digitalWrite (11, LOW);}
    if (c & 0x10) {digitalWrite (12, HIGH);} else {digitalWrite (12, LOW);}
    if (c & 0x20) {digitalWrite (13, HIGH);} else {digitalWrite (13, LOW);}


    if (c & 0x40) {digitalWrite (6, HIGH);} else {digitalWrite (6, LOW);}
    if (c & 0x80) {digitalWrite (7, HIGH);} else {digitalWrite (7, LOW);} // Probably not needed for OK240


  // Strobe low
    digitalWrite (nSTB, LOW);
  }
}


void ClearSTB () {
    // Strobe high
    digitalWrite (nSTB, HIGH);
  
}
