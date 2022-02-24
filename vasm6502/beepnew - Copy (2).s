PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
VID = $6010
DIAS = $6011



  .org $8000

reset:
  ldx #$ff
  txs

  lda #%00000000 ; Set all pins on port B to input (C0-3 R0-3 (Keyboard) )
  sta DDRB
  lda #%00101111 ; Set pins on port A  (L R A0 A Mode CSW CSR KEY)
  sta DDRA

  ; On the left in DDRA/B, That is PA/B D7. Therefore, On the right is D0. (On 65C22) 

  ldx #0
  
  lda #0    ; Reset Ports
  sta PORTA
  lda #0
  sta PORTB

main:
  jsr mixero
  jsr addr
  lda $00
  sta DIAS
  jsr mode
  lda $0C
  sta DIAS
  jsr mixera
  jsr earbut
  jsr loop
   
addr:
  lda #0
  sta PORTA
  rts

delayt:
  ldx $ee
  parentt: 
    dex
    bne parentt
    rts

earbut:
  jsr addr
  lda $08
  sta DIAS
  jsr mode
  lda $0F
  rts

delay:
  ldx $ff
  parent: 
    dex
    bne parent
    rts

mode:
  lda %00100000
  sta PORTA
  rts 

mixera:
  lda #0    ; ADDR Mode
  sta PORTA
  lda $07   ; Mixer Address
  sta DIAS
  lda %00100000  ; DTA Mode
  sta PORTA
  lda $FE   ; Tone A is set
  rts

mixero:
  lda #0    ; ADDR Mode
  sta PORTA
  lda $07   ; Mixer Address
  sta DIAS
  lda %00100000   ; DTA Mode
  sta PORTA
  lda $FF   ; Tones Are Off
  rts
  
loop:
  jmp loop
  
  .org $fffc
  .word reset
  .word $0000
