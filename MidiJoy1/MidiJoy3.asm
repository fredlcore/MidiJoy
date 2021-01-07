;			MidiJoy (c) 2014 by Frederik Holst

			run start
			
			DOSVEC = $0a
			ATTRACT = $4d
			SDMCTL = $22f
			SDLSTL = $230
			CH = $2fc
			TRIG0 = $d010
			TRIG1 = $d011
			AUDF1 = $d200
			AUDC1 = $d201
			AUDC2 = $d203
			AUDC3 = $d205
			AUDC4 = $d207

			AUDCTL = $d208
			SKCTL = $d20f

			PORTA = $d300

			ADSRStart = $4f00
			ADSRTable = ADSRStart+5
;			ADSRTable = ADSRMax+4

			org $80

MIDI		.byte 0
VOICE		.byte 0
PARAM		.byte 0
NOTE		.byte 0, 0
NOTETIMER	.word 0, 0, 0, 0
NOTEPTR		.word $5000
TEMPPTR		.word 0
PLAYPTR		.word $5000
PLAYAUDC	.byte 0
PLAYNOTE	.byte 0
PLAYTIMER	.word 0
TEMP		.byte 0
ACTL		.byte 0
AC1			.byte $a0, $a0, $a0, $a0
D12FLAG		.byte 0
SXBITFLAG	.byte 0
RECFLAG		.byte 0
PLAYFLAG	.byte 0
PORTASAVE	.byte 128
VOICESAVE	.byte 1
VOLSAVE		.byte 0, 0, 0, 0
VolTemp		.byte 0, 0, 0, 0
DispVol		.byte 0, 0 ,0 ,0
ADSRActive	.byte 0, 0, 0 ,0
ADSRC		.byte 1, 1, 1, 1
ADSRVol		.byte 0
ADSRDist	.byte 0
ADSRTemp	.byte 0
; POKEYOffset	.byte 0, 2, 4, 6
AUDCOffset	.byte 106, 117, 146, 157
;RelOffset	.byte Rel1-ADS1, Rel2-ADS2, Rel3-ADS3, Rel4-ADS4	; these can be adjusted if you need a longer release phase at the cost of shorter ADS phase
;RelMax		.byte ADS2-ADS1, ADS3-ADS2, ADS4-ADS3, ENDADSR-ADS4
RelMax		.byte 0, 0, 0, 0
EnvSrc		.word 0
EnvSelect	.byte 0
CHTemp		.byte 0

ACIndex		.byte 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3
BitTable	.byte "7", "6", "5", "4", "3", "2", "1", "0"

			org $3c00
start

			lda #<DLIST		; set up display list
			sta SDLSTL
			lda #>DLIST
			sta SDLSTL+1
			lda #%00100010
			sta SDMCTL
			lda #<INTRO
			sta 88
			lda #>INTRO
			sta 89

			lda #0
			sta AUDCTL
;			sta 20
			lda #3
			sta SKCTL
			
			ldy #<VBI		; set up VBI
			ldx #>VBI
			lda #6
			jsr $e45c

MainLoop
			lda CH
			sta CHTemp
			cmp #255
			bne checkinput
			jmp nokey

checkinput	lda #255
			sta CH

			ldx #7
nb1			lda AUDCTLKeys,x		; read AUDCTL-Keys (Q-Y)
			cmp CHTemp
			beq sb
			dex
			bpl nb1
			bmi audckey
sb			lda #255
			sta CHTemp
			lda AUDCTLVals,x
			eor ACTL
			sta ACTL

audckey		ldx #11					; read AUDC1-4 keys (A-H, Z-N)
nb2			lda ACKeys,x
			cmp CHTemp
			beq sb2
			dex
			bpl nb2
			bmi envkey
sb2			lda #255
			sta CHTemp
			lda ACVals,x
			ldy ACIndex,x
			eor AC1,y
			sta AC1,y

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
			sta $4f00,y
			dey
			bne nextenv

			ldy #3
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
			bne exitdos
			lda #255
			sta CHTemp
			lda D12FLAG
			eor #1
			sta D12FLAG

exitdos		lda CHTemp
			cmp #$01
			bne pauserec
			lda #255
			sta CHTemp
			jmp (DOSVEC)

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
			bne enter
			jmp playram

enter		lda CHTemp
			cmp #$0C
			bne nokey
			lda #255
			sta CHTemp
			lda #0
			sta RECFLAG
			sta 712
			ldy #7
resetsound	sta AUDC1,y
			dey
			bpl resetsound
;			lda #0
			sta NOTETIMER
			sta NOTETIMER+1
			sta NOTETIMER+2
			sta NOTETIMER+3
			sta NOTEPTR
			sta PLAYPTR
			lda #$50
			sta NOTEPTR+1
			sta PLAYPTR+1
			lda #"4"
			sta COUNTER
			lda #"F"
			sta COUNTER+1
			sta COUNTER+2
			sta COUNTER+3

nokey		lda ACTL
			sta AUDCTL
			sta TEMP

			ldy #95			; display AUDCTL bits on screen
			ldx #8
			jsr showbits
			jsr equalizer

			ldy #3				; display AUDC1-4 bits 5-7 on screen
nextaudc	lda AC1,y
			clc
			ror
			ror
			ror
			ror
			ror
			sta TEMP
			tya
			pha
			lda AUDCOffset,y
			tay
			ldx #3
			jsr showbits
			pla
			tay
			dey
;			cpy #0
			bpl nextaudc

			lda TRIG0			; Trigger 0 contains Bit 1 of voice channel
			asl
			clc
			adc TRIG1			; Trigger 1 contains Bit 0 of voice channel
			sta VOICE			; VOICE contains voice channel
			tax					; store VOICE in X

			lda PORTA			; read joysticks 1+2
			cmp PORTASAVE		; check if same or different note/voice combination than before
			bne play			; otherwise playing live would work, but saved data would fill up at once
			lda VOICE
			cmp VOICESAVE
			bne play
			jmp MainLoop

/*
			cmp #%10011111
			bmi play
			jmp MainLoop
*/

play		lda PORTA

/*
			lda CHTemp			; Dummy generation of Midi
			cmp #255
			bne playtemp
			jmp MainLoop
playtemp	lda #0
			sta VOICE
			tax
			inc TempMidi
			lda TempMidi
			cmp #6
			bne endtemp
			lda #0
			sta TempMidi
endtemp		ldy TempMidi
			lda TempData,y
*/

			sta PORTASAVE
			stx VOICESAVE
			sta MIDI			; and store in variable
			sta TEMP

			lda #255
			sta CHTemp

			lda VOICE			; Check for 16-bit voices (Midi-Channel 1 and 3)
			cmp #2
			beq checkv3
			cmp #0
			bne nosxbit
			lda ACTL			; Voice 1 16-bit?
			and #%00010000		; Compare with AUDCTL-Bit 3
			bne sxbit
			beq nosxbit
checkv3		lda ACTL			; Voice 3 16-bit?
			and #%00001000		; Compare with AUDCTL-Bit 4
			bne sxbit
nosxbit		lda #0				; Clear SXBITFLAG
sxbit		sta SXBITFLAG		; Or set it with $08/$10 respectively
			
			ldy VOICE
;			lda MIDI
;			lda POKEYOffset,y
			tya
			asl
			tay					; Y carries AUDF/C-Offset						

			lda MIDI
			and #%01111111		; isolate sound parameter (pitch or volume) from data 
			sta PARAM
			lda MIDI
			and #%10000000		; isolate command (bit 7)
			cmp #%10000000		; if set then volume, otherwise pitch
			bne setpitch

setvolume	clc
			tya					; AUDC1,2,3,4 distance = 2 each
			ror					; AC1,2,3,4 distance = 1 each
			tax					; i.e. Y=6, X=3
			lda SXBITFLAG		; But...
			beq cont8bit
			iny					; ...if 16-bit voice then volume goes to channel+1 (i.e. Y=Y+2, X remains)
			iny
cont8bit	lda PARAM
			and #%00001111
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
			clc
			adc AC1,x
;			sta AUDC1,y			; do not play note when envelopes are active
jmpsave		jsr savenote
			lda VOLSAVE,x
;			cmp #0
			bne jmpmainl2
			sta TEMP
			txa
			asl
			tay
			jsr dispnotes
jmpmainl2	jmp MainLoop		; jump back to main loop and wait for next lot of data

setpitch
			ldx VOICE			; Voice to X
			lda AC1,x			; Read distortion of voice X and use appropriate scale
			cmp #$20
			beq D2
			cmp #$c0
			beq D12
D10			ldx PARAM			; Midi-Note to X
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
D2			ldx PARAM			; Midi-Note to X
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
D12			ldx PARAM			; Midi-Note to X
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
;			jmp setfreq
			
setfreq		jsr dispnotes
			lda NOTE
			sta AUDF1,y			; store the data in the audio frequency register of channel 0 + offset
			lda SXBITFLAG
			beq jmpmainl
			lda #0
			sta AUDC1,y
			iny
			iny
			lda NOTE+1
			sta AUDF1,y
			
/*
dispnotes	ldy #95				; display note bits on screen
			ldx #8
			lda TEMP
			jsr shownotes
*/
			
jmpmainl	jmp MainLoop
jmpexitp	jmp exitplay

playram		lda #0
			sta NOTETIMER
			sta NOTETIMER+1
			sta NOTETIMER+2
			sta NOTETIMER+3
			sta CH
			sta PLAYPTR
			lda #$50
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
;			lda POKEYOffset,x
			txa
			asl
			tay						; Offset to Y
waittimer	lda NOTETIMER+1,y
			cmp PLAYTIMER+1			; Playtimer >= Notetimer (high byte)?
			bcc waittimer
			lda NOTETIMER,y
			cmp PLAYTIMER			; Playtimer >= Notetimer (low byte)?
			bcc waittimer
			lda #0					; First reset counters...
			sta PLAYTIMER
			sta PLAYTIMER+1
			sta NOTETIMER,y
			sta NOTETIMER+1,y
			lda PLAYAUDC			; then play note...
			and #%11110000
			sta AC1,x
			lda #1
			sta ADSRActive,x
			lda PLAYAUDC
			and #%00001111

			pha
			cmp #0				; Voice off, begin release phase?
			bne contADS
			tya
			pha
			ldy ADSRStart,x
			lda ADSRTable,y
			clc
			adc #1
;			lda RelOffset,x		; set beginning of release phase values
			sta ADSRC,x			; to counter
			pla
			tay
			bpl contplay
contADS		lda #1
			sta ADSRC,x
contplay	pla

			sta VOLSAVE,x
;			sta AUDC1,y
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
			
exitplay	ldy #3
waitenvend	lda ADSRActive,y
			bne waitenvend
			dey
			bpl waitenvend
			ldy #3
			lda #0
			sta PLAYFLAG
clearplayer	sta NOTETIMER,y
			sta AUDC1,y
			sta AUDC1+4,y
			sta ADSRActive,y
			sta ADSRC,y
			sta DispVol,y
			dey
			bpl clearplayer
			lda #255
			sta CH
			jmp MainLoop

savenote	ldy RECFLAG
			beq endnotesave
			ldy #0
			pha					; save distortion
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
			txa					; get channel again...
			asl					; multiply by 2 for pointer
			tay					; pointer in Y
			tax					; save pointer in X, too
			lda NOTETIMER,y
			ldy #0
			sta (NOTEPTR),y		; duration (1/50 seconds) of _previous_ note (low-byte)
			txa					; get pointer from X
			tay					; pointer in Y
			lda NOTETIMER+1,y
			ldy #0
			iny
			sta (NOTEPTR),y		; ...high byte
			txa					; get pointer from X, again...
			tay					; pointer in Y
			lda #0				; clear note timer
			sta NOTETIMER,y
			sta NOTETIMER+1,y
			jsr incptr
			jsr incptr
			lda SXBITFLAG
			beq endnotesave
			ldy #4				; copy previous voice data to next set
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
			lda #0
			sta (TEMPPTR),y		; clear distortion on lower channel
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
			cmp #1
			bne zero
			lda BitTable-1,x
			bpl output
zero		lda #"-"
output		sta (88),y
			lda TEMP
			clc
			ror
			sta TEMP
			dey
			dex
;			cpx #0
			bne showbits
			rts

dispnotes	sty MIDI			; save voice index in variable MIDI temporarily
			tya
			clc
			ror
			tax
			cpx #4				; number of voices
			bcs exitequ
			lda EquOffset,x
			tay
			ldx #8
nextbit		lda TEMP
			and #1
			cmp #1
			bne zero2
			lda BitTable-1,x
			bpl output2
zero2		lda #"-"
output2		sta INTRO+537,y
			lda TEMP
			clc
			ror
			sta TEMP
			dey
			dex
;			cpx #0
			bne nextbit
exitequ		ldy MIDI			; restore voice index
			rts


equalizer	ldx #15
nc1			cpx DispVol
			bcs nd1
			lda #128
			bne d1
nd1			lda #0
d1			sta INTRO+520,x		
			dex
;			cpx #0
			bpl nc1

			ldx #15
nc2			cpx DispVol+1
			bcs nd2
			lda #128
			bne dr2
nd2			lda #0
dr2			sta INTRO+560,x		
			dex
;			cpx #0
			bpl nc2

			ldx #15
nc3			cpx DispVol+2
			bcs nd3
			lda #128
			bne d3
nd3			lda #0
d3			sta INTRO+600,x		
			dex
;			cpx #0
			bpl nc3

			ldx #15
nc4			cpx DispVol+3
			bcs nd4
			lda #128
			bne d4
nd4			lda #0
d4			sta INTRO+640,x		
			dex
;			cpx #0
			bpl nc4
			rts

VBI			lda #0
			sta ATTRACT
			lda RECFLAG
			bne dotimer
			lda PLAYFLAG
			beq donetimer
dotimer		inc NOTETIMER
			bne donetimer0
			inc NOTETIMER+1
donetimer0	inc NOTETIMER+2
			bne donetimer1
			inc NOTETIMER+3
donetimer1	inc NOTETIMER+4
			bne donetimer2
			inc NOTETIMER+5
donetimer2	inc NOTETIMER+6
			bne donetimer3
			inc NOTETIMER+7
donetimer3	lda PLAYFLAG

donetimer	ldx #0
nextadsr	lda ADSRActive,x	; are we in ADSR mode?
			bne nextadsr2		; if not then next voice
			jmp nextx
nextadsr2	lda VOLSAVE,x		; get channel's volume
			pha					; save volume
			txa					; channel no. from X to A 
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
;			lda POKEYOffset,x	; find out where to store it
			txa
			asl
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
			cpx #4
			bne jmpnextadsr
			jmp $e45f
jmpnextadsr	jmp nextadsr

DLIST		.byte $70, $70, $70, $42
			.word INTRO
			.byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
			.byte $41
		    .word DLIST

AUDCTLKeys	.byte $2f, $2e, $2a, $28, $2d, $2b, $0b, $0d
AUDCTLVals	.byte 128, 64, 32, 16, 8, 4, 2, 1
ACKeys		.byte $3a, $3e, $3f, $39, $3d, $38, $12, $16, $17, $23, $15, $10
ACVals		.byte 32, 64, 128, 32, 64, 128, 32, 64, 128, 32, 64, 128
EnvKeys		.byte $1f, $1e, $1a, $18, $1d, $1b, $33, $35
EquOffset	.byte 7, 47, 87, 127
; TempData	.byte 143,65,135,65,128,50
; TEMPCOUNT	.byte 0
; TempMIDI	.byte 0

INTRO		.byte "   MidiJoy (c) 2014 by Frederik Holst"
			org INTRO+80
			.byte "AUDCTL:"
			org INTRO+97
			.byte "AUDC1:     AUDC2:"
			org INTRO+120
			.byte "Env.No.:"
EnvBank		.byte "12345678"
			org INTRO+137
			.byte "AUDC3:     AUDC4:"
			org INTRO+200
			.byte "Key Commands:"
			org INTRO+240
			.byte "Q-I: Set AUDCTL  A-H,Z-N: Set AUDCx"
			org INTRO+280
			.byte "1-8: Select Env. SPACE: Toggle D12 Dist."
			org INTRO+320
			.byte "J: Jump to DOS   RETURN: Reset"
			org INTRO+360
			.byte "P: Play Note-RAM TAB: Un/Pause Recording"
			org INTRO+440
			.byte "Note-RAM: $5000-$"
COUNTER		.byte "4FFF"
			org INTRO+760
MSG			.byte " "
			org INTRO+800
			.byte "           Serial No.: 0000"
			org INTRO+920
			.byte "       http://www.phobotron.de"

			org $4900

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

/*
			org $3400

			.byte ADS1-ADS1, ADS2-ADS1, ADS3-ADS1, ADS4-ADS1, EndADSR-ADS1
ADS1		.byte Rel1-ADS1-1
			.byte 15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,6
Rel1		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
ADS2		.byte Rel2-ADS2-1
			.byte 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,0
Rel2		.byte 0,15,0
ADS3		.byte Rel3-ADS3-1
			.byte 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,0
Rel3		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
ADS4		.byte Rel4-ADS4-1
			.byte $80+0,0,$80+15,15,3
Rel4		.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
EndADSR		
*/