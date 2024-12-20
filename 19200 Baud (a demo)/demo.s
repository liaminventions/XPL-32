scroll = $00
scrollinc = $01
sco = $02
count = $03

  .include "kernal_def.s"

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

  .org $0f00

  jsr via_init
  jmp sys

via_init:
  lda #%11111111          ; Set all pins on port B to output
  sta DDRB
  lda #PORTA_OUTPUTPINS   ; Set various pins on port A to output
  sta DDRA
  rts
  
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
sys:
  .include "sys.s"
  .include "text.s"

reset:
  jmp reset

scrollmsg:

  .byte "6502 Power! I know that the graphics look simple, but under the hood, it is crazy. Just wait till you see the color video part a bit later...           A retro laptop with 4 expansion slots       just like PCI slots!", $00
