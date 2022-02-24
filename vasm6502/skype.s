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
  lda #0 ; Song Numbehr
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
InitSid             ldx #$31
                    stx $b004
                    ldx #$13
                    stx $b005
                    ldx #$31
                    stx $b006
                    ldx #$13
                    stx $b007

                    jmp L173e

putbut              ldx #$31
                    stx $b004
                    ldx #$13
                    stx $b005
                    ldx #$31
                    stx $b006
                    ldx #$13
                    stx $b007
                    rts


     .org $1003           
PlaySid             jmp L172e
                    
L1006               jmp L1051
                    
                    .byte $00
L100a               asl a
                    asl a
                    asl a
                    tay
                    ldx #$00
                    stx $1009
L1013               lda $1b33,y
                    sta $1823,x
                    iny
                    lda $1b33,y
                    sta $1826,x
                    iny
                    inx
                    cpx #$03
                    bne L1013
                    lda $1b33,y
                    sta $1829
                    ldx #$02
L102e               lda $1b34,y
                    and $1815,x
                    sta $1811,x
                    lda $1823,x
                    sta $181d,x
                    lda $1826,x
                    sta $1820,x
                    lda #$01
                    sta $182c,x
                    dex
                    bpl L102e
                    lda #$01
                    sta $1814
                    rts
                    
L1051               lda #$40
                    sta $1814
                    ldx #$02
                    jmp L12e6
                    
L105b               lda $1814
                    beq L1096
                    lda #$02
                    sta $182a
                    ldx #$98
                    lda #$00
L1069               dex
                    sta $1833,x
                    bne L1069
                    ldx #$02
L1071               lda #$02
                    sta $1845,x
                    lda #$fe
                    sta $1842,x
                    dex
                    bpl L1071
                    lda #$0f
                    sta $182f
                    lda #$00
                    sta $187c
                    sta $187b
                    lda #$f0
                    sta d417_sFiltControl
                    lda #$00
                    sta $1814
                    rts
                    
L1096               dec $182a
                    bpl L10a1
                    lda $1829
                    sta $182a
L10a1               ldx #$02
L10a3               lda $1811,x
                    bne L10ab
                    jmp L168a
                    
L10ab               inc $1845,x
                    lda $182a
                    beq L10ba
                    cmp #$01
                    beq L10bd
                    jmp L11cb
                    
L10ba               jmp L111c
                    
L10bd               lda $182c,x
                    beq L1119
                    sec
                    sbc #$01
                    sta $1878,x
                    lda #$00
                    sta $182c,x
                    tay
                    lda $181d,x
                    sta $fb
                    lda $1820,x
                    sta $fc
                    lda ($fb),y
                    bpl L10f0
                    cmp #$80
                    beq L10e5
                    sbc #$a0
                    sta $1830,x
L10e5               inc $181d,x
                    bne L10ed
                    inc $1820,x
L10ed               iny
                    lda ($fb),y
L10f0               sta $1875,x
                    iny
                    lda ($fb),y
                    cmp #$f0
                    bcc L1111
                    pha
                    iny
                    lda ($fb),y
                    clc
                    adc $1823,x
                    sta $181d,x
                    pla
                    and #$07
                    adc $1826,x
                    sta $1820,x
                    jmp L11cb
                    
L1111               inc $181d,x
                    bne L1119
                    inc $1820,x
L1119               jmp L11cb
                    
L111c               dec $183f,x
                    bmi L1124
                    jmp L11cb
                    
L1124               ldy $1875,x
                    lda $1aad,y
                    sta $fb
                    lda $1ad8,y
                    sta $fc
                    lda #$02
                    sta $1842,x
                    ldy $1878,x
L1139               lda ($fb),y
                    cmp #$c0
                    bcs L1168
                    cmp #$5f
                    bcc L115b
                    sbc #$60
                    bpl L114e
                    inc $1848,x
                    iny
                    jmp L1139
                    
L114e               pha
                    iny
                    lda ($fb),y
                    beq L115a
                    sta $185a,x
                    inc $1836,x
L115a               pla
L115b               sta $1854,x
                    cmp #$03
                    bcs L1181
                    inc $1848,x
                    jmp L1187
                    
L1168               cmp #$f0
                    bmi L1175
                    and #$0f
                    sta $183c,x
                    iny
                    jmp L1139
                    
L1175               sbc #$bf
                    sta $1857,x
                    inc $1833,x
                    iny
                    jmp L1139
                    
L1181               lda $1830,x
                    sta $1851,x
L1187               iny
                    beq L1194
                    tya
                    sta $1878,x
                    lda ($fb),y
                    cmp #$bf
                    bne L1197
L1194               inc $182c,x
L1197               lda $183c,x
                    sta $183f,x
                    lda $1836,x
                    beq L11cb
                    ldy $185a,x
                    cpy #$40
                    bpl L11cb
                    lda $1b03,y
                    cmp #$07
                    bne L11cb
                    lda $1b13,y
                    and #$0f
                    sta $18bf,x
                    lda $1b23,y
                    sta $18c2,x
                    lda #$81
                    sta $184e,x
                    lda #$00
                    sta $1836,x
                    jmp L11cb
                    
L11cb               lda #$00
                    sta $1839,x
                    lda $1842,x
                    bpl L11d8
                    jmp L12e6
                    
L11d8               dec $1842,x
                    lda $1848,x
                    beq L11e3
                    jmp L12e6
                    
L11e3               lda $1842,x
                    cmp #$01
                    bne L1211
                    lda $1845,x
                    cmp #$02
                    bmi L1209
                    ldy $1857,x
                    lda $1a0b,y
                    bpl L1209
                    and #$20
                    bne L1203
                    lda $1b13
                    sta $18a4,x
L1203               lda $1a77,y
                    sta $18a7,x
L1209               lda #$fe
                    sta $1872,x
                    jmp L1470
                    
L1211               cmp #$ff
                    beq L1218
                    jmp L12e6
                    
L1218               lda $1833,x
                    beq L1236
                    ldy $1857,x
                    lda $19d5,y
                    sta $185d,x
                    lda $19f0,y
                    sta $1860,x
                    lda $184e,x
                    bmi L1236
                    lda #$00
                    sta $184e,x
L1236               lda $1851,x
                    sta $186f,x
                    lda $1854,x
                    clc
                    adc $186f,x
                    sta $184b,x
                    ldy $184e,x
                    bmi L1261
                    tay
                    lda $1751,y
                    sta $18c5,x
                    lda $17b1,y
                    sta $18c8,x
                    txa
                    sta $1863,x
                    lda #$00
                    sta $1866,x
L1261               ldy $1857,x
                    lda $1a92,y
                    sta $18b3,x
                    lda $185d,x
                    sta $18a4,x
                    lda $1860,x
                    sta $18a7,x
                    lda $1a5c,y
                    beq L1294
                    bpl L128a
                    and #$0f
                    sta $18a1,x
                    lda #$00
                    sta $189e,x
                    jmp L128c
                    
L128a               asl a
                    asl a
L128c               sta $1898,x
                    lda #$00
                    sta $189b,x
L1294               lda $1a41,y
                    beq L12a3
                    asl a
                    asl a
                    sta $187f
                    lda #$00
                    sta $187d
L12a3               lda #$00
                    sta $1833,x
                    sta $18bc,x
                    lda #$80
                    sta $18b9,x
                    lda $1a0b,y
                    and #$0f
                    sta $18b6,x
                    lda #$00
                    sta $18b0,x
                    lda $1a0b,y
                    and #$c0
                    cmp #$40
                    beq L12d1
                    lda $1a26,y
                    ora #$01
                    sta $18aa,x
                    inc $1839,x
L12d1               lda #$ff
                    sta $1872,x
                    lda #$00
                    sta $1845,x
                    ldy $184e,x
                    bmi L12e3
                    sta $184e,x
L12e3               jmp L150c
                    
L12e6               ldy $1895,x
                    dec $189b,x
                    bpl L132e
                    lda $1898,x
                    sta $1895,x
                    tay
                    lda $19d0,y
                    cmp #$ff
                    beq L130a
                    sta $fb
                    and #$f0
                    sta $189e,x
                    lda $fb
                    and #$0f
                    sta $18a1,x
L130a               lda $19ce,y
                    and #$7f
                    sta $189b,x
                    lda $19d1,y
                    bne L1320
                    lda $1898,x
                    clc
                    adc #$04
                    jmp L132b
                    
L1320               cmp #$7f
                    bne L1329
                    lda #$00
                    jmp L132b
                    
L1329               asl a
                    asl a
L132b               sta $1898,x
L132e               lda $19ce,y
                    bmi L1345
                    lda $189e,x
                    clc
                    adc $19cf,y
                    sta $189e,x
                    bcc L1354
                    inc $18a1,x
                    jmp L1354
                    
L1345               lda $189e,x
                    sec
                    sbc $19cf,y
                    sta $189e,x
                    bcs L1354
                    dec $18a1,x
L1354               lda $184e,x
                    bne L135c
                    jmp L1470
                    
L135c               cmp #$01
                    bne L1376
                    lda $1863,x
                    clc
                    adc $188f,x
                    sta $1863,x
                    lda $1866,x
                    adc $1892,x
                    sta $1866,x
                    jmp L1470
                    
L1376               cmp #$02
                    bne L1390
                    lda $1863,x
                    sec
                    sbc $188f,x
                    sta $1863,x
                    lda $1866,x
                    sbc $1892,x
                    sta $1866,x
                    jmp L1470
                    
L1390               cmp #$04
                    bne L13a6
                    lda $1889,x
                    sta $fb
                    lda #$00
                    asl $fb
                    rol a
                    asl $fb
                    rol a
                    sta $fc
                    jmp L13a9
                    
L13a6               jmp L13e8
                    
L13a9               lda $1886,x
                    and #$01
                    bne L13c4
                    lda $1863,x
                    clc
                    adc $fb
                    sta $1863,x
                    lda $1866,x
                    adc $fc
                    sta $1866,x
                    jmp L13d5
                    
L13c4               lda $1863,x
                    sec
                    sbc $fb
                    sta $1863,x
                    lda $1866,x
                    sbc $fc
                    sta $1866,x
L13d5               clc
                    lda $1883,x
                    adc #$01
                    cmp $188c,x
                    bcc L13e5
                    inc $1886,x
                    lda #$00
L13e5               sta $1883,x
L13e8               cmp #$81
                    beq L13ef
                    jmp L1470
                    
L13ef               ldy $184b,x
                    lda $1751,y
                    sta $fb
                    lda $17b1,y
                    sta $fc
                    lda $18c5,x
                    sec
                    sbc $fb
                    sta $18c5,x
                    lda $18c8,x
                    sbc $fc
                    sta $18c8,x
                    bmi L1427
                    lda $18c5,x
                    sec
                    sbc $18c2,x
                    sta $18c5,x
                    lda $18c8,x
                    sbc $18bf,x
                    sta $18c8,x
                    bpl L1449
                    jmp L143c
                    
L1427               lda $18c5,x
                    clc
                    adc $18c2,x
                    sta $18c5,x
                    lda $18c8,x
                    adc $18bf,x
                    sta $18c8,x
                    bmi L1449
L143c               lda $fb
                    sta $18c5,x
                    lda $fc
                    sta $18c8,x
                    jmp L145a
                    
L1449               lda $18c5,x
                    clc
                    adc $fb
                    sta $18c5,x
                    lda $18c8,x
                    adc $fc
                    sta $18c8,x
L145a               ldy $184b,x
                    lda $18c5,x
                    sec
                    sbc $1751,y
                    sta $1863,x
                    lda $18c8,x
                    sbc $17b1,y
                    sta $1866,x
L1470               lda $1839,x
                    beq L1478
                    jmp L150c
                    
L1478               dec $18b0,x
                    bpl L14da
                    lda $18b6,x
                    sta $18b0,x
                    ldy $18b3,x
                    lda $18cb,y
                    sta $18ad,x
                    lda $1929,y
                    cmp #$10
                    bcc L149c
                    cmp #$e0
                    bcc L1499
                    and #$0f
L1499               sta $18aa,x
L149c               lda $18cc,y
                    cmp #$7e
                    beq L14b8
                    iny
                    cmp #$7f
                    bne L14ac
                    lda $1929,y
                    tay
L14ac               lda $1929,y
                    beq L14b8
                    cmp #$10
                    bcs L14b8
                    sta $18b0,x
L14b8               tya
                    sta $18b3,x
                    ldy $18b9,x
                    bmi L14da
                    lda $2600,y
                    cmp #$40
                    bcc L14ca
                    ora #$80
L14ca               sta $18bc,x
                    inc $18b9,x
                    lda $2601,y
                    bpl L14da
                    and #$7f
                    sta $18b9,x
L14da               lda $18ad,x
                    bpl L14f1
                    and #$7f
                    tay
                    lda $1751,y
                    sta $1869,x
                    lda $17b1,y
                    sta $186c,x
                    jmp L150c
                    
L14f1               clc
                    adc $184b,x
                    adc $18bc,x
                    tay
                    lda $1751,y
                    clc
                    adc $1863,x
                    sta $1869,x
                    lda $17b1,y
                    adc $1866,x
                    sta $186c,x
L150c               lda $1842,x
                    cmp #$ff
                    beq L1516
                    jmp L1608
                    
L1516               lda $1836,x
                    bne L151e
                    jmp L1608
                    
L151e               lda #$00
                    sta $1836,x
                    ldy $185a,x
                    cpy #$40
                    bcs L152d
                    jmp L159f
                    
L152d               tya
                    cmp #$60
                    bcs L1541
                    and #$1f
                    asl a
                    asl a
                    sta $1898,x
                    lda #$00
                    sta $189b,x
                    jmp L1608
                    
L1541               cmp #$80
                    bcs L1554
                    and #$1f
                    asl a
                    asl a
                    sta $187f
                    lda #$00
                    sta $187d
                    jmp L1608
                    
L1554               cmp #$a0
                    bcs L1564
                    and #$1f
                    tay
                    lda $261d,y
                    sta $18b9,x
                    jmp L1608
                    
L1564               cmp #$b0
                    bcs L157b
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $fb
                    lda $18a4,x
                    and #$0f
                    ora $fb
                    sta $18a4,x
                    jmp L1608
                    
L157b               cmp #$e0
                    bcs L1590
                    and #$0f
                    sta $fb
                    lda $18a7,x
                    and #$f0
                    ora $fb
                    sta $18a7,x
                    jmp L1608
                    
L1590               cmp #$f0
                    bcs L159c
                    and #$0f
                    sta $182f
                    jmp L1608
                    
L159c               jmp L1608
                    
L159f               lda $1b13,y
                    sta $fb
                    lda $1b03,y
                    sta $fc
                    cmp #$03
                    bcc L15b0
                    jmp L15e1
                    
L15b0               cmp #$00
                    bne L15c7
                    lda $fb
                    sta $1892,x
                    lda $1b23,y
                    sta $188f,x
                    lda #$01
                    sta $184e,x
                    jmp L1608
                    
L15c7               cmp #$01
                    bne L15de
                    lda $fb
                    sta $1892,x
                    lda $1b23,y
                    sta $188f,x
                    lda #$02
                    sta $184e,x
                    jmp L1608
                    
L15de               jmp L1608
                    
L15e1               cmp #$05
                    bne L15ff
                    lda #$04
                    sta $184e,x
                    lda $1b13,y
                    sta $188c,x
                    lsr a
                    sta $1883,x
                    lda $1b23,y
                    sta $1889,x
                    lda #$00
                    sta $1886,x
L15ff               cmp #$08
                    bne L1608
                    lda #$00
                    sta $184e,x
L1608               ldy $181a,x
                    lda $1869,x
                    sta d400_sVoc1FreqLo,y
                    lda $186c,x
                    sta d401_sVoc1FreqHi,y
                    lda $18a7,x
                    sta d406_sVoc1SusRel,y
                    lda $18a4,x
                    sta d405_sVoc1AttDec,y
                    lda $189e,x
                    sta d402_sVoc1PWidthLo,y
                    lda $18a1,x
                    sta d403_sVoc1PWidthHi,y
                    lda $18aa,x
                    and $1872,x
                    sta d404_sVoc1Control,y
                    bit $1814
                    bvc L1640
                    jmp L168a
                    
L1640               lda $1842,x
                    cmp #$ff
                    beq L164a
                    jmp L168a
                    
L164a               dec $1842,x
                    lda $1848,x
                    bne L1655
                    jmp L168a
                    
L1655               lda $1851,x
                    sta $186f,x
                    lda $1854,x
                    beq L1687
                    cmp #$03
                    bcc L167e
                    clc
                    adc $186f,x
                    sta $184b,x
                    ldy $184e,x
                    bmi L1685
                    lda #$00
                    sta $1863,x
                    sta $1866,x
                    sta $184e,x
                    jmp L1687
                    
L167e               tay
                    lda $1817,y
                    sta $1872,x
L1685               lda #$00
L1687               sta $1848,x
L168a               dex
                    bmi L1698
                    bit $1814
                    bvs L1695
                    jmp L10a3
                    
L1695               jmp L12e6
                    
L1698               lda #$00
                    sta $1814
                    dec $187d
                    bpl L1701
                    lda $187f
                    sta $187e
                    tay
                    lda $1987,y
                    bpl L16bb
                    and #$70
                    sta $187b
                    lda $1988,y
                    sta d417_sFiltControl
                    lda #$00
L16bb               sta $187d
                    lda $1988,y
                    and #$03
                    asl a
                    sta $1881
                    lda $1988,y
                    cmp #$80
                    ror a
                    cmp #$80
                    ror a
                    sta $1880
                    lda $198a,y
                    bne L16e1
                    lda $187f
                    clc
                    adc #$04
                    jmp L16ec
                    
L16e1               cmp #$7f
                    bne L16ea
                    lda #$00
                    jmp L16ec
                    
L16ea               asl a
                    asl a
L16ec               sta $187f
                    lda $1989,y
                    cmp #$ff
                    beq L16fe
                    sta $187c
                    lda #$00
                    sta $1882
L16fe               jmp L1718
                    
L1701               lda $1881
                    clc
                    adc $1882
                    cmp #$08
                    and #$07
                    sta $1882
                    lda $187c
                    adc $1880
                    sta $187c
L1718               lda $1882
                    sta d415_sFiltFreqLo
                    lda $187c
                    sta d416_sFiltFreqHi
                    lda $182f
                    ora $187b
                    sta d418_sFiltMode
                    rts
                    
L172e               dec $1750
                    bmi L1736
                    jmp L1051
                    
L1736               lda #$03
                    sta $1750
                    jmp L105b
                    
L173e               ldx #$00
                    stx $1750
                    ldx #$31
                    ldy #$13
                    sty $b005
                    stx $b004
                    jmp L100a

	.binary "skype_data.bin"
