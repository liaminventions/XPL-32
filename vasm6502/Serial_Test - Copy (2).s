; 6551 ACIA
ACIA_DATA = $8000
ACIA_STATUS = $8001
ACIA_COMMAND = $8002
ACIA_CONTROL = $8003

    .org $c000

reset:
    ldx #$ff 
    txs

    ; Set up 6551 ACIA
    lda #%00001011          ;No parity, no echo, no interrupt
    sta ACIA_COMMAND
    lda #%00011111          ;1 stop bit, 8 data bits, 19200 baud
    sta ACIA_CONTROL

write:
    LDX #0
next_char:
wait_txd_empty:
    LDA ACIA_STATUS
    AND #$10
    BEQ wait_txd_empty
    LDA text,x
    BEQ jump
    STA ACIA_DATA
    INX
    JMP next_char

jump:
  JMP jump

text:
   .byte $0c, "Hi buts!", $0d, $0a, "If u seee dis itt workk"

  .org $fffc
  .word reset
  .word $0000
