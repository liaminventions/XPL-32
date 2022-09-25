PORTB = $b000
PORTA = $b001
DDRB = $b002
DDRA = $b003

SD_CS   = %00010000
SD_SCK  = %00001000
SD_MOSI = %00000100
SD_MISO = %00000010
EXTVID  = %10000000

PORTA_OUTPUTS = EXTVID | SD_CS | SD_SCK | SD_MOSI

via_init:
  lda #%11111111          ; Set all pins on port B to output
  sta DDRB
  lda #PORTA_OUTPUTS   ; Set various pins on port A to output
  sta DDRA
  rts

