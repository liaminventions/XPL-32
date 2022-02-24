  .org $0f00
rau
  ldx #$00
wop_ee
  lda $8000
  and #$10
  beq wop_ee
  lda $0200,X
  inx
  jmp wop_ee