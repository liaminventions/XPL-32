addr = $02	; 2 bytes
flag = $03	; 1 byte
done = $04	; 1 byte
sample = $05	; 1 byte
state = $06	; 1 byte

zp_sd_address = $40         ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables = $46    ; 24 bytes

fat32_workspace = $200      ; two pages

buffer = $400               ; 512 bytes
endbuf = $600

	.org $0f00
jmptoit:
	jmp start

datname:
  .asciiz "CMC     RAW"  ; music file on SD card
dirname:
  .asciiz "FOLDER     "  ; folder
	
	.include "hwconfig.s"
	.include "libsd.s"	; ah ye sd tim
	.include "libfat32.s"

start
	sei

  ; Open root directory
  jsr fat32_openroot

  ; Find subdirectory by name
  ldx #<dirname
  ldy #>dirname
  jsr fat32_finddirent
  bcc foundsubdir

error:
  rts
  rts
  rts
  rts

foundsubdir

  ; Open subdirectory
  jsr fat32_opendirent
				; ok dats don

	ldx #0
sidclr
	stz $b800,x
	inx
	bne sidclr

	lda #<irq
	sta $7ffe
	lda #>irq
	sta $7fff	

	lda #$55
	sta flag

	; get the missle
	LDX #<datname		; low byte
	LDY #>datname		; high byte
	JSR fat32_finddirent	; do it
	bcc foundfile
	rts
	rts
	rts
	rts
foundfile:
	JSR fat32_opendirent	; yee

 	lda #<fat32_readbuffer
 	sta fat32_address
	sta loadnew+1
 	lda #>fat32_readbuffer
 	sta fat32_address+1
	sta loadnew+2

	; Round the size up to the next whole sector
	lda fat32_bytesremaining
  	cmp #1                      ; set carry if bottom 8 bits not zero
  	lda fat32_bytesremaining+1
  	adc #0                      ; add carry, if any
  	lsr                         ; divide by 2
  	adc #0                      ; round up

  	; No data?
  	beq end

  	; Store sector count - not a byte count any more
  	sta fat32_bytesremaining

	JSR fat32_readnextsector ; 512. yes just 512 bombs for now.	
	LDA (fat32_address)	 ; buy a missle on amazon
	STA mor 		 ; load the missle
	STA sample		 ; prepare the cannons.

	dec fat32_bytesremaining ; note - actually decrements sectors remaining

	jsr putbut
	lda #$c0
	sta $b00e
	cli

	stz done
	stz state
	cli
loop
	lda state
	bne nextsector
	lda done
	beq loop

end:
	sei
	rts
	rts
	rts
	rts

nextsector
	jsr fat32_readnextsector
	bcs end
	stz state
	dec fat32_bytesremaining	; note - actually decrements sectors remaining
	beq end
	jmp loop
	
putbut
	ldx #$80
	stx $b004
	stx $b006
	ldx #$00
	stx $b005
	stx $b007
	rts
irq
	pha
	phx
	phy

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

	ply
	plx
	pla
	rti

loadnew
	lda $ffff
	sta sample
	inc loadnew+1
	beq next
	jsr putbut
	ply
	plx
	pla
	rti
next
	lda loadnew+2
	adc #$01
	cmp #>fat32_readbuffer
	beq nextsect
	sta loadnew+2
	jsr putbut
	ply
	plx
	pla
	rti

nextsect:
	lda #<fat32_readbuffer
	sta loadnew+1
 	lda #>fat32_readbuffer
	sta loadnew+2
	lda #$01
	sta state
	jsr putbut
	ply
	plx
	pla
	rti
	

stop
	sei
	inc done
	ply
	plx
	pla
	rti

mor

	.byte $f0		; smol... ah ye its actually many MB. haha
				; RONG BTW!!!!!!!!

yeryer

