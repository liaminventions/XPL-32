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

irqcount = $00
donefact = $01

; sd card:
zp_sd_address = $48         ; 2 bytes
zp_sd_currentsector = $4a   ; 4 bytes
zp_fat32_variables = $4f    ; 24 bytes
; only used during fat32 processing
path = $400		    ; page
fat32_workspace = $500      ; two pages
buffer = $700		    ; two pages
endbuf = $900

CR=13
LF=10

  .org $0f00

reset:
  ;jsr sd_init
  ;bcs sd_fail
  ; sd init done
  ;lda #'S'
  ;sta ACIAData
  ;jsr fat32_init
  ;bcs faterror
  ; fat32 init done
  ;jsr txpoll
  ;lda #'F'
  ;sta ACIAData

  ldx #<hehe
  ldy #>hehe
  jsr w_acia_full

  jsr rxpoll

  ldx #<goin
  ldy #>goin
  jsr w_acia_full

  lda #<buffer
  sta zp_sd_address
  lda #>buffer
  sta zp_sd_address+1
  
  ; save to sector 3
  lda #03
  sta zp_sd_currentsector
  stz zp_sd_currentsector+1
  stz zp_sd_currentsector+2
  stz zp_sd_currentsector+3

  jsr sd_readsector

; make a dummy file.
  ldx #$ff
  lda #$aa
dummyloop:
  txa
  sta $0700,x
  sta $0800,x
  dex
  bne dummyloop

  jsr sd_writesector

  ldx #<ded
  ldy #>ded
  jsr w_acia_full

  rts

;sd_fail:
;  lda #'s'
;  jsr print_chara
;  rts

hehe:
  .byte "Press any key to fill sector 3",CR,LF,0
goin:
  .byte "Filling...",0
ded:
  .byte "Done.",CR,LF,0

  .include "errors.s"
  .include "hwconfig.s"
  .include "libacia.s"
  .include "libsd.s"
  .include "libfat32.s"

failedmsg:
  .byte "Failed!",CR,LF,$00

