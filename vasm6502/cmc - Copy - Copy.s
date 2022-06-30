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

fat32_readbuffer = fat32_workspace

fat32_fatstart          = zp_fat32_variables + $00  ; 4 bytes
fat32_datastart         = zp_fat32_variables + $04  ; 4 bytes
fat32_rootcluster       = zp_fat32_variables + $08  ; 4 bytes
fat32_sectorspercluster = zp_fat32_variables + $0c  ; 1 byte
fat32_pendingsectors    = zp_fat32_variables + $0d  ; 1 byte
fat32_address           = zp_fat32_variables + $0e  ; 2 bytes
fat32_nextcluster       = zp_fat32_variables + $10  ; 4 bytes
fat32_bytesremaining    = zp_fat32_variables + $14  ; 4 bytes 

fat32_errorstage        = fat32_bytesremaining  ; only used during initializatio
fat32_filenamepointer   = fat32_bytesremaining  ; only used when searching for a file

	.org $0f00
jmptoit:
	jmp start

datname:
  .asciiz "CMC     RAW"  ; music file on SD card
dirname:
  .asciiz "FOLDER     "  ; folder
	
	.include "hwconfig.s"
	.include "kernal_def.s"

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

	JSR fat32_file_readbyte  ; 1. yes just one bomb for now.	
	LDA (fat32_address)	 ; buy a missle on amazon
	STA mor 		 ; load the missle
	STA sample		 ; prepare the cannons.

	jsr putbut
	lda #$c0
	sta $b00e
	cli

	stz done
	stz state
	cli
loop
	lda done
	beq loop

end:
	sei
	rts
	rts
	rts
	rts
	
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
	jsr fat32_file_readbyte
	sta sample
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

	.byte $f0		; smol... ah ye its actually 733kb. haha

yeryer

