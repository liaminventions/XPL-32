error_sound:
  jsr clear_sid
  lda #$0f
  sta $b818
  lda #$e7
  sta $b802
  lda #$0f
  sta $b805
  lda #$f8
  sta $b806
  lda #$50 ; freq
  sta $b800
  lda #$50 ; freq+1
  sta $b801
  lda #$41
  sta $b804

outer:
  ldy #$ff
inner:
  ldx #$ff

innerloop:
  dex
  bne innerloop

  dey
  beq ende
  jmp inner
ende:
  lda #$40
  sta $b804
  rts

clear_sid:
  ldx #$17
  lda #0
csid:
  sta $b800,x
  dex
  bne csid
  rts


