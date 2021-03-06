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
  jsr putbut
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
InitSid
                    jmp L1040               
    
PlaySid             jmp L10c1

	.binary "Arctic_ASCII.bin"
                    
L1040               asl a
                    asl a
                    asl a
                    tay
                    ldx #$00
L1046               lda $17cb,y
                    sta $172e,x
                    sta $1734,x
                    lda $17cc,y
                    sta $1731,x
                    sta $1737,x
                    iny
                    iny
                    inx
                    cpx #$03
                    bne L1046
                    lda $17cb,y
                    sta $1747
                    lda $1020
                    beq L1095
                    ldx #$02
L106c               lda $17cc,y
                    sta $100b
                    and $173a,x
                    sta $1006,x
                    dex
                    bpl L106c
                    bit $100b
                    bpl L1095
                    ldx #$00
L1082               lda $17cd,y
                    sta $1734,x
                    lda $17ce,y
                    sta $1737,x
                    iny
                    iny
                    inx
                    cpx #$03
                    bne L1082
L1095               ldy #$00
                    tya
L1098               sta d400_sVoc1FreqLo,y
                    iny
                    cpy #$17
                    bne L1098
                    tay
L10a1               sta $1014,y
                    iny
                    cpy #$0c
                    bne L10a1
                    ldy #$14
L10ab               sta $1748,y
                    dey
                    bpl L10ab
                    lda #$01
                    sta $1794
                    lda #$03
                    sta $1746
                    lda #$0f
                    sta $1009
                    rts
                    
L10c1               lda $fb
                    pha
                    lda $fc
                    pha
                    dec $1746
                    bpl L10e9
                    lda $1747
                    sta $1746
                    cmp #$02
                    bcs L10e9
                    ldy $1794
                    lda $17e7,y
                    sta $1746
                    dec $1794
                    bpl L10e9
                    lda #$01
                    sta $1794
L10e9               ldx #$02
L10eb               lda $1006,x
                    bne L10f3
                    jmp L1660
                    
L10f3               lda $1746
                    beq L1104
                    cmp #$02
                    bne L1109
                    lda $175a,x
                    beq L110f
                    jmp L1409
                    
L1104               dec $175a,x
                    bmi L110c
L1109               jmp L1409
                    
L110c               jmp L12ef
                    
L110f               lda $172e,x
                    sta $fb
                    lda $1731,x
                    sta $fc
                    ldy #$00
                    tya
                    sta $1748,x
                    lda ($fb),y
                    bpl L1132
                    asl a
                    sta $17ad,x
                    inc $172e,x
                    bne L112f
                    inc $1731,x
L112f               iny
                    lda ($fb),y
L1132               tay
                    lda $18df,y
                    sta $fb
                    lda $191f,y
                    sta $fc
L113d               ldy $1751,x
                    lda ($fb),y
                    bpl L1147
                    jmp L1211
                    
L1147               beq L1172
                    cmp #$7e
                    beq L1167
                    sta $17b3,x
                    lda $1760,x
                    bne L115a
                    lda #$00
                    sta $17b6,x
L115a               lda $1763,x
                    bne L116a
                    lda #$00
                    sta $17b9,x
                    jmp L116a
                    
L1167               inc $1748,x
L116a               lda #$ff
                    sta $17bc,x
                    jmp L118f
                    
L1172               inc $1748,x
                    lda $101a,x
                    cmp #$fe
                    beq L118f
                    lda #$fe
                    sta $17bc,x
                    ldy $101d,x
                    lda $1812,y
                    cmp $1811,y
                    beq L118f
                    sta $1795,x
L118f               inc $1751,x
                    ldy $1751,x
                    lda ($fb),y
                    cmp #$7f
                    bne L11da
                    lda #$00
                    sta $1751,x
                    tay
                    lda $172e,x
                    clc
                    adc #$01
                    sta $172e,x
                    sta $fb
                    lda $1731,x
                    adc #$00
                    sta $1731,x
                    sta $fc
                    lda ($fb),y
                    cmp #$ff
                    bne L11c8
                    lda $1734,x
                    sta $172e,x
                    lda $1737,x
                    sta $1731,x
L11c8               cmp #$fe
                    bne L11da
                    lda #$00
                    sta $1006,x
                    ldy $1740,x
                    sta d404_sVoc1Control,y
                    jmp L1660
                    
L11da               lda $1748,x
                    bne L1201
                    lda #$fe
                    sta $101a,x
                    lda $1754,x
                    beq L1201
                    ldy $1740,x
                    lda $1858
                    sta d405_sVoc1AttDec,y
                    sta $17bf,x
                    lda $1859
                    sta d406_sVoc1SusRel,y
                    sta $17c2,x
                    jmp L1616
                    
L1201               lda $17ca
                    beq L120e
                    lda #$01
                    sta $1766,x
                    jmp L14a0
                    
L120e               jmp L1409
                    
L1211               pha
                    and #$e0
                    cmp #$80
                    bne L122b
                    pla
                    pha
                    and #$10
                    sta $1748,x
                    pla
                    and #$0f
                    sta $1757,x
                    inc $1751,x
                    jmp L113d
                    
L122b               cmp #$a0
                    bne L1243
                    pla
                    asl a
                    asl a
                    asl a
                    sta $17b0,x
                    tay
                    lda $180c,y
                    sta $17c5,x
L123d               inc $1751,x
                    jmp L113d
                    
L1243               pla
                    and #$3f
                    asl a
                    tay
                    lda $1858,y
                    pha
                    and #$0f
                    sta $100b
                    pla
                    and #$f0
                    cmp #$30
                    bcs L1273
                    and #$20
                    sta $17a4,x
                    lda $100b
                    sta $17a1,x
                    lda $1859,y
                    sta $179e,x
                    lda #$01
                    sta $17b6,x
                    sta $1760,x
                    bne L123d
L1273               cmp #$60
                    bne L12ad
                    lda #$01
                    sta $17b9,x
                    sta $1763,x
                    lda $100b
                    sta $176f,x
                    lda $1859,y
                    pha
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $176c,x
                    sec
                    sbc #$01
                    sta $1769,x
                    lda #$00
                    sta $1775,x
                    sta $1772,x
                    sta $1778,x
                    sta $177b,x
                    pla
                    and #$0f
                    sta $177e,x
                    jmp L123d
                    
L12ad               cmp #$e0
                    bne L12ba
                    lda $1859,y
                    sta $1747
                    jmp L123d
                    
L12ba               cmp #$f0
                    bne L12c7
                    lda $1859,y
                    sta $1009
                    jmp L123d
                    
L12c7               cmp #$90
                    bne L12d4
                    lda $1859,y
                    sta $17c5,x
                    jmp L123d
                    
L12d4               lda $1859,y
                    sta $100b
                    lda $1858,y
                    and #$1f
                    asl a
                    asl a
                    asl a
                    tay
                    lda $100b
                    sta $1811,y
                    sta $1812,y
                    jmp L123d
                    
L12ef               lda $17bc,x
                    sta $101a,x
                    lda $17b3,x
                    sta $1014,x
                    lda $17ad,x
                    sta $1017,x
                    lda $17b9,x
                    sta $174b,x
                    lda $17b0,x
                    sta $101d,x
                    lda $17b6,x
                    sta $174e,x
                    bne L131b
                    sta $17a7,x
                    sta $17aa,x
L131b               lda $1757,x
                    sta $175a,x
                    lda $1748,x
                    beq L133a
                    jmp L1409
                    
L1329               lda #$00
                    sta $174b,x
                    sta $174e,x
                    ldy $101d,x
                    lda $180c,y
                    sta $17c5,x
L133a               ldy $101d,x
                    lda $1811,y
                    sta $1795,x
                    lda $180d,y
                    pha
                    and #$80
                    sta $1754,x
                    pla
                    and #$0f
                    sta $1798,x
                    sta $179b,x
                    lda $1810,y
                    sta $1781,x
                    tay
                    lda $17fb,y
                    cmp #$ff
                    beq L136f
                    pha
                    and #$f0
                    sta $1787,x
                    pla
                    and #$0f
                    sta $178a,x
L136f               lda $17fd,y
                    pha
                    and #$80
                    sta $178d,x
                    pla
                    and #$7f
                    sta $1784,x
                    ldy $101d,x
                    lda $180e,y
                    pha
                    and #$f0
                    sta $100b
                    pla
                    ldy #$00
                    and #$0f
                    beq L13b1
                    cmp #$08
                    beq L13b0
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $1793
                    ora $1009
                    sta d418_sFiltMode
                    iny
                    lda $100a
                    and #$0f
                    ora $173a,x
                    ora $100b
                    bne L13b7
L13b0               iny
L13b1               lda $100a
                    and $173d,x
L13b7               sta d417_sFiltControl
                    sta $100a
                    cpy #$01
                    bne L13db
                    ldy $101d,x
                    lda $180f,y
                    sta $1790
                    tay
                    lda $17e7,y
                    cmp #$ff
                    beq L13d5
                    sta $1792
L13d5               lda $17e9,y
                    sta $1791
L13db               ldy $101d,x
                    lda $180b,y
                    ldy $1740,x
                    sta d405_sVoc1AttDec,y
                    sta $17bf,x
                    ldy $101d,x
                    lda $180c,y
                    cmp $17c5,x
                    beq L13f8
                    lda $17c5,x
L13f8               ldy $1740,x
                    sta d406_sVoc1SusRel,y
                    sta $17c2,x
                    lda #$09
                    sta d404_sVoc1Control,y
                    jmp L1660
                    
L1409               dec $1784,x
                    bpl L143a
                    ldy $1781,x
                    lda $17fe,y
                    sta $1781,x
                    tay
                    lda $17fd,y
                    pha
                    and #$80
                    sta $178d,x
                    pla
                    and #$7f
                    sta $1784,x
                    lda $17fb,y
                    cmp #$ff
                    beq L143a
                    pha
                    and #$f0
                    sta $1787,x
                    pla
                    and #$0f
                    sta $178a,x
L143a               ldy $1781,x
                    lda $178d,x
                    bne L1457
                    lda $1787,x
                    clc
                    adc $17fc,y
                    sta $1787,x
                    lda $178a,x
                    adc #$00
                    sta $178a,x
                    jmp L1469
                    
L1457               lda $1787,x
                    sec
                    sbc $17fc,y
                    sta $1787,x
                    lda $178a,x
                    sbc #$00
                    sta $178a,x
L1469               ldy #$00
                    txa
                    cmp $17ea,y
                    beq L1474
                    jmp L14a0
                    
L1474               dec $1791
                    bpl L1493
                    ldy $1790
                    lda $17ea,y
                    sta $1790
                    tay
                    lda $17e9,y
                    sta $1791
                    lda $17e7,y
                    cmp #$ff
                    beq L1493
                    sta $1792
L1493               ldy $1790
                    lda $1792
                    clc
                    adc $17e8,y
                    sta $1792
L14a0               ldy $101d,x
                    lda $180d,y
                    and #$40
                    beq L14d4
                    ldy $1795,x
                    lda $17db,y
                    cmp #$7e
                    bne L14bb
                    dec $1795,x
                    dey
                    jmp L14c6
                    
L14bb               cmp #$7f
                    bne L14c9
                    lda $17e1,y
                    sta $1795,x
                    tay
L14c6               lda $17db,y
L14c9               sta $100f,x
                    lda #$00
                    sta $100c,x
                    jmp L151e
                    
L14d4               ldy $1795,x
                    lda $17db,y
                    bmi L14f7
                    cmp #$7e
                    bne L14e7
                    dec $1795,x
                    dey
                    jmp L14f2
                    
L14e7               cmp #$7f
                    bne L14fd
                    lda $17e1,y
                    sta $1795,x
                    tay
L14f2               lda $17db,y
                    bpl L14fd
L14f7               asl a
                    ldy #$01
                    jmp L1508
                    
L14fd               clc
                    adc $1014,x
                    asl a
                    clc
                    adc $1017,x
                    ldy #$00
L1508               sty $100b
                    tay
                    lda $166d,y
                    clc
                    adc $1743,x
                    sta $100c,x
                    lda $166e,y
                    adc #$00
                    sta $100f,x
L151e               ldy $1795,x
                    lda $17e1,y
                    sta $175d,x
                    dec $1798,x
                    bpl L1535
                    lda $179b,x
                    sta $1798,x
                    inc $1795,x
L1535               lda $174e,x
                    beq L1583
                    lda $17a4,x
                    bne L1555
                    lda $17a7,x
                    clc
                    adc $179e,x
                    sta $17a7,x
                    lda $17aa,x
                    adc $17a1,x
                    sta $17aa,x
                    jmp L1568
                    
L1555               lda $17a7,x
                    sec
                    sbc $179e,x
                    sta $17a7,x
                    lda $17aa,x
                    sbc $17a1,x
                    sta $17aa,x
L1568               lda $100b
                    bne L1580
                    lda $100c,x
                    clc
                    adc $17a7,x
                    sta $100c,x
                    lda $100f,x
                    adc $17aa,x
                    sta $100f,x
L1580               jmp L1616
                    
L1583               lda $1766,x
                    bne L1580
                    lda $174b,x
                    beq L1580
                    lda $1014,x
                    asl a
                    tay
                    lda $166f,y
                    sec
                    sbc $166d,y
                    sta $172d
                    lda $1670,y
                    sbc $166e,y
                    clc
                    adc $1772,x
                    sta $100b
                    ldy $177e,x
L15ac               dey
                    bmi L15b8
                    lsr $100b
                    ror $172d
                    jmp L15ac
                    
L15b8               dec $1769,x
                    bpl L15cb
                    lda $1775,x
                    eor #$01
                    sta $1775,x
                    lda $176c,x
                    sta $1769,x
L15cb               lda $1775,x
                    bne L15e6
                    lda $1778,x
                    clc
                    adc $172d
                    sta $1778,x
                    lda $177b,x
                    adc $100b
                    sta $177b,x
                    jmp L15f9
                    
L15e6               lda $1778,x
                    sec
                    sbc $172d
                    sta $1778,x
                    lda $177b,x
                    sbc $100b
                    sta $177b,x
L15f9               lda $100c,x
                    clc
                    adc $1778,x
                    sta $100c,x
                    lda $100f,x
                    adc $177b,x
                    sta $100f,x
                    lda $1772,x
                    clc
                    adc $176f,x
                    sta $1772,x
L1616               lda #$00
                    sta $1760,x
                    sta $1763,x
                    sta $1766,x
                    ldy $1740,x
                    lda $1787,x
                    sta d402_sVoc1PWidthLo,y
                    lda $178a,x
                    sta d403_sVoc1PWidthHi,y
                    lda $1792
                    sta d416_sFiltFreqHi
                    lda $100c,x
                    sta d400_sVoc1FreqLo,y
                    lda $100f,x
                    sta d401_sVoc1FreqHi,y
                    lda $17bf,x
                    sta d405_sVoc1AttDec,y
                    lda $17c2,x
                    sta d406_sVoc1SusRel,y
                    lda $175d,x
                    and $101a,x
                    sta d404_sVoc1Control,y
                    lda $1793
                    ora $1009
                    sta d418_sFiltMode
L1660               dex
                    bmi L1666
                    jmp L10eb
                    
L1666               pla
                    sta $fc
                    pla
                    sta $fb
                    rts

	.binary "Arctic.bin"
