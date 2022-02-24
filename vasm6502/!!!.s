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
  lda #$90
  sta $b00e
  stz $b00c
  lda #0 ; Song Number
  jsr InitSid
  cli
  nop

; You can put code you want to run in the backround here.

loop:
  jmp loop

irq:
  lda #$10
  sta $b00d
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

  .org $1000

InitSid             jmp L1040
                    
PlaySid             jmp L10da

  .binary "!!!_ASCII.bin"
                    
L1040               asl a
                    asl a
                    asl a
                    tay
                    ldx #$00
L1046               lda $17ef,y
                    sta $174e,x
                    sta $1754,x
                    lda $17f0,y
                    sta $1751,x
                    sta $1757,x
                    iny
                    iny
                    inx
                    cpx #$03
                    bne L1046
                    ldx #$00
                    stx $174d
                    lda $17ef,y
                    sta $100b
                    sta $177b
                    sta $177c
                    sta $177d
L1073               sta $17d9,x
                    inc $174d
                    lda $100b
                    clc
                    adc $17ef,y
                    sta $100b
                    clc
                    adc $174d
                    inx
                    cpx #$10
                    bne L1073
                    lda $1020
                    beq L10bc
                    ldx #$02
L1093               lda $17f0,y
                    sta $174d
                    and $175a,x
                    sta $1006,x
                    dex
                    bpl L1093
                    bit $174d
                    bpl L10bc
                    ldx #$00
L10a9               lda $17f1,y
                    sta $1754,x
                    lda $17f2,y
                    sta $1757,x
                    iny
                    iny
                    inx
                    cpx #$03
                    bne L10a9
L10bc               ldy #$00
                    tya
L10bf               sta d400_sVoc1FreqLo,y
                    iny
                    cpy #$1b
                    bne L10bf
                    tay
L10c8               sta $177e,y
                    sta $1766,y
                    iny
                    cpy #$0c
                    bne L10c8
                    lda $1009
                    sta d418_sFiltMode
                    rts
                    
L10da               ldx #$02
L10dc               lda $1769,x
                    cmp #$02
                    bne L110f
                    ldy $1772,x
                    lda $18c2,y
                    ldy $1760,x
                    sta d405_sVoc1AttDec,y
                    ldy $1772,x
                    lda $18c3,y
                    ldy $1760,x
                    sta d406_sVoc1SusRel,y
                    lda $1892
                    beq L1109
                    lda $1891
                    sta d404_sVoc1Control,y
                    jmp L110f
                    
L1109               lda $1778,x
                    sta d404_sVoc1Control,y
L110f               dex
                    bpl L10dc
                    lda $fb
                    pha
                    lda $fc
                    pha
                    ldx #$02
L111a               lda $1006,x
                    bne L1122
                    jmp L1680
                    
L1122               lda $176f,x
                    beq L112f
                    dec $176f,x
                    bne L113f
                    jmp L12bd
                    
L112f               ldy $1772,x
                    lda $18c5,y
                    and #$0f
                    cmp $177b,x
                    beq L1142
                    dec $177b,x
L113f               jmp L139a
                    
L1142               sta $176f,x
                    lda $1775,x
                    sta $177b,x
                    lda $174e,x
                    sta $fb
                    lda $1751,x
                    sta $fc
                    ldy #$00
                    tya
                    sta $176c,x
                    lda ($fb),y
                    bpl L116e
                    asl a
                    sta $1781,x
                    inc $174e,x
                    bne L116b
                    inc $1751,x
L116b               iny
                    lda ($fb),y
L116e               tay
                    lda $1983,y
                    sta $fb
                    lda $199e,y
                    sta $fc
L1179               ldy $1766,x
                    lda ($fb),y
                    bmi L11a8
                    beq L119e
                    cmp #$7e
                    beq L1194
                    sta $177e,x
                    lda $17ca,x
                    beq L1197
                    dec $17ca,x
                    jmp L1197
                    
L1194               inc $176c,x
L1197               lda #$ff
                    sta $1763,x
                    bne L120a
L119e               lda #$fe
                    sta $1763,x
                    inc $176c,x
                    bne L120a
L11a8               pha
                    and #$e0
                    cmp #$80
                    bne L11c8
                    pla
                    pha
                    and #$10
                    sta $176c,x
                    pla
                    and #$0f
                    tay
                    lda $17d9,y
                    sta $177b,x
                    sta $1775,x
                    inc $1766,x
                    bne L1179
L11c8               cmp #$a0
                    bne L11d8
                    pla
                    asl a
                    asl a
                    asl a
                    sta $1772,x
L11d3               inc $1766,x
                    bne L1179
L11d8               pla
                    and #$3f
                    asl a
                    tay
                    lda $1943,y
                    sta $17c1,x
                    lda $1942,y
                    pha
                    and #$1f
                    sta $17c4,x
                    pla
                    pha
                    and #$80
                    sta $17c7,x
                    lda #$01
                    sta $17ca,x
                    lda #$00
                    sta $17d0,x
                    sta $17d3,x
                    pla
                    and #$20
                    bne L11d3
                    inc $17ca,x
                    bne L11d3
L120a               inc $1766,x
                    ldy $1766,x
                    lda ($fb),y
                    cmp #$7f
                    bne L1243
                    lda #$00
                    sta $1766,x
                    tay
                    lda $174e,x
                    clc
                    adc #$01
                    sta $174e,x
                    sta $fb
                    lda $1751,x
                    adc #$00
                    sta $1751,x
                    sta $fc
                    lda ($fb),y
                    cmp #$ff
                    bne L1243
                    lda $1754,x
                    sta $174e,x
                    lda $1757,x
                    sta $1751,x
L1243               cmp #$fe
                    bne L1255
                    lda #$00
                    sta $1006,x
                    ldy $1760,x
                    sta d404_sVoc1Control,y
                    jmp L1680
                    
L1255               lda $176c,x
                    beq L127d
                    lda $176f,x
                    bne L127a
                    lda $1763,x
                    sta $101a,x
                    lda $177e,x
                    sta $1014,x
                    lda $1781,x
                    sta $1017,x
                    lda $17ca,x
                    sta $17cd,x
                    sta $1769,x
L127a               jmp L139a
                    
L127d               ldy $1760,x
                    lda $1890
                    sta d405_sVoc1AttDec,y
                    sta d406_sVoc1SusRel,y
                    lda $176f,x
                    beq L12bd
                    jmp L1680
                    
L1291               ldy $1760,x
                    lda $1778,x
                    and #$fe
                    sta d404_sVoc1Control,y
                    ldy $1772,x
                    lda $18c2,y
                    ldy $1760,x
                    sta d405_sVoc1AttDec,y
                    ldy $1772,x
                    lda $18c3,y
                    ldy $1760,x
                    sta d406_sVoc1SusRel,y
                    lda $1778,x
                    sta d404_sVoc1Control,y
                    jmp L1304
                    
L12bd               lda $1763,x
                    sta $101a,x
                    lda $177e,x
                    sta $1014,x
                    lda $1781,x
                    sta $1017,x
                    lda $17ca,x
                    sta $17cd,x
                    sta $1769,x
                    lda $176c,x
                    beq L12e0
                    jmp L139a
                    
L12e0               ldy $1760,x
                    lda $188f
                    sta d405_sVoc1AttDec,y
                    sta d406_sVoc1SusRel,y
                    lda $1892
                    beq L12fc
                    lda $1891
                    and #$fe
                    sta d404_sVoc1Control,y
                    jmp L1304
                    
L12fc               lda $1778,x
                    and #$fe
                    sta d404_sVoc1Control,y
L1304               ldy $1772,x
                    tya
                    sta $101d,x
                    lda $18c9,y
                    sta $17be,x
                    lda $18c8,y
                    sta $17ab,x
                    tay
                    lda #$00
                    sta $17ae,x
                    lda $18ac,y
                    and #$80
                    cmp #$80
                    beq L1335
                    lda $18ad,y
                    pha
                    and #$f0
                    sta $17b1,x
                    pla
                    and #$0f
                    sta $17b4,x
L1335               ldy $1772,x
                    lda $18c6,y
                    ldy #$00
                    and #$0f
                    beq L1359
                    cmp #$08
                    beq L1358
                    asl a
                    asl a
                    asl a
                    asl a
                    ora $1009
                    sta d418_sFiltMode
                    iny
                    lda $100a
                    ora $175a,x
                    bne L135f
L1358               iny
L1359               lda $100a
                    and $175d,x
L135f               sta d417_sFiltControl
                    sta $100a
                    cpy #$01
                    bne L1387
                    ldy $1772,x
                    lda $18c7,y
                    sta $17bb
                    tay
                    lda $1891,y
                    and #$80
                    cmp #$80
                    bne L1382
                    lda $1892,y
                    sta $17bd
L1382               lda #$00
                    sta $17bc
L1387               lda #$03
                    sta $1769,x
                    lda $1892
                    bne L1394
                    jmp L14c7
                    
L1394               dec $1769,x
                    jmp L1680
                    
L139a               lda $17ae,x
                    beq L13a5
                    dec $17ae,x
                    jmp L13f0
                    
L13a5               ldy $17ab,x
                    lda $18aa,y
                    pha
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $179f,x
                    pla
                    and #$0f
                    sta $17a2,x
                    lda $18ab,y
                    sta $17a5,x
                    lda $18ac,y
                    sta $174d
                    and #$3f
                    asl a
                    sta $17ae,x
                    bit $174d
                    bpl L13e4
                    lda $18ad,y
                    pha
                    and #$f0
                    sta $17b1,x
                    pla
                    and #$0f
                    sta $17b4,x
                    lda #$00
                    sta $17a8,x
L13e4               bit $174d
                    bvs L13f0
                    tya
                    clc
                    adc #$04
                    sta $17ab,x
L13f0               lda $17a8,x
                    bne L140e
                    lda $17b1,x
                    clc
                    adc $17a5,x
                    sta $17b1,x
                    lda $17b4,x
                    adc #$00
                    sta $17b4,x
                    cmp $17a2,x
                    bne L142d
                    beq L1425
L140e               lda $17b1,x
                    sec
                    sbc $17a5,x
                    sta $17b1,x
                    lda $17b4,x
                    sbc #$00
                    sta $17b4,x
                    cmp $179f,x
                    bne L142d
L1425               lda $17a8,x
                    eor #$01
                    sta $17a8,x
L142d               cpx #$00
                    beq L1434
                    jmp L14c7
                    
L1434               lda $17bc
                    beq L143f
                    dec $17bc
                    jmp L149a
                    
L143f               ldy $17bb
                    lda $188f,y
                    pha
                    and #$f0
                    sta $17b7
                    pla
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $17b8
                    lda $1890,y
                    sta $17b9
                    lda $1891,y
                    sta $174d
                    and #$3f
                    asl a
                    sta $17bc
                    bit $174d
                    bpl L148e
                    lda $100a
                    and #$0f
                    sta $174d
                    lda $1892,y
                    pha
                    and #$f0
                    sta $17bd
                    pla
                    asl a
                    asl a
                    asl a
                    asl a
                    ora $174d
                    sta $100a
                    sta d417_sFiltControl
                    lda #$00
                    sta $17ba
L148e               bit $174d
                    bvs L149a
                    tya
                    clc
                    adc #$04
                    sta $17bb
L149a               lda $17ba
                    bne L14b0
                    lda $17bd
                    clc
                    adc $17b9
                    sta $17bd
                    cmp $17b8
                    bcc L14c7
                    bcs L14bf
L14b0               lda $17bd
                    sec
                    sbc $17b9
                    sta $17bd
                    cmp $17b7
                    bcs L14c7
L14bf               lda $17ba
                    eor #$01
                    sta $17ba
L14c7               ldy $1772,x
                    lda $18c6,y
                    and #$f0
                    cmp #$10
                    bne L14f2
                    ldy $17be,x
                    lda $17ff,y
                    cmp #$7f
                    bne L14e7
                    lda $1847,y
                    sta $17be,x
                    tay
                    lda $17ff,y
L14e7               sta $100f,x
                    lda #$00
                    sta $100c,x
                    jmp L1531
                    
L14f2               ldy $17be,x
                    lda $17ff,y
                    bmi L150a
                    cmp #$7f
                    bne L1510
                    lda $1847,y
                    sta $17be,x
                    tay
                    lda $17ff,y
                    bpl L1510
L150a               asl a
                    ldy #$01
                    jmp L151b
                    
L1510               clc
                    adc $1014,x
                    asl a
                    clc
                    adc $1017,x
                    ldy #$00
L151b               sty $174d
                    tay
                    lda $168d,y
                    clc
                    adc $17d6,x
                    sta $100c,x
                    lda $168e,y
                    adc #$00
                    sta $100f,x
L1531               ldy $17be,x
                    lda $1847,y
                    sta $1778,x
                    inc $17be,x
                    lda $17cd,x
                    beq L1595
                    lda $17c7,x
                    bne L155d
                    lda $17d0,x
                    clc
                    adc $17c1,x
                    sta $17d0,x
                    lda $17d3,x
                    adc $17c4,x
                    sta $17d3,x
                    jmp L1570
                    
L155d               lda $17d0,x
                    sec
                    sbc $17c1,x
                    sta $17d0,x
                    lda $17d3,x
                    sbc $17c4,x
                    sta $17d3,x
L1570               lda $174d
                    bne L1588
                    lda $100c,x
                    clc
                    adc $17d0,x
                    sta $100c,x
                    lda $100f,x
                    adc $17d3,x
                    sta $100f,x
L1588               lda $1769,x
                    cmp #$01
                    beq L1592
                    dec $1769,x
L1592               jmp L1656
                    
L1595               lda $1769,x
                    beq L15d8
                    cmp #$01
                    beq L15a4
                    dec $1769,x
                    jmp L1656
                    
L15a4               ldy $1772,x
                    lda $18c5,y
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $1787,x
                    sec
                    sbc #$01
                    sta $1784,x
                    lda #$00
                    sta $1790,x
                    sta $1796,x
                    sta $1799,x
                    lda $18c4,y
                    pha
                    and #$f0
                    sta $179c,x
                    pla
                    and #$0f
                    asl a
                    sta $1793,x
                    dec $1769,x
                    jmp L1656
                    
L15d8               lda $1787,x
                    beq L1656
                    dec $1793,x
                    bmi L15e5
                    jmp L1656
                    
L15e5               inc $1793,x
                    lda $100f,x
                    lsr a
                    lsr a
                    lsr a
                    sta $100b
                    lda $179c,x
                    clc
                    adc $100b
                    sta $178a,x
                    lda #$00
                    adc #$00
                    sta $178d,x
                    dec $1784,x
                    bpl L1615
                    lda $1790,x
                    eor #$01
                    sta $1790,x
                    lda $1787,x
                    sta $1784,x
L1615               lda $1790,x
                    bne L1630
                    lda $1796,x
                    clc
                    adc $178a,x
                    sta $1796,x
                    lda $1799,x
                    adc $178d,x
                    sta $1799,x
                    jmp L1643
                    
L1630               lda $1796,x
                    sec
                    sbc $178a,x
                    sta $1796,x
                    lda $1799,x
                    sbc $178d,x
                    sta $1799,x
L1643               lda $100c,x
                    clc
                    adc $1796,x
                    sta $100c,x
                    lda $100f,x
                    adc $1799,x
                    sta $100f,x
L1656               ldy $1760,x
                    lda $17b1,x
                    sta d402_sVoc1PWidthLo,y
                    lda $17b4,x
                    sta d403_sVoc1PWidthHi,y
                    lda $17bd
                    sta d416_sFiltFreqHi
                    lda $100c,x
                    sta d400_sVoc1FreqLo,y
                    lda $100f,x
                    sta d401_sVoc1FreqHi,y
                    lda $1778,x
                    and $101a,x
                    sta d404_sVoc1Control,y
L1680               dex
                    bmi L1686
                    jmp L111a
                    
L1686               pla
                    sta $fc
                    pla
                    sta $fb
                    rts
                    
  .binary "!!!_Data.bin"
