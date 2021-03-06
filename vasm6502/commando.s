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

poll = $8001

  .org $0f00
init:
  sei
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff
  lda #$c0
  sta $b00e
  lda #$40
  sta $b00d
  jsr putbut
  lda #0 ; Song Number
  jsr InitSid
  cli
  nop

; You can put code you want to run in the backround here.

loop:
  jmp loop

irq:
  lda #$40
  sta $b00d
  jsr putbut
  jsr PlaySid
  rti

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

  .org $1000
L1000               jmp L1f0c
                    
S1003               jmp L1f42
                    
L1006               jmp $1f48
                    
L1009               jmp $1f4e
                    
L100c               jmp $13cf
                    
L100f               jmp L1f56
                    
PlaySid             inc $1525
                    bit $1519
                    bmi L1038
                    bvc L1052
                    lda #$00
                    sta $1525
                    ldx #$02
L1023               sta $14ec,x
                    sta $14ef,x
                    sta $14f2,x
                    sta $14fb,x
                    dex
                    bpl L1023
                    sta $1519
                    jmp L1052
                    
L1038               bvc L104f
                    lda #$00
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    lda #$0f
                    sta d418_sFiltMode
                    lda #$80
                    sta $1519
L104f               jmp L13a5
                    
L1052               ldx #$02
                    dec $1513
                    bpl L105f
                    lda $1517
                    sta $1513
L105f               lda $14e8,x
                    sta $14eb
                    tay
                    lda $1513
                    cmp $1517
                    bne L1083
                    lda $16f9,x
                    sta $80
                    lda $16fc,x
                    sta $81
                    dec $14f2,x
                    bmi L1086
                    jmp L1174
                    
L1080               jmp $138f
                    
L1083               jmp L119b
                    
L1086               ldy $14ec,x
                    lda ($80),y
                    cmp #$ff
                    beq L1099
                    cmp #$fe
                    bne L10aa
                    jsr S1003
                    jmp L13a5
                    
L1099               lda #$00
                    sta $14f2,x
                    sta $14ec,x
                    sta $14ef,x
                    jmp L1086

L10a7               jmp $138f                    
L10aa               tay
                    lda $1711,y
                    sta $82
                    lda $173e,y
                    sta $83
                    lda #$00
                    sta $1520,x
                    ldy $14ef,x
                    lda #$ff
                    sta $1501
                    lda ($82),y
                    sta $14f5,x
                    sta $1502
                    and #$1f
                    sta $14f2,x
                    bit $1502
                    bvs L1118
                    inc $14ef,x
                    lda $1502
                    bpl L10ed
                    iny
                    lda ($82),y
                    bpl L10e7
                    sta $1520,x
                    jmp L10ea
                    
L10e7               sta $14fe,x
L10ea               inc $14ef,x
L10ed               iny
                    lda ($82),y
                    sta $14fb,x
                    asl a
                    tay
                    lda $1528
                    bpl L111b
                    lda $1428,y
                    sta $1503
                    lda $1429,y
                    ldy $14eb
                    sta d401_sVoc1FreqHi,y
                    sta $151a,x
                    lda $1503
                    sta d400_sVoc1FreqLo,y
                    sta $151d,x
                    jmp L111b
                    
L1118               dec $1501
L111b               ldy $14eb
                    lda $14fe,x
                    stx $1504
                    asl a
                    asl a
                    asl a
                    tax
                    lda $1593,x
                    sta $1505
                    lda $1528
                    bpl L1154
                    lda $1593,x
                    and $1501
                    sta d404_sVoc1Control,y
                    lda $1591,x
                    sta d402_sVoc1PWidthLo,y
                    lda $1592,x
                    sta d403_sVoc1PWidthHi,y
                    lda $1594,x
                    sta d405_sVoc1AttDec,y
                    lda $1595,x
                    sta d406_sVoc1SusRel,y
L1154               ldx $1504
                    lda $1505
                    sta $14f8,x
                    inc $14ef,x
                    ldy $14ef,x
                    lda ($82),y
                    cmp #$ff
                    bne L1171
                    lda #$00
                    sta $14ef,x
                    inc $14ec,x
L1171               jmp L138f
                    
L1174               lda $1528
                    bmi L117c
                    jmp $138f
                    
L117c               ldy $14eb
                    lda $14f5,x
                    and #$20
                    bne L119b
                    lda $14f2,x
                    bne L119b
                    lda $14f8,x
                    and #$fe
                    sta d404_sVoc1Control,y
                    lda #$00
                    sta d405_sVoc1AttDec,y
                    sta d406_sVoc1SusRel,y
L119b               lda $1528
                    bmi L11a3
                    jmp $538f
                    
L11a3               lda $14fe,x
                    asl a
                    asl a
                    asl a
                    tay
                    sty $1518
                    lda $1598,y
                    sta $1523
                    lda $1597,y
                    sta $1507
                    lda $1596,y
                    sta $1506
                    beq L1230
                    lda $1525
                    and #$07
                    cmp #$04
                    bcc L11cc
                    eor #$07
L11cc               sta $150c
                    lda $14fb,x
                    asl a
                    tay
                    sec
                    lda $142a,y
                    sbc $1428,y
                    sta $1508
                    lda $142b,y
                    sbc $1429,y
L11e4               lsr a
                    ror $1508
                    dec $1506
                    bpl L11e4
                    sta $1509
                    lda $1428,y
                    sta $150a
                    lda $1429,y
                    sta $150b
                    lda $14f5,x
                    and #$1f
                    cmp #$06
                    bcc L1221
                    ldy $150c
L1208               dey
                    bmi L1221
                    clc
                    lda $150a
                    adc $1508
                    sta $150a
                    lda $150b
                    adc $1509
                    sta $150b
                    jmp L1208
                    
L1221               ldy $14eb
                    lda $150a
                    sta d400_sVoc1FreqLo,y
                    lda $150b
                    sta d401_sVoc1FreqHi,y
L1230               lda $1523
                    and #$08
                    beq L124c
                    ldy $1518
                    lda $1591,y
                    adc $1507
                    sta $1591,y
                    ldy $14eb
                    sta d402_sVoc1PWidthLo,y
                    jmp L12b3
                    
L124c               lda $1507
                    beq L12b3
                    ldy $1518
                    and #$1f
                    dec $150d,x
                    bpl L12b3
                    sta $150d,x
                    lda $1507
                    and #$e0
                    sta $1524
                    lda $1510,x
                    bne L1285
                    lda $1524
                    clc
                    adc $1591,y
                    pha
                    lda $1592,y
                    adc #$00
                    and #$0f
                    pha
                    cmp #$0e
                    bne L129c
                    inc $1510,x
                    jmp L129c
                    
L1285               sec
                    lda $1591,y
                    sbc $1524
                    pha
                    lda $1592,y
                    sbc #$00
                    and #$0f
                    pha
                    cmp #$08
                    bne L129c
                    dec $1510,x
L129c               stx $1504
                    ldx $14eb
                    pla
                    sta $1592,y
                    sta d403_sVoc1PWidthHi,x
                    pla
                    sta $1591,y
                    sta d402_sVoc1PWidthLo,x
                    ldx $1504
L12b3               ldy $14eb
                    lda $1520,x
                    beq L12fa
                    and #$7e
                    sta $1504
                    lda $1520,x
                    and #$01
                    beq L12e2
                    sec
                    lda $151d,x
                    sbc $1504
                    sta $151d,x
                    sta d400_sVoc1FreqLo,y
                    lda $151a,x
                    sbc #$00
                    sta $151a,x
                    sta d401_sVoc1FreqHi,y
                    jmp L12fa
                    
L12e2               clc
                    lda $151d,x
                    adc $1504
                    sta $151d,x
                    sta d400_sVoc1FreqLo,y
                    lda $151a,x
                    adc #$00
                    sta $151a,x
                    sta d401_sVoc1FreqHi,y
L12fa               lda $1523
                    and #$01
                    beq L1336
                    lda $151a,x
                    beq L1336
                    lda $14f2,x
                    beq L1336
                    lda $14f5,x
                    and #$1f
                    sec
                    sbc #$01
                    cmp $14f2,x
                    ldy $14eb
                    bcc L132b
                    lda $151a,x
                    dec $151a,x
                    sta d401_sVoc1FreqHi,y
                    lda $14f8,x
                    and #$fe
                    bne L1333
L132b               lda $151a,x
                    sta d401_sVoc1FreqHi,y
                    lda #$80
L1333               sta d404_sVoc1Control,y
L1336               lda $1523
                    and #$02
                    beq L135e
                    lda $14f5,x
                    and #$1f
                    cmp #$03
                    bcc L135e
                    lda $5525
                    and #$01
                    beq L135e
                    lda $551a,x
                    beq L135e
                    inc $551a,x
                    inc $551a,x
                    ldy $54eb
                    sta d401_sVoc1FreqHi,y
L135e               lda $1523
                    and #$04
                    beq L138f
                    lda $1525
                    and #$01
                    beq L1375
                    lda $14fb,x
                    clc
                    adc #$0c
                    jmp L1378
                    
L1375               lda $14fb,x
L1378               asl a
                    tay
                    lda $1428,y
                    sta $1503
                    lda $1429,y
                    ldy $14eb
                    sta d401_sVoc1FreqHi,y
                    lda $1503
                    sta d400_sVoc1FreqLo,y
L138f               ldy #$ff
                    lda $1526
                    bne L139c
                    lda $1527
                    bmi L139c
                    iny
L139c               sty $1528
                    dex
                    bmi L13a5
                    jmp L105f
                    
L13a5               lda #$ff
                    sta $1528
                    lda $1526
                    bne L13b4
                    bit $1527
                    bpl L13b5
L13b4               rts
                    
L13b5               bvc L13ba
                    jsr S1531
L13ba               dec $152a
                    bpl L13b4
                    lda $1530
                    and #$0f
                    sta $152a
                    lda $1529
                    cmp $152b
                    bne L13de
                    ldx #$00
                    stx d404_sVoc1Control
                    stx d40b_sVoc2Control
                    dex
                    stx $1527
                    jmp L13b4
                    
L13de               dec $1529
                    asl a
                    tay
                    bit $1530
                    bmi L1408
                    bvs L13f6
                    lda $1428,y
                    sta d400_sVoc1FreqLo
                    lda $1429,y
                    sta d401_sVoc1FreqHi
L13f6               tya
                    sec
                    sbc $152c
                    tay
                    lda $1428,y
                    sta d407_sVoc2FreqLo
                    lda $1429,y
                    sta d408_sVoc2FreqHi
L1408               bit $152d
                    bpl L1418
                    lda $152e
                    eor #$01
                    sta d404_sVoc1Control
                    sta $152e
L1418               bvc L1425
                    lda $152f
                    eor #$01
                    sta d40b_sVoc2Control
                    sta $152f
L1425               jmp L13b4
                    
                    	.binary "commando_data1.bin" 

S1531               lda #$00
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta $152a
                    lda $1527
                    and #$0f
                    sta $1527
                    asl a
                    asl a
                    asl a
                    asl a
                    tay
                    lda $15f9,y
                    sta $1530
                    lda $15fa,y
                    sta $1529
                    lda $1608,y
                    sta $152b
                    lda $1601,y
                    sta $152d
                    and #$3f
                    sta $152c
                    lda $15fe,y
                    sta $152e
                    lda $1605,y
                    sta $152f
                    ldx #$00
L1574               lda $15fa,y
                    sta d400_sVoc1FreqLo,x
                    iny
                    inx
                    cpx #$0e
                    bne L1574
                    lda $1530
                    and #$30
                    ldy #$ee
                    cmp #$20
                    beq L158d
                    ldy #$ce
L158d               sty L13de
                    rts

			.binary "commando_data2.bin"
                    
L1f0c               ldy #$00
                    tax
                    lda $1514,x
                    sta $1517
                    txa
                    asl a
                    sta $1504
                    asl a
                    clc
                    adc $1504
                    tax
L1f20               lda $16ff,x
                    sta $16f9,y
                    inx
                    iny
                    cpy #$06
                    bne L1f20
                    lda #$00
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    lda #$0f
                    sta d418_sFiltMode
                    lda #$40
                    sta $1519
                    rts
                    
L1f42               lda #$c0
                    sta $1519
                    rts
                    
L1f48               lda #$00
                    sta $5526
                    rts
                    
L1f4e               lda #$ff
                    sta $5526
                    jmp $13cf
                    
L1f56               ldx $1526
                    beq L1f5f
                    stx $5527
                    rts
                    
L1f5f               ora #$40
                    sta $1527
                    lda #$0f
                    sta d418_sFiltMode
                    rts
                    
L1f6a               brk
                    
L1f6b               brk
                    
L1f6c               brk
                    
L1f6d               brk
                    
L1f6e               brk
                    
L1f6f               brk
                    
L1f70               brk
                    
L1f71               brk
                    
L1f72               brk
                    
L1f73               brk
                    
L1f74               brk
                    
L1f75               brk
                    
L1f76               brk
                    
L1f77               brk
                    
L1f78               brk
                    
L1f79               brk
                    
L1f7a               brk
                    
L1f7b               brk
                    
L1f7c               brk
                    
L1f7d               brk
                    
L1f7e               brk
                    
L1f7f               brk
                    
InitSid             cmp #$03
                    bcs L1f87
                    jmp L1000
                    
L1f87               pha
                    jsr L1f42
                    pla
                    sec
                    sbc #$03
                    tax
                    lda $1f98,x
                    jmp L100f
                    
                    .byte $00, $00, $00, $01, $02, $04, $05, $09, $0b, $0c 

