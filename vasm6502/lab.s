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
  jsr putbut
  lda #0 ; Song Number
  jsr InitSid
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  ; IRQ code goes here
  lda #$40
  sta $b00d
  jsr putbut
  jsr PlaySid
  nop
  rti

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

  .org $1000

InitSid             jmp L10fb
                    
PlaySid             jmp L10ff
                    
S1006               lda $15dc,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $14ad,x
                    tya
L1013               sta $1484,x
                    lda $1473,x
                    sta $1483,x
                    rts
                    
L101d               sta d405_sVoc1AttDec,x
                    rts
                    
L1021               sta d406_sVoc1SusRel,x
                    rts
                    
L1025               sta $1487,x
                    rts
                    
L1029               sta $1486,x
                    lda #$00
                    sta $14af,x
                    rts
                    
L1032               sta $1488,x
                    lda #$00
                    sta $1489,x
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
                    lda $165b,y
                    sta $146c
                    lda $165e,y
                    sta $146d
                    lda #$00
                    beq L1065
                    bmi L106f
L1065               sta $149a
                    sta $14a1
                    sta $14a8
                    rts
                    
L106f               and #$7f
                    sta $149a,x
                    rts
                    
L1075               dec $14ae,x
L1078               jmp L1331
                    
L107b               beq L1078
                    lda $14ae,x
                    bne L1075
                    lda $165b,y
                    bmi L108b
                    ldy #$00
                    sty $fd
L108b               and #$7f
                    sta $1096
                    lda $14ad,x
                    bmi L109d
                    cmp #$00
                    bcc L109e
                    beq L109d
                    eor #$ff
L109d               clc
L109e               adc #$02
                    sta $14ad,x
                    lsr a
                    bcc L10ce
                    bcs L10e5
                    tya
                    beq L10f5
                    lda #$00
                    cmp #$02
                    bcc L10ce
                    beq L10e5
                    ldy $149c,x
                    lda $14b0,x
                    sbc $14d7,y
                    pha
                    lda $14b1,x
                    sbc $1537,y
                    tay
                    pla
                    bcs L10de
                    adc $fc
                    tya
                    adc $fd
                    bpl L10f5
L10ce               lda $14b0,x
                    adc $fc
                    sta $14b0,x
                    lda $14b1,x
                    adc $fd
                    jmp L132e
                    
L10de               sbc $fc
                    tya
                    sbc $fd
                    bmi L10f5
L10e5               lda $14b0,x
                    sbc $fc
                    sta $14b0,x
                    lda $14b1,x
                    sbc $fd
                    jmp L132e
                    
L10f5               lda $149c,x
                    jmp L131c
                    
L10fb               sta $1102
                    rts
                    
L10ff               ldx #$00
                    ldy #$00
                    bmi L1135
                    txa
                    ldx #$29
L1108               sta $146e,x
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
                    sta $149a,x
                    lda #$01
                    sta $149b,x
                    sta $149d,x
                    jmp L141c
                    
L1135               ldy #$00
                    beq L117e
                    lda #$00
                    bne L1160
                    lda $1652,y
                    beq L1154
                    bpl L115d
                    asl a
                    sta $1189
                    lda $1656,y
                    sta $1184
                    lda $1653,y
                    bne L1172
                    iny
L1154               lda $1656,y
                    sta L117e + 1
                    jmp L116f
                    
L115d               sta $113a
L1160               lda $1656,y
                    clc
                    adc L117e + 1
                    sta L117e + 1
                    dec $113a
                    bne L1180
L116f               lda $1653,y
L1172               cmp #$ff
                    iny
                    tya
                    bcc L117b
                    lda $1656,y
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
S1199               dec $149b,x
                    beq L11c9
                    bpl L11b5
                    lda $149a,x
                    cmp #$02
                    bcs L11b2
                    tay
                    eor #$01
                    sta $149a,x
                    lda $146c,y
                    sbc #$00
L11b2               sta $149b,x
L11b5               jmp L128c
                    
L11b8               sbc #$d0
                    inc $1470,x
                    cmp $1470,x
                    bne L120e
                    lda #$00
                    sta $1470,x
                    beq L1209
L11c9               ldy $1473,x
                    lda $1457,y
                    sta $127e
                    sta $128a
                    lda $1471,x
                    bne L120e
                    ldy $1498,x
                    lda $1597,y
                    sta $fc
                    lda $159a,y
                    sta $fd
                    ldy $146e,x
                    lda ($fc),y
                    cmp #$ff
                    bcc L11f6
                    iny
                    lda ($fc),y
                    tay
                    lda ($fc),y
L11f6               cmp #$e0
                    bcc L1202
                    sbc #$f0
                    sta $146f,x
                    iny
                    lda ($fc),y
L1202               cmp #$d0
                    bcs L11b8
                    sta $1499,x
L1209               iny
                    tya
                    sta $146e,x
L120e               ldy $149d,x
                    lda $15ec,y
                    sta $14c7,x
                    lda $1485,x
                    beq L1286
                    sec
                    sbc #$60
                    sta $149c,x
                    lda #$00
                    sta $1483,x
                    sta $1485,x
                    lda $15e4,y
                    sta $14ae,x
                    lda $15dc,y
                    sta $1484,x
                    lda $1473,x
                    cmp #$03
                    beq L1286
                    lda $15f4,y
                    beq L124e
                    cmp #$fe
                    bcs L124b
                    sta $1487,x
                    lda #$ff
L124b               sta $149e,x
L124e               lda $15cc,y
                    beq L125b
                    sta $1488,x
                    lda #$00
                    sta $1489,x
L125b               lda $15d4,y
                    beq L1268
                    sta L1135 + 1
                    lda #$00
                    sta $113a
L1268               lda $15c4,y
                    sta $1486,x
                    lda $15bc,y
                    sta d406_sVoc1SusRel,x
                    lda $15b4,y
                    sta d405_sVoc1AttDec,x
                    lda $1474,x
                    jsr S1006
                    jmp L141c
                    
L1283               jmp L142c
                    
L1286               lda $1474,x
                    jsr S1006
L128c               ldy $1486,x
                    beq L12cb
                    lda $15fc,y
                    cmp #$10
                    bcs L12a2
                    cmp $14af,x
                    beq L12ab
                    inc $14af,x
                    bne L12cb
L12a2               sbc #$10
                    cmp #$e0
                    bcs L12ab
                    sta $1487,x
L12ab               lda $15fd,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12b7
                    lda $1623,y
L12b7               sta $1486,x
                    lda #$00
                    sta $14af,x
                    lda $15fb,y
                    cmp #$e0
                    bcs L1283
                    lda $1622,y
                    bne L1315
L12cb               ldy $1483,x
                    sty $10ac
                    lda $1467,y
                    sta L1312 + 1
                    ldy $1484,x
L12da               lda $165b,y
                    bmi L12e9
                    sta $fd
                    lda $165e,y
                    sta $fc
                    jmp L1312
                    
L12e9               lda $165e,y
                    sta $1305
                    sty L130e + 1
                    ldy $14c8,x
                    lda $14d8,y
                    sec
                    sbc $14d7,y
                    sta $fc
                    lda $1538,y
                    sbc $1537,y
                    ldy #$00
                    beq L130e
L1308               lsr a
                    ror $fc
                    dey
                    bne L1308
L130e               ldy #$00
                    sta $fd
L1312               jmp L107b
                    
L1315               bpl L131c
                    adc $149c,x
                    and #$7f
L131c               sta $14c8,x
                    tay
                    lda #$00
                    sta $14ad,x
                    lda $14d7,y
                    sta $14b0,x
                    lda $1537,y
L132e               sta $14b1,x
L1331               ldy $1488,x
                    beq L1383
                    lda $1489,x
                    bne L134f
                    lda $164a,y
                    bpl L134c
                    sta $14b3,x
                    lda $164e,y
                    sta $14b2,x
                    jmp L1368
                    
L134c               sta $1489,x
L134f               lda $164e,y
                    clc
                    bpl L1358
                    dec $14b3,x
L1358               adc $14b2,x
                    sta $14b2,x
                    bcc L1363
                    inc $14b3,x
L1363               dec $1489,x
                    bne L137a
L1368               lda $164b,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1374
                    lda $164e,y
L1374               sta $1488,x
                    lda $14b2,x
L137a               sta d402_sVoc1PWidthLo,x
                    lda $14b3,x
                    sta d403_sVoc1PWidthHi,x
L1383               lda $149b,x
                    cmp $14c7,x
                    beq L138e
                    jmp L1410
                    
L138e               ldy $1499,x
                    lda $159d,y
                    sta $fc
                    lda $15a9,y
                    sta $fd
                    ldy $1471,x
                    lda ($fc),y
                    cmp #$40
                    bcc L13bc
                    cmp #$60
                    bcc L13c6
                    cmp #$c0
                    bcc L13da
                    lda $1472,x
                    bne L13b3
                    lda ($fc),y
L13b3               adc #$00
                    sta $1472,x
                    beq L1407
                    bne L1410
L13bc               sta $149d,x
                    iny
                    lda ($fc),y
                    cmp #$60
                    bcs L13da
L13c6               cmp #$50
                    and #$0f
                    sta $1473,x
                    beq L13d5
                    iny
                    lda ($fc),y
                    sta $1474,x
L13d5               bcs L1407
                    iny
                    lda ($fc),y
L13da               cmp #$bd
                    bcc L13e4
                    beq L1407
                    ora #$f0
                    bne L1404
L13e4               adc $146f,x
                    sta $1485,x
                    lda $1473,x
                    cmp #$03
                    beq L1407
                    lda $149d,x
                    cmp #$09
                    bcs L1426
                    lda #$00
                    sta d406_sVoc1SusRel,x
                    lda #$0f
                    sta d405_sVoc1AttDec,x
L1402               lda #$fe
L1404               sta $149e,x
L1407               iny
                    lda ($fc),y
                    beq L140d
                    tya
L140d               sta $1471,x
L1410               lda $14b0,x
                    sta d400_sVoc1FreqLo,x
                    lda $14b1,x
                    sta d401_sVoc1FreqHi,x
L141c               lda $1487,x
                    and $149e,x
                    sta d404_sVoc1Control,x
                    rts
                    
L1426               cmp #$09
                    bcc L1402
                    bcs L1407
L142c               and #$0f
                    sta $fc
                    lda $1622,y
                    sta $fd
                    ldy $fc
                    cpy #$05
                    bcs L1449
                    sty $10ac
                    lda $1467,y
                    sta L1312 + 1
                    ldy $fd
                    jmp L12da
                    
L1449               lda $1457,y
                    sta $1452
                    lda $fd
                    jsr S1006
                    jmp L1331

  .binary "lab.bin"
