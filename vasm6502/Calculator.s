; 6551 ACIA

ACIA_DATA = $8000
ACIA_STATUS = $8001
ACIA_COMMAND = $8002
ACIA_CONTROL = $8003

; -----------------------ZERO PAGE-----------------------

ANSWER = $00
NUMBER1 = $01
NUMBER2 = $02
REMANDER = $0a
TMP = $0d

; -------------------------CODE--------------------------
    .org $1000

reset:
    ldx #$ff                ; Initatlize stack pointer to FF
    txs

    ; Set up 6551 ACIA

    lda #%00001011          ; No parity, no echo, no interrupt
    sta ACIA_COMMAND
    lda #%00011111          ; 1 stop bit, 8 data bits, 19200 baud
    sta ACIA_CONTROL

    LDX #0
start:
    JSR txpoll
    LDA one,x         ; Write first message
    BEQ read_one
    STA ACIA_DATA
    INX
    JMP start

read_one:
  ldx #0
read_one_start:
  jsr rxpoll 

  lda ACIA_DATA
  STA TMP
  sbc #$0d           ; If <ENTER> then continue
  beq write_two
  lda TMP
  sbc #$0a
  beq write_two

  lda TMP
  sta ACIA_DATA      ; Write back to ACIA
  sta NUMBER1        ; Store number

  jmp read_one_start

write_two:
  ldx #0
write_two_start:
  jsr txpoll
  lda two,x         ; Write second message
  beq read_two
  sta ACIA_DATA
  inx
  jmp write_two_start

read_two:
  ldx #0
read_two_start:
  jsr rxpoll

  lda ACIA_DATA
  sta TMP
  sbc #$0d          ; If <ENTER> then continue
  beq find
  lda TMP
  sbc #$0a
  beq find

  lda TMP
  sta ACIA_DATA     ; Write back to ACIA
  sta NUMBER2       ; Store number

  jmp read_two_start

find:
  ldx #0
find_write:
  jsr txpoll
  lda three,x        ; Write "Enter [m] for multiplication, [s] for subtraction, [a] for addition, or [d] for division" 
  beq find_read
  sta ACIA_DATA
  inx
  jmp find_write

find_read:
  ldx #0
  lda NUMBER1
  sbc #$30
  sta NUMBER1
  lda NUMBER2
  sbc #$30
  sta NUMBER2

testbytes:
  jsr rxpoll
  lda ACIA_DATA
  sta TMP
  sbc #$6d
  beq mult
  lda TMP
  sbc #$73
  beq sub
  lda TMP
  sbc #$61
  beq add
  lda TMP
  sbc #$64
  beq div
  jmp testbytes

sub:
  lda NUMBER1
  sbc NUMBER2
  sta ANSWER
  jmp finish

add:
  lda NUMBER1
  adc NUMBER2
  sta ANSWER
  jmp finish

mult:
  lda NUMBER1
  ldy NUMBER2
  lsr a  ; Prime the carry bit for the loop
  sta ANSWER
  sty NUMBER1
  lda #0
  ldy #8
multloop:
  ; At the start of the loop, one bit of prodlo has already been
  ; shifted out into the carry.
  bcc noadd
  clc
  adc NUMBER1
noadd:
  ror a
  ror ANSWER  ; pull another bit out for the next iteration
  dey         ; inc/dec don't modify carry; only shifts and adds do
  bne multloop
  jmp finish

div:
  LDA NUMBER1
  STY NUMBER2
  LDY #$0      ; reset y to 0
  SEC          ; set carry
divloop:
  SBC NUMBER2  ; subtract divisor from divedend
  BCC divend   ; if carry cleared, meaning subtraction went below 0
  INY          ; increment y to increase quotient
  BNE divloop
divend:
  STY ANSWER    ;quotient in $00, remainder in $0A
  STA REMANDER
  JMP finish

finish:
  ldx #0
finish_end:
  jsr txpoll
  lda fin,x
  beq send_answer
  sta ACIA_DATA
  inx
  jmp finish_end

send_answer:
  ldx #0
start_send:
  jsr txpoll
  lda ANSWER
  adc #$30
  sta ACIA_DATA
  jmp rem_msg

rem_msg:
  ldx #0
rem_loop:
  jsr txpoll
  lda rem,x
  beq write_remander
  sta ACIA_DATA
  inx
  jmp rem_loop

write_remander:
  ldx #0
remander_loop:
  jsr txpoll
  lda REMANDER
  adc #$30
  sta ACIA_DATA
  jmp loop

loop:
  jmp loop


  
; ----------------SUBROUTINES----------------


txpoll:
    LDA ACIA_STATUS
    AND #$10
    BEQ txpoll
    RTS

rxpoll:
    LDA ACIA_STATUS
    AND #$08
    BEQ rxpoll
    RTS

one:                                                          
    .byte $0d, $0a, "Enter the first number:", $0d, $0a, $00
two:                                                                           
    .byte $0d, $0a, "Enter the second number:", $0d, $0a, $00
three:
    .byte $0d, $0a, "Enter [m] for multiplication, [s] for subtraction, [a] for addition, or [d] for division", $0d, $0a, $00  
fin:
    .byte $0d, $0a, "The answer is: ", $00
rem:
    .byte $0a, $0a, "And if you divided, the remainder is: ", $00

