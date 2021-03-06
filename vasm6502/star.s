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
  jsr rau
  jsr PlaySid
  nop
  rti

rau                 ldx #$63
                    ldy #$26
                    sty $b005
                    stx $b004
                    sty $b007
                    stx $b006
                    rts

  .org $1000

InitSid             jmp L17c1
                    
PlaySid             jmp L17b1
                    
L1006               jmp L1054
                    brk

L100a               asl a
                    asl a
                    asl a
                    tay
                    ldx #$00
                    stx $18af
                    stx $1009
L1016               lda $1a83,y
                    sta $18a6,x
                    iny
                    lda $1a83,y
                    sta $18a9,x
                    iny
                    inx
                    cpx #$03
                    bne L1016
                    lda $1a83,y
                    sta $18ac
                    ldx #$02
L1031               lda $1a84,y
                    and $1898,x
                    sta $1894,x
                    lda $18a6,x
                    sta $18a0,x
                    lda $18a9,x
                    sta $18a3,x
                    lda #$01
                    sta $18b0,x
                    dex
                    bpl L1031
                    lda #$01
                    sta $1897
                    rts
                    
L1054               lda #$40
                    sta $1897
                    ldx #$02
                    jmp L1309
                    
L105e               lda $1897
                    beq L1099
                    lda #$02
                    sta $18ad
                    ldx #$a4
                    lda #$00
L106c               dex
                    sta $18b7,x
                    bne L106c
                    ldx #$02
L1074               lda #$02
                    sta $18c9,x
                    lda #$fe
                    sta $18c6,x
                    dex
                    bpl L1074
                    lda #$0f
                    sta $18b3
                    lda #$00
                    sta $1900
                    sta $18ff
                    lda #$f0
                    sta d417_sFiltControl
                    lda #$00
                    sta $1897
                    rts
                    
L1099               dec $18ad
                    bpl L10c4
                    lda $18ac
                    cmp #$02
                    bpl L10c1
                    ldy $18af
                    lda $2271,y
                    bpl L10b5
                    ldy #$00
                    sty $18af
                    lda $2271,y
L10b5               inc $18af
                    sta $18ae
                    cmp #$02
                    bpl L10c1
                    lda #$02
L10c1               sta $18ad
L10c4               ldx #$02
L10c6               lda $1894,x
                    bne L10ce
                    jmp $470d
                    
L10ce               inc $18c9,x
                    lda $18ad
                    beq L10dd
                    cmp #$01
                    beq L10e0
                    jmp L11ee
                    
L10dd               jmp L113f
                    
L10e0               lda $18b0,x
                    beq L113c
                    sec
                    sbc #$01
                    sta $18fc,x
                    lda #$00
                    sta $18b0,x
                    tay
                    lda $18a0,x
                    sta $80
                    lda $18a3,x
                    sta $81
                    lda ($80),y
                    bpl L1113
                    cmp #$80
                    beq L1108
                    sbc #$a0
                    sta $18b4,x
L1108               inc $18a0,x
                    bne L1110
                    inc $48a3,x
L1110               iny
                    lda ($80),y
L1113               sta $18f9,x
                    iny
                    lda ($80),y
                    cmp #$f0
                    bcc L1134
                    pha
                    iny
                    lda ($80),y
                    clc
                    adc $18a6,x
                    sta $18a0,x
                    pla
                    and #$07
                    adc $18a9,x
                    sta $18a3,x
                    jmp L11ee
                    
L1134               inc $18a0,x
                    bne L113c
                    inc $48a3,x
L113c               jmp L11ee
                    
L113f               dec $18c3,x
                    bmi L1147
                    jmp L11ee
                    
L1147               ldy $18f9,x
                    lda $1a29,y
                    sta $80
                    lda $1a4a,y
                    sta $81
                    lda #$02
                    sta $18c6,x
                    ldy $18fc,x
L115c               lda ($80),y
                    cmp #$c0
                    bcs L118b
                    cmp #$5f
                    bcc L117e
                    sbc #$60
                    bpl L1171
                    inc $18cc,x
                    iny
                    jmp L115c
                    
L1171               pha
                    iny
                    lda ($80),y
                    beq L117d
                    sta $18de,x
                    inc $18ba,x
L117d               pla
L117e               sta $18d8,x
                    cmp #$03
                    bcs L11a4
                    inc $18cc,x
                    jmp L11aa
                    
L118b               cmp #$f0
                    bmi L1198
                    and #$0f
                    sta $18c0,x
                    iny
                    jmp L115c
                    
L1198               sbc #$bf
                    sta $18db,x
                    inc $18b7,x
                    iny
                    jmp L115c
                    
L11a4               lda $18b4,x
                    sta $18d5,x
L11aa               iny
                    beq L11b7
                    tya
                    sta $18fc,x
                    lda ($80),y
                    cmp #$bf
                    bne L11ba
L11b7               inc $18b0,x
L11ba               lda $18c0,x
                    sta $18c3,x
                    lda $18ba,x
                    beq L11ee
                    ldy $18de,x
                    cpy #$40
                    bpl L11ee
                    lda $1a6b,y
                    cmp #$07
                    bne L11ee
                    lda $1a73,y
                    and #$0f
                    sta $194f,x
                    lda $1a7b,y
                    sta $1952,x
                    lda #$81
                    sta $18d2,x
                    lda #$00
                    sta $18ba,x
                    jmp L11ee
                    
L11ee               lda #$00
                    sta $18bd,x
                    lda $18c6,x
                    bpl L11fb
                    jmp L1309
                    
L11fb               dec $18c6,x
                    lda $18cc,x
                    beq L1206
                    jmp L1309
                    
L1206               lda $18c6,x
                    cmp #$01
                    bne L1234
                    lda $18c9,x
                    cmp #$02
                    bmi L122c
                    ldy $18db,x
                    lda $19f9,y
                    bpl L122c
                    and #$20
                    bne L1226
                    lda $1a73
                    sta $1934,x
L1226               lda $1a19,y
                    sta $1937,x
L122c               lda #$fe
                    sta $18f6,x
                    jmp L14cd
                    
L1234               cmp #$ff
                    beq L123b
                    jmp L1309
                    
L123b               lda $18b7,x
                    beq L1259
                    ldy $18db,x
                    lda $19e9,y
                    sta $18e1,x
                    lda $19f1,y
                    sta $18e4,x
                    lda $18d2,x
                    bmi L1259
                    lda #$00
                    sta $18d2,x
L1259               lda $18d5,x
                    sta $18f3,x
                    lda $18d8,x
                    clc
                    adc $18f3,x
                    sta $18cf,x
                    ldy $18d2,x
                    bmi L1284
                    tay
                    lda $17d4,y
                    sta $1955,x
                    lda $1834,y
                    sta $1958,x
                    txa
                    sta $18e7,x
                    lda #$00
                    sta $18ea,x
L1284               ldy $18db,x
                    lda $1a21,y
                    sta $1943,x
                    lda $18e1,x
                    sta $1934,x
                    lda $18e4,x
                    sta $1937,x
                    lda $1a11,y
                    beq L12b7
                    bpl L12ad
                    and #$0f
                    sta $1931,x
                    lda #$00
                    sta $192e,x
                    jmp L12af
                    
L12ad               asl a
                    asl a
L12af               sta $1928,x
                    lda #$00
                    sta $192b,x
L12b7               lda $1a09,y
                    beq L12c6
                    asl a
                    asl a
                    sta $1903
                    lda #$00
                    sta $1901
L12c6               lda #$00
                    sta $18b7,x
                    sta $194c,x
                    lda #$80
                    sta $1949,x
                    lda $19f9,y
                    and #$0f
                    sta $1946,x
                    lda #$00
                    sta $1940,x
                    lda $19f9,y
                    and #$c0
                    cmp #$40
                    beq L12f4
                    lda $1a01,y
                    ora #$01
                    sta $193a,x
                    inc $18bd,x
L12f4               lda #$ff
                    sta $18f6,x
                    lda #$00
                    sta $18c9,x
                    ldy $18d2,x
                    bmi L1306
                    sta $18d2,x
L1306               jmp L1569
                    
L1309               ldy $1925,x
                    dec $192b,x
                    bpl L1351
                    lda $1928,x
                    sta $1925,x
                    tay
                    lda $19c8,y
                    cmp #$ff
                    beq L132d
                    sta $80
                    and #$f0
                    sta $192e,x
                    lda $80
                    and #$0f
                    sta $1931,x
L132d               lda $19c6,y
                    and #$7f
                    sta $192b,x
                    lda $19c9,y
                    bne L1343
                    lda $1928,x
                    clc
                    adc #$04
                    jmp L134e
                    
L1343               cmp #$7f
                    bne L134c
                    lda #$00
                    jmp L134e
                    
L134c               asl a
                    asl a
L134e               sta $1928,x
L1351               lda $19c6,y
                    bmi L1368
                    lda $192e,x
                    clc
                    adc $19c7,y
                    sta $192e,x
                    bcc L1377
                    inc $1931,x
                    jmp L1377
                    
L1368               lda $192e,x
                    sec
                    sbc $19c7,y
                    sta $192e,x
                    bcs L1377
                    dec $1931,x
L1377               lda $18d2,x
                    bne L137f
                    jmp L14cd
                    
L137f               cmp #$01
                    bne L1399
                    lda $18e7,x
                    clc
                    adc $191f,x
                    sta $18e7,x
                    lda $18ea,x
                    adc $1922,x
                    sta $18ea,x
                    jmp L14cd
                    
L1399               cmp #$02
                    bne L13b3
                    lda $18e7,x
                    sec
                    sbc $191f,x
                    sta $18e7,x
                    lda $18ea,x
                    sbc $1922,x
                    sta $18ea,x
                    jmp L14cd
                    
L13b3               cmp #$03
                    beq L13ba
                    jmp L1445
                    
L13ba               ldy $18cf,x
                    sec
                    lda $17d5,y
                    sbc $17d4,y
                    sta $80
                    lda $1835,y
                    sbc $1834,y
                    sta $81
                    lda $1913,x
                    clc
                    adc $190d,x
                    tay
                    lda #$00
                    sta $1913,x
L13db               dey
                    bmi L13e5
                    lsr $81
                    ror $80
                    jmp L13db
                    
L13e5               lda $80
                    clc
                    adc $1916,x
                    sta $80
                    lda $81
                    adc $1919,x
                    sta $81
                    lda $1916,x
                    clc
                    adc $191c,x
                    sta $1916,x
                    lda $1919,x
                    adc #$00
                    sta $1919,x
                    lda $190a,x
                    and #$01
                    bne L1421
                    lda $18e7,x
                    clc
                    adc $80
                    sta $18e7,x
                    lda $18ea,x
                    adc $81
                    sta $18ea,x
                    jmp L1432
                    
L1421               lda $18e7,x
                    sec
                    sbc $80
                    sta $18e7,x
                    lda $18ea,x
                    sbc $81
                    sta $18ea,x
L1432               clc
                    lda $1907,x
                    adc #$01
                    cmp $1910,x
                    bcc L1442
                    inc $190a,x
                    lda #$00
L1442               sta $1907,x
L1445               cmp #$81
                    beq L144c
                    jmp L14cd
                    
L144c               ldy $18cf,x
                    lda $17d4,y
                    sta $80
                    lda $1834,y
                    sta $81
                    lda $1955,x
                    sec
                    sbc $80
                    sta $1955,x
                    lda $1958,x
                    sbc $81
                    sta $1958,x
                    bmi L1484
                    lda $1955,x
                    sec
                    sbc $1952,x
                    sta $1955,x
                    lda $1958,x
                    sbc $194f,x
                    sta $1958,x
                    bpl L14a6
                    jmp L1499
                    
L1484               lda $1955,x
                    clc
                    adc $1952,x
                    sta $1955,x
                    lda $1958,x
                    adc $194f,x
                    sta $1958,x
                    bmi L14a6
L1499               lda $80
                    sta $1955,x
                    lda $81
                    sta $1958,x
                    jmp L14b7
                    
L14a6               lda $1955,x
                    clc
                    adc $80
                    sta $1955,x
                    lda $1958,x
                    adc $81
                    sta $1958,x
L14b7               ldy $18cf,x
                    lda $1955,x
                    sec
                    sbc $17d4,y
                    sta $18e7,x
                    lda $1958,x
                    sbc $1834,y
                    sta $18ea,x
L14cd               lda $18bd,x
                    beq L14d5
                    jmp L1569
                    
L14d5               dec $1940,x
                    bpl L1537
                    lda $1946,x
                    sta $1940,x
                    ldy $1943,x
                    lda $195b,y
                    sta $193d,x
                    lda $1977,y
                    cmp #$10
                    bcc L14f9
                    cmp #$e0
                    bcc L14f6
                    and #$0f
L14f6               sta $193a,x
L14f9               lda $195c,y
                    cmp #$7e
                    beq L1515
                    iny
                    cmp #$7f
                    bne L1509
                    lda $1977,y
                    tay
L1509               lda $1977,y
                    beq L1515
                    cmp #$10
                    bcs L1515
                    sta $4940,x
L1515               tya
                    sta $1943,x
                    ldy $1949,x
                    bmi L1537
                    lda $2271,y
                    cmp #$40
                    bcc L1527
                    ora #$80
L1527               sta $194c,x
                    inc $1949,x
                    lda $2272,y
                    bpl L1537
                    and #$7f
                    sta $1949,x
L1537               lda $193d,x
                    bpl L154e
                    and #$7f
                    tay
                    lda $17d4,y
                    sta $18ed,x
                    lda $1834,y
                    sta $18f0,x
                    jmp L1569
                    
L154e               clc
                    adc $18cf,x
                    adc $194c,x
                    tay
                    lda $17d4,y
                    clc
                    adc $18e7,x
                    sta $18ed,x
                    lda $1834,y
                    adc $18ea,x
                    sta $18f0,x
L1569               lda $18c6,x
                    cmp #$ff
                    beq L1573
                    jmp L168b
                    
L1573               lda $18ba,x
                    bne L157b
                    jmp L168b
                    
L157b               lda #$00
                    sta $18ba,x
                    ldy $18de,x
                    cpy #$40
                    bcs L158a
                    jmp L1607
                    
L158a               tya
                    cmp #$60
                    bcs L159e
                    and #$1f
                    asl a
                    asl a
                    sta $1928,x
                    lda #$00
                    sta $192b,x
                    jmp L168b
                    
L159e               cmp #$80
                    bcs L15b1
                    and #$1f
                    asl a
                    asl a
                    sta $1903
                    lda #$00
                    sta $1901
                    jmp L168b
                    
L15b1               cmp #$a0
                    bcs L15c1
                    and #$1f
                    tay
                    lda $2292,y
                    sta $1949,x
                    jmp L168b
                    
L15c1               cmp #$b0
                    bcs L15d8
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $80
                    lda $1934,x
                    and #$0f
                    ora $80
                    sta $1934,x
                    jmp L168b
                    
L15d8               cmp #$d0
                    bcs L15ef
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $80
                    lda $1937,x
                    and #$0f
                    ora $80
                    sta $1937,x
                    jmp L168b
                    
L15ef               cmp #$e0
                    bcs L1604
                    and #$0f
                    sta $80
                    lda $1937,x
                    and #$f0
                    ora $80
                    sta $1937,x
                    jmp L168b
                    
L1604               jmp $468b
                    
L1607               lda $1a73,y
                    sta $80
                    lda $1a6b,y
                    sta $81
                    cmp #$03
                    bcc L1618
                    jmp $4682
                    
L1618               cmp #$00
                    bne L162f
                    lda $80
                    sta $1922,x
                    lda $1a7b,y
                    sta $191f,x
                    lda #$01
                    sta $18d2,x
                    jmp L168b
                    
L162f               cmp #$01
                    bne L1646
                    lda $80
                    sta $1922,x
                    lda $1a7b,y
                    sta $191f,x
                    lda #$02
                    sta $18d2,x
                    jmp L168b
                    
L1646               cmp #$02
                    bne L167f
                    lda #$03
                    sta $18d2,x
                    lda $80
                    and #$0f
                    sta $191c,x
                    lda $1a7b,y
                    and #$0f
                    sta $190d,x
                    lda $1a7b,y
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    clc
                    adc #$01
                    sta $1910,x
                    lsr a
                    bcc L1671
                    inc $1913,x
L1671               sta $1907,x
                    lda #$00
                    sta $190a,x
                    sta $1916,x
                    sta $1919,x
L167f               jmp L168b
                    
L1682               cmp #$08
                    bne L168b
                    lda #$00
                    sta $48d2,x
L168b               ldy $189d,x
                    lda $18ed,x
                    sta d400_sVoc1FreqLo,y
                    lda $18f0,x
                    sta d401_sVoc1FreqHi,y
                    lda $1937,x
                    sta d406_sVoc1SusRel,y
                    lda $1934,x
                    sta d405_sVoc1AttDec,y
                    lda $192e,x
                    sta d402_sVoc1PWidthLo,y
                    lda $1931,x
                    sta d403_sVoc1PWidthHi,y
                    lda $193a,x
                    and $18f6,x
                    sta d404_sVoc1Control,y
                    bit $1897
                    bvc L16c3
                    jmp L170d
                    
L16c3               lda $18c6,x
                    cmp #$ff
                    beq L16cd
                    jmp L170d
                    
L16cd               dec $18c6,x
                    lda $18cc,x
                    bne L16d8
                    jmp L170d
                    
L16d8               lda $18d5,x
                    sta $18f3,x
                    lda $18d8,x
                    beq L170a
                    cmp #$03
                    bcc L1701
                    clc
                    adc $18f3,x
                    sta $18cf,x
                    ldy $18d2,x
                    bmi L1708
                    lda #$00
                    sta $18e7,x
                    sta $18ea,x
                    sta $18d2,x
                    jmp L170a
                    
L1701               tay
                    lda $189a,y
                    sta $18f6,x
L1708               lda #$00
L170a               sta $18cc,x
L170d               dex
                    bmi L171b
                    bit $1897
                    bvs L1718
                    jmp L10c6
                    
L1718               jmp L1309
                    
L171b               lda #$00
                    sta $1897
                    dec $1901
                    bpl L1784
                    lda $1903
                    sta $1902
                    tay
                    lda $1993,y
                    bpl L173e
                    and #$70
                    sta $18ff
                    lda $1994,y
                    sta d417_sFiltControl
                    lda #$00
L173e               sta $1901
                    lda $1994,y
                    and #$03
                    asl a
                    sta $1905
                    lda $1994,y
                    cmp #$80
                    ror a
                    cmp #$80
                    ror a
                    sta $1904
                    lda $1996,y
                    bne L1764
                    lda $1903
                    clc
                    adc #$04
                    jmp L176f
                    
L1764               cmp #$7f
                    bne L176d
                    lda #$00
                    jmp L176f
                    
L176d               asl a
                    asl a
L176f               sta $1903
                    lda $1995,y
                    cmp #$ff
                    beq L1781
                    sta $1900
                    lda #$00
                    sta $1906
L1781               jmp L179b
                    
L1784               lda $1905
                    clc
                    adc $1906
                    cmp #$08
                    and #$07
                    sta $1906
                    lda $1900
                    adc $1904
                    sta $1900
L179b               lda $1906
                    sta d415_sFiltFreqLo
                    lda $1900
                    sta d416_sFiltFreqHi
                    lda $18b3
                    ora $18ff
                    sta d418_sFiltMode
                    rts
                    
L17b1               dec $17d3
                    bmi L17b9
                    jmp L1054
                    
L17b9               lda #$01
                    sta $17d3
                    jmp L105e
                    
L17c1               ldx #$00
                    stx $17d3
                    ldx #$63
                    ldy #$26
                    sty $b005
                    stx $b004
                    sty $b007
                    stx $b006
                    jmp L100a

  .binary "star_data.bin"
