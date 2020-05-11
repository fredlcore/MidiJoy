; MidiJoy for Atari VCS 2600 (c) 2014 by Frederik Holst
; Interface port 1 -> VCS right port
; Interface port 2 -> VCS left port
; compiled with DASM

			processor 6502

COLUBK = $09
AUDC0 = $15
AUDC1 = $16
AUDF0 = $17
AUDV0 = $19
GRP0 = $1b
INPT4 = $3c
SWCHA = $280

			org $f000

start
			sei					; clear memory
			cld
			ldx #$ff
			txs
			lda #0
ClearMem	sta 0,x
			dex
			bne ClearMem

			lda #4				; initialize TIA "sound"chip, adjust here for different distortions
			sta AUDC0
			sta AUDC1

loop		ldx #255			; The dT delay in the Teensy code is set to accomodate more code on the 
wait		dex					; computer side. Remove or replace this loop with your own sound processing code
			bne wait			; or decrease dT delay in Teensy code it used for playback only

			lda INPT4			; Take voice channel from Trigger 1
			and #%10000000
			clc
			rol					; save resulting voice index in Y register (0 or 1)
			rol					; by shifting bit 7 to carry and then from carry to bit 0
			tay

			lda SWCHA			; read joysticks 1+2
			cmp #%10000000		; if bit 7 is set then volume data follows, otherwise pitch
			bcc setpitch

setvolume	
			and #%00001111		; mask lower four bits of Midi data which contain volume information
			sta AUDV0,y			; and set based on voice index (from Y)
			sta COLUBK			; some visual feedback :-)
			jmp loop
			
setpitch	
			and #%00011111		; lower 5 bits contain frequency value (0-31)
			tax
			lda NoteTable,x		; read from note table below based on frequency value
			sta AUDF0,y			; and set based on voice index (from Y)
			sta GRP0,y			; some visual feedback :-)
			jmp loop

			; note table tries to match chromatic scale in distortion 4
NoteTable	.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15
			.byte 29, 27, 26, 24, 23, 22, 20, 19, 18, 17, 16, 15

			; alternative note table matches every 32 frequencies of the VCS, no correlation to chromatic scale
;NoteTable	.byte 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20
;			.byte 19, 18, 17, 16, 15, 14, 13, 12, 11, 10
;			.byte 9, 8, 7, 6, 5, 4, 3, 2, 1, 0

			org $fffc
			.word start
			.word start