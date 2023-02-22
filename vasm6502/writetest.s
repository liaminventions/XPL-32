; writetest
;
; !! THIS WILL ERASE THE SD CARD AND MAKE IT REQUIRE A REFORMAT !!
; 
; this code is just for debugging the sd_writesector subroutine.
; it will erase sector 0!
; 
; 

ACIA = $8000
ACIAControl = ACIA+3
ACIACommand = ACIA+2
ACIAStatus = ACIA+1
ACIAData = ACIA

fat32_workspace = $200      ; two pages

buffer = $400               ; 512 bytes
endbuf = $600

irqcount = $00
donefact = $01

zp_sd_address = $40 ; 2
zp_sd_currentsector = $42 ; 4
zp_fat32_variables = $46 ; 32

XYLODSAV2 = $64 ; 2

CR=13
LF=10

  .org $0f00

reset:
  ldx #<hehe
  ldy #>hehe
  jsr w_acia_full

  ; make a dummy file.
  ldx #0
dummyloop:
  txa
  sta $0600,x
  sta $0700,x
  inx
  bne dummyloop
  lda #$06
  sta zp_sd_address+1
  stz zp_sd_address
  
  stz zp_sd_currentsector
  stz zp_sd_currentsector+1
  stz zp_sd_currentsector+2
  stz zp_sd_currentsector+3

  jsr sd_writesector

  ldx #<ded
  ldy #>ded
  jsr w_acia_full

  rts

hehe:
  .byte "Press any key to erase the hard drive.",CR,LF,0
ded:
  .byte "SD card gone...",CR,LF,0

  .include "errors.s"
  .include "hwconfig.s"
  .include "libacia.s"
  .include "libsd.s"
  .include "libfat32.s"

