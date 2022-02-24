; Echos the input from the terminal to the terminal and the LCD
;
; Serial port code from Ben Eater 6502 https://eater.net/6502
; ACIA code from:
; https://www.grappendorf.net/projects/6502-home-computer/acia-serial-interface-hello-world.html
;
; Additional components:
; 6551 ACIA
; 1.8432Mhz osciallator
; TTL/serial converter
;

; 6522 VIA

PORTA = $6001
PORTB = $6000
DDRA = $6003
DDRB = $6002

E  = %10000000
RW = %01000000
RS = %00100000

; 6551 ACIA

ACIA_DATA = $4000
ACIA_STATUS = $4001
ACIA_COMMAND = $4002
ACIA_CONTROL = $4003

    .org $8000

reset:
    ldx #$ff                ; Initatlize stack pointer to FF
    txs

    ; Set up 6522 VIA for the LCD

    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11100000          ; Set top 3 pins on port A to output
    sta DDRA                
    lda #%00111000          ; Set 8-bit mode; 2-line display; 5x8 font
    jsr send_lcd_command
    lda #%00001110          ; Display on; cursor on; blink off
    jsr send_lcd_command
    lda #%00000110          ; Increment and shift cursor; don't shift display
    jsr send_lcd_command
    lda #%00000001          ; Clear LCD
    jsr send_lcd_command


    ; Set up 6551 ACIA

    lda #%00001011          ;No parity, no echo, no interrupt
    sta ACIA_COMMAND
    lda #%00011111          ;1 stop bit, 8 data bits, 19200 baud
    sta ACIA_CONTROL

    ldx #0
lcd_time:
  lda message,x
  beq lcd_two
  jsr print_char
  inx
  jmp lcd_time

lcd_two:
  lda #%11000000            ;Next line
  jsr send_lcd_command
  ldx #0

lineloop:
  lda mess,x
  beq write
  jsr print_char
  inx
  jmp lineloop

write:
    LDX #0
next_char:
wait_txd_empty:
    LDA ACIA_STATUS
    AND #$10
    BEQ wait_txd_empty
    LDA text,x
    BEQ loop
    STA ACIA_DATA
    INX
    JMP next_char

loop:
  jmp loop

                ;Spaces align the text to the screen
                ; |||
message: .asciiz "   BE6502"
mess: .asciiz    "Hello, world!"

lcd_wait:
  pha
  lda #%00000000  ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts

send_lcd_command:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts


nmi:
    RTI

irq:
    RTI

text:                                           ; CR   LF                     
    .byte "Hello, World!", $0d, $0a, "SPECS:", $0d, $0a, "65c02 CPU at 1MHz", $0d, "AT28C256 EEPROM", $0d, "62256 SRAM", $0d, "65c22 VIA With LCD", $0d, "65c51 ACIA at 1.8432MHz", $0d, "74HC00 Quad NAND gate for address decoding", $0d, $0a, "And a TTL-Serial Converter using a FTDI Chip.", $0d, $00
                                                                               ;  CR   LF                                                    CR   LF  Null

    .org $FFFA
    .word nmi
    .word reset
    .word irq
