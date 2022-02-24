d400_sVoc1FreqLo = $b800
d401_sVoc1FreqHi = $b801
d402_sVoc1PWidthLo = $b802
d403_sVoc1PWidthHi = $b803
d404_sVoc1Control = $b804
d405_sVoc1AttDec = $b805
d406_sVoc1SusRel = $b806
d407_sVoc2FreqLo = $b807
d408_sVoc2FreqHi = $b808
d409_sVoc2PWidthLo = $b809
d40a_sVoc2PWidthHi = $b80a
d40b_sVoc2Control = $b80b
d40c_sVoc2AttDec = $b80c
d40d_sVoc2SusRel = $b80d
d40e_sVoc3FreqLo = $b80e
d40f_sVoc3FreqHi = $b80f
d410_sVoc3PWidthLo = $b810
d411_sVoc3PWidthHi = $b811
d412_sVoc3Control = $b812
d413_sVoc3AttDec = $b813
d414_sVoc3SusRel = $b814
d415_sFiltFreqLo = $b815
d416_sFiltFreqHi = $b816
d417_sFiltControl = $b817
d418_sFiltMode = $b818

  .org $0f00
init:
  sei
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff
  lda #$c0
  sta $b00e
  ; IRQ Inits Go Here
  lda #0 ; Song Number
  lda #$40
  sta $b00d 
  jsr InitSid
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  ; IRQ code goes here
  bit $b004
  jsr PlaySid
  nop
  rti
InitSid             ldx #$63
                    stx $b004
                    ldx #$26
                    stx $b005

                    jmp L10cc

     .org $1003               
PlaySid             jmp L10d0
                    
S1006               lda $1680,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $13da,x
                    tya
L1013               sta $13b1,x
                    lda $13a0,x
                    sta $13b0,x
                    rts
                    
L101d               sta $13ef,x
                    rts
                    
L1021               sta $13f0,x
                    rts
                    
L1025               sta $13b5,x
                    lda #$00
                    sta $13b6,x
                    rts
                    
L102e               ldy #$00
                    sty $110b
                    sta L1106 + 1
                    rts
                    
L1037               sta L114f + 1
                    rts
                    
L103b               sta $115c
                    rts
                    
L103f               sta $13c7
                    sta $13ce
                    sta $13d5
                    rts
                    
L1049               dec $13db,x
L104c               jmp L128b
                    
L104f               beq L104c
                    lda $13db,x
                    bne L1049
                    lda #$00
                    sta $fd
                    lda $13da,x
                    bmi L1068
                    cmp $1893,y
                    bcc L1069
                    beq L1068
                    eor #$ff
L1068               clc
L1069               adc #$02
                    sta $13da,x
                    lsr a
                    bcc L109f
                    bcs L10b6
                    tya
                    beq L10c6
                    lda $1893,y
                    sta $fd
                    lda $13b0,x
                    cmp #$02
                    bcc L109f
                    beq L10b6
                    ldy $13c9,x
                    lda $13dd,x
                    sbc $1404,y
                    pha
                    lda $13de,x
                    sbc $1464,y
                    tay
                    pla
                    bcs L10af
                    adc $fc
                    tya
                    adc $fd
                    bpl L10c6
L109f               lda $13dd,x
                    adc $fc
                    sta $13dd,x
                    lda $13de,x
                    adc $fd
                    jmp L1288
                    
L10af               sbc $fc
                    tya
                    sbc $fd
                    bmi L10c6
L10b6               lda $13dd,x
                    sbc $fc
                    sta $13dd,x
                    lda $13de,x
                    sbc $fd
                    jmp L1288
                    
L10c6               ldy $13c9,x
                    jmp L127a
                    
L10cc               sta $10d3
                    rts
                    
L10d0               ldx #$00
                    ldy #$00
                    bmi L1106
                    txa
                    ldx #$29
L10d9               sta $139b,x
                    dex
                    bpl L10d9
                    sta d415_sFiltFreqLo
                    sta $1155
                    sta L1106 + 1
                    stx $10d3
                    tax
                    jsr S10f6
                    ldx #$07
                    jsr S10f6
                    ldx #$0e
S10f6               lda #$0b
                    sta $13c7,x
                    lda #$01
                    sta $13c8,x
                    sta $13ca,x
                    jmp L1376
                    
L1106               ldy #$00
                    beq L114f
                    lda #$00
                    bne L1131
                    lda $181a,y
                    beq L1125
                    bpl L112e
                    asl a
                    sta $115a
                    lda $1856,y
                    sta $1155
                    lda $181b,y
                    bne L1143
                    iny
L1125               lda $1856,y
                    sta L114f + 1
                    jmp L1140
                    
L112e               sta $110b
L1131               lda $1856,y
                    clc
                    adc L114f + 1
                    sta L114f + 1
                    dec $110b
                    bne L1151
L1140               lda $181b,y
L1143               cmp #$ff
                    iny
                    tya
                    bcc L114c
                    lda $1856,y
L114c               sta L1106 + 1
L114f               lda #$00
L1151               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S116a
                    ldx #$07
                    jsr S116a
                    ldx #$0e
S116a               dec $13c8,x
                    beq L117a
                    bpl L1177
                    lda $13c7,x
                    sta $13c8,x
L1177               jmp L1224
                    
L117a               ldy $13a0,x
                    lda $1386,y
                    sta $1219
                    sta $1222
                    lda $139e,x
                    bne L11af
                    ldy $13c5,x
                    lda $14c4,y
                    sta $fc
                    lda $14c7,y
                    sta $fd
                    ldy $139b,x
                    lda ($fc),y
                    cmp #$ff
                    bcc L11a7
                    iny
                    lda ($fc),y
                    tay
                    lda ($fc),y
L11a7               sta $13c6,x
                    iny
                    tya
                    sta $139b,x
L11af               ldy $13ca,x
                    lda $16aa,y
                    sta $13f4,x
                    lda $13b2,x
                    beq L121e
                    sec
                    sbc #$60
                    sta $13c9,x
                    lda #$00
                    sta $13b0,x
                    sta $13b2,x
                    lda $1695,y
                    sta $13db,x
                    lda $1680,y
                    sta $13b1,x
                    lda $13a0,x
                    cmp #$03
                    beq L121e
                    lda $16bf,y
                    sta $13b4,x
                    lda #$ff
                    sta $13cb,x
                    lda $1656,y
                    beq L11f6
                    sta $13b5,x
                    lda #$00
                    sta $13b6,x
L11f6               lda $166b,y
                    beq L1203
                    sta L1106 + 1
                    lda #$00
                    sta $110b
L1203               lda $1641,y
                    sta $13b3,x
                    lda $162c,y
                    sta $13f0,x
                    lda $1617,y
                    sta $13ef,x
                    lda $13a1,x
                    jsr S1006
                    jmp L1355
                    
L121e               lda $13a1,x
                    jsr S1006
L1224               ldy $13b3,x
                    beq L1259
                    lda $16d4,y
                    cmp #$10
                    bcs L123a
                    cmp $13dc,x
                    beq L123f
                    inc $13dc,x
                    bne L1259
L123a               sbc #$10
                    sta $13b4,x
L123f               lda $16d5,y
                    cmp #$ff
                    iny
                    tya
                    bcc L124c
                    clc
                    lda $1752,y
L124c               sta $13b3,x
                    lda #$00
                    sta $13dc,x
                    lda $1751,y
                    bne L1272
L1259               lda $13c8,x
                    beq L128e
                    ldy $13b0,x
                    lda $1396,y
                    sta $1270
                    ldy $13b1,x
                    lda $18a3,y
                    sta $fc
                    jmp L104f
                    
L1272               bpl L1279
                    adc $13c9,x
                    and #$7f
L1279               tay
L127a               lda #$00
                    sta $13da,x
                    lda $1404,y
                    sta $13dd,x
                    lda $1464,y
L1288               sta $13de,x
L128b               lda $13c8,x
L128e               cmp $13f4,x
                    beq L12d6
                    ldy $13b5,x
                    beq L12d3
                    ora $139e,x
                    beq L12d3
                    lda $13b6,x
                    bne L12b3
                    lda $17d0,y
                    bpl L12b0
                    lda $17f5,y
                    sta $13df,x
                    jmp L12c4
                    
L12b0               sta $13b6,x
L12b3               lda $13df,x
                    clc
                    adc $17f5,y
                    adc #$00
                    sta $13df,x
                    dec $13b6,x
                    bne L12d3
L12c4               lda $17d1,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12d0
                    lda $17f5,y
L12d0               sta $13b5,x
L12d3               jmp L1355
                    
L12d6               ldy $13c6,x
                    lda $14ca,y
                    sta $fc
                    lda $1571,y
                    sta $fd
                    ldy $139e,x
                    lda ($fc),y
                    cmp #$40
                    bcc L1304
                    cmp #$60
                    bcc L130e
                    cmp #$c0
                    bcc L1322
                    lda $139f,x
                    bne L12fb
                    lda ($fc),y
L12fb               adc #$00
                    sta $139f,x
                    beq L134c
                    bne L1355
L1304               sta $13ca,x
                    iny
                    lda ($fc),y
                    cmp #$60
                    bcs L1322
L130e               cmp #$50
                    and #$0f
                    sta $13a0,x
                    beq L131d
                    iny
                    lda ($fc),y
                    sta $13a1,x
L131d               bcs L134c
                    iny
                    lda ($fc),y
L1322               cmp #$bd
                    bcc L132c
                    beq L134c
                    ora #$f0
                    bne L1349
L132c               sta $13b2,x
                    lda $13a0,x
                    cmp #$03
                    beq L134c
                    lda $13ca,x
                    cmp #$16
                    bcs L1380
                    lda #$00
                    sta $13f0,x
                    lda #$0f
                    sta $13ef,x
L1347               lda #$fe
L1349               sta $13cb,x
L134c               iny
                    lda ($fc),y
                    beq L1352
                    tya
L1352               sta $139e,x
L1355               lda $13ef,x
                    sta d405_sVoc1AttDec,x
                    lda $13f0,x
                    sta d406_sVoc1SusRel,x
                    lda $13df,x
                    sta d402_sVoc1PWidthLo,x
                    sta d403_sVoc1PWidthHi,x
                    lda $13dd,x
                    sta d400_sVoc1FreqLo,x
                    lda $13de,x
                    sta d401_sVoc1FreqHi,x
L1376               lda $13b4,x
                    and $13cb,x
                    sta d404_sVoc1Control,x
                    rts
                    
L1380               cmp #$17
                    bcc L1347
                    bcs L134c
                    asl $0c
  .binary "ILL_data.bin"
