; 6551 ACIA
ACIA_DATA = $8000
ACIA_STATUS = $8001
ACIA_COMMAND = $8002
ACIA_CONTROL = $8003

    .org $1000

reset:

    ; Set up 6551 ACIA
    lda #%00001011          ;No parity, no echo, no interrupt
    sta ACIA_COMMAND
    lda #%00011111          ;1 stop bit, 8 data bits, 19200 baud
    sta ACIA_CONTROL

read:
    LDA ACIA_STATUS
    AND #$08
    BEQ read
    LDA ACIA_DATA
    STA ACIA_DATA
    JMP read
