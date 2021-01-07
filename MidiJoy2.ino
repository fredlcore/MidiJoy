// A8MidiJoy
// Atari 8-Bit Music Interface Teensy / Teensyduino Code
// based on A8F for 2600 by Sebastian Tomczak (little-scale)
// adapted for Atari 8-bit by Frederik Holst (2014)
// http://www.phobotron.de/midijoy_en.html

/* Atari 8-Bit and Teensy Hardware Setup: 

Atari Player 1 Pin 1 (Up)    ---> Teensy Port B0 (digital pin 0)
Atari Player 1 Pin 2 (Down)  ---> Teensy Port B1 (digital pin 1)
Atari Player 1 Pin 3 (Left)  ---> Teensy Port B2 (digital pin 2)
Atari Player 1 Pin 4 (Right) ---> Teensy Port B3 (digital pin 3)
Atari Player 1 Pin 6 (Fire)  ---> Teensy Port B7 (digital pin 4)
Atari Player 1 Pin 8 (GND)   ---> Teensy Ground

Atari Player 2 Pin 1 (Up)    ---> Teensy Port F4 (digital pin 19)
Atari Player 2 Pin 2 (Down)  ---> Teensy Port F5 (digital pin 18)
Atari Player 2 Pin 3 (Left)  ---> Teensy Port F6 (digital pin 17)
Atari Player 2 Pin 4 (Right) ---> Teensy Port F7 (digital pin 16)
Atari Player 2 Pin 6 (Fire)  ---> Teensy Port B6 (digital pin 15)

OPTIONAL:

Connect a "classic" serial MIDI I/O-board to Teensy Port D2 (RXD, digital pin 7)
and D3 (TXD, digital pin 8) respectively in order to connect older MIDI devices.
Schematics can be found here:
https://www.pjrc.com/teensy/td_libs_MIDI.html

*/

#include <MIDI.h>
// #define DEBUG 1

#define POKEY(x) (x+0)
#define SID(x) (x+16)
#define PSG(x) (x+22)

// define which MIDI channel should be mapped to which soundchip (multiple soundchips only work with PokeyMax extension on ATARI computers)
// POKEYs shoudl come first and have to come first when envelopes are to be used.
int MIDImap[] = {
  SID(0),
  SID(1),
  SID(2),
  SID(3),
  SID(4),
  SID(5),
  PSG(6),
  PSG(7),
  PSG(8),
  PSG(9),
  PSG(10),
  PSG(11),
  POKEY(12),
  POKEY(13),
  POKEY(14),
  POKEY(15)
};

byte data; // general working byte for serially-received data

byte channel;
byte pitch; 
byte velocity;

int dT = 1000; // delay time for write cycles in microseconds

int voice[] = {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255};
int vcount = 0;
int maxvoice = 16; // maximum number of simultaneous voices on the 8-Bit (Atari: 4, C64: 3, PokeyMax: 16)
int startchannel = 1; // first MIDI channel to be used - increase this by [maxvoice] if you use more than one interface
const int ledPin = 11;
const int F7 = 16;

MIDI_CREATE_DEFAULT_INSTANCE(); // required for MIDI library versions 4.2 and above

// Setup
void setup() {
  
#ifdef DEBUG
  Serial.begin(38400);
#endif

  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, HIGH);

  PORTB = B00000000;
  PORTF = B10000000;

  MIDI.begin(MIDI_CHANNEL_OMNI);
  MIDI.setHandleNoteOn(doNote);
  MIDI.setHandleNoteOff(doNoteOff);
  MIDI.setHandlePitchBend(doPitchBend);

  usbMIDI.setHandleNoteOn(doNote); 
  usbMIDI.setHandleNoteOff(doNoteOff);
  usbMIDI.setHandlePitchChange(doPitchBend);
}


// Main Program
void loop() {
  MIDI.read();
  usbMIDI.read(); 
}


// Functions

void doPitchBend(byte channel, int pitch_value) {
  uint8_t pitch_bend = (pitch_value >> 7) & 0x7f;
  writeatari(pitch_bend, 3);
#ifdef DEBUG
  Serial.println(pitch_bend);
#endif
}

void doNote(byte channel, byte pitch, byte velocity) {
#ifdef DEBUG
  if (velocity == 0) {
    Serial.println("ALERT: Note Off via Note On and 0 velocity not supported!");
  }
#endif
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

#ifdef DEBUG
  Serial.print("Voice on: ");
  Serial.println(MIDImap[vcount]);
#endif

  writeatari(MIDImap[vcount] | ((vcount & 12) << 3), 0);
  writeatari(((velocity / 8) | ((vcount & 3) << 4)), 1);
  writeatari(pitch, 2);
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

#ifdef DEBUG
  Serial.print("Voice off: ");
  Serial.println(MIDImap[vcount]);
#endif

  writeatari(MIDImap[vcount] | ((vcount & 12) << 3) , 0);
  writeatari(((vcount & 3) << 4), 1);
  writeatari(pitch, 2);
}

// WRITING DATA TO THE ATARI

void writeatari(uint8_t data, int msg_counter) {

  unsigned long timeout = millis();
  boolean written = false;

  digitalWrite(ledPin, HIGH);
  while (millis() - 1000 < timeout && written == false) {
    if (PINF & 0x80) {        // Is F7 set to high from the Atari?
      DDRF = ((~data) & 112);
      DDRB = ~((data & 15) | (msg_counter << 6));
      written = true;
    }
  }

  if (written == false) {
#ifdef DEBUG
    Serial.println("Message dropped:");
    Serial.println(msg_counter);
    Serial.println(data);
#endif 
  } else {
    while (millis() - 1000 < timeout && (PINF & 0x80)) {}
  }
  digitalWrite(ledPin, LOW);
}
