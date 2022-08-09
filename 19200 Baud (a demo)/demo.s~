scroll = $00
scrollinc = $01
sco = $02
count = $03

zp_sd_address = $40 ; 2
zp_sd_currentsector = $42 ; 4
zp_fat32_variables = $46 ; 24

fat32_workspace = $200

fat32_readbuffer = fat32_workspace

fat32_fatstart          = zp_fat32_variables + $00  ; 4 bytes
fat32_datastart         = zp_fat32_variables + $04  ; 4 bytes
fat32_rootcluster       = zp_fat32_variables + $08  ; 4 bytes
fat32_sectorspercluster = zp_fat32_variables + $0c  ; 1 byte
fat32_pendingsectors    = zp_fat32_variables + $0d  ; 1 byte
fat32_address           = zp_fat32_variables + $0e  ; 2 bytes
fat32_nextcluster       = zp_fat32_variables + $10  ; 4 bytes
fat32_bytesremaining    = zp_fat32_variables + $14  ; 4 bytes 

fat32_errorstage        = fat32_bytesremaining  ; only used during initializatio
fat32_filenamepointer   = fat32_bytesremaining  ; only used when searching for a file

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
  .include "text better.s"

reset:
  jmp reset

scrollmsg:

  .byte "6502 Power! I know that the graphics look simple, but under the hood, it is crazy. Just wait till you see the color video part a bit later...           A retro laptop with 4 expansion slots       just like PCI slots!", $00

  .include "kernal_def.s"
