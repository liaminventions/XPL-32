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

InitSid             jmp L1882
                    
PlaySid             ldx #$00
                    jsr S184c
                    ldx #$07
                    jsr S184c
                    ldx #$0e
                    jsr S184c
                    lda #$00
                    sta d415_sFiltFreqLo
                    lda #$00
                    sta d416_sFiltFreqHi
                    lda #$00
                    beq L1050
                    lda $1056
                    bne L104b
                    lda $192b
                    beq L1031
                    bmi L1031
                    sta $1056
                    bne L104b
L1031               lda $1932
                    beq L103d
                    bmi L103d
                    sta $1056
                    bne L104b
L103d               lda $1939
                    beq L1049
                    bmi L1049
                    sta $1056
                    bne L104b
L1049               lda #$00
L104b               lda $101d
                    ora #$00
L1050               sta d417_sFiltControl
                    lda #$0f
                    ora #$00
                    sta d418_sFiltMode
                    ldx $18b2
                    inx
                    cpx #$06
                    bcs L1065
                    jmp L1297
                    
L1065               ldx $18b3
                    inx
                    cpx #$10
                    beq L1073
                    stx $18b3
                    jmp L10cd
                    
L1073               ldx #$00
                    stx $18b3
                    ldx $18b4
                    inx
                    cpx #$58
                    bcc L1082
                    ldx #$00
L1082               stx $18b4
                    lda $2754,x
                    sta $f0
                    lda $27ac,x
                    sta $f1
                    lda $2a14,x
                    sta $1918
                    lda $2804,x
                    sta $f2
                    lda $285c,x
                    sta $f3
                    lda $2a6c,x
                    sta $191f
                    lda $28b4,x
                    sta $f4
                    lda $290c,x
                    sta $f5
                    lda $2ac4,x
                    sta $1926
                    lda $2964,x
                    sta $f6
                    lda $29bc,x
                    sta $f7
                    lda #$00
                    sta $10d8
                    sta $116e
                    sta $1204
                    sta $12a8
L10cd               dec $18b6
                    beq L10d5
                    jmp L1163
                    
L10d5               ldx #$00
                    ldy #$00
                    lda ($f0),y
                    bmi L10fb
                    beq L111d
                    cmp #$40
                    bcc L10e6
                    and #$3f
                    dex
L10e6               dex
                    lsr a
                    sta $18b6
                    bcc L10f5
                    iny
                    lda ($f0),y
                    sta $1901
                    lda #$80
L10f5               sta $18f2
                    jmp L113b
                    
L10fb               asl a
                    sta $18dc
                    asl a
                    sta $18db
                    lsr a
                    lsr a
                    and #$1f
                    sta $18da
                    tax
                    lda $1df4,x
                    bne L111b
                    sta $18c7
                    sta $18c8
                    lda #$fe
                    sta $18f1
L111b               ldx #$01
L111d               lda #$01
                    sta $18b6
                    iny
                    lda ($f0),y
                    sta $18f2
                    bpl L1138
                    and #$7f
                    sta $18d8
                    iny
                    lda ($f0),y
                    sta $1901
                    jmp L113b
                    
L1138               sta $18d8
L113b               stx $18dd
                    iny
                    bpl L1150
                    tya
                    and #$7f
                    tay
                    lda $f0
                    clc
                    adc #$80
                    sta $f0
                    bcc L1150
                    inc $f1
L1150               lda ($f0),y
                    sta $192c
                    cmp #$01
                    bne L1160
                    iny
                    lda ($f0),y
                    sta $192d
                    iny
L1160               sty $10d8
L1163               dec $18b7
                    beq L116b
                    jmp L11f9
                    
L116b               ldx #$00
                    ldy #$00
                    lda ($f2),y
                    bmi L1191
                    beq L11b3
                    cmp #$40
                    bcc L117c
                    and #$3f
                    dex
L117c               dex
                    lsr a
                    sta $18b7
                    bcc L118b
                    iny
                    lda ($f2),y
                    sta $1908
                    lda #$80
L118b               sta $18f9
                    jmp L11d1
                    
L1191               asl a
                    sta $18e3
                    asl a
                    sta $18e2
                    lsr a
                    lsr a
                    and #$1f
                    sta $18e1
                    tax
                    lda $1df4,x
                    bne L11b1
                    sta $18ce
                    sta $18cf
                    lda #$fe
                    sta $18f8
L11b1               ldx #$01
L11b3               lda #$01
                    sta $18b7
                    iny
                    lda ($f2),y
                    sta $18f9
                    bpl L11ce
                    and #$7f
                    sta $18df
                    iny
                    lda ($f2),y
                    sta $1908
                    jmp L11d1
                    
L11ce               sta $18df
L11d1               stx $18e4
                    iny
                    bpl L11e6
                    tya
                    and #$7f
                    tay
                    lda $f2
                    clc
                    adc #$80
                    sta $f2
                    bcc L11e6
                    inc $f3
L11e6               lda ($f2),y
                    sta $1933
                    cmp #$01
                    bne L11f6
                    iny
                    lda ($f2),y
                    sta $1934
                    iny
L11f6               sty $116e
L11f9               dec $18b8
                    beq L1201
                    jmp L128f
                    
L1201               ldx #$00
                    ldy #$00
                    lda ($f4),y
                    bmi L1227
                    beq L1249
                    cmp #$40
                    bcc L1212
                    and #$3f
                    dex
L1212               dex
                    lsr a
                    sta $18b8
                    bcc L1221
                    iny
                    lda ($f4),y
                    sta $190f
                    lda #$80
L1221               sta $1900
                    jmp L1267
                    
L1227               asl a
                    sta $18ea
                    asl a
                    sta $18e9
                    lsr a
                    lsr a
                    and #$1f
                    sta $18e8
                    tax
                    lda $1df4,x
                    bne L1247
                    sta $18d5
                    sta $18d6
                    lda #$fe
                    sta $18ff
L1247               ldx #$01
L1249               lda #$01
                    sta $18b8
                    iny
                    lda ($f4),y
                    sta $1900
                    bpl L1264
                    and #$7f
                    sta $18e6
                    iny
                    lda ($f4),y
                    sta $190f
                    jmp L1267
                    
L1264               sta $18e6
L1267               stx $18eb
                    iny
                    bpl L127c
                    tya
                    and #$7f
                    tay
                    lda $f4
                    clc
                    adc #$80
                    sta $f4
                    bcc L127c
                    inc $f5
L127c               lda ($f4),y
                    sta $193a
                    cmp #$01
                    bne L128c
                    iny
                    lda ($f4),y
                    sta $193b
                    iny
L128c               sty $1204
L128f               lda #$00
                    sta $18b2
                    jmp L12fa
                    
L1297               stx $18b2
                    cpx #$02
                    beq L130a
                    cpx #$01
                    bne L12fa
                    dec $18b5
                    bne L12fa
                    ldy #$00
                    lda ($f6),y
                    bpl L12b2
                    iny
                    and #$7f
                    bpl L12e1
L12b2               cmp #$20
                    bcs L12bf
                    iny
                    lsr a
                    sta $18bf
                    bcs L12df
                    lda ($f6),y
L12bf               cmp #$40
                    bcs L12ce
                    iny
                    lsr a
                    and #$0f
                    sta $1054
                    bcs L12df
                    lda ($f6),y
L12ce               and #$3f
                    sta $105f
                    tax
                    dex
                    cpx #$02
                    bcc L12db
                    ldx #$02
L12db               stx $129b
                    iny
L12df               lda #$01
L12e1               sta $18b5
                    sty $12a8
                    tya
                    bpl L12fa
                    and #$7f
                    sta $12a8
                    lda $f6
                    clc
                    adc #$80
                    sta $f6
                    bcc L12fa
                    inc $f7
L12fa               ldx #$00
                    jsr S1630
                    ldx #$07
                    jsr S1630
                    ldx #$0e
                    jsr S1630
                    rts
                    
L130a               ldx #$00
                    jsr S13a2
                    ldx #$07
                    jsr S13a2
                    ldx #$0e
                    jsr S13a2
                    jmp L131c
                    
L131c               ldy $18d9
                    lda $1ade,y
                    bmi L1328
                    tay
                    lda $1bee,y
L1328               sta $192b
                    ldy $18e0
                    lda $1ade,y
                    bmi L1337
                    tay
                    lda $1bee,y
L1337               sta $1932
                    ldy $18e7
                    lda $1ade,y
                    bmi L1346
                    tay
                    lda $1bee,y
L1346               sta $1939
                    lda #$00
                    ldx #$00
                    cpx $192b
                    beq L1354
                    ora #$01
L1354               cpx $1932
                    beq L135b
                    ora #$02
L135b               cpx $1939
                    beq L1362
                    ora #$04
L1362               sta $101d
                    rts
                    
L1366               lda #$00
                    ldy $18d9
                    ldx $1ade,y
                    bmi L1373
                    ldx $1bee,y
L1373               stx $192b
                    beq L137a
                    ora #$01
L137a               ldy $18e0
                    ldx $1ade,y
                    bmi L1385
                    ldx $1bee,y
L1385               stx $1932
                    beq L138c
                    ora #$02
L138c               ldy $18e7
                    ldx $1ade,y
                    bmi L1397
                    ldx $1bee,y
L1397               stx $1939
                    beq L139e
                    ora #$04
L139e               sta $101d
                    rts
                    
S13a2               lda $18dd,x
                    cmp #$01
                    beq L13c3
                    lda $192c,x
                    cmp #$01
                    bne L1404
                    ldy $18d9,x
                    lda $1906,x
                    bmi L1404
                    lda #$00
                    sta $192c,x
                    lda $192d,x
                    jmp L13e3
                    
L13c3               ldy $18da,x
                    lda $1e14,y
                    sta $1906,x
                    bmi L1404
                    lda $192c,x
                    cmp #$01
                    bne L13e0
                    lda #$00
                    sta $192c,x
                    lda $192d,x
                    jmp L13e3
                    
L13e0               lda $1e54,y
L13e3               sta $1917,x
                    lda #$00
                    sta $1907,x
                    sta $1919,x
                    sta $191a,x
                    lda $1e34,y
                    clc
                    adc #$01
                    lsr a
                    sta $1916,x
                    bcc L1404
                    lda $1917,x
                    lsr a
                    sta $1919,x
L1404               lda $18f2,x
                    bpl L142c
                    lda $1901,x
                    asl a
                    sta $1904,x
                    lda #$00
                    bcc L1416
                    lda #$ff
L1416               sta $1905,x
                    lda $18dd,x
                    bpl L1442
                    and $18f1,x
                    sta $18f1,x
                    lda #$00
                    sta $18f2,x
                    jmp S1630
                    
L142c               lda $18dd,x
                    bpl L143a
                    and $18f1,x
                    sta $18f1,x
                    jmp S1630
                    
L143a               tay
                    lda #$00
                    sta $1904,x
                    beq L1445
L1442               tay
                    lda #$00
L1445               sta $1902,x
                    sta $1903,x
                    cpy #$01
                    beq L1481
                    ldy $18d9,x
                    lda $1dd4,y
                    beq L1467
                    lda $18d8,x
                    clc
                    adc $1918,x
                    clc
                    adc #$44
                    sta $18d7,x
                    jmp S1630
                    
L1467               lda $18d8,x
                    clc
                    adc $1918,x
                    sta $18d7,x
                    tay
                    lda $2b1c,y
                    sta $191b,x
                    lda $2b7c,y
                    sta $191c,x
                    jmp S1630
                    
L1481               lda $18d8,x
                    clc
                    adc $1918,x
                    sta $18d7,x
                    lda $18da,x
                    sta $18d9,x
                    lda #$ff
                    sta $18f1,x
                    ldy $18d9,x
                    lda $1940,y
                    sta $18c7,x
                    lda $1960,y
                    sta $18c8,x
                    lda $18c6,x
                    and #$fe
                    sta d404_sVoc1Control,x
                    lda $1980,y
                    sta $18c6,x
                    lda $1dd4,y
                    sta $18f0,x
                    beq L14de
                    tay
                    lda $18d7,x
                    clc
                    adc #$44
                    sta $18d7,x
                    lda $1c3e,y
                    bpl L14ce
                    clc
                    adc $18d7,x
L14ce               tay
                    lda $2b1b,y
                    sta $191b,x
                    lda $2b7b,y
                    sta $191c,x
                    jmp L14ed
                    
L14de               ldy $18d7,x
                    lda $2b1c,y
                    sta $191b,x
                    lda $2b7c,y
                    sta $191c,x
L14ed               lda $18db,x
                    bpl L1540
                    ldy $18d9,x
                    lda $19a0,y
                    tay
                    sta $18ec,x
                    bpl L1526
                    lda $1a39,y
                    sta $18ed,x
                    lda $1a14,y
                    sta $18ee,x
                    bpl L1510
                    lda #$ff
                    bne L1512
L1510               lda #$00
L1512               sta $18ef,x
                    lda $19ca,y
                    beq L1540
                    lda $19ef,y
                    sta $18c4,x
                    sta $18c5,x
                    jmp L1540
                    
L1526               lda $19c0,y
                    sta $18c4,x
                    sta $18c5,x
                    lda #$00
                    sta $18ed,x
                    lda $19ee,y
                    sta $18ee,x
                    lda $1a05,y
                    sta $18ef,x
L1540               lda $18dc,x
                    bmi L1548
                    jmp L17ff
                    
L1548               ldy $18d9,x
                    cpx $18bf
                    bne L15ca
                    lda $1ade,y
                    sta $18b9
                    tay
                    bpl L1592
                    lda $1bb4,y
                    sta $18bd
                    lda $1b50,y
                    sta $104f
                    lda $1b8c,y
                    lsr a
                    sta $1056
                    bcc L1579
                    lda $1b96,y
                    sta $1018
                    lda #$00
                    sta $1013
L1579               lda #$00
                    sta $18ba
                    lda $1baa,y
                    sta $18bc
                    lda $1ba0,y
                    lsr a
                    sta $18bb
                    bcc L15ca
                    inc $18ba
                    bne L15ca
L1592               lda $1afe,y
                    sta $1018
                    lda #$00
                    sta $1013
                    sta $18ba
                    lda $1bd0,y
                    sta $104f
                    lda $1bee,y
                    sta $1056
                    lda $1b3a,y
                    sta $18bc
                    lda $1b1c,y
                    lsr a
                    sta $18bb
                    bcc L15be
                    inc $18ba
L15be               lda $1b58,y
                    sta $18bd
                    lda $1b76,y
                    sta $18be
L15ca               jmp L17ff
                    
L15cd               dec $18ed,x
                    bmi L15da
                    bne L161a
                    iny
                    lda $1a39,y
                    bne L15e2
L15da               lda #$ff
                    sta $18ed,x
                    jmp L167b
                    
L15e2               bpl L15f1
                    sta $18ec,x
                    tay
                    lda $1a39,y
                    sta $18ed,x
                    jmp L15f8
                    
L15f1               sta $18ed,x
                    tya
                    sta $18ec,x
L15f8               lda $1a14,y
                    sta $18ee,x
                    bpl L1604
                    lda #$ff
                    bne L1606
L1604               lda #$00
L1606               sta $18ef,x
                    lda $19ca,y
                    beq L167b
                    lda $19ef,y
                    sta $18c4,x
                    sta $18c5,x
                    jmp L167b
                    
L161a               lda $18c4,x
                    clc
                    adc $18ee,x
                    sta $18c4,x
                    lda $18c5,x
                    adc $18ef,x
                    sta $18c5,x
                    jmp L167b
                    
S1630               ldy $18ec,x
                    bmi L15cd
                    dec $18ee,x
                    bne L1655
                    dec $18ef,x
                    bpl L1655
                    lda $1a1c,y
                    sta $18ee,x
                    lda $1a33,y
                    sta $18ef,x
                    lda $18ed,x
                    eor #$01
                    sta $18ed,x
                    bpl L167b
L1655               lda $18ed,x
                    bne L166c
                    clc
                    lda $18c4,x
                    adc $19d7,y
                    sta $18c4,x
                    bcc L167b
                    inc $18c5,x
                    jmp L167b
                    
L166c               sec
                    lda $18c4,x
                    sbc $19d7,y
                    sta $18c4,x
                    bcs L167b
                    dec $18c5,x
L167b               lda $1904,x
                    beq L1690
                    clc
                    adc $1902,x
                    sta $1902,x
                    lda $1905,x
                    adc $1903,x
                    sta $1903,x
L1690               lda $1906,x
                    beq L169c
                    bmi L16f4
                    dec $1906,x
                    bpl L16f4
L169c               ldy $18d9,x
                    lda $1907,x
                    bne L16c2
                    lda $1919,x
                    clc
                    adc $1917,x
                    sta $1919,x
                    bcc L16b3
                    inc $191a,x
L16b3               dec $1916,x
                    bne L16f4
                    lda $1e34,y
                    sta $1916,x
                    lda #$01
                    bpl L16de
L16c2               lda $1919,x
                    sec
                    sbc $1917,x
                    sta $1919,x
                    bcs L16d1
                    dec $191a,x
L16d1               dec $1916,x
                    bne L16f4
                    lda $1e34,y
                    sta $1916,x
                    lda #$00
L16de               sta $1907,x
                    lda $1e74,y
                    beq L16f4
                    clc
                    adc $1917,x
                    sta $1917,x
                    bcc L16f4
                    lda #$ff
                    sta $1917,x
L16f4               cpx $18bf
                    beq L16fc
                    jmp L17ad
                    
L16fc               ldy $18b9
                    bpl L1759
                    dec $18bd
                    bmi L170e
                    bne L1779
                    iny
                    lda $1bb4,y
                    bne L1716
L170e               lda #$ff
                    sta $18bd
                    jmp L17ad
                    
L1716               bpl L1725
                    sta $18b9
                    tay
                    lda $1bb4,y
                    sta $18bd
                    jmp L172c
                    
L1725               sta $18bd
                    tya
                    sta $18b9
L172c               lda $1b8c,y
                    lsr a
                    sta $1056
                    bcc L1740
                    lda $1b96,y
                    sta $1018
                    lda #$00
                    sta $1013
L1740               lda #$00
                    sta $18ba
                    lda $1baa,y
                    sta $18bc
                    lda $1ba0,y
                    lsr a
                    sta $18bb
                    bcc L17ad
                    inc $18ba
                    bne L17ad
L1759               dec $18bd
                    bne L1779
                    dec $18be
                    bpl L1779
                    lda $1b94,y
                    sta $18bd
                    lda $1bb2,y
                    sta $18be
                    lda $18ba
                    eor #$01
                    sta $18ba
                    bpl L17ad
L1779               lda $18ba
                    bne L1798
                    lda $1013
                    ora #$f8
                    clc
                    adc $18bb
                    and #$07
                    sta $1013
                    lda $1018
                    adc $18bc
                    sta $1018
                    jmp L17ad
                    
L1798               lda $1013
                    sec
                    sbc $18bb
                    and #$07
                    sta $1013
                    lda $1018
                    sbc $18bc
                    sta $1018
L17ad               ldy $18f0,x
                    beq L17e1
                    lda $1c3f,y
                    bne L17c1
                    lda $1d0a,y
                    sta $18f0,x
                    tay
                    jmp L17c5
                    
L17c1               inc $18f0,x
                    iny
L17c5               lda $1d09,y
                    sta $18c6,x
                    lda $1c3e,y
                    bpl L1838
                    clc
                    adc $18d7,x
                    tay
                    lda $2b1b,y
                    sta $191b,x
                    lda $2b7b,y
                    sta $191c,x
L17e1               lda $1906,x
                    beq L180c
                    lda $191b,x
                    clc
                    adc $1902,x
                    sta $18c2,x
                    lda $191c,x
                    adc $1903,x
                    cmp $1905,x
                    beq L1846
                    sta $18c3,x
                    rts
                    
L17ff               lda $191b,x
                    sta $18c2,x
                    lda $191c,x
                    sta $18c3,x
                    rts
                    
L180c               lda $191b,x
                    clc
                    adc $1902,x
                    sta $18c0
                    lda $191c,x
                    adc $1903,x
                    cmp $1905,x
                    beq L1846
                    sta $18c1
                    lda $18c0
                    clc
                    adc $1919,x
                    sta $18c2,x
                    lda $18c1
                    adc $191a,x
                    sta $18c3,x
                    rts
                    
L1838               tay
                    lda $2b1b,y
                    sta $18c2,x
                    lda $2b7b,y
                    sta $18c3,x
                    rts
                    
L1846               lda #$00
                    sta $1904,x
                    rts
                    
S184c               lda $18c6,x
                    and $18f1,x
                    sta d404_sVoc1Control,x
                    and #$f7
                    sta d404_sVoc1Control,x
                    sta $18c6,x
                    lda $18c7,x
                    sta d405_sVoc1AttDec,x
                    lda $18c8,x
                    sta d406_sVoc1SusRel,x
                    lda $18c4,x
                    sta d402_sVoc1PWidthLo,x
                    lda $18c5,x
                    sta d403_sVoc1PWidthHi,x
                    lda $18c2,x
                    sta d400_sVoc1FreqLo,x
                    lda $18c3,x
                    sta d401_sVoc1FreqHi,x
                    rts
                    
L1882               lda #$00
                    ldx #$14
L1886               sta $18c2,x
                    dex
                    bpl L1886
                    sta $12a8
                    lda #$01
                    sta $18b5
                    sta $18b6
                    sta $18b7
                    sta $18b8
                    lda #$ff
                    sta $18b4
                    lda #$0f
                    sta $18b3
                    lda #$fe
                    sta $18b2
                    lda #$06
                    sta $105f
                    rts

  .binary "trapped.bin"
