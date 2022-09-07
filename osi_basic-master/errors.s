error_sound:
	jsr clear_sid
	lda #$0f
	sta $b818
	lda #$e7
	sta $b802
	lda #$0f
	sta $b805
	lda #$f8 ; cheezy error sound that takes no memory (sad)
	sta $b806
	lda freq_table
	sta $b800
	lda freq_table+1
	sta $b801
	lda #$41
	sta $b804

outer:
	ldy #$ff
inner:
	ldx #$ff

innerloop:
	dex
	bne innerloop

	dey
	beq ende
	jmp inner
ende:
	lda #$40
	sta $b804
	rts
	
freq_table:
	.byte $50, $50

clear_sid:
	ldx #$18
	lda #0
csid:
	sta $B800,X
	dex
	bne csid
	rts

