addr = $02	; 2 bytes
flag = $03	; 1 byte
done = $04	; 1 byte
sample = $05	; 1 byte

	.org $0f00

start
	sei

	ldx #0
sidclr
	stz $b800,x
	inx
	bne sidclr

	lda #<irq
	sta $7ffe
	lda #>irq
	sta $7fff	
	lda #<mor
	sta loadnew+1
	lda #>mor
	sta loadnew+2

	lda #$55
	sta flag
	lda mor
	sta sample
	inc loadnew+1

	jsr putbut
	lda #$c0
	sta $b00e
	cli

	lda #0
	sta done
loop
	lda done
	beq loop

	rts
	rts
	rts
	rts	
putbut
	ldx #$2d
	stx $b004
	ldx #$00
	stx $b005
	ldx #$2d
	stx $b006
	ldx #$00
	stx $b007
	rts
irq
	pha

	lda sample
	ora #$10
	and #$1f
	sta $b818
	lda #$40
	sta $b00d

	asl flag
	bcc loadnew
	inc flag
shiftupr
	lda sample
	lsr a
	lsr a
	lsr a
	lsr a
	sta sample
	jsr putbut
	pla
	rti
loadnew
	lda $ffff
	sta sample
	inc loadnew+1
	beq next
	jsr putbut
	pla
	rti
next
	lda loadnew+2
	adc #$01
	cmp #>yeryer
	beq stop
	sta loadnew+2
	jsr putbut
	
	pla
	rti
stop
	sei
	inc done
	pla
	rti

mor

 	.binary "cmc_SCL_SR8K_2_RND.raw"

yeryer
