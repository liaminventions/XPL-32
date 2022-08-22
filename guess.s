;; a simple number guessing game
;;
;; manually converted from c++

;;;;;; VARIABLES ;;;;;;

  ;;correct = $00   ; 1   ; bool correct; 
  ;           you dont need this in asm (better then c)

  guess = $01     ; 2   ; int guess;
  buffer = $03    ; 1
  number = $04    ; 1

  cr=#$0d;
  lf=#$0a;
  null=#0;

;;;;;;;; CODE ;;;;;;;;;

  .include "kernal_def.s"
  .org $0f00

main:
  stz correct		; correct = false;
  jsr random		; generate the number
while:
  ldx #<msg1		; Guess my number.
  ldy #>msg1
  jsr w_acia_full
  jsr cin		; input a 2-digit value from the keyboard, then press enter
  lda guess+1
  bne high
  lda guess
  cmp number
  beq win		; if guess = number, branch to "win"
  bcc low		; if guess < number, branch to "low"
high:			; otherwise, guess > number.
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
  lda $b81b ; voice 3 oscillator status
  sec       ; set carry
  and #%00111111
  sta number
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
  jsr print_chara
  cmp #$0d
  beq ecin	; read in
  cmp #$0a
  beq ecin
  sta guess,x
  inx
  jmp wop
ecin:
  lda guess
  sec		; rid of ascii encoding
  sbc #$30
  sta guess
  lda guess+1
  sec
  sbc #$30
  sta buffer
  lda #10
  sta guess+1
  ; multiply most significant digit by 10
  LDA #0
  LDX  #$8
  LSR  guess
loop:
  BCC  no_add
  CLC
  ADC  guess+1
no_add:
  ROR
  ROR  guess
  DEX
  BNE  loop
  STA  guess+1
  ; low in guess, high in guess+1
  lda guess
  clc
  adc buffer	; add in the least signifacent digit
  bcc not
  inc guess+1	; (16 bit add)
not:
  pla
  ply 
  plx
  rts

;;;;;;;;; DATA ;;;;;;;;;;

msg1:
  .byte "Guess my number.",cr,lf,null
highmsg:
  .byte "Your Guess is too high. Try again!",cr,lf,null
lowmsg:
  .byte "Your Guess is too low. Try again!",cr,lf,null
winmsg:
  .byte "Congratulations! You guessed it!",cr,lf,null


; end of file
