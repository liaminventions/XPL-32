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

  .org $1000

InitSid             jmp L1040
                    
PlaySid             jmp L1095
                    
L1006               jmp L10d3


  .binary "wavid_ascii.bin"

                    
L1040               lda #$00
                    asl a
                    tay
                    ldx #$00
L1046               lda $18a0,y
                    sta $17d9,x
                    lda $18a1,y
                    sta $17dc,x
                    iny
                    iny
                    inx
                    cpx #$03
                    bne L1046
                    lda $18a0,y
                    sta L10be + 1
                    lda $18a1,y
                    sta $101a
                    ldx #$00
                    txa
L1068               sta $17df,x
                    inx
                    cpx #$79
                    bne L1068
                    tax
L1071               lda #$02
                    sta $17e5,x
                    sta $1009,x
                    inx
                    cpx #$03
                    bne L1071
                    ldx #$00
                    txa
L1081               sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$18
                    bne L1081
                    lda #$08
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    rts
                    
L1095               lda $fa
                    pha
                    lda $fb
                    pha
                    dec $1016
                    bmi L10be
                    ldx #$00
                    jsr S1373
                    inx
                    jsr S1373
                    inx
                    jsr S1373
L10ad               lda $1019
                    clc
                    adc $1853
                    sta d416_sFiltFreqHi
                    pla
                    sta $fb
                    pla
                    sta $fa
                    rts
                    
L10be               lda #$00
                    sta $1016
                    ldx #$00
                    jsr S10e1
                    inx
                    jsr S10e1
                    inx
                    jsr S10e1
                    jmp L10ad
                    
L10d3               ldx #$00
                    jsr L1654
                    inx
                    jsr L1654
                    inx
                    jsr L1654
                    rts
                    
S10e1               lda $1009,x
                    beq L10eb
                    dec $17e5,x
                    beq L10ee
L10eb               jmp S1373
                    
L10ee               lda $17d9,x
                    sta $fa
                    lda $17dc,x
                    sta $fb
                    ldy $17df,x
                    lda ($fa),y
                    bpl L1145
                    cmp #$ff
                    bne L110c
                    iny
                    lda ($fa),y
                    sta $17df,x
                    tay
                    lda ($fa),y
L110c               cmp #$fd
                    bne L1120
                    iny
                    lda ($fa),y
                    sta $17ee,x
                    iny
                    tya
                    sta $17df,x
                    lda ($fa),y
                    jmp L1145
                    
L1120               cmp #$fc
                    bne L1139
                    iny
                    lda ($fa),y
                    eor #$ff
                    clc
                    adc #$01
                    sta $17ee,x
                    iny
                    tya
                    sta $17df,x
                    lda ($fa),y
                    jmp L1145
                    
L1139               cmp #$fe
                    bne L1145
                    lda #$00
                    sta $1009,x
                    jmp L1654
                    
L1145               tay
                    lda $1c45,y
                    sta $fa
                    lda $1c55,y
                    sta $fb
L1150               ldy $17e2,x
L1153               lda ($fa),y
                    bmi L115a
                    jmp L1314
                    
L115a               cmp #$fd
                    bne L116c
                    iny
                    lda ($fa),y
                    sta $17e8,x
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L116c               cmp #$fc
                    bne L117e
                    iny
                    lda ($fa),y
                    sta $17eb,x
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L117e               cmp #$f0
                    bne L11cc
                    iny
                    lda ($fa),y
                    pha
                    and #$07
                    sta $1856
                    ldy $1012,x
                    lda $1779,y
                    sta $180c,x
                    lda $1856
                    beq L11b7
                    lda #$00
                    sta $180f,x
                    sta $1806,x
                    sta $1833,x
                    sta $1836,x
                    sta $1839,x
                    tay
L11ab               asl $180c,x
                    rol $180f,x
                    iny
                    cpy $1856
                    bne L11ab
L11b7               pla
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $1809,x
                    lda $17e2,x
                    clc
                    adc #$02
                    sta $17e2,x
                    tay
                    jmp L1153
                    
L11cc               cmp #$fe
                    bne L11f4
L11d0               lda $17e8,x
                    sta $17e5,x
                    inc $17e2,x
                    iny
                    lda ($fa),y
                    sta $1827,x
                    cmp #$ff
                    bne L11f1
                    lda #$00
                    sta $17e2,x
                    sta $17f1,x
                    sta $17f4,x
                    inc $17df,x
L11f1               jmp L1654
                    
L11f4               cmp #$f4
                    bne L1203
                    lda $1821,x
                    eor #$01
                    sta $1821,x
                    jmp L11d0
                    
L1203               cmp #$f5
                    bne L1215
                    lda $17f4,x
                    eor #$ff
                    sta $17f4,x
                    inc $17e2,x
                    jmp L1150
                    
L1215               cmp #$f3
                    bne L1227
                    iny
                    lda ($fa),y
                    sta $17f1,x
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L1227               cmp #$fb
                    bne L124c
                    iny
                    lda ($fa),y
                    sta $17f7,x
                    iny
                    lda ($fa),y
                    clc
                    adc $17ee,x
                    sta $1012,x
                    iny
                    lda ($fa),y
                    clc
                    adc $17ee,x
                    sta $17fa,x
                    tya
                    sta $17e2,x
                    jmp L1323
                    
L124c               cmp #$fa
                    bne L126f
                    iny
                    lda ($fa),y
                    sta $17f7,x
                    iny
                    lda ($fa),y
                    clc
                    adc $17ee,x
                    sta $17fa,x
                    tya
                    sta $17e2,x
                    lda #$00
                    sta $183c,x
                    sta $183f,x
                    jmp L11d0
                    
L126f               cmp #$f9
                    bne L1294
                    iny
                    lda ($fa),y
                    sta $1857
                    beq L1281
                    asl a
                    asl a
                    asl a
                    asl a
                    ora #$04
L1281               sta d417_sFiltControl
                    lda $1857
                    and #$f0
                    sta $1018
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L1294               cmp #$f8
                    bne L12a6
                    iny
                    lda ($fa),y
                    sta $1853
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L12a6               cmp #$f2
                    bne L12bf
                    iny
                    lda ($fa),y
                    ldy $100c,x
                    sta d405_sVoc1AttDec,y
                    lda $17e2,x
                    clc
                    adc #$02
                    sta $17e2,x
                    jmp L1150
                    
L12bf               cmp #$f1
                    bne L12d8
                    iny
                    lda ($fa),y
                    ldy $100c,x
                    sta d406_sVoc1SusRel,y
                    lda $17e2,x
                    clc
                    adc #$02
                    sta $17e2,x
                    jmp L1150
                    
L12d8               cmp #$f7
                    bne L12ea
                    iny
                    lda ($fa),y
                    sta $1854
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L12ea               cmp #$f6
                    bne L12fc
                    iny
                    lda ($fa),y
                    sta $1855
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L12fc               cmp #$ef
                    bne L130e
                    iny
                    lda ($fa),y
                    sta $1842,x
                    iny
                    tya
                    sta $17e2,x
                    jmp L1153
                    
L130e               inc $17e2,x
                    jmp L1150
                    
L1314               clc
                    adc $17ee,x
                    sta $1012,x
                    lda $17f4,x
                    beq L1323
                    jmp L11d0
                    
L1323               iny
                    lda ($fa),y
                    sta $1827,x
                    lda $17eb,x
                    asl a
                    asl a
                    asl a
                    sta $184b,x
                    tay
                    lda $17f1,x
                    bne L1352
                    lda $1c65,y
                    pha
                    lda $1c66,y
                    ldy $100c,x
                    sta d406_sVoc1SusRel,y
                    pla
                    sta d405_sVoc1AttDec,y
                    lda #$09
                    sta d404_sVoc1Control,y
                    sta $1815,x
                    rts
                    
L1352               asl a
                    asl a
                    asl a
                    asl a
                    sta $fa
                    lda $1c66,y
                    and #$0f
                    ora $fa
                    ldy $100c,x
                    sta d406_sVoc1SusRel,y
                    lda #$00
                    sta d405_sVoc1AttDec,y
                    lda #$09
                    sta d404_sVoc1Control,y
                    sta $1815,x
                    rts
                    
S1373               lda $1815,x
                    bne L137b
                    jmp L147b
                    
L137b               lda #$00
                    sta $1815,x
                    sta $183c,x
                    sta $183f,x
                    lda $17e8,x
                    sta $17e5,x
                    inc $17e2,x
                    ldy $184b,x
                    lda $1c6b,y
                    and #$0f
                    sta $1809,x
                    beq L13e1
                    lda $1c6a,y
                    sta $1806,x
                    lda $1c6c,y
                    and #$f0
                    lsr a
                    lsr a
                    lsr a
                    sta $1812,x
                    lda $1c6c,y
                    and #$07
                    sta $1856
                    ldy $1012,x
                    lda $1779,y
                    sta $180c,x
                    lda #$00
                    sta $180f,x
                    sta $1833,x
                    sta $1836,x
                    sta $1839,x
                    tay
                    lda $1856
                    beq L13de
L13d2               asl $180c,x
                    rol $180f,x
                    iny
                    cpy $1856
                    bne L13d2
L13de               ldy $184b,x
L13e1               lda $1c6b,y
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $1845,x
                    sta $1848,x
                    lda $1c67,y
                    sta $17fd,x
                    lda $1c68,y
                    beq L1411
                    tay
                    sta $1800,x
                    lda $1d0f,y
                    sta $182d,x
                    lda $1d24,y
                    sta $182a,x
                    lda #$00
                    sta $1830,x
                    inc $1800,x
L1411               cpx #$02
                    bne L142f
                    ldy $184b,x
                    lda $1c69,y
                    beq L142f
                    sta $1803
                    tay
                    lda $1d39,y
                    sta $1019
                    lda #$00
                    sta $184e
                    inc $1803
L142f               ldy $17fd,x
                    lda $1cb5,y
                    sta $181e,x
                    and #$08
                    beq L144a
                    lda $1ce2,y
                    sta $181b,x
                    lda #$00
                    sta $1818,x
                    jmp L145e
                    
L144a               lda $1ce2,y
                    clc
                    adc $1012,x
                    tay
                    lda $1719,y
                    sta $1818,x
                    lda $1779,y
                    sta $181b,x
L145e               lda #$f7
                    sta $1821,x
                    lda $1827,x
                    cmp #$ff
                    bne L1478
                    lda #$00
                    sta $17e2,x
                    sta $17f1,x
                    sta $17f4,x
                    inc $17df,x
L1478               jmp L1696
                    
L147b               cpx #$02
                    bne L14b4
                    lda $1857
                    beq L14b4
                    ldy $1803
                    lda $1d39,y
                    cmp #$90
                    bne L1495
                    lda $1d4e,y
                    sta $1803
                    tay
L1495               lda $1d39,y
                    clc
                    adc $1019
                    sta $1019
                    iny
                    inc $184e
                    lda $184e
                    cmp $1d4e,y
                    bne L14b4
                    lda #$00
                    sta $184e
                    iny
                    sty $1803
L14b4               ldy $1800,x
                    lda $1d0f,y
                    cmp #$90
                    bne L14c5
                    lda $1d24,y
                    sta $1800,x
                    tay
L14c5               lda $1d24,y
                    clc
                    adc $182a,x
                    sta $182a,x
                    lda $1d0f,y
                    adc $182d,x
                    sta $182d,x
                    iny
                    inc $1830,x
                    lda $1830,x
                    cmp $1d24,y
                    bne L14ee
                    lda #$00
                    sta $1830,x
                    iny
                    tya
                    sta $1800,x
L14ee               lda $17f7,x
                    bne L14f6
                    jmp L156c
                    
L14f6               lda $1012,x
                    cmp $17fa,x
                    bcs L152b
                    lda $1818,x
                    clc
                    adc $183c,x
                    lda $181b,x
                    adc $183f,x
                    ldy $17fa,x
                    cmp $1779,y
                    bne L1516
                    jmp L1558
                    
L1516               lda $183c,x
                    clc
                    adc $17f7,x
                    sta $183c,x
                    lda $183f,x
                    adc #$00
                    sta $183f,x
                    jmp L1654
                    
L152b               lda $1818,x
                    clc
                    adc $183c,x
                    lda $181b,x
                    adc $183f,x
                    ldy $17fa,x
                    cmp $1779,y
                    bne L1543
                    jmp L1558
                    
L1543               lda $183c,x
                    sec
                    sbc $17f7,x
                    sta $183c,x
                    lda $183f,x
                    sbc #$00
                    sta $183f,x
                    jmp L1654
                    
L1558               lda $17fa,x
                    sta $1012,x
                    lda #$00
                    sta $183c,x
                    sta $183f,x
                    sta $17f7,x
                    jmp L1654
                    
L156c               lda $17f4,x
                    beq L157c
                    lda #$00
                    sta $183c,x
                    sta $183f,x
                    jmp L1654
                    
L157c               lda $1809,x
                    bne L1584
                    jmp L1612
                    
L1584               lda $1806,x
                    beq L158f
                    dec $1806,x
                    jmp L1612
                    
L158f               lda $1836,x
                    bne L15dd
                    lda $183c,x
                    clc
                    adc $180c,x
                    sta $183c,x
                    lda $183f,x
                    adc $180f,x
                    sta $183f,x
                    inc $1839,x
                    lda $1839,x
                    cmp $1809,x
                    bne L1612
                    inc $1836,x
                    lda $1812,x
                    beq L15cc
                    clc
                    adc $180c,x
                    sta $180c,x
                    lda $180f,x
                    adc #$00
                    sta $180f,x
                    jmp L1654
                    
L15cc               lda $1833,x
                    bne L15da
                    asl $180c,x
                    rol $180f,x
                    inc $1833,x
L15da               jmp L1654
                    
L15dd               lda $183c,x
                    sec
                    sbc $180c,x
                    sta $183c,x
                    lda $183f,x
                    sbc $180f,x
                    sta $183f,x
                    dec $1839,x
                    lda $1839,x
                    bne L1612
                    dec $1836,x
                    lda $1812,x
                    beq L1612
                    clc
                    adc $180c,x
                    sta $180c,x
                    lda $180f,x
                    adc #$00
                    sta $180f,x
                    jmp L1654
                    
L1612               lda $1855
                    beq L162e
                    lda $101b
                    sec
                    sbc $1855
                    sta $101b
                    lda $101a
                    sbc #$00
                    sta $101a
                    bne L162e
                    sta $1855
L162e               lda $1854
                    beq L164b
                    clc
                    adc $101b
                    sta $101b
                    lda $101a
                    adc #$00
                    sta $101a
                    cmp #$0f
                    bne L164b
                    lda #$00
                    sta $1854
L164b               lda $101a
                    ora $1018
                    sta d418_sFiltMode
L1654               ldy $17fd,x
                    lda $1cb5,y
                    cmp #$90
                    bne L1668
                    lda $1ce2,y
                    sta $17fd,x
                    tay
                    lda $1cb5,y
L1668               sta $181e,x
                    and #$08
                    beq L167d
                    lda $1ce2,y
                    sta $181b,x
                    lda #$00
                    sta $1818,x
                    jmp L1696
                    
L167d               lda $1ce2,y
                    clc
                    adc $1012,x
                    tay
                    lda $1719,y
                    adc $1842,x
                    sta $1818,x
                    lda $1779,y
                    adc #$00
                    sta $181b,x
L1696               lda $1848,x
                    beq L16a1
                    dec $1848,x
                    jmp L16aa
                    
L16a1               inc $17fd,x
                    lda $1845,x
                    sta $1848,x
L16aa               ldy $100c,x
                    lda $1827,x
                    cmp #$fe
                    beq L16f0
                    cmp #$fa
                    beq L16f0
                    cmp #$f4
                    beq L16f0
                    cmp #$f5
                    beq L16eb
                    cmp #$f3
                    bcs L16c6
                    bmi L16f0
L16c6               lda $17f4,x
                    bne L16f0
L16cb               lda $17e5,x
                    cmp #$01
                    bne L16da
                    lda #$00
                    sta d406_sVoc1SusRel,y
                    jmp L16f0
                    
L16da               cmp #$02
                    bne L16f0
                    lda $1016
                    bne L16f0
                    lda #$f6
                    sta $1821,x
                    jmp L16f0
                    
L16eb               lda $17f4,x
                    bne L16cb
L16f0               lda $1818,x
                    clc
                    adc $183c,x
                    sta d400_sVoc1FreqLo,y
                    lda $181b,x
                    adc $183f,x
                    sta d401_sVoc1FreqHi,y
                    lda $182a,x
                    sta d402_sVoc1PWidthLo,y
                    lda $182d,x
                    sta d403_sVoc1PWidthHi,y
                    lda $181e,x
                    and $1821,x
                    sta d404_sVoc1Control,y
                    rts
  .binary "wavid.bin"
