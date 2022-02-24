; 6551 ACIA
ACIA_DATA = $8000
ACIA_STATUS = $8001
ACIA_COMMAND = $8002
ACIA_CONTROL = $8003

; -------------PAGE DEFINITIONS--------------

seed = $00     ;255 Bytes
addr = $0400   ;2 Bytes
answer = $0300 ;255 Bytes

; --------------ANSWER ADDRESSS--------------
    .org $0500
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8
    .word ans1
    .word ans2
    .word ans3
    .word ans4
    .word ans5
    .word ans6
    .word ans7
    .word ans8

; -------------------CODE--------------------

    .org $1000

reset:
  ldx #$ff                ; Initatlize stack pointer to FF
  txs

  ; Set up 6551 ACIA

  lda #%00001011          ;No parity, no echo, no interrupt
  sta ACIA_COMMAND
  lda #%00011111          ;1 stop bit, 8 data bits, 19200 baud
  sta ACIA_CONTROL
  
  ldx #0
ask:
  ;Write "Ask me anything" + CRLF
  jsr txpoll
  lda askmsg,x 
  beq readbyt
  inx 
  jmp ask
readbyt:
  ;Fill zero page with what you typed
  ldx #0
readloop:
  jsr rxpoll
  lda ACIA_DATA
  sta ACIA_DATA
  sta seed,x
  inx
  sbc #$0d
  beq rand
  lda ACIA_DATA
  sbc #$0a
  beq rand

rand:
  ldy #8     ; iteration count (generates 8 bits)
  lda seed
rand1:
  asl        ; shift the register
  rol seed+1
  bcc rand2
  eor #$39   ; apply XOR feedback whenever a 1 bit is shifted out
rand2:
  dey
  bne rand1
  sta seed+0
  cmp #0     ; reload flags
  
detrand:
  tax
  jmp (answer,x)
; -------------SUBROUTINES--------------

crlf:
  phx
  pha
  ldx #$ff
crlfloop
  jsr txpoll
  lda crlfbyte,x
  beq crlfend
  inx
  jmp crlfloop
crlfend: 
  pla
  plx
  rts
  
txpoll:
  pha
txpoll_loop:
  lda ACIA_STATUS
  and #$10
  beq txpoll_loop
  pla
  rts

rxpoll:
  pha
rxpoll_loop:
  lda ACIA_STATUS
  and #$08
  beq txpoll_loop
  pla
  rts

askmsg:
  .byte "Ask me anything", $0d, $0a, $00
crlfbyte:
  .byte $0d, $0a

jump_end:
  jmp readbyt

ans1:
  jsr txpoll
  lda msg1,x
  beq jump_end
  inx
  jmp ans1
msg1:
  .byte "No", $0d, $0a, $00

ans2:
  jsr txpoll
  lda msg2,x
  beq jump_end
  inx
  jmp ans2
msg2:
  .byte "Not Clear", $0d, $0a, $00

ans3:
  jsr txpoll
  lda msg3,x
  beq jump_end
  inx
  jmp ans3
msg3:
  .byte "Maybe So", $0d, $0a, $00

ans4:
  jsr txpoll
  lda msg4,x
  beq jump_end
  inx
  jmp ans4
msg4:
  .byte "Try again", $0d, $0a, $00

ans5:
  jsr txpoll
  lda msg5,x
  beq jump_end
  inx
  jmp ans5
msg5:
  .byte "Go ask the dog", $0d, $0a, $00

ans6:
  jsr txpoll
  lda msg6,x
  beq jump_end
  inx
  jmp ans6
msg6:
  .byte "Maybe", $0d, $0a, $00

ans7:
  jsr txpoll
  lda msg7,x
  beq jump_end2
  inx
  jmp ans7
msg7:
  .byte "Signs point to yes.", $0d, $0a, $00

ans8:
  jsr txpoll
  lda msg8,x
  beq jump_end2
  inx
  jmp ans8
msg8:
  .byte "Yes", $0d, $0a, $00

jump_end2:
  jmp readbyt

