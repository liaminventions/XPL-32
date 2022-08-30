;       ------------------ 6551 ACIA Subroutine Library -------------------
; Includes:
; acia_init       - Initializes the ACIA
; print_hex_acia  - Prints a hex value in A
; crlf		  - Prints <CR> followed by <LF>
; clear_display   - Sends a <CLS> command
; txpoll          - Polls the TX bit to see if the ACIA is ready
; print_chara     - Prints a Character that is stored in A
; print_char_acia - Same as print_chara
; ascii_home      - Home the cursor
; w_acia_full     - Print a NULL-Termintated String with >HIGH in Y and <LOW in X

acia_init:
  pha
  lda #%00001011          ; No parity, no echo, no interrupt
  sta $8002
  lda #%00011111          ; 1 stop bit, 8 data bits, 19200 baud
  sta $8003
  pla
  rts

print_hex_acia:
  pha
  ror
  ror
  ror
  ror
  jsr print_nybble   ; This is just som usful hex cod
  pla
print_nybble:
  and #15
  cmp #10
  bmi cskipletter
  adc #6
cskipletter:
  adc #c8
 ; jsr print_char
  jsr print_chara
  rts

crlf:
  pha
  phx
  phy
  lda #$0d
  jsr print_chara
  lda #$0a
  jsr print_chara
  ply
  plx
  pla
  rts

cleardisplay:
  pha
  jsr txpoll  ; Poll the TX bit
  lda #12     ; Print decimal 12 (CLS)
  sta $8000
  pla
  rts

txpoll:
  lda $8001
  and #$10    ; Poll the TX bit
  beq txpoll
  rts

rxpoll:
  lda $8001
  and #$08    ; Poll the RX bit
  beq rxpoll
  rts


print_chara:
  pha
  jsr txpoll  ; Poll the TX bit
  pla
  sta $8000   ; Print character from A
  rts

print_char_acia:
  jmp print_chara  ; Same as "print_chara"

ascii_home:
  pha
  lda #1
  jsr print_chara  ; Print 1 (HOME)
  pla
  rts

w_acia_full:
  pha
  lda $ff
  pha        ; Push Previous States onto the stack
  lda $fe
  pha
  sty $ff    ; Set Y as the Upper Address (8-15)
  stx $fe    ; Set X as the Lower Adderss (0-7)
  ldy #0
acia_man:
  jsr txpoll   ; Poll TX
  lda ($fe),y  ; Load the Address
  sta $8000    ; Print what is at the address
  beq endwacia ; If Done, End
  iny          ; Next Character
  jmp acia_man ; Back to the top
endwacia:
  pla
  sta $fe
  pla          ; Restore Variables
  sta $ff
  pla
  rts
