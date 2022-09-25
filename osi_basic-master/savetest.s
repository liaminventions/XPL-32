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
zp_fat32_variables = $46 ; 24

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
nmi:
  rti 
irq:
  rti 
  .org $fffc
  .word nmi
  .word reset
  .word irq