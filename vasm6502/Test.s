CHAR = $4000
VRAM = $5000
VREG = $5001
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e
SADDR = $7000
SDTA = $7001


K = %00000001

  .org $8000

reset:
  ldx #$ff
  txs
  cli

  lda #$82
  sta IER
  lda #$00
  sta PCR

  lda #%00000000 ; Set pins on Port B (Columns and Rows)
  sta DDRB
  lda #%00101001 ; Set pins on port A (KEY, U, D, nope, A, nope, R, L)
  sta DDRA

  ; On the left in DDRA/B, That is PA/B D7. Therefore, On the right is D0. (On 65C22)

setupsound:
  
  ldy #$08
  ldx #$03
  lda #$0f
  
setupsoundloop:
  sty SADDR     ; Loop to turn on volume
  sta SDTA
  iny
  dex
  bne setupsoundloop

              ; Turn on sound (mixer)
  lda #$07
  sta SADDR
  lda #%11111110
  sta SDTA
  
           ; Setup address for loop
  lda #$00
  sta SADDR
    
setupvid:
  ldx #$0f
  ldy #$08

setupirq:
  lda #$ff
  sta $00  

loop:
  stx VREG   ; Add color
  lda #$87   ; In Reg 7 (BG color)
  sta VREG
  sty SDTA
  jsr delay  ; Add delay
  iny
  dex
  bne loop
  ldx #$0f
  ldy #$08
  jmp loop



delay
  pha
  tya
  pha
  txa
  pha
  lda #$30
  sta $01
  ldy #$ff
  ldx #$ff
delayxy:
  dex
  bne delayxy
  dey
  bne delayxy
  lda #$00
  sta $01
  pla
  tax
  pla
  tay
  pla

kernal:
  
  lda $01
  sbc #$30

bugjmp:
  pla
  tax
  pla
  tay
  pla
  
starts:

  lda #$07
  sta SADDR       ; Turn off sound
  lda #$00 
  sta SDTA
    
  ldy #$00
  ldx #$08

init_vdp:

  lda $4000,y     ; Init VDP (Text)
  sta VREG
  tya
  adc #$80
  sta VREG
  iny
  dex
  bne init_vdp
  
init_char:




























  
  
  
  

nmi:
  rti

irq:
  pha
  tya
  pha
  txa
  pha
  ldy #$ff
  ldx #$ff
delayirq:
  dex
  bne delayirq
  dey
  bne delayirq
  bit PORTA
  
  lda $00
  sbc #$ff
  bne returnirq

returnirq:
  pla
  tax
  pla
  tay
  pla
  rti


  .org $fffa
  .word nmi
  .word reset
  .word irq
