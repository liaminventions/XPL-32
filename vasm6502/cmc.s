addr = $02	; 2 bytes
flag = $03	; 1 byte
done = $04	; 1 byte
sample = $05	; 1 byte

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
  .asciiz "SMOL    RAW"  ; music file on SD card
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

	JSR fat32_file_readbyte ; one. yes just one bomb for now.
	STA mor 		; load the missle
	STA sample		; prepare the cannons.

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
	ldx #$5a
	stx $b004
	ldx #$00
	stx $b005
	ldx #$5a
	stx $b006
	ldx #$00
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
        JSR fat32_file_readbyte ; manny! read da bite.
        BCS stop               ; 2-3- if thats it then stop
	STA mor
        STA sample              ; 3- save to temp location

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

	.byte $88		; smol... ah ye its actually many MB. haha

yeryer

