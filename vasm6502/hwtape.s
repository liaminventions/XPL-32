PORTB = $b000
PORTA = $b001
DDRB = $b002
DDRA = $b003

;LCD_E  = %10000000
;LCD_RW = %01000000
;LCD_RS = %00100000

SD_CS    = %00010000
SD_SCK   = %00001000
SD_MOSI  = %00000100
SD_MISO  = %00000010
TAPE_EAR = %00000000 ; PA6 IN
TAPE_MIC = %10000000 ; PA7 OUT

PORTA_OUTPUTPINS = TAPE_EAR | TAPE_MIC

via_init:
  lda #%11111111          ; Set all pins on port B to output
  sta DDRB
  lda #PORTA_OUTPUTPINS   ; Set various pins on port A to output
  sta DDRA
  rts

