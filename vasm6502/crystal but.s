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
  lda #0 ; Song Number
  jsr InitSid
  lda #$40
  sta $b00d
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  phy
  phx
  pha
  jsr putbut
check:
  sei
  lda $8001
  and #$08
  beq cont
  jmp clear
cont:
  jsr PlaySid
  cli
  pla
  plx
  ply
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

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

InitSid             jsr putbut
                    jmp InitSid2

	.org $1000

InitSid2            jmp L1007
                    
PlaySid             jmp L1094
                    
                    .byte $00 
L1007               asl a
                    asl a
                    asl a
                    tay
                    ldx #$84
                    lda #$00
L100f               dex
                    sta $1696,x
                    bne L100f
                    lda #$00
                    sta $1718
                    sta $1715
                    sta $1092
                    sta $1006
                    lda #$01
                    sta $1693
                    sta $1719
                    lda #$0f
                    sta $1093
                    sta $1714
                    lda $17f2,y
                    sta $1694
                    sta $1695
                    cmp #$02
                    bpl L1047
                    tay
                    lda $132e,y
                    sta $0e95
L1047               ldx #$00
                    jsr S1053
                    ldx #$07
                    jsr S1053
                    ldx #$0e
S1053               lda $17ec,y
                    sta $171a,x
                    sta $171c,x
                    lda $17ed,y
                    sta $171b,x
                    sta $171d,x
                    iny
                    iny
                    lda #$01
                    sta $169a,x
                    sta $16ea,x
                    sta $16ec,x
                    sta $16c6,x
                    lda #$00
                    sta $16d8,x
                    rts
                    
                    .byte $00, $00, $00, $00, $00 
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                    .byte $00, $00, $00, $00 
L1094               jsr S10e6
                    lda $1090
                    sta d415_sFiltFreqLo
                    lda $1091
                    sta d416_sFiltFreqHi
                    lda $1092
                    sta d417_sFiltControl
                    lda $1093
                    sta d418_sFiltMode
                    ldx #$00
                    jsr S10bb
                    ldx #$07
                    jsr S10bb
                    ldx #$0e
S10bb               lda $107b,x
                    sta d400_sVoc1FreqLo,x
                    lda $107c,x
                    sta d401_sVoc1FreqHi,x
                    lda $1081,x
                    sta d406_sVoc1SusRel,x
                    lda $1080,x
                    sta d405_sVoc1AttDec,x
                    lda $107d,x
                    sta d402_sVoc1PWidthLo,x
                    lda $107e,x
                    sta d403_sVoc1PWidthHi,x
                    lda $107f,x
                    sta d404_sVoc1Control,x
                    rts
                    
S10e6               dec $1693
                    bpl L111d
                    lda $1719
                    beq L10fb
                    dec $1719
                    lda #$01
                    sta $1693
                    jmp L111d
                    
L10fb               lda $1694
                    cmp #$02
                    bpl L111a
                    ldy $0f18
                    lda $132e,y
                    sta $0e95
                    iny
                    lda $132e,y
                    bpl L1114
                    and #$7f
                    tay
L1114               sty $0f18
                    lda $0e95
L111a               sta $1693
L111d               ldy #$00
                    bne L1124
                    jmp L118f
                    
L1124               dec $1716
                    bpl L117b
                    ldy $1717
                    sty L111d + 1
                    beq L118f
                    lda $1a34,y
                    bpl L1159
                    and #$70
                    sta $1715
                    ora $1714
                    sta $1093
                    lda $1a35,y
                    sta $1092
                    lda $1a36,y
                    cmp #$ff
                    beq L1154
                    sta $1185
                    sta $1091
L1154               lda #$00
                    sta L117b + 1
L1159               sta $1716
                    lda $1a37,y
                    bne L116a
                    lda $1717
                    clc
                    adc #$04
                    jmp L1175
                    
L116a               cmp #$7f
                    bne L1173
                    lda #$00
                    jmp L1175
                    
L1173               asl a
                    asl a
L1175               sta $1717
                    jmp L118f
                    
L117b               lda #$00
                    clc
                    adc $1a35,y
                    sta L117b + 1
                    lda #$00
                    adc $1a36,y
                    sta $1185
                    sta $1091
L118f               lda $1693
                    bne L1197
                    jmp L126b
                    
L1197               cmp $1695
                    bne L119f
                    jmp L12d9
                    
L119f               ldx #$00
                    jsr S11ab
                    ldx #$07
                    jsr S11ab
                    ldx #$0e
S11ab               lda $1693
                    cmp $1696,x
                    bne L11b8
                    dec $1698,x
                    bmi L11bb
L11b8               jmp L13d3
                    
L11bb               lda #$00
                    sta $169a,x
                    sta $122c
                    ldy $16c0,x
                    lda $1888,y
                    sta $80
                    lda $18b8,y
                    sta $81
                    ldy $16c1,x
L11d3               lda ($80),y
                    cmp #$c0
                    bcs L120a
                    cmp #$5f
                    bcc L11f2
                    sbc #$60
                    bpl L11ea
                    lda #$80
                    sta $169a,x
                    iny
                    jmp L11d3
                    
L11ea               pha
                    iny
                    lda ($80),y
                    sta $122c
                    pla
L11f2               cmp #$03
                    bcs L1223
                    inc $169a,x
                    sbc #$00
                    bmi L1202
                    eor #$fe
                    sta $16c2,x
L1202               lda $122c
                    beq L123f
                    jmp L122d
                    
L120a               cmp #$f0
                    bmi L1217
                    and #$0f
                    sta $16b1,x
                    iny
                    jmp L11d3
                    
L1217               sbc #$bf
                    sta $16ad,x
                    inc $16ec,x
                    iny
                    jmp L11d3
                    
L1223               sta $16ae,x
                    lda #$00
                    sta $169c,x
                    lda #$00
L122d               cmp #$40
                    bcc L1237
                    sta $169b,x
                    jmp L123f
                    
L1237               sta $169c,x
                    lda #$00
                    sta $16ac,x
L123f               iny
                    beq L124c
                    tya
                    sta $16c1,x
                    lda ($80),y
                    cmp #$bf
                    bne L124f
L124c               inc $16ea,x
L124f               lda $16b1,x
                    sta $1698,x
                    lda $16eb,x
                    sta $1699,x
                    lda $169a,x
                    bpl L1263
                    jmp L13b5
                    
L1263               bne L1268
                    jmp L131e
                    
L1268               jmp L13db
                    
L126b               ldx #$00
                    jsr S1277
                    ldx #$07
                    jsr S1277
                    ldx #$0e
S1277               lda $16ea,x
                    beq L12ce
                    sec
                    sbc #$01
                    sta $16c1,x
                    lda $171c,x
                    sta $80
                    lda $171d,x
                    sta $81
                    ldy #$00
                    lda ($80),y
                    bpl L129b
                    sec
                    sbc #$a0
                    sta $16eb,x
                    iny
                    lda ($80),y
L129b               sta $16c0,x
                    iny
                    lda ($80),y
                    cmp #$f0
                    bcc L12bc
                    and #$03
                    pha
                    iny
                    lda ($80),y
                    clc
                    adc $171a,x
                    sta $171c,x
                    pla
                    adc $171b,x
                    sta $171d,x
                    jmp L12c9
                    
L12bc               tya
                    clc
                    adc $171c,x
                    sta $171c,x
                    bcc L12c9
                    inc $171d,x
L12c9               lda #$00
                    sta $16ea,x
L12ce               lda $16c6,x
                    beq L12d6
                    jmp L1347
                    
L12d6               jmp L13db
                    
L12d9               ldx #$00
                    jsr S12e5
                    ldx #$07
                    jsr S12e5
                    ldx #$0e
S12e5               lda $16ae,x
                    clc
                    adc $1699,x
                    sta $16af,x
                    lda $16c2,x
                    beq L12f7
                    sta $16b0,x
L12f7               ldy $169a,x
                    beq L1308
                    lda $16b0,x
                    and $16c5,x
                    sta $107f,x
                    jmp L1313
                    
L1308               lda #$ff
                    sta $16b0,x
                    and $16c5,x
                    sta $107f,x
L1313               lda #$00
                    sta $16c6,x
                    sta $16c2,x
                    jmp L1465
                    
L131e               ldy $16ad,x
                    lda $1939,y
                    sta $1081,x
                    lda #$0f
                    sta $1080,x
                    lda $191e,y
                    sta $16c6,x
                    bmi L133b
                    and #$10
                    lsr a
                    sta $107f,x
                    rts
                    
L133b               lda #$fe
                    sta $16b0,x
                    and $16c5,x
                    sta $107f,x
                    rts
                    
L1347               ldy $16ad,x
                    lda $16ec,x
                    beq L1362
                    lda #$00
                    sta $16ec,x
                    lda $1954,y
                    sta $16ee,x
                    lda $191e,y
                    and #$0f
                    sta $1696,x
L1362               lda $1903,y
                    sta $1081,x
                    lda $18e8,y
                    sta $1080,x
                    lda #$01
                    sta $107f,x
                    lda $19a5,y
                    sta $16ef,x
                    lda $198a,y
                    beq L139e
                    bpl L138e
                    sta $107e,x
                    lda #$00
                    sta $107d,x
                    sta $16d7,x
                    jmp L139e
                    
L138e               asl a
                    asl a
                    sta $16d7,x
                    sta $16d9,x
                    lda #$00
                    sta $16d8,x
                    ldy $16ad,x
L139e               lda $196f,y
                    beq L13b5
                    bpl L13a8
                    jmp $0bb5
                    
L13a8               asl a
                    asl a
                    sta L111d + 1
                    sta $1717
                    lda #$00
                    sta $1716
L13b5               lda #$80
                    sta $16ff,x
                    lda #$00
                    sta $1700,x
                    sta $16ed,x
                    sta $16ac,x
                    lda $16ae,x
                    clc
                    adc $1699,x
                    cmp $16af,x
                    ror $1703,x
                    rts
                    
L13d3               lda $16c6,x
                    beq L13db
                    bmi L13db
                    rts
                    
L13db               ldy $16d7,x
                    beq L1427
                    dec $16d8,x
                    bpl L142a
                    lda $16d9,x
                    sta $16d7,x
                    beq L1427
                    tay
                    lda $1ab9,y
                    cmp #$ff
                    beq L1403
                    sta $16d6,x
                    sta $107e,x
                    and #$f0
                    sta $16d5,x
                    sta $107d,x
L1403               lda $1ab7,y
                    and #$7f
                    sta $16d8,x
                    lda $1aba,y
                    bne L1419
                    lda $16d9,x
                    clc
                    adc #$04
                    jmp L1424
                    
L1419               cmp #$7f
                    bne L1422
                    lda #$00
                    jmp $0c24
                    
L1422               asl a
                    asl a
L1424               sta $16d9,x
L1427               jmp L14e0
                    
L142a               lda $1ab7,y
                    bmi L144a
                    lda $16d5,x
                    clc
                    adc $1ab8,y
                    sta $16d5,x
                    sta $107d,x
                    lda $16d6,x
                    adc #$00
                    sta $16d6,x
                    sta $107e,x
                    jmp L14e0
                    
L144a               lda $16d5,x
                    sec
                    sbc $1ab8,y
                    sta $16d5,x
                    sta $107d,x
                    lda $16d6,x
                    sbc #$00
                    sta $16d6,x
                    sta $107e,x
                    jmp L14e0
                    
L1465               lda $169b,x
                    bne L146d
                    jmp L14e0
                    
L146d               cmp #$a0
                    bcs L147d
                    and #$1f
                    tay
                    lda $1b3b,y
                    sta $16ff,x
                    jmp L14db
                    
L147d               cmp #$b0
                    bcs L1497
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $80
                    ldy $16ad,x
                    lda $18e8,y
                    and #$0f
                    ora $80
                    sta $1080,x
                    jmp L14db
                    
L1497               cmp #$d0
                    bcs L14b1
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $80
                    ldy $16ad,x
                    lda $1903,y
                    and #$0f
                    ora $80
                    sta $1081,x
                    jmp L14db
                    
L14b1               cmp #$e0
                    bcs L14c9
                    and #$0f
                    sta $80
                    ldy $16ad,x
                    lda $1903,y
                    and #$f0
                    ora $80
                    sta $1081,x
                    jmp L14db
                    
L14c9               cmp #$f0
                    bcs L14db
                    and #$0f
                    sta $1714
                    ora $1715
                    sta $1093
                    jmp L14db
                    
L14db               lda #$00
                    sta $169b,x
L14e0               ldy $16ef,x
                    beq L14e8
                    jmp L1609
                    
L14e8               lda $169c,x
                    bne L14f9
                    ldy $16af,x
                    lda $169a,x
                    bmi L14f6
                    rts
                    
L14f6               jmp L1680
                    
L14f9               cmp #$20
                    bcs L154f
                    ldy $16ac,x
                    bne L1517
                    and #$0f
                    tay
                    inc $16ac,x
                    lda $1b0e,y
                    sta $1701,x
                    lda $1b1e,y
                    sta $1702,x
                    lda $169c,x
L1517               cmp #$10
                    bcs L1535
L151b               lda $16c3,x
                    clc
                    adc $1701,x
                    sta $16c3,x
                    sta $107b,x
                    lda $16c4,x
                    adc $1702,x
                    sta $16c4,x
                    sta $107c,x
                    rts
                    
L1535               lda $16c3,x
                    sec
                    sbc $1701,x
                    sta $16c3,x
                    sta $107b,x
                    lda $16c4,x
                    sbc $1702,x
                    sta $16c4,x
                    sta $107c,x
                    rts
                    
L154f               cmp #$30
                    bcs L1596
                    ldy $16ac,x
                    bne L157b
                    inc $16ac,x
                    and #$0f
                    asl a
                    tay
                    lda #$00
                    sta $1703,x
                    sta $1702,x
                    lda $1aee,y
                    sta $16da,x
                    lsr a
                    sta $16db,x
                    lda $1aef,y
                    asl a
                    rol $1702,x
                    sta $1701,x
L157b               dec $16db,x
                    bpl L158e
                    lda $16da,x
                    sta $16db,x
                    lda $1703,x
                    eor #$80
                    sta $1703,x
L158e               lda $1703,x
                    bmi L1535
                    jmp L151b
                    
L1596               and #$0f
                    tay
                    lda $1703,x
                    bpl L15c5
                    lda $16c3,x
                    clc
                    adc $1b0e,y
                    sta $16c3,x
                    lda $16c4,x
                    adc $1b1e,y
                    sta $16c4,x
                    ldy $16af,x
                    lda $16c3,x
                    cmp $172c,y
                    lda $16c4,x
                    sbc $178c,y
                    bcc L15fc
                    jmp L15e9
                    
L15c5               lda $16c3,x
                    sec
                    sbc $1b0e,y
                    sta $16c3,x
                    lda $16c4,x
                    sbc $1b1e,y
                    sta $16c4,x
                    ldy $16af,x
                    lda $16c3,x
                    cmp $172c,y
                    lda $16c4,x
                    sbc $178c,y
                    bcs L15fc
L15e9               lda $172c,y
                    sta $16c3,x
                    sta $107b,x
                    lda $178c,y
                    sta $16c4,x
                    sta $107c,x
                    rts
                    
L15fc               lda $16c3,x
                    sta $107b,x
                    lda $16c4,x
                    sta $107c,x
                    rts
                    
L1609               dec $16ed,x
                    bpl L166e
                    lda $16ee,x
                    sta $16ed,x
                    lda $19bf,y
                    sta $16f0,x
                    lda $19fb,y
                    cmp #$10
                    bcc L1630
                    cmp #$e0
                    bcc L1627
                    and #$0f
L1627               sta $16c5,x
                    and $16b0,x
                    sta $107f,x
L1630               lda $19c0,y
                    cmp #$7e
                    beq L164c
                    iny
                    cmp #$7f
                    bne L1640
                    lda $19fb,y
                    tay
L1640               lda $19fb,y
                    beq L164c
                    cmp #$10
                    bcs L164c
                    sta $16ed,x
L164c               tya
                    sta $16ef,x
                    ldy $16ff,x
                    bmi L166e
                    lda $1b2e,y
                    cmp #$40
                    bcc L165e
                    ora #$80
L165e               sta $1700,x
                    inc $16ff,x
                    lda $1b2f,y
                    bpl L166e
                    and #$7f
                    sta $16ff,x
L166e               lda $16f0,x
                    bpl L1678
                    and #$7f
                    jmp L167f
                    
L1678               clc
                    adc $16af,x
                    adc $1700,x
L167f               tay
L1680               lda $172c,y
                    sta $16c3,x
                    sta $107b,x
                    lda $178c,y
                    sta $16c4,x
                    sta $107c,x
                    rts

	.binary "crobut82.bin"
