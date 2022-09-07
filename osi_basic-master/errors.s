error_sound:
	sei
	jsr clear_sid
	lda #$0f
	sta $b818
	lda #$e7
	sta $b802
	lda #$0f
	sta $b805
	lda #$00 ; cheezy error sound that takes no memory (sad)
	sta $b806
	lda #$50
	sta $b800
	lda #$50
	sta $b801
	lda #$41
	sta $b804

outer:
	ldy #$ff
inner:
	ldx #$ff

innerloop:
	dex
	nop
	nop
	nop
	nop
	bne innerloop

	dey
	beq ende
	jmp inner
ende:
	jsr clear_sid
	rts
	
clear_sid:
	ldx #$17
	lda #0
csid:
	sta $B800,X
	dex
	bne csid
	rts

