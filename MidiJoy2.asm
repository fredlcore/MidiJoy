;			MidiJoy (c) 2014 by Frederik Holst

			run start
			
			DOSVEC = $0a
			ATTRACT = $4d
			SDMCTL = $22f
			SDLSTL = $230
			CH = $2fc
			TRIG0 = $d010
			TRIG1 = $d011
			CONSOL = $d01F
			AUDF1 = $d200
			AUDC1 = $d201

			AUDCTL = $d208
			KBCODE = $d209
			PMCFG = $d20c
			SKCTL = $d20f
			PMCAP = $d211
			PSGMODE = $d215

			FREQ1 = $d240
			SQPW1 = $d243
			WAVE1 = $d244
			ATTDEC1 = $d245
			SUSTREL1 = $d246
			SIDVOLUME = $d258

			PSGFREQ = $d2a0
			PSGNFREQ = $d2a6
			PSGMIXER = $d2a7
			PSGVOL = $d2a8
			PSGEFREQ = $d2ab
			PSGESHP = $d2ad

			PORTA = $d300
			PACTL = $d302

			ADSRStart = $5f00
			ADSRTable = ADSRStart+17
;			ADSRTable = ADSRMax+4

			org $80

VOICE		.byte 0
CHANNEL		.byte 0
NOTE		.byte 0, 0
NOTETIMER	.word 0
NOTEPTR		.word $6000
TEMPPTR		.word 0
PLAYPTR		.word $6000
PLAYAUDC	.byte 0
PLAYNOTE	.byte 0
PLAYTIMER	.word 0
TIME		.byte 0
TEMP		.byte 0
TEMP2		.byte 0
MINUS
ACTL		.byte 0, 0, 0, 0
AC1			.byte $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0
SIDWAVE		.byte 32, 32, 32, 32, 32, 32
SIDAttack	.byte 0, 0, 0, 0, 0, 0
SIDDecay	.byte 0, 0, 0, 0, 0, 0
SIDRelease	.byte 0, 0, 0, 0, 0, 0
SIDSqPw		.byte 8, 8, 8, 8, 8, 8
PSGMix		.byte $38, $38
PSGEnvAct	.byte 0, 0, 0, 0, 0, 0
PSGEnvShape	.byte 0, 0
PSGEnvFqLo	.byte 0, 0
PSGEnvFqHi	.byte 0, 0
PSGNoise	.byte 0, 0
MSGSAVE		.byte $ff
PITCH		.byte 0
VELOCITY	.byte 0
PITCHBEND	.byte 0
D12FLAG		.byte 0
SXBITFLAG	.byte 0
RECFLAG		.byte 0
PLAYFLAG	.byte 0
PORTASAVE	.byte 128
VOICESAVE	.byte 255
ADSRVol		.byte 0
ADSRDist	.byte 0
ADSRTemp	.byte 0
POKEYOffset	.byte 0, 2, 4, 6, 16, 18, 20, 22, 32, 34, 36, 38, 48, 50, 52, 54
AUDCOffset	.byte 106, 117, 146, 157
;RelOffset	.byte Rel1-ADS1, Rel2-ADS2, Rel3-ADS3, Rel4-ADS4	; these can be adjusted if you need a longer release phase at the cost of shorter ADS phase
;RelMax		.byte ADS2-ADS1, ADS3-ADS2, ADS4-ADS3, ENDADSR-ADS4
EnvSrc		.word 0
EnvSelect	.byte 0
CHTemp		.byte 0
EquOffset	.word 0
PMDevice	.byte 0
PMConfig	.byte 0
ChipCount	.byte 1
ChipFlag	.byte 0

			org $3c00

DLIST		.byte $70, $70, $70, $42
ScreenMem	.word INTRO
			.byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
			.byte $41
		    .word DLIST

start

			lda PMCFG
			cmp #1
			bne setupDL
			lda #$3f
			sta PMCFG
			lda #101
			sta PSGMODE
			lda PMCAP
			sta PMConfig
			and #3			; number of POKEYs
			asl
			bne store
			lda #1
store		sta ChipCount
			lda #0
			sta PMCFG

setupDL		lda #<DLIST		; set up display list
			sta SDLSTL
			lda #>DLIST
			sta SDLSTL+1
			lda #%00100010
			sta SDMCTL

			lda #56
			sta PACTL
			lda #%10000000	; set all lines for input except Player 2 Right (port 2 pin 4)
			sta PORTA
			lda #60
			sta PACTL

			lda #0
			sta AUDCTL
			sta AUDCTL+$10
			sta AUDCTL+$20
			sta AUDCTL+$30
			lda #3
			sta SKCTL
			sta SKCTL+$10
			sta SKCTL+$20
			sta SKCTL+$30
			
			lda #15
			sta SIDVOLUME
			sta SIDVOLUME+$20

			ldy #<VBI		; set up VBI
			ldx #>VBI
			lda #6
			jsr $e45c

MainLoop	lda 20
			cmp TIME
			beq novbi
			sta TIME
			jsr playadsr
novbi		lda CONSOL		; test for OPTION and SELECT key
			cmp #3
			beq changeID
			cmp #5
			beq changeCore
checkkeys	lda CH
			sta CHTemp
			cmp #255
			bne jmpcheck
			jmp nokey
jmpcheck	jmp checkinput

changeId	lda CONSOL
			and #4
			beq changeId	; wait for OPTION key to be released
			lda PMDevice
			clc
			adc #1
			cmp ChipCount	; rollover?
			bcc setId
			lda #0
setId		sta PMDevice
			clc
			adc #$11
			ldy #6			; Device number position for POKEY, will be different for other soundchips
			sta Device,y
			bne checkkeys	; always greater than 0, jump to checkkeys

changeCore	lda CONSOL		; wait for SELECT to be releasesd
			and #2
			beq changeCore
			lda #0
			sta PMDevice
			lda ChipFlag
			beq writeSID
			cmp #1
			beq writePSG
			cmp #2
			beq writePOKEY
;			bne checkkeys

writeSID	lda PMConfig
			and #4
			clc
			ror
			sta ChipCount
			ldy #6
nextchar1	lda SIDText,y
			sta Device,y
			dey
			bpl nextchar1
			ldy #119
SIDlines	lda SIDStats,y
			sta ConfigLines,y
			dey
			bpl SIDLines
			lda #1
			sta ChipFlag
			bne checkkeys
			lda #0
			ldy #39
CleanSID	sta ConfigLines+120,y
			dey
			bpl cleanSID

writePSG	lda PMConfig
			and #8
			clc
			ror
			ror
			sta ChipCount
			ldy #6
nextchar3	lda PSGText,y
			sta Device,y
			dey
			bpl nextchar3
			ldy #0
PSGlines	lda PSGStats,y
			sta ConfigLines,y
			iny
			cpy #132
			bne PSGlines
			lda #2
			sta ChipFlag
			bne jmpchkkeys

writePOKEY	lda PMConfig
			and #3
			asl
			sta ChipCount
			ldy #6
nextchar2	lda POKEYText,y
			sta Device,y
			dey
			bpl nextchar2
			ldy #79
Pokeylines	lda PokeyStats,y
			sta ConfigLines,y
			dey
			bpl PokeyLines
			lda #0
			sta ChipFlag
			lda #0
			ldy #79
CleanPOKEY	sta ConfigLines+80,y
			dey
			bpl cleanPOKEY
jmpchkkeys	jmp checkkeys

checkinput	lda #255
			sta CH

; Functions applicable to all soundchips go here...

exitdos		lda CHTemp
			cmp #$1C
			bne enter
			lda #255
			sta CHTemp
			jmp (DOSVEC)

enter		lda CHTemp
			cmp #$0C
			bne TestKeys
			lda #255
			sta CHTemp
			lda #0
			sta RECFLAG
			sta 712
			ldx #15
resetsound	lda POKEYoffset,x
			tay
			lda #0
			sta AUDC1,y
			dex
			bpl resetsound
;			lda #0
			sta NOTETIMER
			sta NOTETIMER+1
			sta NOTEPTR
			sta PLAYPTR
			lda #$60
			sta NOTEPTR+1
			sta PLAYPTR+1
			lda #"5"
			sta COUNTER
			lda #"F"
			sta COUNTER+1
			sta COUNTER+2
			sta COUNTER+3
			lda #0
			sta PITCHBEND
			lda #8				; unblock potential noise generator lockups on SID
			sta WAVE1
			sta WAVE1+$07
			sta WAVE1+$0E
			sta WAVE1+$20
			sta WAVE1+$27
			sta WAVE1+$2E
			lda #0
			sta WAVE1
			sta WAVE1+$07
			sta WAVE1+$0E
			sta WAVE1+$20
			sta WAVE1+$27
			sta WAVE1+$2E

			sta PSGVOL
			sta PSGVOL+1
			sta PSGVOL+2
			sta PSGVOL+16
			sta PSGVOL+17
			sta PSGVOL+18

TestKeys	lda ChipFlag
			beq PokeyKeys
			cmp #1
			beq jmpSIDKeys
			jmp PSGKeys
jmpSIDKeys	jmp SIDKeys

; Keys for POKEY functions go here...

PokeyKeys	ldx #7
nb1			lda AUDCTLKeys,x		; read AUDCTL-Keys (Q-Y)
			cmp CHTemp
			beq sb
			dex
			bpl nb1
			bmi audckey
sb			lda #255
			sta CHTemp
			lda AUDCTLVals,x
			ldy PMDevice
			eor ACTL,y
			sta ACTL,y

audckey		ldx #11					; read AUDC1-4 keys (A-H, Z-N)
nb2			lda ACKeys,x
			cmp CHTemp
			beq sb2
			dex
			bpl nb2
			bmi envkey
sb2			lda #255
			sta CHTemp
			lda PMDevice			; read device id
			asl						; multiply by four
			asl
			clc
			adc ACIndex,x			; add the index
			tay						; transfer to Y as final index to AC1
			lda ACVals,x
			eor AC1,y				; invert previous bit status
			sta AC1,y				; and store back

envkey		ldx #0					; read envelope keys (1-8)

nb3			lda EnvKeys,x
			cmp CHTemp
			beq sb3
			inx
			cpx #9
			bne nb3
			beq spacekey
sb3			lda #255
			sta CHTemp
			txa
			sta EnvSelect
			clc
			adc #$34
			sta EnvSrc+1
nextenv		lda (EnvSrc),y
			sta $5f00,y
			dey
			bne nextenv

			ldy #15
ClearADSR	lda #1
			sta ADSRC,y
			lda #0
			sta ADSRActive,y
			dey
			bpl ClearADSR
			
			ldy #0
nextbank	tya
			cmp EnvSelect
			clc
			bne contenv
			adc #128
contenv		adc #"1"
			sta EnvBank,y
			iny
			cpy #8
			bne nextbank

spacekey	lda CHTemp
			cmp #$21
			bne pauserec
			lda #255
			sta CHTemp
			lda D12FLAG
			eor #1
			sta D12FLAG

pauserec	lda CHTemp
			cmp #$2c
			bne playkey
			lda #255
			sta CHTemp
			lda RECFLAG
			eor #1
			sta RECFLAG
			asl
			asl
			asl
			asl
			asl
			sta 712

playkey		lda CHTemp
			cmp #$0a
			bne jmpnokey
			jmp playram
jmpnokey	jmp nokey

SIDKeys		ldx #11
readSIDWave	lda SIDWaveKeys,x
			cmp CHTemp
			beq SetSIDWave
			dex
			bpl readSIDWave
			bmi SIDAtt
SetSIDWave	jsr getSIDindex
			lda SIDWaveVals,x		; SIDWaveVals' index is 0 to 11
			eor SIDWAVE,y
			sta SIDWAVE,y
			dex
			bpl readSIDWave

SIDAtt		ldx #2
readSIDAtt	lda CHTemp
			cmp SIDAttKeys,x
			beq SetSIDAtt
			sec
			sbc #64
			cmp SIDAttKeys,x
			beq AttMinus
			dex
			bpl readSIDAtt
			bmi SIDDec
AttMinus	lda #0
SetSIDAtt	sta MINUS
			jsr getregindex		; index is in Y
			lda SIDAttack,y
			jsr storereg
			sta SIDAttack,y
			dex
			bpl readSIDAtt	

SIDDec		ldx #2
readSIDDec	lda CHTemp
			cmp SIDDecKeys,x
			beq SetSIDDec
			sec
			sbc #64
			cmp SIDDecKeys,x
			beq DecMinus
			dex
			bpl readSIDDec
			bmi SIDRel
DecMinus	lda #0
SetSIDDec	sta MINUS
			jsr getregindex		; index is in Y
			lda SIDDecay,y
			jsr storereg
			sta SIDDecay,y
			dex
			bpl readSIDDec

SIDRel		ldx #2
readSIDRel	lda CHTemp
			cmp SIDRelKeys,x
			beq SetSIDRel
			sec
			sbc #64
			cmp SIDRelKeys,x
			beq RelMinus
			dex
			bpl readSIDRel
			bmi SIDPW
RelMinus	lda #0
SetSIDRel	sta MINUS
			jsr getregindex		; index is in Y
			lda SIDRelease,y
			jsr storereg
			sta SIDRelease,y
			dex
			bpl readSIDRel

SIDPW		ldx #2
readSIDPw	lda CHTemp
			cmp SIDPwKeys,x
			beq SetSIDPw
			sec
			sbc #64
			cmp SIDPwKeys,x
			beq PwMinus
			dex
			bpl readSIDPw
			bmi noSIDkeys
PwMinus		lda #0
SetSIDPw	sta MINUS
			jsr getregindex		; index is in Y
			lda SIDSqPw,y
			jsr storereg
			sta SIDSqPw,y
			dex
			bpl readSIDPw

			
noSIDkeys	jmp nokey

PSGKeys		ldx #5
readPSGMix	lda PSGMixKeys,x
			cmp CHTemp
			beq SetPSGMix
			dex
			bpl readPSGMix
			bmi Noise
SetPSGMix	lda #255
			sta CHTemp
			ldy PMDevice
			lda PSGMixVals,x
			eor PSGMix,y
			sta PSGMix,y
			dex
			bpl readPSGMix

Noise		lda CHTemp
			cmp #$0b
			beq SetNoise
			sec
			sbc #64
			cmp #$0b
			beq NoiseMinus
			bne EnvFreqLo
NoiseMinus	lda #0
SetNoise	sta MINUS
			lda #255
			sta CHTemp
			ldy PMDevice
			lda PSGNoise,y
			jsr storereg
			sta PSGNoise,y

EnvFreqLo	lda CHTemp
			cmp #$3d
			beq SetEnvFqLo
			sec
			sbc #64
			cmp #$3d
			beq FqLoMinus
			bne EnvFreqHi
FqLoMinus	lda #0
SetEnvFqLo	sta MINUS
			lda #255
			sta CHTemp
			ldy PMDevice
			lda PSGEnvFqLo,y
			jsr storereg
			sta PSGEnvFqLo,y

EnvFreqHi	lda CHTemp
			cmp #$39
			beq SetEnvFqHi
			sec
			sbc #64
			cmp #$39
			beq FqHiMinus
			bne ActEnv
FqHiMinus	lda #0
SetEnvFqHi	sta MINUS
			lda #255
			sta CHTemp
			ldy PMDevice
			lda PSGEnvFqHi,y
			jsr storereg
			sta PSGEnvFqHi,y


ActEnv		ldx #2
readActEnv	lda PSGEnvKeys,x
			cmp CHTemp
			beq SetActEnv
			dex
			bpl readActEnv
			bmi EnvShape
SetActEnv	lda #255
			sta CHTemp
			jsr getregindex
			lda PSGEnvAct,y
			eor #128
			sta PSGEnvAct,y
			dex
			bpl readActEnv

EnvShape	ldx #3
readEnvKeys	lda EnvShpKeys,x
			cmp CHTemp
			beq SetEnvShape
			dex
			bpl readEnvKeys
			bmi nokey
SetEnvShape	lda #255
			sta CHTemp
			ldy PMDevice
			lda EnvShpVals,x
			eor PSGEnvShape,y
			sta PSGEnvShape,y
			dex
			bpl readEnvKeys
			

nokey		lda ChipFlag
			beq PokeyWorks
			cmp #1
			beq jmpSIDWorks
			jmp PSGWorks
jmpSIDWorks	jmp SIDWorks
PokeyWorks	lda PMDevice	; POKEY number 1-4 (0-3)
			tay
			asl
			asl				; multiply by four to get PokeyOffset index
			pha				; save
			lda ACTL,y		; to get AUDCTL value of respective POKEY
			sta TEMP		; store temporarily
			pla				; get back PokeyOffset index
			tay
			lda PokeyOffset,y	; and get the actual PokeyOffset
			tay				; use as index
			lda TEMP		; get back AUDCTL value
			sta AUDCTL,y	; and store in the respective AUDCTL

			ldy #95			; display AUDCTL bits on screen
			ldx #8
			jsr showbits

			ldy #3				; display AUDC1-4 bits 5-7 on screen
nextaudc	tya
			pha
			sta TEMP
			lda PMDevice
			asl
			asl
			clc
			adc TEMP
			tay
			lda AC1,y
			clc
			ror
			ror
			ror
			ror
			ror
			sta TEMP
			pla
			pha
			tay
			lda AUDCOffset,y
			tay
			ldx #3
			jsr showbits
			pla
			tay
			dey
;			cpy #0
			bpl nextaudc
			jmp receiveMIDI

SIDWorks	ldy #2
nextwave	lda PMDevice
			cmp #1
			beq sid2wave
			lda SIDWAVE,y
			jmp gowave
sid2wave	lda SIDWAVE+3,y
gowave		sta TEMP
			ldx #3
nextwavebit	tya					; save Y and X...
			pha
			txa
			pha
			tya
			clc					; calculate position for SIDWavePos
			asl
			asl
			sta TEMP2
			txa
			ora TEMP2
			tax
			lda SIDWavePos,x
			tay
			pla
			tax
			lda TEMP
			and #128
			bne waveset
			beq wavenotset
waveset		lda WaveTxt,x
			ora #128
			bne writewave
wavenotset	lda WaveTxt,x
writewave	sta INTRO+120,y
			pla
			tay
			lda TEMP
			asl
			sta TEMP
			dex
			bpl nextwavebit
			dey
			bpl nextwave

; SID envelope data

			ldx #2
			ldy #100
nextatt		lda PMDevice
			cmp #1
			beq sid2att
			lda SIDAttack,x
			bcc goatt
sid2att		lda SIDAttack+3,x
goatt		jsr dispEnv
			tya
			sec
			sbc #40
			tay
			dex
			bpl nextatt

			ldx #2
			ldy #106
nextdec		lda PMDevice
			cmp #1
			beq sid2dec
			lda SIDDecay,x
			bcc godec
sid2dec		lda SIDDecay+3,x
godec		jsr dispEnv
			tya
			sec
			sbc #40
			tay
			dex
			bpl nextdec

			ldx #2
			ldy #112
nextrel		lda PMDevice
			cmp #1
			beq sid2rel
			lda SIDRelease,x
			bcc gorel
sid2rel		lda SIDRelease+3,x
gorel		jsr dispEnv
			tya
			sec
			sbc #40
			tay
			dex
			bpl nextrel
			
			ldx #2
			ldy #118
nextpw		lda PMDevice
			cmp #1
			beq sid2pw
			lda SIDSqPw,x
			bcc gopw
sid2pw		lda SIDSqPw+3,x
gopw		jsr dispEnv
			tya
			sec
			sbc #40
			tay
			dex
			bpl nextpw


			jmp receiveMIDI

PSGWorks	ldy PMDevice				; Mixer
			lda PSGMix,y
			sta TEMP
			ldx #5
nextMixBit	lda TEMP
			and #1
			bne MixNotSet
			beq MixSet
MixSet		lda MixerTxt,x
			ora #128
			bne writemix
MixNotSet	lda MixerTxt,x
writemix	sta INTRO+126,x
			lda TEMP
			clc
			ror
			sta TEMP
			dex
			bpl nextMixBit

			ldx #2						; Active Envelopes
			ldy #35
nextactenv	lda PMDevice
			cmp #1
			beq psg2ae
			lda PSGEnvACt,x
			bcc goactenv
psg2ae		lda PSGEnvAct+3,x
goactenv	sta TEMP
			lda EnvActTxt,x
			ora TEMP
			sta INTRO+120,y
			dey
			dex
			bpl nextactenv

			ldy PMDevice				; Envelope Shape
			lda PSGEnvShape,y
			sta TEMP
			ldx #3
			ldy #76
nextshpbit	lda TEMP
			and #1
			bne shapeset
			beq shapenotset
shapeset	lda EnvShpTxt,x
			ora #128
			bne writeshape
shapenotset	lda EnvShpTxt,x
writeshape	sta INTRO+120,y
			lda TEMP
			clc
			ror
			sta TEMP
			dey
			dex
			bpl nextshpbit

			ldy #134					; Noise Frequency
			ldx PMDevice
			lda PSGNoise,x
			jsr dispEnv

			ldy #94						; Envelope Frequency Lo
			ldx PMDevice
			lda PSGEnvFqLo,x
			jsr dispEnv

			ldy #113					; Envelope Frequency Hi
			ldx PMDevice
			lda PSGEnvFqHi,x
			jsr dispEnv



receiveMIDI	lda #$80			; set control line to "ready"
			sta PORTA
			jsr wait			; Give the Teensy a little bit time to interpret the "ready" signal and get all lines set up...
			lda TRIG0			; Trigger Port 1 contains Bit 1 of message number
			asl
			clc
			adc TRIG1			; Trigger Port 2 contains Bit 0 of message number
			sta TEMP
			ldy #0
			sty PORTA			; Set control line to "not ready" while we do other stuff...
			sty ATTRACT
			cmp MSGSAVE			; do we have the same message number as last time?
			bne parseMsg		; if no, then parse message
			cmp #3				; special case: msg type 03 (pitch bend) can occur repeatedly during a note is played
			bne jmain
			lda TEMP
			and #$7f
			cmp PITCHBEND
			bne parseMsg
jmain		jmp MainLoop		; otherwise back to square one

wait		ldy #8				; a few dozen cycles shall do...
w1			dey
			bne w1
			rts

parseMsg	sta MSGSAVE
			cmp #0
			beq setVoice
			cmp #1
			beq setVelocity
			cmp #2
			beq setPitch
			cmp #3
			beq setAux
contparse	lda #255
			sta CHTemp
			lda VOICE
			cmp #22
			bcs jmpPSG
			cmp #16
			bcs jmpSID
			bne playPOKEY
jmpSID		jmp playSID
jmpPSG		jmp playPSG

setVoice	lda PORTA
			and #31
			sta VOICE
			lda PORTA
			and #96
			clc
			ror
			ror
			ror
			sta CHANNEL
			lda MSGSAVE			; restore accumulator
			jmp contparse

setVelocity	lda PORTA
			and #15
			sta VELOCITY
			lda PORTA
			and #48
			clc
			ror
			ror
			ror
			ror
			ora CHANNEL
			sta CHANNEL
			lda MSGSAVE
			jmp contparse

setPitch	lda PORTA
			and #$7f
			sta PITCH
			lda MSGSAVE
			jmp contparse

setAux		lda PORTA
			and #$7f
			clc
			rol
			sta PITCHBEND
			lda MSGSAVE
			jmp contparse

playPOKEY
/*
			stx VOICESAVE
			sta MIDI			; and store in variable
			sta TEMP
*/
			ldy PMDevice
			lda VOICE			; Check for 16-bit voices (Midi-Channel 1 and 3)
			and #3
			cmp #2
			beq checkv3
			cmp #0
			bne nosxbit
			lda ACTL,y			; Voice 1 16-bit?
			and #%00010000		; Compare with AUDCTL-Bit 4
			bne sxbit
			beq nosxbit
checkv3		lda ACTL,y			; Voice 3 16-bit?
			and #%00001000		; Compare with AUDCTL-Bit 3
			bne sxbit
nosxbit		lda #0				; Clear SXBITFLAG
sxbit		sta SXBITFLAG		; Or set it with $08/$10 respectively

/*
			lda MIDI
			and #%01111111		; isolate sound parameter (pitch or volume) from data 
			sta PARAM
			lda MIDI
			and #%10000000		; isolate command (bit 7)
			cmp #%10000000		; if set then volume, otherwise pitch
			bne setpitch
*/

			lda MSGSAVE
			cmp #1				; velocity message?
			beq govolume
			cmp #2
			beq gopitch			; pitch message?
			cmp #3
			beq jmpsetfreq		; pitch bend goes here as well
;			beq handleaux		; for future implementations such as midi program messages
			jmp MainLoop
jmpsetfreq	jmp setfreq

handleaux	jmp MainLoop

govolume	clc
			ldx VOICE
			lda POKEYOffset,x
			tay
/*			tya					; AUDC1,2,3,4 distance = 2 each
			and #%00000111		; mask out Pokey-Offset
			ror					; AC1,2,3,4 distance = 1 each
			tax					; i.e. Y=6, X=3
*/
			lda SXBITFLAG		; But...
			beq cont8bit
			iny					; ...if 16-bit voice then volume goes to channel+1 (i.e. Y=Y+2, X=X+1)
			iny
			inx
cont8bit	lda VELOCITY
;			ldy CHANNEL
			sta VOLSAVE,x
			cmp #0				; Voice off, begin release phase?
			bne newnote
			lda ADSRActive,x	; are we in ADSR mode?
			beq contvolume
			tya
			pha
			ldy ADSRStart,x
			lda ADSRTable,y
			clc
			adc #1
;			lda RelOffset,x		; set beginning of release phase values
			sta ADSRC,x			; to counter
;			lda AC1,x
;			sta AUDC1,y
			pla
			tay
			jmp contvolume
newnote		lda #1
			sta ADSRC,x
			lda #0
			sta AUDC1,y
contvolume	lda #1
			sta ADSRActive,x
			lda VOLSAVE,x
;			cmp #0
			bne jmpmainl2
			sta TEMP

			txa					; ToDo: these tree lines can go?
			asl
			tay

jmpmainl2	jmp MainLoop		; jump back to main loop and wait for next lot of data

gopitch		ldx VOICE
			lda POKEYOffset,x
			tay

			lda AC1,x			; Read distortion of voice X and use appropriate scale
			cmp #$20
			beq D2
			cmp #$c0
			beq D12
D10			ldx PITCH			; Midi-Note to X
			lda SXBITFLAG		; 16-bit voice?
			bne D10SX
			lda NotesD10,x
			sta NOTE
			jmp setfreq
D10SX		lda NotesD10SXL,x	; Load (L)ow and (H)igh byte of (S)i(X)teen Bit value
			sta NOTE			; and store in low...
			lda NotesD10SXH,x
			sta NOTE+1			; and high byte respectively.
			jmp setfreq
D2			ldx PITCH			; Midi-Note to X
			lda SXBITFLAG
			bne D2SX
			lda NotesD2,x
			sta NOTE
			jmp setfreq
D2SX		lda NotesD2SXL,x
			sta NOTE
			lda NotesD2SXH,x
			sta NOTE+1
			jmp setfreq
D12			ldx PITCH			; Midi-Note to X
			lda SXBITFLAG
			bne D12SX
			lda D12FLAG
			bne D12b
			lda NotesD12,x
			jmp setnote
D12b		lda NotesD12b,x
setnote		sta NOTE
			jmp setfreq
D12SX		lda D12FLAG
			bne D12bSX
			lda NotesD12SXL,x
			sta NOTE
			lda NotesD12SXH,x
			sta NOTE+1
			jmp setfreq
D12bSX		lda NotesD12bSXL,x
			sta NOTE
			lda NotesD12bSXH,x
			sta NOTE+1
			
setfreq		ldx VOICE
			lda POKEYOffset,x
			tay

			lda MSGSAVE
			cmp #3
			bne storefreq
			lda NOTE
			pha
			lda NOTE+1
			pha
			lda SXBITFLAG		; handle pitch bend
			bne handle16
			lda PITCHBEND
			bmi pitchdownp1
			lda NOTE
			sec
			sbc PITCHBEND
			sta NOTE
			jmp storefreq
pitchdownp1	lda NOTE
			sec
			sbc PITCHBEND
			sta NOTE
			jmp storefreq
handle16	lda PITCHBEND
			bmi pitchdown2
			lda NOTE
			sec
			sbc PITCHBEND
			sta NOTE
			lda NOTE+1
			sbc #0
			sta NOTE+1
			jmp storefreq
pitchdown2	lda NOTE
			sec
			sbc PITCHBEND
			sta NOTE
			lda NOTE+1
			adc #0
			sta NOTE+1

storefreq	lda NOTE
			sta AUDF1,y			; store the data in the audio frequency register of channel 0 + offset
			lda SXBITFLAG
			beq jmpmainl
;			lda #0
;			sta AUDC1,y
			iny
			iny
			lda NOTE+1
			sta AUDF1,y
						
jmpmainl	jsr savenote
			lda MSGSAVE			; restore original NOTE values after applying pitch bend
			cmp #3
			bne exitpbend
			pla
			sta NOTE+1
			pla
			sta NOTE
exitpbend	jmp MainLoop
jmpexitp	jmp exitplay

playram		
			lda #0
			sta NOTETIMER
			sta NOTETIMER+1
			sta CH
			sta PLAYPTR
			lda #$60
			sta PLAYPTR+1
			sta PLAYFLAG
playloop	lda CH
			cmp #$0a
			beq jmpexitp
			lda PLAYPTR+1
			cmp NOTEPTR+1
			bcc doplay
			lda PLAYPTR
			cmp NOTEPTR
			bcs exitplay
doplay		ldy #0
			lda (PLAYPTR),y
			tax						; voice to X
			iny
			lda (PLAYPTR),y
			sta PLAYAUDC			; save AUDC-value
			iny
			lda (PLAYPTR),y
			sta PLAYNOTE			; save note
			iny
			lda (PLAYPTR),y
			sta PLAYTIMER			; save timer low-byte
			iny
			lda (PLAYPTR),y
			sta PLAYTIMER+1			; save timer high-byte

waittimer	lda 20
			cmp TIME
			beq novbi2
			sta TIME
			jsr playadsr
novbi2		lda NOTETIMER+1
			cmp PLAYTIMER+1			; Playtimer >= Notetimer (high byte)?
			bcc waittimer
			lda NOTETIMER
			cmp PLAYTIMER			; Playtimer >= Notetimer (low byte)?
			bcc waittimer

			lda PLAYAUDC			; then play note...
			and #%11110000
			sta AC1,x
			lda #1
			sta ADSRActive,x
			lda PLAYAUDC
			and #%00001111

			pha
;			cmp #0				; Voice off, begin release phase?
			bne contADS
			ldy ADSRStart,x
			lda ADSRTable,y
			clc
			adc #1
;			lda RelOffset,x		; set beginning of release phase values
			sta ADSRC,x			; to counter
			bpl contplay
contADS		lda #1
			sta ADSRC,x
contplay	pla

			sta VOLSAVE,x
;			sta AUDC1,y
			lda PokeyOffset,x
			tay
			lda PLAYNOTE
			sta AUDF1,y
			clc
			lda PLAYPTR
			adc #$05				; increase pointer
			sta PLAYPTR
			bcc jmpplayl
			lda PLAYPTR+1
			adc #0
			sta PLAYPTR+1
jmpplayl	jmp playloop
			
exitplay	lda 20
			cmp TIME
			beq novbi3
			sta TIME
			jsr playadsr
novbi3		ldy #15
waitenvend	lda ADSRActive,y
			bne exitplay
			dey
			bpl waitenvend
			ldy #15
			lda #0
			sta PLAYFLAG
			sta NOTETIMER
			sta NOTETIMER+1
clearplayer	sta ADSRC,y
			sta DispVol,y
			sta ADSRActive,y
			lda PokeyOffset,y
			tax
			lda #0
			sta AUDC1,x
			dey
			bpl clearplayer
			lda #255
			sta CH
			jmp MainLoop

savenote	lda RECFLAG
			beq endnotesave
			ldx VOICE
			lda SXBITFLAG
			beq no16
			lda VOLSAVE+1,x
			jmp startsave
no16		lda VOLSAVE,x
startsave	clc
			adc AC1,x
			pha					; save distortion
			lda RECFLAG
			beq endnotesave
			ldy #0
			lda NOTEPTR			; save note pointer for 16-bit
			sta TEMPPTR
			lda NOTEPTR+1
			sta TEMPPTR+1
			txa					; get channel from X
			sta (NOTEPTR),y		; store channel
			jsr incptr
			pla					; get distortion
			sta (NOTEPTR),y		; store distortion
			jsr incptr
			lda NOTE
			sta (NOTEPTR),y		; store note (AUDFx)
			jsr incptr
			lda NOTETIMER
			ldy #0
			sta (NOTEPTR),y		; duration (1/50 seconds) of _previous_ note (low-byte)
			lda NOTETIMER+1
			iny
			sta (NOTEPTR),y		; ...high byte
			jsr incptr
			jsr incptr
			lda SXBITFLAG
			beq endnotesave
			ldy #4				; copy previous voice data to next set for 16-Bit notes
copy16bit	lda (TEMPPTR),y
			sta (NOTEPTR),y
			dey
			bpl copy16bit
			ldy #0
			lda (TEMPPTR),y
			clc
			adc #1
			sta (NOTEPTR),y		; increase channel
			iny
			lda (TEMPPTR),y
			and #$f0
			sta (TEMPPTR),y		; clear volume on lower channel
			iny
			lda NOTE+1
			sta (NOTEPTR),y	
			ldy #4				; adjust note pointer
updateptr	jsr incptr
			dey
			bpl updateptr
endnotesave	rts

incptr		inc NOTEPTR
			bne doneinc
			inc NOTEPTR+1
doneinc		jsr showcounter
			rts

showcounter	tya					; update note counter display
			pha
			ldy #3
counterloop	lda COUNTER,y
			clc
			adc #$01
			cmp #":"
			beq rolloverA
			cmp #"G"
			beq rollover0
			bne norollover
rolloverA	lda #"A"
			bne norollover
rollover0	lda #"0"
nextdigit	sta COUNTER,y
			dey
			bpl counterloop
norollover	sta COUNTER,y
			pla
			tay
			rts

showbits	lda TEMP
			and #1
			beq zero
			lda BitTable-1,x
			bpl output
zero		lda #"-"
output		sta INTRO+40,y
			lda TEMP
			clc
			ror
			sta TEMP
			dey
			dex
;			cpx #0
			bne showbits
			rts
			
dispEnv		pha
			cmp #10
			bcs gt10
			lda #"0"
			sta INTRO+120,y
			bne singledigit
gt10		lda #"1"
			sta INTRO+120,y
singledigit	pla
			cmp #10
			bcc lt10
			sec
			sbc #$0a
lt10		clc
			adc #$10
			sta INTRO+121,y
			rts

getSIDindex	lda #255
			sta CHTemp
			clc
			lda PMDevice			; get number of chip (0 or 1)
			asl						; make it 0 or 2
			sta TEMP				; and save
			lda PMDevice			; get number of chip again (0 or 1)
			adc TEMP				; add TEMP (0 or 2)
			sta TEMP				; result is 0 or 3
			txa						; get index of key pressed (0 to 11)
			lsr
			lsr						; make it 0 to 2
			clc
			adc TEMP				; add TEMP (0 or 3), result is 0 to 5
			tay						; that's our index
			rts

getregindex	lda #255
			sta CHTemp
			clc
			lda PMDevice			; get number of chip (0 or 1)
			asl						; make it 0 or 2
			sta TEMP				; and save
			lda PMDevice			; get number of chip again (0 or 1)
			adc TEMP				; add TEMP (0 or 2)
			sta TEMP				; result is 0 or 3
			txa						; get index of key pressed (0 to 2)
			clc
			adc TEMP				; add TEMP (0 or 3), result is 0 to 5
			tay						; that's our index
			rts

storereg	pha
			lda MINUS
			bne RegPlus
			pla
			cmp #0
			beq writeSIDReg
			sec
			sbc #1
			jmp writeSIDReg
RegPlus		pla
			cmp #15
			beq writeSIDReg
			clc
			adc #1
writeSIDReg	rts

getPSGDev	lda VOICE
			sec
			sbc #22
			tax
			cmp #3
			bcc PSG1
			ldy #1
			jmp DevExit
PSG1		ldy #0
DevExit		rts

equalizer	ldx #0
			lda #<EquStart
			sta EquOffset
			lda #>EquStart
			sta EquOffset+1
nextequ		ldy #15				; (max) velocity level
nextequbit	tya
			cmp DispVol,x
			bcs notset
			lda #128
			bne plot
notset		lda #0
plot		sta (EquOffset),y
			dey
			bpl nextequbit
			lda EquOffset
			clc
			adc #20
			sta EquOffset
			bcc nopagejump
			inc EquOffset+1
nopagejump	inx
			cpx #16
			bne nextequ
			rts

playadsr	tya
			pha
			txa
			pha
			ldx #0
nextadsr	lda ADSRActive,x	; are we in ADSR mode?
			bne nextadsr2		; if not then next voice
			jmp nextx
nextadsr2	lda VOLSAVE,x		; get channel's volume
			pha					; save volume
			lda ADSRStart,x
			clc
			adc ADSRC,x			; add counter to create final pointer
			tay					; store pointer in Y
			sta ADSRTemp		; and in temp variable
			lda ADSRTable,y		; mask DistEnv
			pha
			and #%00001111
			sta ADSRVol
			pla
			and #%11110000
			sta ADSRDist
			pla					; get back volume

			cmp #0				; are we in release phase
			bne adsphase
relphase	clc					; yes, then add value to current sound level (zero)
;			adc ADSRTable,y
			adc ADSRVol
			cmp VOLTemp,x
			bcc setadsr
			lda VOLTemp,x
			jmp setadsr

adsphase	sec					; otherwise, in ADS mode:
;			sbc ADSRTable,y		; subtract envelope
			sbc ADSRVol
			sta VOLTemp,x		; remember last volume level for possible release phase
			bcs setadsr			; less than zero?
			lda #0				; then zero it is.
			sta VOLTemp,x
setadsr		pha					; save volume to stack
			sta DispVol,x
			lda ADSRDist		; test DistEnv
			bne DistEnv
			pla
			clc
			adc AC1,x			; either add standard distortion
			jmp storeAUDC
DistEnv		pla
			clc
			adc ADSRDist		; or add distortion from envelope
;			lda VOLTemp,x
;			clc
;			adc AC1,x			; add distortion
storeAUDC	pha					; save resulting AUDC value
			lda POKEYOffset,x	; find out where to store it
;			txa
;			asl
			tay
			pla
			sta AUDC1,y			; and play
 
			lda ADSRStart+1,x
			sec
			sbc ADSRStart,x
			sta RelMax,x
;			sec
;			sbc #1
;			cmp ADSRC,x
			lda ADSRC,x			; increase envelope counter
			clc
			adc #1
			cmp RelMax,x		; if in release mode
			bcs resetADSR		; check for end of release
			ldy ADSRStart,x
			cmp ADSRTable,y		; otherwise, is ADS stage maxed out?
			bne incADSRC		; if not then increase

			lda ADSRTemp		; get back current counter
			tay
			iny					; increase
			lda ADSRTable,y
			beq nextx			; if zero then remain at last position
			lda ADSRC,x			; otherwise
			sbc ADSRTable,y		; subtract offset byte (pos. ADSRMax)
incADSRC	sta ADSRC,x			; and set counter accordingly
			jmp nextx

resetADSR	lda #1
			sta ADSRC,x
			lda #0
			sta ADSRActive,x
			sta ADSRVol
			sta ADSRDist
			sta VolTemp,x

nextx		inx
			cpx #16
			bne jmpnextadsr
			jsr equalizer
			pla
			tax
			pla
			tay
			rts
jmpnextadsr	jmp nextadsr

playSID		lda MSGSAVE
			cmp #1				; velocity message?
			beq volumeSID
			cmp #2
			beq pitchSID		; pitch message?
			cmp #3
			beq pitchSID		; pitch bend goes here as well
;			beq auxSID			; for future implementations such as midi program messages
			jmp MainLoop

volumeSID	lda VOICE
			and #15
			tax
			lda SIDOffset,x
			tay
			lda #0
			sta WAVE1,y
			lda VELOCITY
			beq SIDoff
			lda SIDWAVE,x
			clc
			adc #1
			sta WAVE1,y
			bne attack
SIDoff		lda SIDWAVE,x
			sta WAVE1,y
attack		lda SIDAttack,x
			clc
			asl
			asl
			asl
			asl
			ora SIDDecay,x
			sta ATTDEC1,y
			lda VELOCITY
			pha
			asl
			asl
			asl
			asl
			ora SIDRelease,x
			sta SUSTREL1,y
			lda SIDSqPw,x
			sta SQPW1,y
			pla
			ldx CHANNEL
			sta DispVol,x
			jsr equalizer
			jmp MainLoop

pitchSID	lda VOICE
			and #15
			tax
			lda SIDOffset,x
			tay
			ldx PITCH
			lda PITCHBEND
			bmi pitchbends1
			clc
			adc SIDTableLo,x
			sta FREQ1,y
			lda SIDTableHi,x
			adc #0
			sta FREQ1+1,y
			jmp MainLoop
pitchbends1	lda SIDTableLo,x
			clc
			adc PITCHBEND
			sta FREQ1,y
			lda SIDTableHi,x
			sbc #0
			sta FREQ1+1,y
			jmp MainLoop

auxSID		jmp MainLoop

playPSG		lda MSGSAVE
			cmp #1				; velocity message?
			beq volumePSG
			cmp #2
			beq jmppitchPSG		; pitch message?
			cmp #3
			beq jmpauxPSG		; for future implementations such as midi program messages
			jmp MainLoop			
jmppitchPSG
jmpauxPSG	jmp pitchPSG

volumePSG	jsr getPSGDev		; Y index is 0 or 1 to access variables for PSG1 and 2 in memory; X holds PSG channel (0-5)
PSGcont		lda PSGEnvAct,x
			pha
			lda PSGMix,y
			pha
			lda PSGEnvShape,y
			pha
			lda PSGNoise,y
			pha
			lda PSGEnvFqLo,y
			pha 
			lda PSGEnvFqHi,y
			pha					; all of them pushed to stack 
			tya
			clc
			rol					; so we can convert the Y index to match the 16 byte difference 
			rol					; between the two banks of hardware registers
			rol
			rol
			tay
			pla					; get back envelope frequency Hi setting
			clc
			rol					; move to high nibble + 1, highest bit goes to carry to be put as bit 0 into PSGEFREQ+1
			rol
			rol
			rol
			rol
			sta TEMP
			lda #0
			adc #0
			sta PSGEFREQ+1,y
			pla					; get back envelope frequency Lo setting
			clc
			rol
			adc TEMP
			sta PSGEFREQ,y		; we only use the low byte
			pla					; get back noise frequency settings
			clc
			rol					; they are from 0-31, but we only set 0-15, so shift one to the left
			sta PSGNFREQ,y
			pla					; get back envelope shape settings
			sta PSGESHP,y
			pla					; get back mixer settings
			sta PSGMIXER,y
			lda PSGVolOffset,x
			tay
			lda VELOCITY
			cmp #0
			bne envon
			pla
			lda #0
			beq envoff
envon		pla					; get back active envelope setting (0 or 128)
			clc
			ror
			ror
			ror					; make it 0 or 16
			adc VELOCITY		; add volume
envoff		ldx CHANNEL			; get MIDI channel to X
			sta PSGVOL,y		; and store in hardware register
			and #15				; mask out envelope bit
			sta DispVol,x		; prepare for equalizer
			jsr equalizer
			jmp MainLoop

pitchPSG	lda VOICE
			sec
			sbc #22
			tax
			lda PSGPitchOffset,x
			tay
			ldx PITCH
			dex					; ToDo: Get note table in order and remove these two DEX
			dex
			lda PITCHBEND
			bmi pitchbendg1
			lda PSGTableLo,x
			sec
			sbc PITCHBEND
			sta PSGFREQ,y
			lda PSGTableHi,x
			sbc #0
			sta PSGFREQ+1,y
			jmp MainLoop
pitchbendg1	lda PSGTableLo,x
			sec
			sbc PITCHBEND
			sta PSGFREQ,y
			lda PSGTableHi,x
			adc #0
			sta PSGFREQ+1,y
			jmp MainLoop

auxPSG		jmp MainLoop

VBI			lda RECFLAG
			bne dotimer
			lda PLAYFLAG
			beq donetimer
			
dotimer		inc NOTETIMER
			bne donetimer
			inc NOTETIMER+1

donetimer	lda KBCODE
			cmp #$11
			bne exitvbi
			lda SKCTL
			and #4
			bne showMenu
showHelp	lda #<HelpText
			sta ScreenMem
			lda #>HelpText
			sta ScreenMem+1
			bne exitvbi
showMenu	lda #<INTRO
			sta ScreenMem
			lda #>INTRO
			sta ScreenMem+1
exitvbi		jmp $e45f

; EquOffset	.byte 7, 47, 87, 127, 167, 207
; TempData	.byte 143,65,135,65,128,50
; TEMPCOUNT	.byte 0
; TempMIDI	.byte 0

DEBUG
INTRO		.byte "MidiJoy (c) 2014-2020 by Frederik Holst"
			org INTRO+80
Device		.byte "POKEY 1"
			org INTRO+120
ConfigLines	.byte "AUDCTL:"
			org INTRO+137
			.byte "AUDC1:     AUDC2:"
			org INTRO+160
			.byte "Env.No.:"
EnvBank		.byte "12345678"
			org INTRO+177
			.byte "AUDC3:     AUDC4:"
			org INTRO+440
			.byte "Press HELP for keyboard commands        "
			.byte "Note-RAM: $6000-$"
COUNTER		.byte "5FFF"
			org INTRO+560
EquStart	.byte 0
			org INTRO+920
			.byte "       http://www.phobotron.de"

			org INTRO+960

HelpText	.byte "MidiJoy (c) 2014-2020 by Frederik Holst "
			org HelpText+80
			.byte "Key Commands POKEY:                     "
			.byte "Q-I: Set AUDCTL  A-H,Z-N: Set AUDCx     "
			.byte "1-8: Select Env. SPACE: Toggle D12 Dist."
			.byte "P: Play Note-RAM TAB: Un/Pause Recording"
			.byte "                                        "
			.byte "Key Commands SID:                       "
			.byte "Q-R: Waveform 1  T-U: ADR 1  I: PWSQ 1  "
			.byte "A-F: Waveform 2  G-J: ADR 2  K: PWSQ 2  "
			.byte "Z-V: Waveform 3  B-M: ADR 3  ,: PWSQ 3  "
			.byte "                                        "
			.byte "Key Commands PSG:                       "
			.byte "Q-Y: Mixer       Z-C: Activate Envelope "
			.byte "A-F: Env. Shape  G-H: Env. Frequency    "
			.byte "U:   Noise Freq.                        "
			.byte "                                        "
			.byte "All soundchips:                         "
			.byte "RETURN: Reset    ESC: Exit to DOS       "
			.byte "OPTION: Next chip instance              "
			.byte "SELECT: Next soundchip                  "
			.byte "Use SHIFT+key to decrease a value       "
			.byte "                                        "
			.byte "       http://www.phobotron.de          "

POKEYText	.byte "POKEY 1"
SIDText		.byte "  SID 1"
PSGText		.byte "  PSG 1"
WaveTxt		.byte "TQSN"
MixerTxt	.byte "CBACBA"
EnvActTxt	.byte "ABC"
EnvShpTxt	.byte "4321"

PokeyStats	.byte "AUDCTL:          AUDC1:     AUDC2:      "
			.byte "Env.No.:12345678 AUDC3:     AUDC4:      "

SIDStats	.byte "Waveform 1:NSQT  A1:   D1:   R1:   P1:  "
			.byte "Waveform 2:NSQT  A2:   D2:   R2:   P2:  "
			.byte "Waveform 3:NSQT  A3:   D3:   R3:   P3:  "

PSGStats	.byte "Mixer:ABCABC     Active Envelope:ABC    "
			.byte "      NNNTTT     Envelope Shape: 4321   "
			.byte "Env. Freq. Lo:   Env. Freq. Hi:         "
			.byte "Noise Freq.:  "

VOLSAVE		.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
VolTemp		.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
DispVol		.byte 0, 0 ,0 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ADSRActive	.byte 0, 0, 0 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ADSRC		.byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
RelMax		.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

PSGMixKeys
AUDCTLKeys	.byte $2f, $2e, $2a, $28, $2d, $2b, $0b, $0d
AUDCTLVals	.byte 128, 64, 32, 16, 8, 4, 2, 1
ACKeys		.byte $3a, $3e, $3f, $39, $3d, $38, $12, $16, $17, $23, $15, $10
ACVals		.byte 32, 64, 128, 32, 64, 128, 32, 64, 128, 32, 64, 128
EnvKeys		.byte $1f, $1e, $1a, $18, $1d, $1b, $33, $35
ACIndex		.byte 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3
BitTable	.byte "7", "6", "5", "4", "3", "2", "1", "0"
SIDOffset	.byte 0, 7, 14, 32, 39, 46
PSGVolOffset	.byte 0, 1, 2, 16, 17, 18
PSGPitchOffset	.byte 0, 2, 4, 16, 18, 20
SIDWaveKeys	.byte $2f, $2e, $2a, $28, $3f, $3e, $3a, $38, $17, $16, $12, $10
SIDWaveVals	.byte 128, 64, 32, 16, 128, 64, 32, 16, 128, 64, 32, 16
SIDWavePos	.byte 14, 13, 12, 11, 54, 53, 52, 51, 94, 93, 92, 91
SIDAttKeys	.byte $2d, $3d, $15
SIDDecKeys	.byte $2b, $39, $23
SIDRelKeys	.byte $0b, $01, $25
SIDPwKeys	.byte $0d, $05, $20
PSGEnvKeys	.byte $17, $16, $12
EnvShpKeys	.byte $3f, $3e, $3a, $38
EnvShpVals	.byte 8, 4, 2, 1
PSGMixVals	.byte 32, 16, 8, 4, 2, 1

; POKEY note tables (8 bit values)

NotesD10	.byte $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $79, $72, $6C, $66, $60, $5B, $55, $51, $4C, $48, $44, $40, $3C, $39, $35, $32, $2F, $2D, $2A, $28, $25, $23, $21, $1F, $1E, $1C, $1A, $19, $17, $16, $15, $13, $12, $11, $10, $0F, $0E, $1C, $1A, $19, $17, $16, $15, $13, $12, $11, $10, $0F, $0E, $1C, $1A, $19, $17, $16, $15, $13, $12, $11, $10, $0F, $0E, $1C, $1A, $19, $17, $16, $15
NotesD10SXL	.byte $DD, $DD, $34, $DB, $D0, $0D, $8E, $50, $4F, $88, $F7, $99, $DD, $DD, $34, $DB, $D0, $0D, $8E, $50, $4F, $88, $F7, $99, $DD, $DD, $34, $DB, $D0, $0D, $8E, $50, $4F, $88, $F7, $99, $6B, $6B, $96, $EA, $64, $03, $C4, $A5, $A4, $C0, $F8, $49, $B2, $32, $C8, $72, $2F, $FE, $DE, $CF, $CF, $DD, $F8, $21, $56, $96, $E0, $35, $94, $FB, $6C, $E4, $64, $EB, $79, $0D, $A7, $47, $ED, $97, $46, $FA, $B2, $6E, $2E, $F2, $B9, $83, $50, $20, $F3, $C8, $A0, $7A, $56, $34, $14, $F5, $D9, $BE, $A5, $8D, $76, $61, $4C, $39, $27, $16, $06, $F7, $E9, $DB, $CF, $C3, $B7, $AD, $A3, $99, $90, $88, $80, $78, $71, $6A, $64, $5E, $58, $53, $4E, $49, $45
NotesD10SXH	.byte $6A, $64, $5F, $59, $54, $50, $4B, $47, $43, $3F, $3B, $38, $6A, $64, $5F, $59, $54, $50, $4B, $47, $43, $3F, $3B, $38, $6A, $64, $5F, $59, $54, $50, $4B, $47, $43, $3F, $3B, $38, $35, $32, $2F, $2C, $2A, $28, $25, $23, $21, $1F, $1D, $1C, $1A, $19, $17, $16, $15, $13, $12, $11, $10, $0F, $0E, $0E, $0D, $0C, $0B, $0B, $0A, $09, $09, $08, $08, $07, $07, $07, $06, $06, $05, $05, $05, $04, $04, $04, $04, $03, $03, $03, $03, $03, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
NotesD2		.byte $1F, $1D, $1B, $1A, $18, $17, $15, $14, $13, $12, $11, $10, $0F, $0E, $0D, $0C, $0B, $0B, $0A, $09, $09, $08, $08, $07, $07, $06, $06, $05, $05, $05, $04, $04, $04, $03, $03, $03, $03, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
NotesD2SXL	.byte $6C, $3A, $0B, $DF, $B6, $8E, $69, $47, $25, $06, $E8, $CD, $6C, $3A, $0B, $DF, $B6, $8E, $69, $47, $25, $06, $E8, $CD, $B5, $9A, $82, $6C, $57, $44, $32, $20, $0F, $00, $F0, $E3, $D6, $C9, $BE, $B2, $A7, $9E, $95, $8C, $84, $7C, $74, $6E, $67, $61, $5C, $55, $51, $4C, $47, $43, $3E, $3A, $36, $33, $30, $2D, $2A, $27, $25, $22, $20, $1E, $1C, $1A, $19, $16, $15, $13, $12, $10, $0F, $0E, $0C, $0B, $0A, $09, $08, $07, $07, $13, $12, $10, $0F, $0E, $0C, $0B, $0A, $09, $08, $07, $07, $13, $12, $10, $0F, $0E, $0C, $0B, $0A, $09, $08, $07, $07, $13, $12, $10, $0F, $0E, $0C, $0B, $0A, $09, $08, $07, $07, $13, $12, $10, $0F, $0E, $0C
NotesD2SXH	.byte $03, $03, $03, $02, $02, $02, $02, $02, $02, $02, $01, $01, $03, $03, $03, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
NotesD12	.byte $82, $7B, $75, $6C, $67, $61, $5D, $55, $52, $4C, $48, $43, $3F, $3D, $39, $37, $33, $30, $2D, $2B, $28, $25, $24, $21, $1F, $1E, $1C, $1B, $19, $47, $16, $15, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A, $0A, $3E, $12, $35, $10, $0F, $29, $29, $29, $0C, $23, $0A
NotesD12SXL	.byte $3A, $6C, $AC, $F5, $49, $A7, $0F, $8A, $F4, $71, $F9, $86, $26, $B2, $51, $F7, $A1, $50, $04, $BC, $75, $35, $F9, $C0, $8A, $57, $27, $F8, $CD, $A4, $7D, $59, $37, $17, $F9, $DB, $C2, $A8, $8F, $78, $63, $4E, $3B, $29, $18, $08, $F9, $EB, $DC, $CF, $C4, $B8, $AE, $A2, $9A, $91, $87, $81, $79, $72, $6A, $64, $5E, $5A, $54, $4F, $48, $45, $40, $3D, $39, $36, $31, $2E, $2D, $2A, $27, $24, $22, $1F, $1E, $1B, $19, $17, $15, $4A, $47, $41, $3E, $3B, $38, $1F, $1E, $1B, $19, $17, $15, $4A, $47, $41, $3E, $3B, $38, $1F, $1E, $1B, $19, $17, $15, $4A, $47, $41, $3E, $3B, $38, $1F, $1E, $1B, $19, $17, $15, $4A, $47, $41, $3E, $3B, $38
NotesD12SXH	.byte $0E, $0D, $0C, $0B, $0B, $0A, $0A, $09, $08, $08, $07, $07, $07, $06, $06, $05, $05, $05, $05, $04, $04, $04, $03, $03, $03, $03, $03, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
NotesD12b	.byte $F5, $E9, $DA, $CE, $C5, $B6, $AD, $A7, $9B, $92, $89, $83, $F5, $E9, $DA, $CE, $C5, $B6, $AD, $A7, $9B, $92, $89, $83, $7A, $74, $B8, $65, $62, $5C, $56, $50, $4D, $47, $44, $41, $3E, $38, $35, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29, $29, $26, $23, $20, $20, $1A, $1A, $1A, $32, $2F, $29, $29
NotesD12bSXL	.byte $BC, $55, $12, $FC, $E9, $03, $38, $85, $E7, $64, $F9, $A0, $7D, $27, $07, $F3, $F1, $FB, $1D, $3F, $70, $AD, $F9, $4E, $A9, $10, $80, $F6, $75, $FA, $8B, $1C, $B3, $53, $F9, $A2, $51, $06, $BB, $79, $37, $FB, $BF, $89, $56, $26, $F9, $CC, $A5, $81, $5A, $39, $18, $FA, $DC, $C1, $A6, $91, $79, $64, $4F, $3A, $28, $19, $0A, $FB, $EC, $DD, $D1, $C5, $B9, $B0, $A4, $9B, $92, $89, $83, $7A, $6E, $6B, $65, $5F, $59, $50, $4D, $4A, $47, $41, $3E, $3B, $38, $6B, $65, $5F, $59, $50, $4D, $4A, $47, $41, $3E, $3B, $38, $6B, $65, $5F, $59, $50, $4D, $4A, $47, $41, $3E, $3B, $38, $6B, $65, $5F, $59, $50, $4D, $4A, $47, $41, $3E, $3B, $38
NotesD12bSXH	.byte $2A, $28, $26, $23, $21, $20, $1E, $1C, $1A, $19, $17, $16, $15, $14, $13, $11, $10, $0F, $0F, $0E, $0D, $0C, $0B, $0B, $0A, $0A, $09, $08, $08, $07, $07, $07, $06, $06, $05, $05, $05, $05, $04, $04, $04, $03, $03, $03, $03, $03, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; SID note tables (16 bit values split in Lo and Hi tables)

SIDTableLo
;				  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
			.byte $16,$27,$39,$4B,$5F,$74,$8A,$A1,$BA,$D4,$F0,$0E  ; 1
			.byte $16,$27,$39,$4B,$5F,$74,$8A,$A1,$BA,$D4,$F0,$0E  ; 1
			.byte $2D,$4E,$71,$96,$BE,$E7,$14,$42,$74,$A9,$E0,$1B  ; 2
			.byte $5A,$9C,$E2,$2D,$7B,$CF,$27,$85,$E8,$51,$C1,$37  ; 3
			.byte $B4,$38,$C4,$59,$F7,$9E,$4E,$0A,$D0,$A2,$81,$6D  ; 4
			.byte $67,$70,$89,$B2,$ED,$3B,$9D,$14,$A0,$45,$03,$DB  ; 5
			.byte $CF,$E1,$12,$65,$DB,$76,$3A,$27,$41,$8A,$05,$B5  ; 6
			.byte $9D,$C1,$24,$C9,$B6,$ED,$73,$4E,$82,$14,$0A,$6A  ; 7
			.byte $3B,$82,$48,$93,$6B,$DA,$E7,$9C,$04,$28,$14,$6a  ; 8
			.byte $3B,$82,$48,$93,$6B,$DA,$E7,$9C,$04,$28,$14,$6a  ; 8
			.byte $3b,$82,$48,$93,$6b,$da,$e7

/*
			.byte $17,$27,$39,$4b,$5f,$74,$8a,$a1,$ba,$d4,$f0,$0e  ; 1
			.byte $2d,$4e,$71,$96,$be,$e8,$14,$43,$74,$a9,$e1,$1c  ; 2
			.byte $5a,$9c,$e2,$2d,$7c,$cf,$28,$85,$e8,$52,$c1,$37  ; 3
			.byte $b4,$39,$c5,$5a,$f7,$9e,$4f,$0a,$d1,$a3,$82,$6e  ; 4
			.byte $68,$71,$8a,$b3,$ee,$3c,$9e,$15,$a2,$46,$04,$dc  ; 5
			.byte $d0,$e2,$14,$67,$dd,$79,$3c,$29,$44,$8d,$08,$b8  ; 6
			.byte $a1,$c5,$28,$cd,$ba,$f1,$78,$53,$87,$1a,$10,$71  ; 7
			.byte $42,$89,$4f,$9b,$74,$e2,$f0,$a6,$0e,$33,$20,$ff  ; 8
*/

SIDTableHi
;				  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
			.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02  ; 1
			.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02  ; 1
			.byte $02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04  ; 2
			.byte $04,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$08  ; 3
			.byte $08,$09,$09,$0a,$0a,$0b,$0c,$0d,$0d,$0e,$0f,$10  ; 4
			.byte $11,$12,$13,$14,$15,$17,$18,$1a,$1b,$1d,$1f,$20  ; 5
			.byte $22,$24,$27,$29,$2b,$2e,$31,$34,$37,$3a,$3e,$41  ; 6
			.byte $45,$49,$4e,$52,$57,$5c,$62,$68,$6e,$75,$7c,$83  ; 7
			.byte $8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8,$83  ; 8
			.byte $8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8,$83  ; 8
			.byte $8b,$93,$9c,$a5,$af,$b9,$c4

PSGTableLo
;				  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
			.byte $5D,$9C,$E7,$3C,$9B,$02,$73,$EB,$6B,$F2,$80,$14  ; 1
			.byte $5D,$9C,$E7,$3C,$9B,$02,$73,$EB,$6B,$F2,$80,$14  ; 1
			.byte $AF,$4E,$F4,$9E,$4E,$01,$BA,$76,$36,$F9,$C0,$8A  ; 2
			.byte $57,$27,$FA,$CF,$A7,$81,$5D,$3B,$1B,$FD,$E0,$C5  ; 3
			.byte $AC,$94,$7D,$68,$53,$40,$2E,$1D,$0D,$FE,$F0,$E3  ; 4
			.byte $D6,$CA,$BE,$B4,$AA,$A0,$97,$8F,$87,$7F,$78,$71  ; 5
			.byte $6B,$65,$5F,$5A,$55,$50,$4C,$47,$43,$40,$3C,$39  ; 6
			.byte $35,$32,$30,$2D,$2A,$28,$26,$24,$22,$20,$1E,$1C  ; 7
			.byte $1B,$19,$18,$16,$15,$14,$13,$12,$11,$10,$0F,$0E  ; 8
			.byte $1B,$19,$18,$16,$15,$14,$13,$12,$11,$10,$0F,$0E  ; 8
			.byte $1B,$19,$18,$16,$15,$14,$13

PSGTableHi
;				  C   C#  D   D#  E   F   F#  G   G#  A   A#  B
			.byte $0D,$0C,$0B,$0B,$0A,$0A,$09,$08,$08,$07,$07,$07  ; 1
			.byte $0D,$0C,$0B,$0B,$0A,$0A,$09,$08,$08,$07,$07,$07  ; 1
			.byte $06,$06,$05,$05,$05,$05,$04,$04,$04,$03,$03,$03  ; 2
			.byte $03,$03,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01  ; 3
			.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00  ; 4
			.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 5
			.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 6
			.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 7
			.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 8
			.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; 8
			.byte $00,$00,$00,$00,$00,$00,$00
			

			org $3400

			.byte ADS1-ADS1, ADS2-ADS1, ADS3-ADS1, ADS4-ADS1, ADS5-ADS1, ADS6-ADS1, ADS7-ADS1, ADS8-ADS1
			.byte ADS9-ADS1, ADS10-ADS1, ADS11-ADS1, ADS12-ADS1, ADS13-ADS1, ADS14-ADS1, ADS15-ADS1, ADS16-ADS1,EndADSR-ADS1
			
ADS1		.byte Rel1-ADS1-1
			.byte 15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,6
Rel1		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
ADS2		.byte Rel2-ADS2-1
			.byte $80+0,0,$80+15,15,3
Rel2		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
ADS3		.byte Rel3-ADS3-1
			.byte 0
Rel3		.byte 0
ADS4		.byte Rel4-ADS4-1
			.byte 0
Rel4		.byte 0
ADS5		.byte Rel5-ADS5-1
			.byte $80+0,0,$80+15,15,3
Rel5		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
ADS6		.byte Rel6-ADS6-1
			.byte 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,0
Rel6		.byte 0,15,0
ADS7		.byte Rel7-ADS7-1
			.byte 0
Rel7		.byte 0
ADS8		.byte Rel8-ADS8-1
			.byte 0
Rel8		.byte 0
ADS9		.byte Rel9-ADS9-1
			.byte 0
Rel9		.byte 0
ADS10		.byte Rel10-ADS10-1
			.byte 0
Rel10		.byte 0
ADS11		.byte Rel11-ADS11-1
			.byte 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,0
Rel11		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
ADS12		.byte Rel12-ADS12-1
			.byte 0
Rel12		.byte 0
ADS13		.byte Rel13-ADS13-1
			.byte 0
Rel13		.byte 0
ADS14		.byte Rel14-ADS14-1
			.byte 0
Rel14		.byte 0
ADS15		.byte Rel15-ADS15-1
			.byte 0
Rel15		.byte 0
ADS16		.byte Rel16-ADS16-1
			.byte $80+0,$80+0,$80+15,$80+15,3
Rel16		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
EndADSR		
