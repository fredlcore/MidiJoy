			run start

			ATTRACT = $4d
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

			ADSRTable = ADSRMax+4

			org $CB

NOTEPTR		.word $9900			; change this to end of notes
PLAYPTR		.word $5000			; change this to beginning of notes
PLAYTIMER	.word 0
TIMER		.byte 0

			org $4000

			pla					; BASIC routine to pull beginning and length of notes
			cmp #2				; usage: X=USR(16384,PLAYPTR,NOTEPTR) (see above)
			beq pulldata
			tay					; not exactly 2 arguments, so exit, but do leave with a proper stack...
			dey
clearstack	pla
			pla
			dey
			bpl clearstack
			rts

pulldata	pla
			sta PLAYPTR+1
			pla
			sta PLAYPTR
			pla 
			sta NOTEPTR+1
			pla 
			sta NOTEPTR

start
			lda PLAYPTR
			sta TEMPPTR
			lda PLAYPTR+1
			sta TEMPPTR+1
			
			ldy #<VBI				; set up VBI
			ldx #>VBI
			lda #6
			jsr $e45c

			lda #3
			sta SKCTL
			lda #0
			sta AUDCTL
			sta 20
			
			ldy #3
cleartimer	sta NOTETIMER,y
			dey
			bpl cleartimer

playloop	
			sec
			lda 20
			sbc TIMER
			beq playloop
			lda 20
			sta TIMER
			lda #0
			sta ATTRACT

			inc NOTETIMER			; increase timer
			bne donetimer0
			inc NOTETIMER+1
donetimer0	inc NOTETIMER+2
			bne donetimer1
			inc NOTETIMER+3
donetimer1	inc NOTETIMER+4
			bne donetimer2
			inc NOTETIMER+5
donetimer2	inc NOTETIMER+6
			bne exitcond
			inc NOTETIMER+7
			
exitcond	lda CH					; define an exit condition - here: SPACE key
			cmp #$21
			beq jmpexitp
			lda PLAYPTR+1			; check end of music
			cmp NOTEPTR+1
			bcc doplay
			lda PLAYPTR
			cmp NOTEPTR
jmpexitp	bcs exitplay

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

			lda POKEYOffset,x
			tay						; Offset to Y
waittimer	lda NOTETIMER+1,y
			cmp PLAYTIMER+1			; Playtimer >= Notetimer (high byte)?
			bcc playloop
			lda NOTETIMER,y
			cmp PLAYTIMER			; Playtimer >= Notetimer (low byte)?
			bcc playloop
			lda #0					; First reset counters...
			sta PLAYTIMER
			sta PLAYTIMER+1
			sta NOTETIMER,y
			sta NOTETIMER+1,y
			lda PLAYAUDC			; then play note...
			and #%11110000
			sta AC1,x
			sta ADSRActive,x
			lda PLAYAUDC
			and #%00001111

			pha
			cmp #0				; Voice off, begin release phase?
			bne contADS
			lda RelOffset,x		; set beginning of release phase values
			sta ADSRC,x			; to counter
			bne contplay
contADS		lda #0
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
			bcc jmpexitc
			lda PLAYPTR+1
			adc #0
			sta PLAYPTR+1
jmpexitc	jmp exitcond
			
exitplay	ldy #$5f			; disable VBI
			ldx #$e4
			lda #6
			jsr $e45c

			ldy #3
			lda #0
clearplayer	sta NOTETIMER,y
			sta AUDC1,y
			sta AUDC1+4,y
			dey
			bpl clearplayer
			rts

VBI			ldx #0
nextadsr	lda ADSRActive,x	; are we in ADSR mode?
			beq nextx			; if not then next voice
			lda VOLSAVE,x		; get channel's volume
			pha					; save volume
			txa					; channel no. from X to A 
			asl					; move six bits to left as pointer for ADSR table
			asl
			asl
			asl
			asl
			asl
			adc ADSRC,x			; add counter to create final pointer
			tay					; store pointer in Y
			sta ADSRTemp		; and in temp variable
			pla					; get back volume

			cmp #0				; are we in release phase
			bne adsphase
relphase	clc					; yes, then add value to current sound level (zero)
			adc ADSRTable,y
			cmp VOLTemp,x
			bcc setadsr
			lda VOLTemp,x
			jmp setadsr

adsphase	sec					; otherwise, in ADS mode:
			sbc ADSRTable,y		; subtract envelope
			sta VOLTemp,x		; remember last volume level for possible release phase
			bcs setadsr			; less than zero?
			lda #0				; then zero it is.
			sta VOLTemp,x
setadsr		sta DispVol,x
			clc
			adc AC1,x			; add distortion
			pha					; save resulting AUDC value
			lda POKEYOffset,x	; find out where to store it
			tay
			pla
			sta AUDC1,y			; and play

			lda ADSRC,x			; increase envelope counter
			clc
			adc #1
			cmp RelMax,x		; if in release mode
			beq resetADSR		; check for end of release
			cmp ADSRMax,x		; otherwise, is ADS stage maxed out?
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

resetADSR	lda #0
			sta ADSRC,x
			sta ADSRActive,x

nextx		inx
			cpx #4
			bne nextadsr
			jmp $e45f

NOTE		.byte 0, 0
NOTETIMER	.word 0, 0, 0, 0
PLAYAUDC	.byte 0
PLAYNOTE	.byte 0
TEMPPTR		.word 0

POKEYOffset	.byte 0, 2, 4, 6
RelOffset	.byte $30, $70, $b0, $f0	; these can be adjusted if you need a longer release phase at the cost of shorter ADS phase
RelMax		.byte $40, $80, $c0, $00
ADSRC		.byte 0, 0, 0, 0
AC1			.byte $a0, $a0, $a0, $a0
VOLSAVE		.byte 0, 0, 0, 0
VolTemp		.byte 0, 0, 0, 0
DispVol		.byte 0, 0 ,0 ,0
ADSRActive	.byte 0, 0, 0 ,0
ADSRTemp	.byte 0

			org $4efc
ADSRMax
/*
ADSRMax		.byte 32, 34, 26, 4
			.byte 15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,6
			org $4f30
			.byte 6,6,5,5,4,4,3,3,2,2,1,1,0,0
			org $4f40
			.byte 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,0
			org $4f80
			.byte 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,0
			org $4fc0
			.byte 0,0,15,15,3
*/