			run start
			
			CH = $2fc
			TRIG0 = $d010
			AUDF1 = $d200
			AUDC1 = $d201
			AUDC2 = $d203
			AUDC3 = $d205
			AUDC4 = $d207

			AUDCTL = $d208
			SKCTL = $d20f

			PORTA = $d300

			org $80

MIDI		.byte 0
VOICE		.byte 0
PARAM		.byte 0
NOTE		.byte 0
TEMP		.byte 0
TRIGGER		.byte 0
ACTL		.byte 0
AC1			.byte $a0
AC2			.byte $a0
AC3			.byte $a0
AC4			.byte $a0
D12FLAG		.byte 0
			
			org $2000
start
			ldy #0
			ldx #0
nextchar	lda INTRO,x
			sta (88),y
			iny
			inx
			cpx #END-INTRO
			bne nextchar
			
			lda #0
			sta AUDCTL
			lda #3
			sta SKCTL

MainLoop
			ldx #7
nb1			lda AUDCTLKeys,x		; read AUDCTL-Keys (1-8)
			cmp CH
			beq sb
			dex
			bpl nb1
			bmi audckey
sb			lda AUDCTLVals,x
			eor ACTL
			sta ACTL

audckey		ldx #11					; read AUDC1-4 keys (Q-Z, A-H)
nb2			lda ACKeys,x
			cmp CH
			beq sb2
			dex
			bpl nb2
			bmi spacekey
sb2			lda ACVals,x
			ldy ACIndex,x
			eor AC1,y
			sta AC1,y

spacekey	lda CH
			cmp #$21
			bne nokey
			lda D12FLAG
			eor #1
			sta D12FLAG

nokey		lda #255
			sta CH

			lda ACTL
			sta AUDCTL
			sta TEMP

			ldy #135			; display AUDCTL bits on screen
			ldx #8
			jsr showbits

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
			cpy #0
			bpl nextaudc

			lda TRIG0
			lda #0
			sta TRIGGER
			lda PORTA			; read joysticks 1+2
/*
;			lda #%00001000
			lda MIDI
			adc 20
			eor #%10000000
			ora #%01110101
*/
			sta MIDI			; and store in variable
			sta TEMP

			lda MIDI
			clc
			and #%01100000		; isolate voice channel from data (bits 6+7)
			ror
			ror
			ror
			ror
			ror
			sta VOICE
			ldy VOICE
			lda POKEYOffset,y
			tay					; Y carries AUDF/C-Offset						

			lda MIDI
			and #%00011111		; isolate sound parameter (pitch or volume) from data 
			sta PARAM
			lda MIDI
			and #%10000000		; isolate command (bit 7)
			cmp #%10000000		; if set then volume, otherwise pitch
			beq setvolume

			lda TRIGGER			; fire button as 6th bit for pitch
			beq cont
			lda PARAM
			ora #%00100000
			sta PARAM
			sta TEMP

cont		
			ldx VOICE			; Voice to X
			lda AC1,x			; Read distortion of voice X and use appropriate scale
			cmp #$20
			beq D2
			cmp #$c0
			beq D12
D10			ldx PARAM			; Midi-Note to X
			lda NotesD10,x
			sta NOTE
			bne setfreq
D2			ldx PARAM			; Midi-Note to X
			lda NotesD2,x
			sta NOTE
			bne setfreq
D12			ldx PARAM			; Midi-Note to X
			lda D12FLAG
			bne D12b
			lda NotesD12,x
			bne setnote
D12b		lda NotesD12b,x
setnote		sta NOTE

setfreq		lda NOTE
			sta AUDF1,y			; store the data in the audio frequency register of channel 0 + offset
;			sta 708,y			; some graphic feedback
			
			ldy #95				; display note bits on screen
			ldx #8
			lda TEMP
			jsr showbits
			
			jmp MainLoop

setvolume	clc
			tya					; AUDC1,2,3,4 distance = 2 each
			ror					; AC1,2,3,4 distance = 1 each
			tax					; i.e. Y=6, X=3
			lda PARAM
			and #%00001111
			clc
			adc AC1,x
			sta AUDC1,y

			jmp  MainLoop		; jump back to main loop and wait for next lot of data

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
			cpx #0
			bne showbits
			rts

AUDCTLKeys	.byte $35, $33, $1b, $1d, $18, $1a, $1e, $1f
AUDCTLVals	.byte 1, 2, 4, 8, 16, 32, 64, 128
ACKeys		.byte $2a, $2e, $2f, $2b, $2d, $28, $3a, $3e, $3f, $39, $3d, $38
ACVals		.byte 32, 64, 128, 32, 64, 128, 32, 64, 128, 32, 64, 128
ACIndex		.byte 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3
BitTable	.byte "7", "6", "5", "4", "3", "2", "1", "0"
POKEYOffset	.byte 0, 2, 4, 6
AUDCOffset	.byte 106, 117, 146, 157
NotesD10	.byte 243, 230, 217, 204, 193, 182, 172, 162, 153, 144, 136, 128, 121, 114, 108, 102, 96, 91, 85, 81, 76, 72, 68, 64, 60, 57, 53, 50, 47, 45, 42, 40, 37, 35, 33, 31, 30, 28, 26, 25, 23, 22, 21, 19, 18, 17, 16, 15, 243, 230, 217, 204, 193, 182, 172, 162, 153, 144, 136, 128, 121, 114, 108, 102, 96, 91, 85, 81, 76, 72, 68, 64, 60, 57, 53, 50, 47, 45, 42, 40, 37, 35, 33, 31, 30, 28, 26, 25, 23, 22, 21, 19, 18, 17, 16, 15
NotesD2		.byte 31, 29, 27, 26, 24, 23, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 11, 10, 9, 9, 8, 8, 7, 7, 6, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1
NotesD12	.byte 130, 123, 117, 108, 103, 97, 93, 85, 82, 76, 72, 67, 63, 61, 57, 55, 51, 48, 45, 43, 40, 37, 36, 33, 31, 30, 28, 27, 25, 71, 22, 21, 62, 18, 53, 16, 15, 15, 15, 41, 12, 35, 35, 10, 10, 10, 10, 10
NotesD12b	.byte 245, 245, 245, 245, 245, 245, 245, 245, 245, 233, 218, 206, 197, 182, 173, 167, 155, 146, 137, 131, 122, 116, 184, 101, 98, 92, 86, 80, 77, 71, 68, 65, 62, 56, 53, 50, 47, 41, 41, 41, 38, 35, 32, 32, 26, 26, 26, 26

INTRO		.byte "   MidiJoy (P) 2014 by Frederik Holst"
			org INTRO+80
			.byte "Note:"
			org INTRO+97
			.byte "AUDC1:     AUDC2:"
			org INTRO+120
			.byte "AUDCTL:"
			org INTRO+137
			.byte "AUDC3:     AUDC4:"
END	

