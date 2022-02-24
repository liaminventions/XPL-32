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
  lda #$90
  sta $b00e
  ; IRQ Inits Go Here
  lda #0 ; Song Number
  sta $b00c
  jsr InitSid
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  ; IRQ code goes here
  lda #$10
  sta $b00d
  jsr PlaySid
  nop
  rti

	.org $1000
InitSid             jmp L10fb
                    
PlaySid             jmp L10ff
                    
S1006               lda $1669,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $14c3,x
                    tya
L1013               sta $149a,x
                    lda $1489,x
                    sta $1499,x
                    rts
                    
L101d               sta $14d8,x
                    rts
                    
L1021               sta $14d9,x
                    rts
                    
L1025               sta $149d,x
                    rts
                    
L1029               sta $149c,x
                    lda #$00
                    sta $14c5,x
                    rts
                    
L1032               sta $149e,x
                    lda #$00
                    sta $149f,x
                    rts
                    
L103b               ldy #$00
                    sty $113a
L1040               sta L1135 + 1
                    rts
                    
L1044               sta $1184
                    beq L1040
                    rts
                    
L104a               sta L117e + 1
                    rts
                    
L104e               sta $118b
                    rts
                    
L1052               tay
                    lda $17e2,y
                    sta $1482
                    lda $17ec,y
                    sta $1483
                    lda #$00
                    beq L1065
                    bmi L106f
L1065               sta $14b0
                    sta $14b7
                    sta $14be
                    rts
                    
L106f               and #$7f
                    sta $14b0,x
                    rts
                    
L1075               dec $14c4,x
L1078               jmp L1336
                    
L107b               beq L1078
                    lda $14c4,x
                    bne L1075
                    lda $17e2,y
                    bmi L108b
                    ldy #$00
                    sty $73
L108b               and #$7f
                    sta $1096
                    lda $14c3,x
                    bmi L109d
                    cmp #$00
                    bcc L109e
                    beq L109d
                    eor #$ff
L109d               clc
L109e               adc #$02
                    sta $14c3,x
                    lsr a
                    bcc L10ce
                    bcs L10e5
                    tya
                    beq L10f5
                    lda #$00
                    cmp #$02
                    bcc L10ce
                    beq L10e5
                    ldy $14b2,x
                    lda $14c6,x
                    sbc $14ed,y
                    pha
                    lda $14c7,x
                    sbc $154d,y
                    tay
                    pla
                    bcs L10de
                    adc $72
                    tya
                    adc $73
                    bpl L10f5
L10ce               lda $14c6,x
                    adc $72
                    sta $14c6,x
                    lda $14c7,x
                    adc $73
                    jmp L1333
                    
L10de               sbc $72
                    tya
                    sbc $73
                    bmi L10f5
L10e5               lda $14c6,x
                    sbc $72
                    sta $14c6,x
                    lda $14c7,x
                    sbc $73
                    jmp L1333
                    
L10f5               lda $14b2,x
                    jmp L1321
                    
L10fb               sta $1102
                    rts
                    
L10ff               ldx #$00
                    ldy #$00
                    bmi L1135
                    txa
                    ldx #$29
L1108               sta $1484,x
                    dex
                    bpl L1108
                    sta d415_sFiltFreqLo
                    sta $1184
                    sta L1135 + 1
                    stx $1102
                    tax
                    jsr S1125
                    ldx #$07
                    jsr S1125
                    ldx #$0e
S1125               lda #$05
                    sta $14b0,x
                    lda #$01
                    sta $14b1,x
                    sta $14b3,x
                    jmp L1432
                    
L1135               ldy #$00
                    beq L117e
                    lda #$00
                    bne L1160
                    lda $1787,y
                    beq L1154
                    bpl L115d
                    asl a
                    sta $1189
                    lda $17b4,y
                    sta $1184
                    lda $1788,y
                    bne L1172
                    iny
L1154               lda $17b4,y
                    sta L117e + 1
                    jmp L116f
                    
L115d               sta $113a
L1160               lda $17b4,y
                    clc
                    adc L117e + 1
                    sta L117e + 1
                    dec $113a
                    bne L1180
L116f               lda $1788,y
L1172               cmp #$ff
                    iny
                    tya
                    bcc L117b
                    lda $17b4,y
L117b               sta L1135 + 1
L117e               lda #$00
L1180               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S1199
                    ldx #$07
                    jsr S1199
                    ldx #$0e
S1199               dec $14b1,x
                    beq L11c9
                    bpl L11b5
                    lda $14b0,x
                    cmp #$02
                    bcs L11b2
                    tay
                    eor #$01
                    sta $14b0,x
                    lda $1482,y
                    sbc #$00
L11b2               sta $14b1,x
L11b5               jmp L128c
                    
L11b8               sbc #$d0
                    inc $1486,x
                    cmp $1486,x
                    bne L120e
                    lda #$00
                    sta $1486,x
                    beq L1209
L11c9               ldy $1489,x
                    lda $146d,y
                    sta $127e
                    sta $128a
                    lda $1487,x
                    bne L120e
                    ldy $14ae,x
                    lda $15ad,y
                    sta $72
                    lda $15b0,y
                    sta $73
                    ldy $1484,x
                    lda ($72),y
                    cmp #$ff
                    bcc L11f6
                    iny
                    lda ($72),y
                    tay
                    lda ($72),y
L11f6               cmp #$e0
                    bcc L1202
                    sbc #$f0
                    sta $1485,x
                    iny
                    lda ($72),y
L1202               cmp #$d0
                    bcs L11b8
                    sta $14af,x
L1209               iny
                    tya
                    sta $1484,x
L120e               ldy $14b3,x
                    lda $168b,y
                    sta $14dd,x
                    lda $149b,x
                    beq L1286
                    sec
                    sbc #$60
                    sta $14b2,x
                    lda #$00
                    sta $1499,x
                    sta $149b,x
                    lda $167a,y
                    sta $14c4,x
                    lda $1669,y
                    sta $149a,x
                    lda $1489,x
                    cmp #$03
                    beq L1286
                    lda $169c,y
                    beq L124e
                    cmp #$fe
                    bcs L124b
                    sta $149d,x
                    lda #$ff
L124b               sta $14b4,x
L124e               lda $1647,y
                    beq L125b
                    sta $149e,x
                    lda #$00
                    sta $149f,x
L125b               lda $1658,y
                    beq L1268
                    sta L1135 + 1
                    lda #$00
                    sta $113a
L1268               lda $1636,y
                    sta $149c,x
                    lda $1625,y
                    sta $14d9,x
                    lda $1614,y
                    sta $14d8,x
                    lda $148a,x
                    jsr S1006
                    jmp L140e
                    
L1283               jmp L1442
                    
L1286               lda $148a,x
                    jsr S1006
L128c               ldy $149c,x
                    beq L12cb
                    lda $16ad,y
                    cmp #$10
                    bcs L12a2
                    cmp $14c5,x
                    beq L12ab
                    inc $14c5,x
                    bne L12cb
L12a2               sbc #$10
                    cmp #$e0
                    bcs L12ab
                    sta $149d,x
L12ab               lda $16ae,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12b7
                    lda $16fc,y
L12b7               sta $149c,x
                    lda #$00
                    sta $14c5,x
                    lda $16ac,y
                    cmp #$e0
                    bcs L1283
                    lda $16fb,y
                    bne L131a
L12cb               lda $14b1,x
                    beq L1339
                    ldy $1499,x
                    sty $10ac
                    lda $147d,y
                    sta L1317 + 1
                    ldy $149a,x
L12df               lda $17e2,y
                    bmi L12ee
                    sta $73
                    lda $17ec,y
                    sta $72
                    jmp L1317
                    
L12ee               lda $17ec,y
                    sta $130a
                    sty L1313 + 1
                    ldy $14de,x
                    lda $14ee,y
                    sec
                    sbc $14ed,y
                    sta $72
                    lda $154e,y
                    sbc $154d,y
                    ldy #$00
                    beq L1313
L130d               lsr a
                    ror $72
                    dey
                    bne L130d
L1313               ldy #$00
                    sta $73
L1317               jmp L107b
                    
L131a               bpl L1321
                    adc $14b2,x
                    and #$7f
L1321               sta $14de,x
                    tay
                    lda #$00
                    sta $14c3,x
                    lda $14ed,y
                    sta $14c6,x
                    lda $154d,y
L1333               sta $14c7,x
L1336               lda $14b1,x
L1339               cmp $14dd,x
                    beq L138c
                    ldy $149e,x
                    beq L1389
                    ora $1487,x
                    beq L1389
                    lda $149f,x
                    bne L1361
                    lda $174b,y
                    bpl L135e
                    sta $14c9,x
                    lda $1769,y
                    sta $14c8,x
                    jmp L137a
                    
L135e               sta $149f,x
L1361               lda $1769,y
                    clc
                    bpl L136a
                    dec $14c9,x
L136a               adc $14c8,x
                    sta $14c8,x
                    bcc L1375
                    inc $14c9,x
L1375               dec $149f,x
                    bne L1389
L137a               lda $174c,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1386
                    lda $1769,y
L1386               sta $149e,x
L1389               jmp L140e
                    
L138c               ldy $14af,x
                    lda $15b3,y
                    sta $72
                    lda $15e4,y
                    sta $73
                    ldy $1487,x
                    lda ($72),y
                    cmp #$40
                    bcc L13ba
                    cmp #$60
                    bcc L13c4
                    cmp #$c0
                    bcc L13d8
                    lda $1488,x
                    bne L13b1
                    lda ($72),y
L13b1               adc #$00
                    sta $1488,x
                    beq L1405
                    bne L140e
L13ba               sta $14b3,x
                    iny
                    lda ($72),y
                    cmp #$60
                    bcs L13d8
L13c4               cmp #$50
                    and #$0f
                    sta $1489,x
                    beq L13d3
                    iny
                    lda ($72),y
                    sta $148a,x
L13d3               bcs L1405
                    iny
                    lda ($72),y
L13d8               cmp #$bd
                    bcc L13e2
                    beq L1405
                    ora #$f0
                    bne L1402
L13e2               adc $1485,x
                    sta $149b,x
                    lda $1489,x
                    cmp #$03
                    beq L1405
                    lda $14b3,x
                    cmp #$0a
                    bcs L143c
                    lda #$00
                    sta $14d9,x
                    lda #$0f
                    sta $14d8,x
L1400               lda #$fe
L1402               sta $14b4,x
L1405               iny
                    lda ($72),y
                    beq L140b
                    tya
L140b               sta $1487,x
L140e               lda $14c8,x
                    sta d402_sVoc1PWidthLo,x
                    lda $14c9,x
                    sta d403_sVoc1PWidthHi,x
                    lda $14d9,x
                    sta d406_sVoc1SusRel,x
                    lda $14d8,x
                    sta d405_sVoc1AttDec,x
                    lda $14c6,x
                    sta d400_sVoc1FreqLo,x
                    lda $14c7,x
                    sta d401_sVoc1FreqHi,x
L1432               lda $149d,x
                    and $14b4,x
                    sta d404_sVoc1Control,x
                    rts
                    
L143c               cmp #$12
                    bcc L1400
                    bcs L1405
L1442               and #$0f
                    sta $72
                    lda $16fb,y
                    sta $73
                    ldy $72
                    cpy #$05
                    bcs L145f
                    sty $10ac
                    lda $147d,y
                    sta L1317 + 1
                    ldy $73
                    jmp L12df
                    
L145f               lda $146d,y
                    sta $1468
                    lda $73
                    jsr S1006
                    jmp L1336

	.binary "demoscene.bin"
