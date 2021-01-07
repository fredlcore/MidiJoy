			run start
			
			TRIG0 = $d010
			COLBK = $d01a
;			AUDF1 = $d200
;			AUDC1 = $d201
;			AUDF2 = $d202
			AUDC2 = $d203
;			AUDF1 = 708
;			AUDF2 = 709
;			AUDC1 = 710
;			AUDC2 = 712
			PORTA = $d300
			WSYNC = $d40a

;			AUDC1TMP = $80
;			AUDC2TMP = $81
;			AUDV1TMP = $82
;			AUDV2TMP = $83
			
			org $2000
start
MainLoop
			lda TRIG0			; load the status of the player 1 button into the accumulator 
			bne MainLoop        ; if there is nothing pressed, dont read data

			lda PORTA
			and #%00001110
			cmp #%00001010
			bne MainLoop
			

/*
			lda PORTA			; load the directional information of both joysticks into the accumulator
			cmp #$80			; swap nibbles
			rol
			cmp #$80
			rol
			cmp #$80
			rol
			cmp #$80
 			rol
			sta PORTATEMP
			and #%11100000		; for now, we are only interested in our three signifier bits...	

			cmp #%00000000		; let us compare the accumulator to a value
			beq REG0			; and jump to a register-loading function if the two are equal
			cmp #%00100000		; let us compare the accumulator to a value
			beq REG1			; and jump to a register-loading function if the two are equal
			cmp #%01000000		; let us compare the accumulator to a value
			beq REG2			; and jump to a register-loading function if the two are equal
			cmp #%01100000		; let us compare the accumulator to a value
			beq REG3			; and jump to a register-loading function if the two are equal
			cmp #%10000000		; let us compare the accumulator to a value
			beq REG4			; and jump to a register-loading function if the two are equal

			cmp #%10100000		; let us compare the accumulator to a value
			beq REG5			; and jump to a register-loading function if the two are equal
			jmp DontRead		; if it was a false value, jump back to the main loop

REG0
			lda PORTATEMP		; load the directional information of both joysticks into the accumulator
			sta AUDC1TMP		; store the data in the audio control register of channel 0
			jmp DontRead		; jump back to main loop and wait for next lot of data

REG1
			lda PORTATEMP		; load the directional information of both joysticks into the accumulator
			sta AUDC2TMP		; store the data in the audio control register of channel 1
			jmp DontRead		; jump back to main loop and wait for next lot of data

REG2
			ldx PORTATEMP		; load the directional information of both joysticks into the accumulator
			lda Notes,x
			sta AUDF1			; store the data in the audio frequency register of channel 0
			jmp DontRead		; jump back to main loop and wait for next lot of data

REG3
			ldx PORTATEMP		; load the directional information of both joysticks into the accumulator
			lda Notes,x
			sta AUDF2			; store the data in the audio frequency register of channel 1
			jmp DontRead		; jump back to main loop and wait for next lot of data

REG4
          	lda PORTATEMP		; load the directional information of both joysticks into the accumulator
			and #%00001111
			ora #%00010000
			sta AUDC1			; store the data in the audio volume register of channel 0
			sta 710
			jmp DontRead		; jump back to main loop and wait for next lot of data

REG5
			lda PORTATEMP		; load the directional information of both joysticks into the accumulator
			and #%00001111
*/
			lda PORTA
			lsr
			lsr
			lsr
			lsr
			ora #%00010000
			sta AUDC2			; store the data in the audio volume register of channel 1
			sta COLBK
			sta WSYNC


DontRead
			jmp  MainLoop		; jump back to main loop and wait for next lot of data

/*
Notes		.byte 243, 230, 217, 204, 193, 182, 172, 162, 153, 144, 136, 128, 121, 114, 108, 102, 96, 91, 85, 81, 76, 72, 68, 64, 60, 57, 53, 50, 47, 45, 42, 40, 37, 35, 33, 31, 30, 28, 26, 25, 23, 22, 21, 19, 18, 17, 16, 15, 14

PORTATEMP	.byte 0
*/
