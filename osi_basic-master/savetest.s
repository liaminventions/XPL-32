; Save test
; 
; this code is just for debugging the sd card saving system.
; i will use ben eater's debugger for this.
; BUG not sure if the SD card or the ACIA can run at a low clock rate
; 
ACIA = $8000
ACIAControl = ACIA+3
ACIACommand = ACIA+2
ACIAStatus = ACIA+1
ACIAData = ACIA

fat32_workspace = $200      ; two pages

buffer = $400               ; 512 bytes
endbuf = $600

zp_sd_address = $40 ; 2
zp_sd_currentsector = $42 ; 4
zp_fat32_variables = $46 ; 32

XYLODSAV2 = $64 ; 2

  .org $c000
reset:
  ldx #$ff
  txs
  jsr via_init
  ; via init done
  jsr txpoll
  lda #'V'
  sta ACIAData
  jsr acia_init
  ; acia init done
  jsr txpoll
  lda #'A'
  sta ACIAData
  jsr sd_init
  ; sd init done
  jsr txpoll
  lda #'S'
  sta ACIAData
  jsr fat32_init
  ; fat32 init done
  jsr txpoll
  lda #'F'
  sta ACIAData
  ; init done
  ; now make a dummy file.
  ldx #0
dummyloop:
  txa
  sta $0601,x
  inx
  bne dummyloop
  ; add an EOF
  lda #0
  sta $0701
  sta $0702
  sta $0703

  jmp MEMORY_SAVE ; OK, here we go.

  .include "hwconfig.s"
  .include "libacia.s"
  .include "libsd.s"
  .include "libfat32.s"

rootsetup:		; setup <ROOT>

  ; Open root directory
  jsr fat32_openroot

  ; Find the subdirectory by name
  ldx #<dirname
  ldy #>dirname
  jsr fat32_finddirent
  bcc foundsub

  ; Subdirectory not found
  jmp transfer_error

foundsub:

  ; Open subdirectory
  jsr fat32_opendirent	; open folder
	
  rts			; done

transfer_error:
  ldy #>errormsg
  ldx #<errormsg
  jsr w_acia_full
  jsr error_sound
  jmp stop_sl

msincremaining:
    inc fat32_bytesremaining
    bne msinca
    inc fat32_bytesremaining
msinca:
    inc XYLODSAV2
    bne msincb
    inc XYLODSAV2+1
msincb:
    rts
MEMORY_SAVE:
    ; finally. this is what we need to debug.
	jsr rootsetup
	jsr list
	jsr type
        jsr fat32_findnextfreecluster
	ldy #>sdbuffer
	ldx #<sdbuffer
	jsr fat32_finddirent
	bcs saveok
	jsr file_exists
	bcs stopmemsave
saveok:
        ; Now calculate file size and store it in fat32_bytesremaining.
        lda #$01
        sta XYLODSAV2
        lda #$06
        sta XYLODSAV2+1
        lda #0
        sta fat32_bytesremaining
        sta fat32_bytesremaining
        ldy #0
savecalclp:
        lda (XYLODSAV2),y
        beq mszero
        jsr msincremaining
        jmp savecalclp
mszero:
        jsr msincremaining
        lda (XYLODSAV2),y
        bne savecalclp
        jsr msincremaining
        lda (XYLODSAV2),y
        bne savecalclp
; done
	jsr fat32_writedirent
	ldx #<savmsg
 	ldy #>savmsg
  	jsr w_acia_full
  	lda #$01
  	sta fat32_address
  	lda #$06
  	sta fat32_address+1
  	jsr fat32_file_write  ; Yes. It is finally time to save the file.
  	ldx #<SAVE_DONE
  	ldy #>SAVE_DONE
  	jsr w_acia_full
stopmemsave:
doneloop:
	jmp doneloop
file_exists:
	; clc if 'y'
	; sec if 'n'
	ldx #<EXIST_MSG
	ldy #>EXIST_MSG
	jsr w_acia_full
fexlp:
	jsr rxpoll
	lda ACIAData
	pha
	cmp #'y'
	beq exy
	cmp #'n'
	beq exn
	pla
	jmp fexlp
exy:
	jsr crlf
	clc
	rts
exn:
	jsr crlf
	sec
	rts

nmi:
  rti 
irq:
  rti

  .org $fffc
  .word nmi
  .word reset
  .word irq