;			MidiJoy sample code (c) 2014 by Frederik Holst

			run start

			TRIG0 = $d010
			TRIG1 = $d011
			AUDF1 = $d200
			AUDC1 = $d201
			AUDCTL = $d208
			SKCTL = $d20f
			PORTA = $d300
			
			org $4000

start
			lda #0				; initialize POKEY soundchip
			sta AUDCTL
			lda #3
			sta SKCTL

loop		ldx #255			; The dT delay in the Teensy code is set to accomodate more code on the 
wait		dex					; computer side. Remove or replace this loop with your own sound processing code			cpx #0				; or decrease dT delay in Teensy code it used for playback only
			bne wait			; or decrease dT delay in Teensy code it used for playback only

			lda TRIG0			; Trigger 0 contains Bit 1 of voice channel
			asl					; move left to Bit 1 position
			clc
			adc TRIG1			; Trigger 1 contains Bit 0 of voice channel
			asl					; POKEY sound registers are two bytes per voice, so multiply voice by two
			tay					; save resulting voice index in Y register

			lda PORTA			; read joysticks 1+2
			cmp #%10000000		; if bit 7 is set then volume data follows, otherwise pitch
			bcc setpitch

setvolume	and #%00001111		; mask lower four bits of Midi data which contain volume information
			clc
			adc #$a0			; add standard distortion (stored in the same POKEY register)
			sta AUDC1,y			; and set based on voice index (from Y)
			jmp loop
			
setpitch	tax					; transfer Midi value to X
			lda Notes,x			; load frequency from table using Midi pitch value from X as index
			sta AUDF1,y			; and set based on voice index (from Y)
			jmp loop
			
;			Note conversion table, sound values corresponding to Midi notes C0 (1st byte) to G10 (127th byte)
;			In case pitch range of the computer does not match Midi range, repeat lowest/highest octave accordingly
Notes		.byte $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $F3, $E6, $D9, $CC
			.byte $C1, $B6, $AC, $A2, $99, $90, $88, $80, $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2
			.byte $99, $90, $88, $80, $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80
			.byte $F3, $E6, $D9, $CC, $C1, $B6, $AC, $A2, $99, $90, $88, $80, $79, $72, $6C, $66
			.byte $60, $5B, $55, $51, $4C, $48, $44, $40, $3C, $39, $35, $32, $2F, $2D, $2A, $28
			.byte $25, $23, $21, $1F, $1E, $1C, $1A, $19, $17, $16, $15, $13, $12, $11, $10, $0F
			.byte $0E, $1C, $1A, $19, $17, $16, $15, $13, $12, $11, $10, $0F, $0E, $1C, $1A, $19
			.byte $17, $16, $15, $13, $12, $11, $10, $0F, $0E, $1C, $1A, $19, $17, $16, $15
