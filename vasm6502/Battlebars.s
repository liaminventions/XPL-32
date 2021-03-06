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
  jmp check

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

  .org $0fff

InitSid             tay
                    jmp L10f2
                    
PlaySid             jmp L115e
                    
L1006               jmp L1154
                    
L1009               jmp L1250

  .binary "Battlebars_ascii.bin"
                    
L10f2               lda $18e3,y
                    tay
                    lda $1c1a,y
                    sta $106c
                    lda $1c1b,y
                    sta $106d
                    lda #$0f
                    sta $1073
                    ldx #$00
L1109               iny
                    iny
                    lda $1c1a,y
                    sta $1092,x
                    sta $1095,x
                    lda $1c1b,y
                    sta $109e,x
                    lda $1c1c,y
                    sta $10a1,x
                    lda #$01
                    sta $1069
                    sta $1074,x
                    sta $106b
                    lda #$00
                    sta $109b,x
                    sta $1098,x
                    sta $10a4,x
                    sta $1080,x
                    iny
                    inx
                    cpx #$03
                    bne L1109
                    sta $10f1
                    sta $1071
                    sta $1072
                    sta $106a
L114b               sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
L1154               sta $106e
S1157               sta $106f
                    sta $1070
                    rts
                    
L115e               lda $1069
                    beq L114b
                    cld
                    ldx #$02
                    lda $106f
                    beq L117b
                    ldy $1073
                    beq L117b
                    dec $1070
                    bne L117b
                    sta $1070
                    dec $1073
L117b               dec $106b
                    bpl L1188
                    lda $106d
                    sta $106b
                    bne L119c
L1188               dec $106a
                    bpl L119c
                    lda $106c
                    sta $106a
                    dec $1074
                    dec $1075
                    dec $1076
L119c               stx $1067
                    lda $1074,x
                    beq L11a7
                    jmp L1416
                    
L11a7               lda $109e,x
                    sta $fe
                    lda $10a1,x
                    sta $ff
                    ldy $109b,x
                    lda ($fe),y
                    bpl L11fb
                    cmp #$ff
                    bne L11c7
                    iny
                    lda ($fe),y
                    sta $109b,x
                    tay
                    lda ($fe),y
                    bpl L11fb
L11c7               cmp #$c0
                    bcs L11db
                    and #$3f
                    adc $1092,x
                    sta $1095,x
                    inc $109b,x
                    iny
                    lda ($fe),y
                    bpl L1256
L11db               cmp #$e0
                    bcs L11ec
                    and #$1f
                    sta $1080,x
                    inc $109b,x
                    iny
                    lda ($fe),y
                    bpl L1256
L11ec               cmp #$fb
                    bcs L11ff
                    and #$1f
                    sta $10a4,x
                    inc $109b,x
                    iny
                    lda ($fe),y
L11fb               bpl L1256
                    cmp #$fb
L11ff               bne L1223
                    inc $109b,x
                    iny
                    lda ($fe),y
                    sta $106a
                    sta $106c
                    inc $109b,x
                    iny
                    lda ($fe),y
                    sta $106d
                    lda #$00
                    sta $106b
                    inc $109b,x
                    iny
                    lda ($fe),y
                    bpl L1256
L1223               cmp #$fc
                    bne L1236
                    lda $106e
                    bne L1248
                    jsr S1157
                    lda #$0f
                    sta $1073
                    bne L1248
L1236               cmp #$fd
                    bne L1250
                    inc $109b,x
                    iny
                    lda $106e
                    bne L1248
                    lda ($fe),y
                    jsr S1157
L1248               inc $109b,x
                    iny
                    lda ($fe),y
                    bpl L1256
L1250               lda #$00
                    sta $1069
                    rts
                    
L1256               tay
                    lda $1ce1,y
                    sta $fe
                    lda $1d00,y
                    sta $ff
                    lda #$00
                    sta $107a,x
                    sta $10c8,x
                    sta $10bc,x
                    sta $10ee,x
                    ldy $1098,x
                    bne L1280
                    sta $10b9,x
                    sta $108f,x
                    sta $1083,x
                    sta $1086,x
L1280               lda ($fe),y
                    bpl L12c2
                    cmp #$81
                    bcs L1293
                    iny
                    lda ($fe),y
                    sta $108f,x
                    iny
                    lda ($fe),y
                    bpl L12c2
L1293               cmp #$c0
                    bcs L12ac
                    and #$3f
L1299               sta $1077,x
                    iny
                    lda ($fe),y
                    bpl L12c2
                    cmp #$c0
                    bcs L12ac
                    and #$3f
                    adc $1077,x
                    bne L1299
L12ac               cmp #$e0
                    bcs L12c4
                    and #$1f
                    adc $1080,x
                    tax
                    lda $18e3,x
                    ldx $1067
                    sta $107d,x
                    iny
                    lda ($fe),y
L12c2               bpl L1325
L12c4               cmp #$f8
                    bcs L12dd
                    and #$1f
L12ca               sta $10b9,x
                    iny
                    lda ($fe),y
                    bpl L1325
                    cmp #$f8
                    bcs L12dd
                    and #$1f
                    adc $10b9,x
                    bne L12ca
L12dd               bne L12e9
                    lda #$00
                    sta $1071
                    iny
                    lda ($fe),y
                    bpl L1325
L12e9               cmp #$f9
                    bne L12f8
                    iny
                    lda ($fe),y
                    sta $1083,x
                    iny
                    lda ($fe),y
                    bpl L1325
L12f8               cmp #$fa
                    bne L1307
                    iny
                    lda ($fe),y
                    sta $1086,x
                    iny
                    lda ($fe),y
                    bpl L1325
L1307               cmp #$fb
                    beq L1311
                    cmp #$fc
                    bne L1319
                    lda #$01
L1311               sta $10ee,x
                    iny
                    lda ($fe),y
                    bpl L1325
L1319               cmp #$fe
                    beq L131f
                    lda #$00
L131f               sta $10f1
                    iny
                    lda ($fe),y
L1325               cmp #$60
                    beq L133f
                    bcs L1333
                    adc $1095,x
                    sta $108c,x
                    bpl L135e
L1333               and #$1f
                    sta $1074,x
                    lda #$00
                    sta $1089,x
                    beq L136a
L133f               iny
                    lda ($fe),y
                    sta $10c5,x
                    iny
                    lda ($fe),y
                    sta $10c8,x
                    iny
                    lda ($fe),y
                    clc
                    adc $1095,x
                    sta $108c,x
                    iny
                    lda ($fe),y
                    adc $1095,x
                    sta $10cb,x
L135e               lda $107d,x
                    sta $1089,x
                    lda $1077,x
                    sta $1074,x
L136a               iny
                    lda ($fe),y
                    cmp #$ff
                    bne L1380
                    lda $10a4,x
                    bne L137b
                    inc $109b,x
                    bne L137e
L137b               dec $10a4,x
L137e               ldy #$00
L1380               tya
                    sta $1098,x
                    lsr $10ad,x
                    asl $10ad,x
                    lda $10ad,x
                    ldy $18dd,x
                    sta d404_sVoc1Control,y
                    ldy $1089,x
                    lda $1a96,y
                    sta $fe
                    lda $1a95,y
                    sta $10b6,x
                    and #$08
                    beq L13b8
                    lda $108c,x
                    sec
                    sbc $1095,x
                    sta $108c,x
                    lda $10cb,x
                    sbc $1095,x
                    sta $10cb,x
L13b8               lda $10ee,x
                    bmi L13d5
                    lda $10b6,x
                    and #$01
                    bne L13c7
                    lda $1a8e,y
L13c7               sta $10ad,x
                    lda $1a94,y
                    sta $10da,x
                    and #$0f
                    sta $10de,x
L13d5               lda $1083,x
                    bne L13dd
                    lda $1a90,y
L13dd               sta $10a7,x
                    lda $1086,x
                    bne L13e8
                    lda $1a91,y
L13e8               sta $10aa,x
                    ldy $fe
                    beq L1410
                    lda $10f1
                    bmi L1410
                    lda $1b9d,y
                    sta $10dd
                    lda $1b9e,y
                    sta $10e1
                    lda $1b9f,y
                    clc
                    adc $18e0,x
                    sta $1071
                    lda $1ba0,y
                    sta $1072
L1410               jsr S163e
                    jmp L156d
                    
L1416               lda $10b6,x
                    and #$04
                    beq L142c
                    lda $107a,x
                    cmp #$00
                    bcc L142c
                    lda $10c2,x
                    beq L142c
                    dec $10c2,x
L142c               lda $10b6,x
                    and #$02
                    beq L145a
                    jsr S163e
                    lda $107a,x
                    cmp #$00
                    bcc L145a
                    cmp #$20
                    bcs L145a
                    lsr a
                    bcc L1489
                    rol a
                    sec
                    sbc #$00
                    lsr a
                    sta $fe
                    inc $fe
                    lda $10c2,x
                    sec
                    sbc $fe
                    bcc L145a
                    sta $10c2,x
                    bcs L1489
L145a               ldy $10c8,x
                    beq L146d
                    lda $107a,x
                    cmp $10c5,x
                    bcc L146d
                    jsr S16a5
                    jmp L1489
                    
L146d               ldy $1089,x
                    lda $1a97,y
                    beq L1489
                    lsr a
                    tay
                    lda $107a,x
                    lsr a
                    bne L1480
                    sta $10d7,x
L1480               rol a
                    cmp $1b83,y
                    bcc L1489
                    jsr S170a
L1489               ldy $1089,x
                    lda $1a98,y
                    beq L149e
                    tay
                    lda $107a,x
                    lsr a
                    bne L149b
                    jsr S17cc
L149b               jsr S17e0
L149e               ldy $1089,x
                    lda $1a96,y
                    beq L14ba
                    tay
                    lda $107a,x
                    lsr a
                    bne L14b2
                    ldx #$03
                    jsr S17cc
L14b2               ldx #$03
                    jsr S17e0
                    ldx $1067
L14ba               ldy $10b9,x
                    beq L14c9
                    lda $10b6,x
                    and #$10
                    bne L14c9
                    jsr S1643
L14c9               lda $10b6,x
                    bpl L14dd
                    lda $107a,x
                    lsr a
                    bne L14da
                    sta $10b0,x
                    sta $10b3,x
L14da               jsr S15dc
L14dd               lda $10b6,x
                    and #$20
                    beq L1522
                    lda $107a,x
                    cmp #$03
                    bcc L1522
                    lda $106a
                    sta $fe
                    lda $1074,x
                    sta $ff
                    ldy $106b
                    dey
                    bpl L1500
                    ldy $106d
                    bne L150d
L1500               dec $fe
                    bpl L150d
                    lda $106c
                    sta $fe
                    dec $ff
                    beq L151d
L150d               dey
                    bpl L1515
                    ldy $106d
                    bne L1522
L1515               dec $fe
                    bpl L1522
                    dec $ff
                    bne L1522
L151d               lda #$00
                    sta $10aa,x
L1522               ldy $1089,x
                    lda $107a,x
                    cmp #$02
                    bcs L1542
                    lsr a
                    bne L1562
                    lda $10b6,x
                    and #$40
                    beq L1562
                    ldy $18dd,x
                    lda #$81
                    sta $10ad,x
                    lda #$f9
                    bne L1585
L1542               lda $107a,x
                    cmp $1a92,y
                    bcc L1562
                    lda $1a93,y
                    beq L1561
                    cmp $1074,x
                    bcc L1562
                    lda $10b6,x
                    bpl L1561
                    lsr $10ad,x
                    asl $10ad,x
                    bcc L156d
L1561               iny
L1562               lda $10b6,x
                    bmi L156d
                    lda $1a8e,y
                    sta $10ad,x
L156d               ldy $18dd,x
                    lda $10de,x
                    sta d403_sVoc1PWidthHi,y
                    lda $10da,x
                    sta d402_sVoc1PWidthLo,y
                    lda $10bf,x
                    sta d400_sVoc1FreqLo,y
                    lda $10c2,x
L1585               sta d401_sVoc1FreqHi,y
                    lda $10aa,x
                    sta d406_sVoc1SusRel,y
                    lda $10a7,x
                    sta d405_sVoc1AttDec,y
                    lda $10ee,x
                    beq L15a1
                    bmi L15a7
                    lsr $10ad,x
                    asl $10ad,x
L15a1               lda $10ad,x
                    sta d404_sVoc1Control,y
L15a7               inc $107a,x
                    bne L15af
                    dec $107a,x
L15af               dex
                    bmi L15b5
                    jmp L119c
                    
L15b5               lda $10dd
                    sta d415_sFiltFreqLo
                    lsr a
                    lsr a
                    lsr a
                    sta $fe
                    lda $10e1
                    lsr a
                    ror a
                    ror a
                    ror a
                    ora $fe
                    sta d416_sFiltFreqHi
                    lda $1071
                    sta d417_sFiltControl
                    lda $1073
                    ora $1072
                    sta d418_sFiltMode
                    rts
                    
S15dc               ldy $1089,x
                    lda $1a8f,y
                    sta $1068
                    tay
                    lda $1a6a,y
                    sta $fe
                    lda $1a6c,y
                    sta $ff
                    ldy $10b0,x
                    lda ($fe),y
                    cmp #$fe
                    beq L1609
                    bcc L1601
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L1601               sta $10ad,x
                    iny
                    tya
                    sta $10b0,x
L1609               ldy $1068
                    lda $1a6e,y
                    sta $fe
                    lda $1a70,y
                    sta $ff
                    ldy $10b3,x
                    lda ($fe),y
                    cmp #$fd
                    bcc L162f
                    beq L163b
                    cmp #$fe
                    beq L163a
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
                    cmp #$fd
                    beq L163b
L162f               sta $10c2,x
                    sta $10bf,x
                    iny
                    tya
                    sta $10b3,x
L163a               rts
                    
L163b               inc $10b3,x
S163e               ldy $108c,x
                    bpl L166b
S1643               lda $19b9,y
                    sta $fe
                    lda $19c4,y
                    sta $ff
                    ldy $10bc,x
                    iny
                    lda ($fe),y
                    bpl L1660
                    cmp #$81
                    beq L165c
                    bcs L1660
                    rts
                    
L165c               iny
                    lda ($fe),y
                    tay
L1660               tya
                    sta $10bc,x
                    lda ($fe),y
                    clc
                    adc $108c,x
                    tay
L166b               lda $18fa,y
                    sta $10bf,x
                    sec
                    sbc $18f9,y
                    sta $fe
                    lda $195a,y
                    sta $10c2,x
                    sbc $1959,y
                    ldy $108f,x
                    beq L16a4
                    lsr a
                    ror $fe
                    lsr a
                    ror $fe
                    lsr a
                    sta $ff
                    ror $fe
L1690               lda $10bf,x
                    sec
                    sbc $fe
                    sta $10bf,x
                    lda $10c2,x
                    sbc $ff
                    sta $10c2,x
                    dey
                    bne L1690
L16a4               rts
                    
S16a5               sty $fe
                    lda #$00
                    asl $fe
                    rol a
                    asl $fe
                    rol a
                    sta $ff
                    ldy $10cb,x
                    tya
                    cmp $108c,x
                    bcs L16e9
                    lda $10bf,x
                    sec
                    sbc $fe
                    sta $10bf,x
                    lda $10c2,x
                    sbc $ff
                    sta $10c2,x
                    lda $10bf,x
                    sec
                    sbc $18fa,y
                    lda $10c2,x
                    sbc $195a,y
                    bcs L1709
L16da               lda #$00
                    sta $10c8,x
                    sta $10d7,x
                    tya
                    sta $108c,x
                    jmp L166b
                    
L16e9               lda $10bf,x
                    clc
                    adc $fe
                    sta $10bf,x
                    lda $10c2,x
                    adc $ff
                    sta $10c2,x
                    lda $18fa,y
                    sec
                    sbc $10bf,x
                    lda $195a,y
                    sbc $10c2,x
                    bcc L16da
L1709               rts
                    
S170a               lda $10d7,x
                    bne L174d
                    sta $10ce,x
                    inc $10d7,x
                    lda $1b88,y
                    sta $fe
                    lda $108c,x
                    clc
                    adc $1b87,y
                    tay
                    sta $ff
                    lda $18fa,y
                    sec
                    ldy $108c,x
                    sbc $18fa,y
                    sta $10d1,x
                    ldy $ff
                    lda $195a,y
                    ldy $108c,x
                    sbc $195a,y
                    sta $10d4,x
                    ldy $fe
                    beq L174c
L1743               lsr $10d4,x
                    ror $10d1,x
                    dey
                    bne L1743
L174c               rts
                    
L174d               lda $107a,x
                    cmp $1b84,y
                    bcc L176c
                    cmp $1b8a,y
                    bcs L176c
                    lda $10d1,x
                    clc
                    adc $1b89,y
                    sta $10d1,x
                    lda $10d4,x
                    adc #$00
                    sta $10d4,x
L176c               sty $1068
                    jsr S163e
                    ldy $1068
                    lda $1b85,y
                    sta $fe
                    lda $1b86,y
                    sta $ff
L177f               ldy $10ce,x
                    lda ($fe),y
                    beq L17c8
                    tay
                    bpl L179a
                    cmp #$81
                    bne L17b2
                    inc $10ce,x
                    ldy $10ce,x
                    lda ($fe),y
                    sta $10ce,x
                    bpl L177f
L179a               lda $10bf,x
                    clc
                    adc $10d1,x
                    sta $10bf,x
                    lda $10c2,x
                    adc $10d4,x
                    sta $10c2,x
                    dey
                    bne L179a
                    beq L17c8
L17b2               lda $10bf,x
                    sec
                    sbc $10d1,x
                    sta $10bf,x
                    lda $10c2,x
                    sbc $10d4,x
                    sta $10c2,x
                    iny
                    bne L17b2
L17c8               inc $10ce,x
                    rts
                    
S17cc               lda $10ee,x
                    bmi L17df
                    sta $10e6,x
                    sta $10ea,x
                    lda $1ba1,y
                    and #$04
                    sta $10e2,x
L17df               rts
                    
S17e0               lda $1ba4,y
                    beq L1858
                    sta $ff
                    lda $1ba3,y
                    sta $fe
                    sty $1068
                    ldy $10e6,x
                    lda $10ea,x
                    bne L1811
                    lda ($fe),y
                    bpl L1846
                    cmp #$fe
                    bcc L1809
                    beq L1855
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
                    bpl L1846
L1809               and #$7f
                    sta $10ea,x
                    jsr S184f
L1811               dec $10ea,x
                    bne L1819
                    inc $10e6,x
L1819               lda $10e2,x
                    bmi L1896
                    bne L1833
                    lda ($fe),y
                    clc
                    adc $10da,x
                    sta $10da,x
                    ldy $1068
                    bcc L1875
                    inc $10de,x
                    bcs L1875
L1833               lda $10da,x
                    sec
                    sbc ($fe),y
                    sta $10da,x
                    ldy $1068
                    bcs L18ad
                    dec $10de,x
                    bcc L18ad
L1846               sta $10de,x
                    iny
                    lda ($fe),y
                    sta $10da,x
S184f               iny
                    tya
                    sta $10e6,x
                    rts
                    
L1855               ldy $1068
L1858               lda $10e2,x
                    bmi L1896
                    bne L1897
                    lda $10da,x
                    clc
                    adc $1bab,y
                    sta $10da,x
                    lda $10de,x
                    adc $1bac,y
                    sta $10de,x
                    lda $10da,x
L1875               sec
                    sbc $1ba7,y
                    lda $10de,x
                    sbc $1ba8,y
                    bmi L1896
                    lda $1ba2,y
                    lsr a
                    bcs L18d7
                    lsr a
                    bcc L18cf
                    lda $1ba5,y
                    sta $10da,x
                    lda $1ba6,y
                    sta $10de,x
L1896               rts
                    
L1897               lda $10da,x
                    sec
                    sbc $1ba9,y
                    sta $10da,x
                    lda $10de,x
                    sbc $1baa,y
                    sta $10de,x
                    lda $10da,x
L18ad               sec
                    sbc $1ba5,y
                    lda $10de,x
                    sbc $1ba6,y
                    bpl L1896
                    lda $1ba1,y
                    lsr a
                    bcs L18d7
                    lsr a
                    bcc L18d3
                    lda $1ba7,y
                    sta $10da,x
                    lda $1ba8,y
                    sta $10de,x
                    rts
                    
L18cf               lda #$01
                    bne L18d9
L18d3               lda #$00
                    beq L18d9
L18d7               lda #$ff
L18d9               sta $10e2,x
                    rts
                    
  .binary "Battlebars_Data.bin" 

check:
  sei
  lda poll
  and #$08
  beq cont
  jmp clear
cont:
  jsr PlaySid
  cli
  rti
clear:
  ldx #$18
  lda #$00
cloop:
  sta d400_sVoc1FreqLo,x
  dex
  beq end
  jmp cloop
end:
  jmp ($fffc)

