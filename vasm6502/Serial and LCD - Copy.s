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

    .org $1000

reset:
    ; Set up 6522 VIA for the LCD
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11100001          ; Set top 3 pins on port A to output
    sta DDRA
    lda #%00111000          ; Set 8-bit mode; 2-line display; 5x8 font
    JSR send_lcd_command
    lda #%00001110          ; Display on; cursor on; blink off
    JSR send_lcd_command
    lda #%00000110          ; Increment and shift cursor; don't shift display
    JSR send_lcd_command

write:
    LDX #0
next_char:
wait_txd_empty:
    LDA ACIA_STATUS
    AND #$10
    BEQ wait_txd_empty
    LDA text,x
    BEQ read
    STA ACIA_DATA
    INX
    JMP next_char
read:
    LDA ACIA_STATUS
    AND #$08
    BEQ read
    LDA ACIA_DATA
    STA ACIA_DATA
    JSR write_lcd           ; Also send to LCD
    JMP read

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

write_lcd:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

text:                    ; CR   LF  Null
    .byte "Hello World!", $0d, $0a, $00

