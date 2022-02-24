DATA = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
DATM = %00100000

  .org $8000

reset:
  ldx #$ff
  txs

  lda #%11111111 ; Set all pins on port B to output (YMZ284 D0-7)
  sta DDRB
  lda #%00100000 ; Set pin on port A to output (L R A0 U D M CSR CSW)
  sta DDRA

  ldx #0
  
  lda #0    ; Reset Ports
  sta PORTA
  lda #0
  sta DATA

main:
  jsr addr
  lda $00
  sta DATA
  jsr mode
  lda $09
  sta DATA
  toggle:
    jsr mixera
    jsr delay
    jsr mixero
    jsr delay
    jmp toggle
  
addr:
  lda #0
  sta PORTA
  rts

delay:
  ldx $ff
  parent: 
    dex
    bne parent
    rts

mode:
  lda DATM
  sta PORTA
  rts 

mixera:
  lda #0    ; ADDR Mode
  sta PORTA
  lda $07   ; Mixer Address
  sta DATA
  lda DATM   ; DTA Mode
  sta PORTA
  lda $FE   ; Tone A is set
  rts

mixero:
  lda #0    ; ADDR Mode
  sta PORTA
  lda $07   ; Mixer Address
  sta DATA
  lda DATM   ; DTA Mode
  sta PORTA
  lda $FF   ; Tones Are Off
  rts
  
loop:
  jmp loop

  .org $fffc
  .word reset
  .word $0000
