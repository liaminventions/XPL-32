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

InitSid             jmp L1040
                    
PlaySid             jmp L10a1

  .binary "man_ascii.bin"
                    
L1040               lda #$00
                    asl a
                    tay
                    ldx #$00
L1046               lda $18b2,y
                    sta $17cf,x
                    lda $18b3,y
                    sta $17d2,x
                    iny
                    iny
                    inx
                    cpx #$03
                    bne L1046
                    lda $18b2,y
                    sta $1012
                    lda $18b3,y
                    sta $101b
                    ldx #$00
                    txa
L1068               sta $17d5,x
                    inx
                    cpx #$71
                    bne L1068
                    sta $1018
                    sta $1019
                    ldx #$00
                    lda #$01
L107a               sta $17db,x
                    sta $1006,x
                    inx
                    cpx #$03
                    bne L107a
                    ldx #$00
                    txa
L1088               sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$18
                    bne L1088
                    lda #$08
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    lda #$02
                    sta $1842
                    rts
                    
L10a1               lda $f8
                    pha
                    lda $f9
                    pha
                    ldx #$00
                    lda $1842
                    beq L10b4
                    dec $1842
                    jmp L10d6
                    
L10b4               dec $1013
                    bpl L10bf
                    lda $1012
                    sta $1013
L10bf               jsr S10dd
                    inx
                    jsr S10dd
                    inx
                    jsr S10dd
                    lda $1017
                    sta d415_sFiltFreqLo
                    lda $1016
                    sta d416_sFiltFreqHi
L10d6               pla
                    sta $f9
                    pla
                    sta $f8
                    rts
                    
S10dd               lda $1012
                    cmp $1013
                    bne L10ef
                    lda $1006,x
                    beq L10ef
                    dec $17db,x
                    beq L10f2
L10ef               jmp L1332
                    
L10f2               lda $17cf,x
                    sta $f8
                    lda $17d2,x
                    sta $f9
                    ldy $17d5,x
                    lda ($f8),y
                    bpl L114d
                    cmp #$ff
                    bne L1113
                    iny
                    lda ($f8),y
                    sta $17d5,x
                    tay
                    lda ($f8),y
                    jmp L111f
                    
L1113               cmp #$fe
                    bne L111f
                    lda #$00
                    sta $1006,x
                    jmp L165b
                    
L111f               cmp #$fd
                    bne L1135
                    iny
                    inc $17d5,x
                    inc $17d5,x
                    lda ($f8),y
                    sta $17e4,x
                    iny
                    lda ($f8),y
                    jmp L114d
                    
L1135               cmp #$fc
                    bne L114d
                    iny
                    inc $17d5,x
                    inc $17d5,x
                    lda ($f8),y
                    eor #$ff
                    clc
                    adc #$01
                    sta $17e4,x
                    iny
                    lda ($f8),y
L114d               tay
                    lda $1bcc,y
                    sta $f8
                    lda $1be1,y
                    sta $f9
L1158               ldy $17d8,x
                    lda ($f8),y
                    bmi L1162
                    jmp L12b5
                    
L1162               cmp #$fd
                    bne L1175
                    iny
                    lda ($f8),y
                    sta $17de,x
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L1175               cmp #$fc
                    bne L1188
                    iny
                    lda ($f8),y
                    sta $17e1,x
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L1188               cmp #$fe
                    bne L11b0
L118c               lda $17de,x
                    sta $17db,x
                    inc $17d8,x
                    iny
                    lda ($f8),y
                    sta $181d,x
                    cmp #$ff
                    bne L11ad
                    lda #$00
                    sta $17d8,x
                    sta $17e7,x
                    sta $17ea,x
                    inc $17d5,x
L11ad               jmp L165b
                    
L11b0               cmp #$f4
                    bne L11bf
                    lda $1817,x
                    eor #$01
                    sta $1817,x
                    jmp L118c
                    
L11bf               cmp #$f5
                    bne L11d1
                    lda $17ea,x
                    eor #$ff
                    sta $17ea,x
                    inc $17d8,x
                    jmp L1158
                    
L11d1               cmp #$f3
                    bne L11e4
                    iny
                    lda ($f8),y
                    sta $17e7,x
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L11e4               cmp #$fb
                    bne L120e
                    iny
                    lda ($f8),y
                    sta $17ed,x
                    iny
                    lda ($f8),y
                    clc
                    adc $17e4,x
                    sta $100f,x
                    iny
                    lda ($f8),y
                    clc
                    adc $17e4,x
                    sta $17f0,x
                    lda $17d8,x
                    clc
                    adc #$03
                    sta $17d8,x
                    jmp L12c4
                    
L120e               cmp #$fa
                    bne L122e
                    iny
                    lda ($f8),y
                    sta $17ed,x
                    iny
                    lda ($f8),y
                    clc
                    adc $17e4,x
                    sta $17f0,x
                    lda $17d8,x
                    clc
                    adc #$02
                    sta $17d8,x
                    jmp L118c
                    
L122e               cmp #$f9
                    bne L1250
                    iny
                    lda ($f8),y
                    pha
                    beq L123e
                    asl a
                    asl a
                    asl a
                    asl a
                    ora #$04
L123e               sta d417_sFiltControl
                    pla
                    and #$f0
                    sta $1015
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L1250               cmp #$f8
                    bne L1263
                    iny
                    lda ($f8),y
                    sta $1843
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L1263               cmp #$f2
                    bne L1279
                    iny
                    lda ($f8),y
                    ldy $1009,x
                    sta d405_sVoc1AttDec,y
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L1279               cmp #$f1
                    bne L128f
                    iny
                    lda ($f8),y
                    ldy $1009,x
                    sta d406_sVoc1SusRel,y
                    inc $17d8,x
L1289               inc $17d8,x
                    jmp L1158
                    
L128f               cmp #$f7
                    bne L12a2
                    iny
                    lda ($f8),y
                    sta $1018
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L12a2               cmp #$f6
                    bne L1289
                    iny
                    lda ($f8),y
                    sta $1019
                    inc $17d8,x
                    inc $17d8,x
                    jmp L1158
                    
L12b5               clc
                    adc $17e4,x
                    sta $100f,x
                    lda $17ea,x
                    beq L12c4
                    jmp L118c
                    
L12c4               lda $17e1,x
                    asl a
                    asl a
                    asl a
                    tay
                    lda $1bf6,y
                    pha
                    lda $1bf7,y
                    pha
                    ldy $1009,x
                    lda $17e7,x
                    beq L12ee
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $1840
                    pla
                    and #$0f
                    ora $1840
                    sta d406_sVoc1SusRel,y
                    jmp L12f2
                    
L12ee               pla
                    sta d406_sVoc1SusRel,y
L12f2               pla
                    sta d405_sVoc1AttDec,y
                    lda $17de,x
                    sta $17db,x
                    lda #$00
                    sta $1808,x
                    ldy $1009,x
                    lda #$09
                    sta d404_sVoc1Control,y
                    sta $180b,x
                    lda #$00
                    sta d400_sVoc1FreqLo,y
                    sta d401_sVoc1FreqHi,y
                    inc $17d8,x
                    ldy $17d8,x
                    lda ($f8),y
                    sta $181d,x
                    cmp #$ff
                    bne L1331
                    lda #$00
                    sta $17d8,x
                    sta $17e7,x
                    sta $17ea,x
                    inc $17d5,x
L1331               rts
                    
L1332               lda $180b,x
                    bne L133a
                    jmp L1439
                    
L133a               lda #$00
                    sta $180b,x
                    lda $1015
                    ora $101b
                    sta d418_sFiltMode
                    lda $17e1,x
                    asl a
                    asl a
                    asl a
                    tay
                    lda $1bfb,y
                    sta $17fc,x
                    lda $1bfc,y
                    sta $17ff,x
                    lda $1bfd,y
                    and #$07
                    sta $101a
                    lda $1bf8,y
                    sta $17f3,x
                    lda $1bf9,y
                    sta $1841
                    beq L1374
                    sta $17f6,x
L1374               lda $1bfa,y
                    sta $183f
                    beq L137f
                    sta $17f9
L137f               ldy $17f3,x
                    inc $17f3,x
                    lda $1c3e,y
                    sta $1814,x
                    and #$08
                    beq L139d
                    lda $1c59,y
                    sta $1811,x
                    lda #$00
                    sta $180e,x
                    jmp L13b1
                    
L139d               lda $1c59,y
                    clc
                    adc $100f,x
                    tay
                    lda $170f,y
                    sta $180e,x
                    lda $176f,y
                    sta $1811,x
L13b1               lda #$f7
                    sta $1817,x
                    lda $1841
                    beq L13d7
                    ldy $17f6,x
                    beq L13d7
                    lda $1c74,y
                    sta $1823,x
                    lda $1c7a,y
                    sta $1820,x
                    lda #$00
                    sta $1826,x
                    sta $1829,x
                    inc $17f6,x
L13d7               lda $183f
                    beq L1406
                    ldy $17f9
                    lda $1843
                    beq L13ef
                    sta $1016
                    lda #$00
                    sta $1017
                    jmp L13fb
                    
L13ef               lda $1c80,y
                    sta $1016
                    lda $1c82,y
                    sta $1017
L13fb               lda #$00
                    sta $183b
                    sta $183c
                    inc $17f9
L1406               lda #$00
                    sta $1805,x
                    sta $182c,x
                    sta $182f,x
                    sta $1832,x
                    sta $1835,x
                    sta $1838,x
                    ldy $100f,x
                    lda $176f,y
                    sta $1802,x
                    lda $101a
                    beq L1436
                    ldy #$00
L142a               asl $1802,x
                    rol $1805,x
                    iny
                    cpy $101a
                    bne L142a
L1436               jmp L169b
                    
L1439               ldy $17f6,x
                    lda $1c74,y
                    cmp #$90
                    bne L144d
                    lda $1c7a,y
                    sta $17f6,x
                    tay
                    lda $1c74,y
L144d               sta $101f
                    lda $1c7a,y
                    sta $101e
                    iny
                    lda $1820,x
                    clc
                    adc $101e
                    sta $1820,x
                    lda $1823,x
                    adc $101f
                    sta $1823,x
                    lda $1826,x
                    clc
                    adc #$01
                    sta $1826,x
                    lda $1829,x
                    adc #$00
                    sta $1829,x
                    cmp $1c74,y
                    bne L1496
                    lda $1826,x
                    cmp $1c7a,y
                    bne L1496
                    lda #$00
                    sta $1826,x
                    sta $1829,x
                    inc $17f6,x
                    inc $17f6,x
L1496               cpx #$02
                    bne L14f7
                    ldy $17f9
                    lda $1c80,y
                    cmp #$90
                    bne L14ae
                    lda $1c82,y
                    sta $17f9
                    tay
                    lda $1c80,y
L14ae               sta $101f
                    lda $1c82,y
                    sta $101e
                    iny
                    lda $1017
                    clc
                    adc $101e
                    sta $1017
                    lda $1016
                    adc $101f
                    sta $1016
                    lda $183b
                    clc
                    adc #$01
                    sta $183b
                    lda $183c
                    adc #$00
                    sta $183c
                    cmp $1c80,y
                    bne L14f7
                    lda $183b
                    cmp $1c82,y
                    bne L14f7
                    lda #$00
                    sta $183b
                    sta $183c
                    inc $17f9
                    inc $17f9
L14f7               lda $17ed,x
                    bne L14ff
                    jmp L1592
                    
L14ff               lda $100f,x
                    cmp $17f0,x
                    bcs L1555
                    lda $1835,x
                    clc
                    adc $17ed,x
                    sta $1835,x
                    lda $1838,x
                    adc #$00
                    sta $1838,x
                    lda $180e,x
                    clc
                    adc $1835,x
                    sta $183d
                    lda $1811,x
                    adc $1838,x
                    sta $183e
                    ldy $17f0,x
                    cmp $176f,y
                    bne L158f
L1534               lda $17f0,x
                    sta $100f,x
                    tay
                    lda $170f,y
                    sta $180e,x
                    lda $176f,y
                    sta $1811,x
                    lda #$00
                    sta $1835,x
                    sta $1838,x
                    sta $17ed,x
                    jmp L1592
                    
L1555               lda $1835,x
                    sec
                    sbc $17ed,x
                    sta $1835,x
                    lda $1838,x
                    sbc #$00
                    sta $1838,x
                    lda $180e,x
                    clc
                    adc $1835,x
                    sta $183d
                    lda $1811,x
                    adc $1838,x
                    sta $183e
                    ldy $17f0,x
                    cmp $176f,y
                    bcc L1534
                    bne L158f
                    lda $183d
                    cmp $170f,y
                    bcs L158f
                    jmp L1534
                    
L158f               jmp L1614
                    
L1592               lda $17ea,x
                    beq L15a2
                    lda #$00
                    sta $1835,x
                    sta $1838,x
                    jmp L1614
                    
L15a2               lda $17ff,x
                    beq L1614
                    lda $17fc,x
                    beq L15b2
                    dec $17fc,x
                    jmp L1614
                    
L15b2               lda $182f,x
                    bne L15ee
                    lda $1835,x
                    clc
                    adc $1802,x
                    sta $1835,x
                    lda $1838,x
                    adc $1805,x
                    sta $1838,x
                    inc $1832,x
                    lda $1832,x
                    cmp $17ff,x
                    bne L1614
                    lda #$00
                    sta $1832,x
                    inc $182f,x
                    lda $182c,x
                    bne L1614
                    asl $1802,x
                    rol $1805,x
                    inc $182c,x
                    jmp L1614
                    
L15ee               lda $1835,x
                    sec
                    sbc $1802,x
                    sta $1835,x
                    lda $1838,x
                    sbc $1805,x
                    sta $1838,x
                    inc $1832,x
                    lda $1832,x
                    cmp $17ff,x
                    bne L1614
                    lda #$00
                    sta $1832,x
                    dec $182f,x
L1614               lda $1019
                    beq L1632
                    lda $101c
                    sec
                    sbc $1019
                    sta $101c
                    lda $101b
                    sbc #$00
                    sta $101b
                    bne L1632
                    lda #$00
                    sta $1019
L1632               lda $1018
                    beq L1652
                    lda $101c
                    clc
                    adc $1018
                    sta $101c
                    lda $101b
                    adc #$00
                    sta $101b
                    cmp #$0f
                    bne L1652
                    lda #$00
                    sta $1018
L1652               lda $101b
                    ora $1015
                    sta d418_sFiltMode
L165b               ldy $17f3,x
                    lda $1c3e,y
                    cmp #$90
                    bne L166f
                    lda $1c59,y
                    sta $17f3,x
                    tay
                    lda $1c3e,y
L166f               sta $1814,x
                    and #$08
                    beq L1684
                    lda $1c59,y
                    sta $1811,x
                    lda #$00
                    sta $180e,x
                    jmp L1698
                    
L1684               lda $1c59,y
                    clc
                    adc $100f,x
                    tay
                    lda $170f,y
                    sta $180e,x
                    lda $176f,y
                    sta $1811,x
L1698               inc $17f3,x
L169b               ldy $1009,x
                    lda $181d,x
                    cmp #$fe
                    beq L16e6
                    cmp #$f4
                    beq L16e6
                    cmp #$fa
                    beq L16e6
                    cmp #$f2
                    beq L16e6
                    cmp #$f1
                    beq L16e6
                    cmp #$f5
                    beq L16cd
                    lda $17ea,x
                    bne L16e6
L16be               lda $17db,x
                    cmp #$01
                    bne L16d5
                    lda #$00
                    sta d406_sVoc1SusRel,y
                    jmp L16e6
                    
L16cd               lda $17ea,x
                    beq L16e6
                    jmp L16be
                    
L16d5               lda $17db,x
                    cmp #$02
                    bne L16e6
                    lda $1013
                    bne L16e6
                    lda #$f6
                    sta $1817,x
L16e6               lda $180e,x
                    clc
                    adc $1835,x
                    sta d400_sVoc1FreqLo,y
                    lda $1811,x
                    adc $1838,x
                    sta d401_sVoc1FreqHi,y
                    lda $1820,x
                    sta d402_sVoc1PWidthLo,y
                    lda $1823,x
                    sta d403_sVoc1PWidthHi,y
                    lda $1814,x
                    and $1817,x
                    sta d404_sVoc1Control,y
                    rts

  .binary "man.bin"
