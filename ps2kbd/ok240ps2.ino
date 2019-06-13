#include <PS2KeyAdvanced.h>
#include <PS2KeyMap.h>
#include <PS2KeyData.h>

const int DataPin = 4;
const int IRQpin =  3;
const byte ACKpin = 2;
const int nSTB = 5;

PS2KeyAdvanced keyboard;
PS2KeyMap keymap;


void setup() {

  Serial.begin( 115200 );
  
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
  
  // Disable Break codes (key release) from PS2KeyAdvanced
  keyboard.setNoBreak (1);
  
  // and set no repeat on CTRL, ALT, SHIFT, GUI while outputting
  keyboard.setNoRepeat( 1 );

  // Typematic rate (0x1f = 2 CPS) and delay (in 0.25s increments)
  keyboard.typematic (0x10, 0);

  // Reset
  Reset ();
}

void Reset () {
  digitalWrite (A0, LOW);
  delay (1);
  digitalWrite (A0, HIGH);  
}


void loop() {


  if (keyboard.available()) {
    
    // read the next key
    int code = keyboard.read();

    Serial.println (code, HEX);
    
    int c = keymap.remapKey(code);
  
    Serial.println (c, HEX);

    Serial.print ("\n");


    if (((c & 0xff) == PS2_DELETE) && (c & PS2_ALT) && (c & PS2_CTRL)) {
    /*if (c == 0x287f) {  */
      Serial.println ("Reset!");
      Reset ();
    };
    
   
      

      /* Remap certain codes */      
      switch (code) {
        case 0x115: c = 8; break;      /* Left */
        case 0x116: c = 0x18; break;   /* Right */
        case 0x117: c = 0x19; break;   /* Up */
        case 0x118: c = 0x1a; break;   /* Down */
        default:
          break;
      }
      
      Serial.println (c, HEX);

      if ((c > 0) && (c < 0x100)) {
      
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
}


void ClearSTB () {
    // Strobe high
    digitalWrite (nSTB, HIGH);
  
}
