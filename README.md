<IMG SRC="MidiJoy Logo.png" ALIGN=RIGHT>
<h1>MidiJoy - Using your Atari 800, C64 or VCS 2600 as a Chiptune-instrument</h1>
<p>
<H2><B>Contents</B></H2>
<P>
<UL>
<B>
<LI><A HREF="#Disclaimer">Disclaimer</A>
<LI><A HREF="#WhatIs">What is MidiJoy?</A>
<LI><A HREF="#WhatIsNot">What is MidiJoy NOT?</A>
<LI><A HREF="#GettingIt">Getting and supporting MidiJoy</A>
<LI><A HREF="#Demo">Atari Demo / Examples</A>
<LI><A HREF="#Breadboard">Setting up the interface - non soldering</A>
<LI><A HREF="#PCB">Setting up the interface - Printed Circuit Board 
(PCB)</A>
<LI><A HREF="#Teensy">Flashing the Teensy microcontroller</A>
<LI><A HREF="#Connecting">Connecting the interface</A>
<LI><A HREF="#MidiJoyAtari">Using MidiJoy on the Atari</A>
<UL>
<LI><A HREF="#ADSR">ADSR/Distortion Envelopes</A>
<LI><A HREF="#Recording">Recording format</A>
<LI><A HREF="#Playback">Playback</A>
</UL>
<LI><A HREF="#MidiJoyC64">Using MidiJoy on a C64</A>
<LI><A HREF="#MidiJoyVCS">Using MidiJoy on a VCS 2600</A>
<LI><A HREF="#OtherSystems">Using MidiJoy on other systems / sample code</A>
<LI><A HREF="#Samples">Playing digi-samples</A>
<LI><A HREF="#FAQ">Troubleshooting / Frequently Asked Questions</A>
<LI><A HREF="#Contact">Questions? Comments? Suggestions?</A>
</UL>
</B>
<P>
<H2><B><A NAME="Disclaimer">Disclaimer</B></H2>
<P>
Both the MidiJoy software as well as the interface are a hobby of 
mine. While great care has been taken to ensure that this project allows 
you to enjoy making music with your home computer or console, there is no 
guarantee that the software or the hardware design is free of flaws and 
errors. Therefore, using the software and/or the device is at your own 
risk and I shall not be liable to any damage that might happen in 
conjunction with the software and/or the device.
<P>
Having said that, I now hope you'll enjoy MidiJoy as much as I do :-)!
<P>
<A NAME="WhatIs">
<H2><B>What is MidiJoy?</B></H2>
<P>
MidiJoy is a software/interface combination that allows you to use your 
Atari or Commodore homecomputer as a musical instrument. The idea is based 
on the
<A HREF="http://little-scale.blogspot.de/2013/03/how-to-make-atari-2600-midi-music.html">Atari 
2600-PC-Interface</A> created by Sebastian Tomczak and was expanded 
to suit the extended capabilities of the 8-Bit homecomputers.<BR>
The interface part emulates a USB-Midi (serial Midi is optional) device 
that can be accessed by any kind of instrument as well as sequencer 
software on a PC or Mac that can output Midi data (e.g. Ableton Live or Aria 
Maestosa).
The MidiJoy software receives these data from the interface via the 
joystick ports and plays them on the POKEY (or SID or TIA) sound-chip. In 
contrast to most SIO-based Midi interfaces, a  MidiJoy-driven Atari can 
bei used as a live instrument in real time with  up to four sound 
channels simultaneously. At the same time, all POKEY parameters (AUDCTL, 
AUDC1-4) can be changed on-the-fly fly as well as activation of ADSR 
envelopes. Music input can be recorded and saved to disk for later usage 
- even in your own programs/games.<BR>
For limitations of the Commodore and VCS 2600 version please see the info 
at the bottom of this page.
<p>
The source code for the Teensy microcontroller (an Arduino offspring) on 
the interface is available as open source as the basic idea is based on 
Sebastian Tomczak's interface. 
The adapted code is very simple and just converts incoming Midi 
data into bit combinations that are sent to the Atari or C64 via its 
joystick ports. The MidiJoy software on the Atari/C64 end then plays the 
incoming notes live.<BR>
On the Atari, MidiJoy makes full use of the 
capabilities of the POKEY sound chip and thus partly extends the features 
of the Atari 2600-interface: Instead of just two voices with a 32-pitch range of 
the TIA, MidiJoy enables you to make full use of four voices spanning four 
octaves. Two 16-bit channels are also possible, and with corresponding 
POKEY frequencies, a much larger range of sounds can be created. The 
playback of samples - such as with the original interface - is on the 
development roadmap of MidiJoy. 
<P>
<A NAME="WhatIsNot">
<H2><B>What is MidiJoy NOT?</B></H2>
<P>
The device has some limitations due to the fact that I want it to run on 
several 8-Bit systems and thus have to make some compromises:
<UL>
<LI>Due to the limited input pins available on standard joysticks, there 
can only be 10 bits of data transmitted at the same time (for each port 4 
directions and 1 fire button). This requires limiting data to max. 4 
voices (2 bit), volume and pitch differentiation (1 bit) and 127 note 
values (7 bit). Stuffing more information into these bit is simply not 
possible unless I would break compatibility with common joystick port 
design.
<LI>For the same reason, it is not possible to transmit more Midi 
information than pitch and volume, including their respective data values. 
Therefore, complex Midi CC messages, pitch bend in cents or 
controlling other aspects of the sound chip etc. cannot be realized via 
Midi messages but would have to be incorporated in the MidiJoy software 
and controlled from the computer keyboard (as the MidiJoy software for 
the Atari does).
<LI>The MidiJoy software also does not support playback of samples due to 
the reasons stated above. However, it is possible to use the device itself 
with the firmware of Sebastian Tomczak which needs to be modified 
slightly. Then not only his VCS 2600 player can be used, but also two 
adaptations I wrote for the Atari XL/XE as well as the C64. Continue
<A HREF="#Samples">here</A> if this is what you are looking for.
<LI>In case you are disappointed now about the features of MidiJoy, you 
might be interested in 
<A HREF="http://www.instructables.com/id/Dual-POKEY-Synth/?ALLSTEPS">this 
project</A> which directly plays on the soundchips of the Atari, C64, 
VCS2600 etc. However, bear in mind that you need to obtain these 
soundchips first, it does not work straight away with your computer, 
unlike MidiJoy.
</UL>
<P>
<A NAME="GettingIt">
<H2><B>Getting and supporting MidiJoy</B></H2>
<p>
<I>The MidiJoy software is available free of charge</I>. Just send me 
e-mail with your system (Atari or C64) to me ("midijoy (&auml;t) 
phobotron dot de") in order to receive your personal copy in ATR/PRG 
format. It will be sent to you via e-mail in and you need to be able to 
transfer it to the computer you want to use it with, for example with a 
SD2IEC (C64) or SIO2SD (Atari) interface.<BR>
Details for assembling the hardware interface can be found 
below. Currently (yes, that still applies in 2019 ;) ), I still have a few 
prototypes left from developing 
which I would give away for material costs. Contact me if you are 
interested.<P>

If you like MidiJoy and would like to support my work, how about buying me a 
drink? Or a meal? Or a drink and a meal :)?<BR>
Doing so is easy via PayPal, just click on the link below and send 4,99 &euro; 
if you want to buy me a drink or 9,99 &euro; if you want to buy me a 
meal. Those who treat me both will receive a personalized copy of MidiJoy 
with a name or text of their choice shown in MidiJoy's user interface :).

<form action="https://www.paypal.com/cgi-bin/webscr" method="post" 
target="_top">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="9YV6FH3QZXJK8">
<input type="image" 
src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" 
border="0" name="submit" alt="PayPal - The safer, easier way to pay 
online!">
<img alt="" border="0" 
src="https://www.paypalobjects.com/de_DE/i/scr/pixel.gif" width="1" 
height="1">
</form>

<!-- <B>ABBUC Hardware Contest</B>
<P>MidiJoy participates in this year's ABBUC hardware contest. The 
rules of this contest state that no part of the contribution can be published
before the end of the contest, i.e. October 2014.<BR>
Help support MidiJoy by voting for it in the ABBUC contest if you are a 
member - should MidiJoy make it to the Top 3, I will make it available for 
free afterwards :-)!
//-->
<BR>
<P>
<A NAME="Demo">
<B>Atari Demo / Examples</B><BR>
(for a C64 demo video please scroll to the bottom of this page)
<P>
This <A HREF="MidiJoyDemo.atr">disk image</A> contains three Atari recordings 
(FSUITE.EXE, FUGUE.EXE and ESTHER.EXE) which demonstrate the playback 
capabilities in the background using VBI. In addition, there is 
ESTHENV.EXE which is the same as ESTHER.EXE but using custom ADSR 
envelopes (see below).<BR>
For those who do not have a real Atari or an emulator at hand there are 
recordings available in MP3 format 
(<A HREF="FSuite.mp3">FSuite.mp3</A>, <A HREF="Fugue.mp3">Fugue.mp3</A>,
<A HREF="Esther.mp3">Esther.mp3</A> and <A HREF="EsthEnv.mp3">EsthEnv.mp3</A>).
<BR>
Imagine creating complex tracks like these on your Atari within just a few 
minutes and no sound programming experience!
<P>
These two videos demonstrate the use of MidiJoy on an Atari 800XL 
(the first one was recorded at an early stage of development with not all 
currently implemented features visible):
<P>
<object width="560" height="315"><param name="movie" value="//www.youtube.com/v/8PfGtNIwVJE?version=3&amp;hl=de_DE&amp;rel=0"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="//www.youtube.com/v/8PfGtNIwVJE?version=3&amp;hl=de_DE&amp;rel=0" type="application/x-shockwave-flash" width="560" height="315" allowscriptaccess="always" allowfullscreen="true"></embed></object>
<object width="560" height="315"><param name="movie" value="//www.youtube.com/v/Q483aN9JE-E?version=3&amp;hl=de_DE&amp;rel=0"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="//www.youtube.com/v/Q483aN9JE-E?version=3&amp;hl=de_DE&amp;rel=0" type="application/x-shockwave-flash" width="560" height="315" allowscriptaccess="always" allowfullscreen="true"></embed></object>
<P>
<A NAME="Breadboard">
<H2><B>Setting up the interface - non soldering</B></H2>
<P>
<B><U>CAUTION!</U></B> Joystick ports carry a relatively small but 
potentially damaging 5V current on one of the pins. Connecting the pins in 
a wrong way may potentially damage your home computer, the MidiJoy device 
and/or any other connected equipment. It is also generally safest to cold 
start the computer before attaching the device.
<P>
Due to the more powerful soundchips in the Atari (POKEY) and Commodore 
(SID) compared to the 2600's TIA, the setup of the orignal interface - for 
which all credits go to Sebastian Tomczak - as well as the Teensy code 
need to be adjusted in a few ways in order to use them on these home 
computers. The following images show the design and wiring used by 
MidiJoy:
<P>
<A HREF="InterfaceFullSize.jpg"><IMG SRC="InterfaceFullSize_small.jpg"></A>
<A HREF="InterfaceHalfSize.jpg"><IMG SRC="InterfaceHalfSize_small.jpg"></A>
<A HREF="InterfaceWithSerialMidi.jpg"><IMG SRC="InterfaceWithSerialMidi_small.jpg"></A>
<A HREF="InterfaceConnected.jpg"><IMG SRC="InterfaceConnected_small.jpg"></A>
<A HREF="MidiJoyC64.jpg"><IMG SRC="MidiJoyC64_small.jpg"></A><BR>
<small>(Click images to enlarge in a new window)</small>
<P>
This setup also has the advantage that the interface can be assembled 
without any soldering or using old joystick cables.<BR> 
To do so, one needs:
<UL>
<LI>	A <A HREF="https://www.pjrc.com/store/teensy_pins.html">Teensy 2.0 Board with pin-header</A> (in Germany available at <A HREF="http://www.watterott.com/de/Teensy-USB-Board-v20-ATMEGA32U4-mit-Pins">Watterott</A>)
<LI>	Two <A HREF="http://www.kooing.com/index.php?route=product/product&path=20_26&product_id=55">DB-9 
breakout boards (f)</A> for breadboard use
<LI>	One full-size breadboard (search at Ebay or Amazon for 
"full-size breadboard"; half-size or smaller would work as well, 
but then you would either need the DB-9 extension cables mentiond below 
or use DB-9 connectors for soldering)
<LI>	11 jumper wires (m/m) for connecting the Breadboard and the 
DB-9 ports (search at Ebay or Amazon for "jumper wires" and make sure they 
are male/male)
<LI>	Optional: two fully patched DB-9 extension cables (m/f) in case 
you don't want to plug the DB-9 connectors right into your Atari (see 
second image above)
</UL>
<P>
You might also use DB-9 ports which require the cables to be soldered (as 
in the video above). These are usually cheaper than the plug-in ones for 
breadboards and might offer more flexibility (at the cost of less stability)
when plugging the connectors into you Atari or Commodore.
<P>
When all parts are obtained, simply plug the Teensy board as well as 
the DB-9 breakout boards into the breadboard. If you use a full-size 
breadboard, make sure that the DB-9 ports are in the right distance so 
they fit into the computer's joystick ports. In that case you would also 
have to remove the shoulder screws for the ports to fit in.<BR>
Once this is done you only need to connect the pins of the Teensy board to 
the DB-9-connectors. The images above give you a good indication, but 
make sure you double-check the exact pins as the perspective in the 
images can be misleading. You can find the mapping in the description 
at the beginning of the <A HREF="A8MidiJoy.ino">source code</A>.
<P>
Pins 7 and 8 (D2 and D3) on the Teensy board are optional and can be used 
to connect a "classic" serial Midi board, the schematics can be found
<A HREF="https://www.pjrc.com/teensy/td_libs_MIDI.html">here</A>.
When installed (see third image above) you could use both USB- as well as 
serial Midi devices at the same time.
<P>
<A NAME="PCB">
<H2><B>Setting up the interface - Printed Circuit Board (PCB)</B></H2>
<P>
<A HREF="MidiJoyPCB.jpg"><IMG SRC="MidiJoyPCB_small.jpg"></A>
<P>
The interface can also be set up as a standalone circuit. This has the 
advantage that the design already includes the necessary wirings for a 
"classical" serial MIDI input connector. Also, if you remove the 
metal screws from the joystick port connectors on the device, the board 
fits directly into the original C64 as well as the C64C - the Atari 
connectors are unfortunately too far apart for such a small design.
<P>
<B><U>CAUTION!</U></B> Joystick ports carry a relatively small but 
potentially damaging 5V current on one of the pins. Connecting the pins in 
a wrong way may potentially damage your home computer, the MidiJoy device 
and/or any other connected equipment. It is also generally safest to cold 
start the computer before attaching the device.
<P>
You can find the Gerber files for manufacturing the printed circuit board 
(PCB) <A HREF="MidiJoyGerber.zip">here</A> - they are for private, 
non-commercial use only. The board layout contains 
descriptions where each part should be placed.<BR>
Currently, I still have a few prototypes left from developing 
which I would give away for material costs. Contact me if you are 
interested.<P>
For populating the PCB, you need the following items if you just want 
to use USB-Midi:<BR>
<UL>
<LI>1 <A HREF="https://www.pjrc.com/store/teensy_pins.html">Teensy 2.0 
Board with pin-header</A> (in Germany available at <A HREF="http://www.watterott.com/de/Teensy-USB-Board-v20-ATMEGA32U4-mit-Pins">Watterott</A>)
<LI>1 IC socket, 24 pins (15.24mm raster size)
<LI>2 female DB9 (D-Sub) connectors for PCB
<LI>2 joystick extension cords or 2 fully patched DB-9 extension cables 
(m/f), unless you use an (original) C64 where the device fits directly 
into the computer once you remove the metal screws from the DB9-connectors
</UL>
If you want to add serial Midi functionality as well, you need to add the 
following:
<UL>
<LI>1 planar epitaxial diode 1N 4148
<LI>1 optocoupler 6N 138
<LI>1 IC socket, 8 pins (raster size 7.62mm)
<LI>1 female MIDI connector for PCB (for example MABPM 5S)
<LI>1 resistor 220
<LI>1 resistor 1.2k
<LI>1 resistor 5.6k
</UL>
For German customers, a list of all necessary parts can be found 
<A HREF="https://secure.reichelt.de/index.html?&ACTION=20&AWKID=991808&PROVID=2084">here</A>
at reichelt.de.
<p>
<B><U>CAUTION!</U></B> On the PCB you can find a location for a Schottky 
diode (1N 5817) right below the first joystick port connector. This is for powering 
the device from the current that the joystick port supplies.<BR>
<U>DO NOT</U> use this diode if you connect the device via USB as this 
could seriously damage your PC. This diode is only useful if you use serial 
("classic") Midi input only, for example if you want to connect a 
Midi-keyboard directly to the Atari/C64.<BR>
If you want to use both USB- and serial Midi, you have to either prepare 
the Teensy or the USB-cable you use to connect the Teensy. Instructions 
how to do this can be found <A 
HREF="https://www.pjrc.com/teensy/external_power.html">here</A>.

<P> 
<A NAME="Teensy">
<H2><B>Flashing the Teensy microcontroller</B></H2>
<p>
After the interface is fully assembled, perform the following steps:<P>
<UL>
<LI>Download and install the 
<A HREF="http://www.arduino.cc/en/Main/Software">Arduino development environment</A>
<LI>Download and install the
<A HREF="http://www.pjrc.com/teensy/td_download.html">Teensyduino</A> 
extension (when asked which libraries to install, either select "all" or 
at least "MIDI")
<LI>(Please take not that when updating the Arduino IDE at a later stage 
to make sure you also update the Teensyduino extension seperately as the 
latter has to include support for the former)
<LI>Start Arduino and configure it in the "Tools" section as 
follows: <PRE>Board -> Teensy 2.0 | USB Type -> MIDI</PRE>
<LI>Create a new sketch (<I>File -> New</I>) and paste the <A 
HREF="source.html">source code</A> into it
<LI>Connect the interface via USB and press the "Upload"-button (right 
arrow) to flash the code into the interface (You might be asked to press 
the little reset button on the Teensy board)
<LI>In case your computer does not recognize the Teensy as a new Midi 
device, unplug the interface and restart your computer.
</UL>
Once this is done, the interface should be detected by the Midi sequencer 
software on the Mac/PC. For simply playing via your keyboard or Midi 
playback, <A HREF="http://ariamaestosa.sourceforge.net/">Aria Maestosa</A> 
is a great free program for Windows, Mac and Linux. For more complex 
tasks, Ableton Live is a powerful alternative. See <A 
HREF="AbletonLiveConfig.jpg">here</A> for a sample configuration of Ableton Live.<BR>
<p>
<A NAME="Connecting">
<H2><B>Connecting the interface</B></H2>
<P>
Depending on the way you assembled the interface and what homecomputer you 
are using it with, there are several ways to connect each component:
<UL>
<LI>PCB versions of the interface fit directly into a C64, otherwise 
you need to get extension cables as mentioned above to connect the 
interface with your homecomputer.
<LI>You can connect a keyboard with serial Midi-Out connector directly to 
the interface's Midi-In connector (in case you have a PCB version or added 
one to the do-it-yourself version). The interface still needs to be powered 
via USB or the joystick ports (see caution note above!).
<LI>If your keyboard only has a USB port, you'll have to use a sequencer 
software (see previous section), connect your keyboard to your PC/Mac 
via USB and configure the sequencer softwar to use the keyboard as Midi 
input.
<LI>When working with a sequencer on your PC/Mac, you can connect to the 
interface either via USB or serial Midi using the corresponding connectors 
on the interface. Configure the Midi output settings of your sequencer 
software accordingly to use the Teensy (for USB connections) or the name of 
your Midi interface (for connecting to MidiJoy's Midi connector).
</UL>
<p>
<A NAME="MidiJoyAtari">
<H2><B>Using MidiJoy on the Atari</B></H2>
<P>
<img src="MidiJoy.jpg">
<p>
When you have connected the interface to both the Mac/PC and the Atari 
has booted into MidiJoy, you are ready to play music on your Atari by 
sending Midi notes from the Mac/PC to the interface, a simple equalizer 
will give you visible feedback as well.<BR>
All incoming data will be adjusted correctly to the Atari note table and 
then played immediately. As far as possible, proper scales are used also 
in distortion modes 2 and 12. Pressing the SPACE key switches between two 
different scales in mode 12. 
<P>
Incoming Midi data is expected on Midi channel 1 to 4. These are then 
played through the corresponding sound channels on the Atari. Midi channel 
1 is special: here, up to four voices are being split up automatically to 
unused sound channels on the Atari. This enables playing multi-chords with 
up to four voices in real time, for example via a Midi keyboard connected 
to the Mac/PC. Five or more voices will overwrite the last used channel.
<P>
You may use your own ADSR envelopes (see details below) during live 
playback by activating one of them by pressing keys 1 to 8. Envelope data 
needs to be loaded prior to starting MidiJoy (e.g. via DOS).
<P>
Keys O to I control the eight bits of the AUDCTL register. This enables 
making live use of all POKEY features such as filters, 16-bit voices or 
frequency changes. Like with sound programming in general, only certain 
combinations make sense. For example, it is advisable to set POKEY's 
frequency to 1.77 MHz (bits 5 and 6) when using 16-bit voices (bits 3 and 
4 respectively).
<P>
Individual channels can use different distortions (AUDC1-4). These can be 
set using keys A to D, F to H, Z to C and V to N. The status of each bit 
is displayed on the screen.
<P>
The tabulator key starts and stops the recording mode. Pressing RETURN 
resets all recordings, for example to start anew.<BR>
While recording, all incoming note data is saved to RAM and can then be 
played back using the P key (after recording is stopped). A counter 
displays the memory area used by the recording. This area can afterwards 
be saved for later use by jumping into DOS (J key) and use the "Save 
Binary File" function there. 
This of course requires that MidiJoy has been started with DOS in the 
background - simply booting the executable from a game DOS or SD-card will 
not allow you to save your recordings!
<P>
Take note that when you enter recording more, also the silence until the 
first note value comes in is recorded. So if you press TAB and only then 
start to boot your Mac/PC, you'll have a long(er) silence at the 
beginning when you later start to play the recording.
<p>
<A NAME="ADSR">
<H3><B>ADSR/Distortion Envelopes</B></H3>
<P>
MidiJoy supports ADSR (Attack/Decay/Sustain/Release) and 
distortion envelopes both for live performance as well as for playback. 
In order to allow for maximum flexibility, envelope data can be loaded on 
a case-by-case basis and can also be exchanged with other users of 
MidiJoy.<P>

An envelope data block consists of 256 bytes ($00 to $FF) which can be used 
in variying proportions for the ADS- as well as the Release-phases of 
each voice and also modify the distortion. Each byte modifies the volume 
for 1/50 second (1/60 on NTSC machines) and consists of two components: 
Bits 0 to 3 modify the volume for that time-frame and Bits 5-7 set the 
distortion. Any distiortion other than zero will override the general 
distortion set for this channel as long as the envelope is active. The 
other way round this means that if the distortion bits 5 to 7 are not set 
(only volume bits 0 to 3 are used), the standard distortion for this 
channel is used.<P>

ADSR notation differs between ADS and Release phase: ADS values range from 
0 to 15 and <I>reduce</I> the note's volume, i.e. a value of zero leaves 
the volume unchanged whereas a value of 15 will always silence it. In the 
Release phase it is the other way round: values here will be added to 
zero (although not exceeding the last volume value), i.e. a value of zero 
is silence and anything above will result in the voice still being played 
/ faded out.
<P>
An envelope file (see <A HREF="envelope.txt">here</A> for a sample 
structure) has to start at $4F00 and begins with four index/offset bytes 
pointing to the start of the ADSR/distortion-data for each voice. These 
four bytes are followed by a fifth byte indicating the position after the 
end of the fourth voice's Release-phase.<BR>
Actual envelope-data begins with a status byte containing the length of 
the subsequent ADS-phase, followed by the ADS-envelope data. The last byte 
here is special: it indicates whether the sustain phase should be repeated 
from an earlier position onwards which is useful if you want to create a 
vibrato and keep it going indefinitely as long as the key is being 
pressed.<BR>
To do that, this byte contains the number of bytes the envelope 
counter should 'rewind'. A zero means the volume will remain at its last 
level, otherwise the counter will be set back by the number specified 
here. Take note to count this 'rewind' byte into the status byte as 
well.<BR>
Following the 'rewind' byte is the Release-phase data up to the beginning 
of the next voice's ADSR-data.
<P> 
In order to use ADSR/distortion envelopes you simply need to load a file 
containing the envelope data in the prescribed format to address $4F00 
prior to launching MidiJoy or one of the playback programs. The 
separation between note data and envelope data allows you to record music 
and add or change the ADSR envelope at a later stage, giving you all the 
flexibility you need.<BR>
If you want to use multiple envelopes during live performances, there are 
eight slots available from $3400...$34FF up to $4B00...$4BFF where 
envelope data can be stored and selected during playback with keys 1 to 8.<BR>
<P>
The MidiJoy disk contains DEMO.MJE that demonstrates the use of four 
different envelopes and the demo disk above contains ESTHENV.EXE which is 
the same track as ESTHER.EXE but with four different ADSR envelopes 
added.<P>
Commodore users do not need this functionality as the SID chip can be set 
up for ADSR envelopes with just a few pokes prior to launching MidiJoy. 
<p> 
<A NAME="Recording">
<H3><B>Recording format</B></H3>
<P>
The recording format is kept very simple and consists of five bytes per 
incoming Midi data:
<UL>
<LI>Byte 00: Sound channel on the Atari
<LI>Byte 01: AUDCx value (distortion und volume)
<LI>Byte 02: Frequency (AUDFx)
<LI>Byte 03: Duration until note is played in 1/50th seconds (low-byte)
<LI>Byte 04: Duration until note is played in 1/50th seconds (high-byte)
</UL>
<P>
Tracks with many simultaneous notes which are played very quickly 
therefore create a much larger memory footprint than fewer, longer notes. 
If no note (or pause) is longer than five seconds, then the high-byte can 
be omitted when parsing the recorded file. Similarly, when distortion is 
always the same, the sound channel and the volume could be written into 
four bits each. Both changes would require changes in the playback 
routine, but would also almost reduce the amount of data by half.
<p>
ADSR envelope data is not part of the recording, but ADSR envelope files 
can be loadad prior to playback.
<p>
<A NAME="Playback">
<H3><B>Playback</B></H3>
<P>
Two small playback routines in assembler will be available for free, one 
for <A HREF="MJPVBI.asm.txt">playback using VBI</A> (as in the demo disk 
above) and one <A HREF="MJPlayer.asm.txt">without using 
interrupts</A>. Both can be accessed from BASIC as well. They are less than 
256 bytes in size and thus fit nicely into page six for example.<BR>
You can play the songs from the demo disk in BASIC as well, simply boot 
into DOS with BASIC enabled, load the .EXE file and jump back into BASIC. 
In BASIC you can start playback with 
<pre>X=USR(1536,20480,40000)</pre>
(in your own songs, the second and third parameter must match the note 
data RAM area as displayed in MidiJoy). To stop/pause simply enter
<pre>POKE 207,0:FOR X=0 TO 3:SOUND X,0,0,0:NEXT X</pre>
and continue playing with
<pre>POKE 207,1</pre>
<p>
A third playback routine has <A HREF="MJPEnv.asm.txt">ADSR envelope 
playback enabled</A>. As it is too 
large for storing it in Page 6, it is generally advisable to use it in 
machine language programs only. 
<P>
<A NAME="MidiJoyC64">
<H2><B>Using MidiJoy on a C64</B></H2>
<P>
Due to the similar design of the joystick ports in the Atari and the C64, the 
interface can be used without any modifications in hard- or firmware on 
the arch rival as well (and probably on any other computer that supports 
Atari-style joysticks). If you use the PCB version, the device even 
fits directly into the C64 if you remove the metal screws from the 
DB9-connectors!
<BR>
Having never written any program for the Commodore 
before, my small proof-of-concept conversion only covers the product's 
main feature: live playback. And this works quite well, as the 
following demo video shows (first version shown here, for current user 
interface see newer demo video  on the right):
<P>
<object width="560" height="315"><param name="movie" 
value="//www.youtube.com/v/tyt6FRv0RXc?hl=de_DE&amp;version=3&amp;rel=0"></param><param 
name="allowFullScreen" value="true"></param><param 
name="allowscriptaccess" value="always"></param><embed 
src="//www.youtube.com/v/tyt6FRv0RXc?hl=de_DE&amp;version=3&amp;rel=0" 
type="application/x-shockwave-flash" width="560" height="315" 
allowscriptaccess="always" allowfullscreen="true"></embed></object> 
<object width="560" height="315"><param name="movie" 
value="//www.youtube.com/v/nYBQy-TMExs?hl=de_DE&amp;version=3&amp;rel=0"></param><param 
name="allowFullScreen" value="true"></param><param 
name="allowscriptaccess" value="always"></param><embed 
src="//www.youtube.com/v/nYBQy-TMExs?hl=de_DE&amp;version=3&amp;rel=0" 
type="application/x-shockwave-flash" width="560" height="315" 
allowscriptaccess="always" allowfullscreen="true"></embed></object> 
<!--
<IMG SRC="MidiJoyC64Screenshot.jpg" HEIGHT=315>
//-->
<P>
On the Commodore, incoming Midi data is expected on Midi channels 1 to 3. 
These are then played through the corresponding sound channels on the 
C64. Midi channel 1 again is special: here, up to three voices are being 
split up automatically to unused sound channels on the Commodore. This 
enables playing multi-chords in real time, as with the Atari, albeit only 
up to three voices. Four or more voices will overwrite the last used 
channel. 
<P>
Despite the limited user interface of the program itself, one can of 
course initialize the SID sound chip prior to launching MidiJoy (by 
entering or loading a program that POKEs the desired values into the 
corresponding registers). This makes it still possible to use almost all 
the features SID has to offer - one just cannot change them while MidiJoy 
is running. If you make use of that approach, make sure you choose "No" 
when asked at startup whether SID's registers should be cleared.<BR>
Since the wave form is reset within MidiJoy, use addresses 251 to 253 for 
POKEing the desired waveform to be used during playback. Otherwise (or if 
MidiJoy is told to clear the SID registers prior to start) a default value 
of 17 (triangle) is set for all voices.<BR>
You may press "Q" to quit the program and restart it with "RUN", for 
example if you want to POKE different SID values for different playback.
<P>
<A NAME="MidiJoyVCS">
<H2><B>Using MidiJoy on the Atari VCS 2600</B></H2>
<P>
Using the same firmware above, the VCS can be used to play its 
internal sounds and distortions. The source code can be found 
<A HREF="MJ2600.asm.txt">here</A> as well as a 
<A HREF="MJ2600.bin">pre-compiled binary</A> for use with a Harmony 
cartridge. However, this approach is limited to the (heavily reduced) 
scale of the VCS.<BR>
Due to the irregular tonal system of the VCS which does not correspond to 
our common chromatic scales, MidiJoy for the VCS consists of only one 
octave that is mapped to all the 10+ octaves of the Midi standard. Even 
within this one octave there are notes which are "off" and this cannot be 
prevented.<BR>
However, using the VCS with MidiJoy might still be interesting for 
musicians who would like to make use of the various sound effects / 
distortions built into the VCS. Just change the distortion value in the 
source code to something else and enable the alternative note table, 
compile and you are good to go.
<P> 
<P>For playing back pre-recorded digi-samples on the VCS, see another 
option <A HREF="#Samples">below</A>.
<p>
<A NAME="OtherSystems">
<H2><B>Using MidiJoy on other systems / sample code</B></H2>
<P>
So far, the MidiJoy software is available for the Atari and C64 
homecomputer families. However, due to the design of the interface, it is 
relatively easy to adapt the software for other systems as well - as long 
as they have two standard 9-pin joystick connectors. So how about using a 
VIC-20, an Atari ST or Amiga in your setup?
<P>
Providing basic functionality for use with the interface is relatively 
easy and consists of just a few steps:
<OL>
<LI>Initialize the sound chip for playback
<LI>Read trigger buttons from joystick ports 1 and 2 (port numbers refer to 
connectors on the MidiJoy interface and may not correspond with the port 
numbers on the computer)
<UL>
<LI>Button values contain the sound channel to be used for the subsequent 
command
<LI>Button 1 is bit 1 of the channel value, button 2 is bit 0, i.e. 4 
sound channels can be addressed.
</UL>
<LI>Read direction pins from joystick ports 1 and 2 
<UL>
<LI>If pin 1 ('Right') is active on joystick port 2 of the MidiJoy 
interface, the other direction pins ('Right', 'Left', 'Down', 'Up' each, 
i.e. pins 2 to 4 on port 2 as well as pins 1 to 4 on port 1) are volume data, 
otherwise (if pin 1 is not active), the other direction pins contain 
pitch data.
<LI>On the Atari, for example, you would get these data bits in the 
right order by reading the PORTA register.
<LI>On the C64, you would read $dc00 first, move the lower four bits to 
the upper four bits and then add $dc01's lower four bits.
</UL>
<LI>Proceed depending on whether the data just read was pitch or volume data:
<UL>
<LI>In case of volume data: Set the sound channel's volume based on the 
data just read (sound data will only be four bits, i.e. 0 to 15).
<LI>In case of pitch data: Values range from 0 to 127 and 
correspond to Midi note data. Therefore, a table lookup needs to be 
made to read the corresponding value(s) the soundchip requires in 
order to play that note.
</UL>
<LI>Repeat from step 2.
</OL>
<P>
The source code for a  minimal example for the Atari 8-Bit can be found <A 
HREF="MidiJoySample.asm.txt">here</A>.<BR>
It should be easy to adapt to other systems, even non-6502 compatible
processors. If feasible, sound chip specific functions as well as other 
functions (such as saving data etc.) can then be added, too. <BR>
Due to the fast transmission of data through the interface, such a program 
would have to be written in assemlby language in order to provide 
satisfying results. Should you have written a port for a different system, 
I'd be happy to link to your website or host the file here on mine.
<p>
<A NAME="Samples">
<H2><B>Playing digi-samples</B></H2>
<P>
In order to use the MidiJoy interface to play of digi-samples on your old 
computers/consoles via Midi instruments or sequencers, you 
can make use of the firmware for the Teensy developed by Sebastian 
Tomczak. His firmware can be used to play pre-recorded samples 
on the Atari VCS 2600, the Atari XL/XE as well as the C64 in the typical 
4-bit sample sound. 
More information can be found on his <A 
HREF="http://little-scale.blogspot.de/2013/03/how-to-make-atari-2600-midi-music.html">project 
website</A>.<BR>
Here's a little demo showing playback on an Atari 800 XL (works likewise 
on a C64 or VCS 2600) using the simple playback software that can be 
downloaded in source as well as binary below. Take note of the change of 
playback speed of the last sample, all these parameters can be controlled 
directly from your Midi keyboard or sequencer:
<P>
<object width="560" height="315"><param name="movie" 
value="//www.youtube.com/v/qOZ4FaymSZY?hl=de_DE&amp;version=3&amp;rel=0"></param><param 
name="allowFullScreen" value="true"></param><param 
name="allowscriptaccess" value="always"></param><embed 
src="//www.youtube.com/v/qOZ4FaymSZY?hl=de_DE&amp;version=3&amp;rel=0" 
type="application/x-shockwave-flash" width="560" height="315" 
allowscriptaccess="always" allowfullscreen="true"></embed></object> 
<P>
To make his firmware work with the MidiJoy device, first download 
his
<A 
HREF="http://little-scale.com/A26F/A26F_100/A26F_Teensy_100.ino">firmware</A>.
In the firmware code you need to just change the 
following four lines (which also make connecting the interface to the VCS 
more secure as no voltage runs from the interface to the VCS):
<UL>
<LI>Replace<BR>
<PRE>DDRB = B00001111;
DDRD = B00001111;
</PRE>
with
<PRE>PORTB = B00000000;
PORTF = B00000000;
</PRE>
<LI>and
<PRE>PORTB = data >> 4;
PORTD = data & B00001111; 
</PRE>
with
<PRE>DDRB = ~(data >> 4);
DDRF = ~(data << 4);
</PRE>
</UL>
<P>
Then, download one of the following versions for your device and 
copy/install it on your homecomputer/console:
<UL>
<LI>VCS 2600: The
<A HREF="http://little-scale.com/A26F/A26F_100/A26F_100_ROM.bin">binary</A> 
can be downloaded from Sebastian Tomczak's website.
<LI>Atari XL/XE: The <A HREF="MJSPBA800.asm.txt">source 
code</A> as well as the <A HREF="MJSPBA800.xex">binary</A> were adapted by 
me for the Atari 8-Bit, based on Sebastian's VCS 2600 version.
<LI>C64: Likewise, the <A HREF="MJSPBC64.asm.txt">source code</A> as well 
as the <A HREF="MJSPBC64.prg">binary</A> are also my adaptations based on 
Sebastian's approach.
</UL>
Details how to play and modify the samples from your Midi device or 
sequencer can be found on Sebastian's website.<BR>
Do not forget to re-flash the Teensy with the MidiJoy firmware above once 
you want to use it with MidiJoy again!
<P>
<A NAME="FAQ">
<H2><B>Troubleshooting / Frequently Asked Questions</B></H2>
<P>
<LI><B>I hear some notes playing, but they are out of tone or just varying 
in volume</B>
<UL>
<LI>This is either due to the joystick cables not being connected 
correctly (joystick port 1 goes to the port facing the user, on the VCS it 
is the right port), or some of the pins are not connected correctly with 
the Teensy board. Use a digital meter to check if everything is correctly 
wired/connected.
</UL>
<LI><B>Sometimes the MidiJoy software keeps playing the 
last note continuously although I stopped playback.</B>
<UL>
<LI>This happens if the stop sequence of the playback did not send a 
proper "Note Off" Midi message (or it wasn't received properly). The 
MidiJoy software plays a note until a  "Note Off" message is received. If, 
for example, you just quit your playback program rather than stopping 
playback, or if you unplug the device, the software won't know when to 
stop playback. To fix this, restart playback on all channels and 
stop it properly. If that does not help, unplug and reinsert the device 
and then resume playback.
</UL>
<LI><B>My device is no longer accessible / recognized as a Teensy Midi device</B>
<UL>
<LI>This seldom happens and I haven't figured out completely what is 
the cause for this. It seems to be that when the device is not 
disconnected at the right time, for example when there was still playback 
going on, the Teensy "crashes". To fix this, just re-flash the firmware in 
the process outlined above and it'll be fine again.
</UL>
<LI><B>There seems to be a lag between pressing a note and actual playback 
on the computer?</B>
<UL>
<LI>There might be several reasons for this: For one, there is the typical 
latency of any MIDI device (seems to be worse on Windows than on Mac, if 
Iâ€™m not mistaken, although itâ€™s a bit better when using the ASIO drivers) 
which then results in such a delay between playing the note and recording 
it from the ATARI/C64.
<P>
The second thing is that the Teensy can only send one note at a time to 
the ATARI/C64. This is due to the fact that the joystick ports only offer 
10 lines and thus 10 bits of parallel communication. As it needs already 
7 bits for the pitch value (0-127) and another 2 bits for the channel 
value (0-3 on the Atari and 0-2 on the C64), it is not even possible to 
squeeze in the velocity value (0-15, i.e. 4 bits), let alone more than 
one note.<BR>
Because of this, each note played ist sent to the Atari/C 64 in two steps 
with a 0.3ms delay. This should usually not be noticable, but if you play 
a chord of four notes at the same time, each note is transferred to the 
computer with a 0.3ms delay between pitch and velocity like this:
<PRE>
t+0: 		note 1: pitch + channel data
t+0.3ms		note 1: velocity + channel data
t+0.6ms		note 2: pitch + channel data
t+0.9ms		note 2: velocity + channel data
t+1.2ms		note 3: pitch + channel data
t+1.5ms		note 3: velocity + channel data
t+1.8ms		note 4: pitch + channel data
t+2.1ms		note 4: velocity + channel data
t+2.4ms		transmission of chord finished
</PRE>
There is unfortunately no way to prevent this because contrary to the 
proper MIDI protocol, the joystick ports to not have a fixed (and faster) 
transmission rate, let alone a transmission protocol which would work in 
the way of "Ok, I'm done already, no need to wait before you can send the 
send the next piece of data".<BR>
This is basically the price I had to pay for being able to realize the 
live playback option. If I had gone through the "proper" IO chip of the 
Atari - which is also the POKEY who does the sound - data transmission 
would have been more seamless, but direct playback of the received notes 
would not have been possible as the POKEY can do either data transmission 
or sound playback.
</UL>
</UL> 
<p>
<A NAME="Contact">
<H2><B>Questions? Comments? Suggestions?</B></H2>
<P>
There are two forum threads where I look forward to questions, comments 
and suggestions - one thread in English on 
<A HREF="http://atariage.com/forums/topic/229790-midijoy-using-your-atari-as-a-chiptune-instrument/">AtariAge</A>
and one in German in the
<A HREF="http://www.abbuc.de/community/forum/viewtopic.php?f=15&t=8154">ABBUC
forum</A>. Feel free to get in touch!
<P>
<HR>
<P>

