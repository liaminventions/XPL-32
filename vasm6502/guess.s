;; a simple number guessing game
;;
;; manually converted from c++

;;;;;; VARIABLES ;;;;;;

buf = $05     ; many   ; int buf;
guess = $03   ; 2
number = $01  ; 2

cr = $0d;
lf = $0a;
null = 0;

;;;;;;;; CODE ;;;;;;;;;

  .include "kernal_def.s"
  .org $0f00

main:
  cld
  jsr random		; generate the number
while:
  ldx #<msg1		; Guess my number.
  ldy #>msg1
  jsr w_acia_full
  jsr cin		; input a 1-digit value from the keyboard, then press enter
  lda guess
  cmp number
  beq win		; if buf = number, branch to "win"
  bcc low		; if buf < number, branch to "low"
high:			; otherwise, buf > number.
  ldx #<highmsg
  ldy #>highmsg		; Your Guess is too high. Try again!
  jsr w_acia_full
  jmp while
low:
  ldx #<lowmsg
  ldy #>lowmsg		; Your Guess is too low. Try again!
  jsr w_acia_full
  jmp while
win:
  ldx #<winmsg
  ldy #>winmsg		; Congratulations! You guessed it!
  jsr w_acia_full
  rts
  rts
  rts	; end
  rts

;;;;;; SUBROUTINES ;;;;;;

random:
  ; now we will generate a random number from the sid
  LDA #$FF  ; maximum frequency value
  STA $b80e ; voice 3 frequency low byte
  STA $b80f ; voice 3 frequency high byte
  LDA #$80  ; noise waveform, gate bit off
  STA $b812 ; voice 3 control register 
  ldx #<wqe
  ldy #>wqe
  jsr w_acia_full
lop:
  jsr rxpoll
  lda $8000
  beq lop 
  lda $b81b ; voice 3 oscillator status
  and #100  ; ensure
  sta number
  stz number+1
  stz $b80e ; clear used registers
  stz $b80f
  stz $b812
  rts
  
cin:
  phx
  phy		; push
  pha
  ldx #0
wop:
  jsr rxpoll
  lda $8000
  pha
  jsr print_chara
  pla
  cmp #$0d
  beq ecin	; read in
  cmp #$0a
  beq ecin
  sta buf,x
  inx
  jmp wop
ecin:
  stz buf,x
  jsr crlf
  jsr str2int
  pla
  ply
  plx
  rts

str2int:
  lda #0
  sta guess+1
  lda buf
  sta guess
  ldx #1
  lda buf,x
  cmp #0
  bne stinext
  clc
  rts
stinext:
  jsr mult10
  bcs stican
  inx
  lda buf,x
  cmp #0
  bne stinext
  clc
stican:
  rts

mult10:
  lda guess+1
  pha
  lda guess
  asl guess
  rol guess+1
  asl guess		; goin crazy with da speedcode (he he he ha)
  rol guess+1
  adc guess
  sta guess
  pla
  adc guess+1
  sta guess+1
  asl guess
  rol guess+1
  lda buf,x
  adc guess
  sta guess
  lda #0
  adc guess+1
  sta guess+1
  rts
  
;;;;;;;;; DATA ;;;;;;;;;;

msg1:
  .byte "Guess my number. (2 Digits then Enter)",cr,lf,null
highmsg:
  .byte "Your Guess is too high. Try again!",cr,lf,null
lowmsg:
  .byte "Your Guess is too low. Try again!",cr,lf,null
winmsg:
  .byte "Congratulations! You guessed it!",cr,lf,null
wqe:
  .byte "Press Any Key to Begin.",cr,lf,null

; end of file
