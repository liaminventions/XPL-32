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
  lda #%00101111 ; Set pins on port A  (L R A0 A CSR CSW MODE KEY)
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
  lda $05
  sta DIAS

  initvdp:
    lda %00001010
    sta PORTA
    lda %00000000
    sta VID
    lda $80
    sta VID

    lda %00001010
    sta PORTA
    lda %11010000
    sta VID
    lda $81
    sta VID
    
    lda %00001010
    sta PORTA
    lda %00000010
    sta VID
    lda $82
    sta VID

    lda %00001010
    sta PORTA
    lda $00
    sta VID
    lda $83
    sta VID

    lda %00001010
    sta PORTA
    lda $00
    sta VID
    lda $84
    sta VID

    lda %00001010
    sta PORTA
    lda $20
    sta VID
    lda $85
    sta VID

    lda %00001010
    sta PORTA
    lda $F1
    sta VID
    lda $87
    sta VID
    
    

  keypress:
    lda $01   ; Set Keyboard mode
    sta PORTB
    keypoit
      lda PORTB 
      sta $6005
      jmp keypoit

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
