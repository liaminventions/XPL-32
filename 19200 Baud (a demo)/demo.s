zp_sd_address = $40 ; 2
zp_sd_currentsector = $42 ; 4
zp_fat32_variables = $46 ; 24

fat32_workspace = $200

buffer = $400
endbuf = $600

PORTB = $b000
PORTA = $b001
DDRB = $b002
DDRA = $b003

SD_CS   = %00010000
SD_SCK  = %00001000
SD_MOSI = %00000100
SD_MISO = %00000010
EXTVID  = %10000000

PORTA_OUTPUTPINS = SD_CS | SD_SCK | SD_MOSI

  .org $0600

via_init:
  lda #%11111111          ; Set all pins on port B to output
  sta DDRB
  lda #PORTA_OUTPUTPINS   ; Set various pins on port A to output
  sta DDRA
  rts
  
  .include "libsd.s"
  .include "libfat32.s"
  .include "libacia.s"

wait:
	phx
	phy
        ldy  #$ff
        ldx  #$ff
delay   dex          ; (2 cycles)
        bne  delay   ; (3 cycles in loop, 2 cycles at end)
        dey          ; (2 cycles)
        bne  delay   ; (3 cycles in loop, 2 cycles at end)
	ply
	plx
	rts


  .org $0f00
  jsr via_init
  .include "sys.s"
  .include "text.s"

reset:
  jmp reset
