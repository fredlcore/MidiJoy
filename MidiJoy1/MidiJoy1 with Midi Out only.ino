// A8MidiJoy
// Atari 8-Bit Music Interface Teensy / Teensyduino Code
// based on A8F for 2600 by Sebastian Tomczak (little-scale)
// adapted for Atari 8-bit by Frederik Holst (2014)
// Version for PCB layout 1.0 (with optional Midi Out connector)
// http://www.phobotron.de/midijoy_en

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

MIDI_CREATE_DEFAULT_INSTANCE(); // required for MIDI library versions 4.2 and above

// Setup
void setup() {
  
  Serial.begin(38400);

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

  DDRB = ~((data & 15) | ((voice & 2) << 6));
  DDRF = ~(((data & 48) >> 4) | ((data & 192) >> 2) | ((voice & 1) << 6));

  delayMicroseconds(dT);

}
