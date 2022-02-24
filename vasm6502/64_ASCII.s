  .org $1000
start:
  ldx #0
txp:
  lda $8001
  and #$10
  beq txp
  lda ascii,x
  tay
  sta $8000
  cpy #$ff
  beq end
  jmp txp
end:
  jmp $c000

ascii:
  .binary "64_ASCII.bin"

irq:
  rti

  .org $7ffe
  .word irq  
