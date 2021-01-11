// A8MidiJoy
// Atari 8-Bit Music Interface Teensy / Teensyduino Code
// based on A8F for 2600 by Sebastian Tomczak (little-scale)
// adapted for Atari 8-bit by Frederik Holst (2014)
// http://www.phobotron.de/midijoy_en.html

/* Atari 8-Bit and Teensy Hardware Setup: 

Atari Player 1 Pin 1 ---> Teensy Port B0 (digital pin 0)
Atari Player 1 Pin 2 ---> Teensy Port B1 (digital pin 1)
Atari Player 1 Pin 3 ---> Teensy Port B2 (digital pin 2)
Atari Player 1 Pin 4 ---> Teensy Port B3 (digital pin 3)
Atari Player 1 Pin 6 ---> Teensy Port B7 (digital pin 4)
Atari Player 1 Pin 8 ---> Teensy Ground

Atari Player 2 Pin 1 ---> Teensy Port F4 (digital pin 19)
Atari Player 2 Pin 2 ---> Teensy Port F5 (digital pin 18)
Atari Player 2 Pin 3 ---> Teensy Port F6 (digital pin 17)
Atari Player 2 Pin 4 ---> Teensy Port F7 (digital pin 16)
Atari Player 2 Pin 6 ---> Teensy Port B6 (digital pin 15)
For future use: Atari Player 2 Pin 9 ---> Teensy Port D0 (digital pin 5)

OPTIONAL:

Connect a "classic" serial MIDI I/O-board to Teensy Port D2 (RXD, digital pin 7)
and D3 (TXD, digital pin 8) respectively in order to connect older MIDI devices.
Schematics can be found here:
https://www.pjrc.com/teensy/td_libs_MIDI.html

*/

#include <MIDI.h>

byte data; // general working byte for serially-received data

byte channel;
byte pitch; 
byte velocity;

int dT = 3000; // delay time for write cycles in microseconds

int voice[] = {255,255,255,255};
int vcount = 0;
int maxvoice = 4; // maximum number of simultaneous voices on the 8-Bit (Atari: 4, C64: 3)
int startchannel = 1; // first MIDI channel to be used - increase this by [maxvoice] if you use more than one interface
const int ledPin = 11;

MIDI_CREATE_DEFAULT_INSTANCE(); // required for MIDI library versions 4.2 and above

// Setup
void setup() {
  
  Serial.begin(38400);

  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, HIGH);

  PORTB = B00000000;
  PORTF = B00000000;
    
  MIDI.begin(MIDI_CHANNEL_OMNI);
  MIDI.setHandleNoteOn(doNote);
  MIDI.setHandleNoteOff(doNoteOff);

  usbMIDI.setHandleNoteOn(doNote); 
  usbMIDI.setHandleNoteOff(doNoteOff); 

}


// Main Program
void loop() {
  MIDI.read();
  usbMIDI.read(); 
}


// Functions
void doNote(byte channel, byte pitch, byte velocity) {

  if (channel > startchannel) {
    vcount = channel-startchannel;
    voice[vcount] = pitch;
  } else {
    for (int x=0;x<=(maxvoice-1);x++) {
      if (voice[x] == 255) {
        vcount = x;
        voice[vcount] = pitch;
        break;
      }
    } 
  }

  writeatari(B00000000 | pitch, vcount);
  writeatari(B10000000 | velocity / 8, vcount);

}

void doNoteOff(byte channel, byte pitch, byte velocity) {

  if (channel > startchannel) {
    vcount = channel-startchannel;
    voice[vcount] = 255;
  } else {
    for (int x=(maxvoice-1);x>=0;x--) {
      if (voice[x] == pitch) {
        vcount = x;
        voice[vcount] = 255;
        break;
      }
    } 
  }

  writeatari(B10000000, vcount);

}

// WRITING DATA TO THE ATARI

void writeatari(int data, int voice) {

  digitalWrite(ledPin, HIGH);

  DDRB = ~((data & 15) | (voice << 6));
  DDRF = ~(data);

  delayMicroseconds(dT);

  digitalWrite(ledPin, LOW);

}
