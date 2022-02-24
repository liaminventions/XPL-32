PORTB = $6000
DDRB = $6002

  .org $8000

reset:
  lda #$ff
  sta DDRB

loop:
  lda #$55
  sta PORTB

  lda #$aa
  sta PORTB

  jmp loop

  .org $fffc
  .word reset
  .word $0000
