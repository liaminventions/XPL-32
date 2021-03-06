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

InitSid             jmp L1908
                    
L1003               jmp L1917
                    
PlaySid             lda $1974
                    cmp #$02
                    beq L1014
                    cmp #$01
                    bne L102a
                    jmp L18e8
                    
L1014               rts
                    
L1015               ora ($26,x)
                    inc L1015 + 1
                    inc L1015 + 1
                    lda L1015 + 1
L1020               cmp #$32
                    bne L1029
L1024               lda #$01
                    sta L1015
L1029               rts
                    
L102a               inc $1942
                    inc $1943
                    inc $1944
                    lda #$1f
                    sta d418_sFiltMode
                    ldx #$02
                    dec $1973
                    bpl L1045
                    lda $191d
                    sta $1973
L1045               bit $d020
                    stx $ff
                    lda $191e,x
                    sta $1956
                    tay
                    lda $1973
                    cmp $191d
                    bne L106b
                    lda $16a1,x
                    sta $fb
                    lda $16a4,x
                    sta $fc
                    dec $1927,x
                    bmi L106e
                    jmp L11fa
                    
L106b               jmp L120a
                    
L106e               ldy $1921,x
                    lda ($fb),y
                    cmp #$fe
                    beq L108c
                    cmp #$ff
                    bne L1094
                    lda #$00
                    sta $1927,x
                    sta $1921,x
                    sta $1924,x
                    sta $1972
                    jmp L106e
                    
L108c               lda #$02
                    sta $1974
                    jmp L190b
                    
L1094               sta $1967
                    and #$80
                    beq L10a9
                    lda $1967
                    and #$1f
                    sta $194f,x
                    inc $1921,x
                    jmp L106e
                    
L10a9               lda $1967
                    and #$40
                    beq L10be
                    lda $1967
                    and #$3f
                    sta $1976,x
                    inc $1921,x
                    jmp L106e
                    
L10be               lda $1967
                    asl a
                    tay
                    lda $16a7,y
                    sta $fd
                    lda $16a8,y
                    sta $fe
                    lda #$00
                    sta $193f,x
                    ldy $1924,x
                    sta $1942,x
                    lda #$03
                    sta $1961,x
L10dd               lda ($fd),y
                    sta $f8
                    and #$f0
                    cmp #$f0
                    bne L10f7
                    lda #$01
                    sta $1980,x
                    inc $1924,x
                    iny
                    lda ($fd),y
                    sta $f8
                    jmp L1157
                    
L10f7               lda #$00
                    sta $1980,x
                    lda $f8
                    and #$f0
                    cmp #$e0
                    bne L1130
                    lda $f8
                    and #$01
                    clc
                    adc #$01
                    sta $193f,x
                    lda $f8
                    and #$0e
                    lsr a
                    sta $1965
                    inc $1924,x
                    iny
                    lda ($fd),y
                    pha
                    and #$f0
                    sta $1964
                    pla
                    and #$0f
                    sta $12f8
                    inc $1924,x
                    iny
                    lda ($fd),y
                    sta $f8
L1130               lda $f8
                    and #$e0
                    cmp #$c0
                    bne L1142
                    lda $f8
                    and #$1f
                    sta $1933,x
                    jsr S11ed
L1142               lda $f8
                    and #$c0
                    cmp #$80
                    bne L1157
                    lda $f8
                    and #$3f
                    sta $192a,x
                    jsr S11ed
                    jmp L10dd
                    
L1157               lda $192a,x
                    sta $1927,x
                    lda $f8
                    clc
                    adc $194f,x
                    sta $1930,x
                    tay
                    lda $1564,y
                    pha
                    lda $15c4,y
                    ldy $1956
                    sta d401_sVoc1FreqHi,y
                    sta $1936,x
                    sta $1939,x
                    pla
                    sta d400_sVoc1FreqLo,y
                    sta $193c,x
                    lda $1980,x
                    bne L11cc
                    lda $1933,x
                    asl a
                    asl a
                    asl a
                    tax
                    stx $1952
                    lda $198a,x
                    sta d405_sVoc1AttDec,y
                    lda $198b,x
                    sta d406_sVoc1SusRel,y
                    lda $198c,x
                    pha
                    lda $1988,x
                    pha
                    lda $1989,x
                    ldx $ff
                    sta $192d,x
                    sta $1979,x
                    lda #$00
                    sta d402_sVoc1PWidthLo,y
                    sta $1945,x
                    pla
                    sta $194b,x
                    and #$0f
                    sta d403_sVoc1PWidthHi,y
                    sta $1948,x
                    lda #$01
                    sta $196f,x
                    pla
                    sta $196c,x
L11cc               inc $1924,x
                    ldy $1924,x
                    lda ($fd),y
                    cmp #$ff
                    bne L11ea
L11d8               lda #$00
                    sta $1924,x
                    lda $1976,x
                    beq L11e7
                    dec $1976,x
                    bpl L11ea
L11e7               inc $1921,x
L11ea               jmp L1552
                    
S11ed               inc $1924,x
                    iny
                    lda ($fd),y
                    cmp #$ff
                    beq L11d8
                    sta $f8
                    rts
                    
L11fa               ldy $1956
                    lda $1942,x
                    beq L120a
                    lda $192d,x
                    and #$fe
                    sta $1979,x
L120a               lda $1933,x
                    asl a
                    asl a
                    asl a
                    tay
                    lda $198d,y
                    sta $1953
                    lda $198e,y
                    sta $1954
                    lda $198f,y
                    sta $1955
                    and #$04
                    bne L1233
                    lda $1955
                    and #$10
                    bne L1233
                    lda $1953
                    bne L1236
L1233               jmp L1830
                    
L1236               pha
                    and #$78
                    lsr a
                    lsr a
                    lsr a
                    sta $1958,x
                    pla
                    and #$07
                    sta $1957
                    lda $195b,x
                    beq L1254
                    dec $195e,x
                    bne L1268
                    inc $195b,x
                    bpl L1268
L1254               inc $195e,x
                    lda $1958,x
                    cmp $195e,x
                    bcs L1268
                    sta $195e,x
                    dec $195b,x
                    dec $195e,x
L1268               lda $1930,x
                    tay
                    lda $1565,y
                    sec
                    sbc $1564,y
                    sta $197f
                    lda $15c5,y
                    sbc $15c4,y
                    adc $1942,x
                    lsr a
L1280               dec $1957
                    bmi L128c
                    lsr a
                    ror $197f
                    jmp L1280
                    
L128c               sta $197e
                    lda $1564,y
                    sta $197c
                    lda $15c4,y
                    sta $197d
                    lda $1958,x
                    lsr a
                    tay
L12a0               dey
                    bmi L12b9
                    sec
                    lda $197c
                    sbc $197f
                    sta $197c
                    lda $197d
                    sbc $197e
                    sta $197d
                    jmp L12a0
                    
L12b9               lda $1942,x
                    cmp #$04
                    bcc L12eb
                    ldy $195e,x
L12c3               dey
                    bmi L12dc
                    clc
                    lda $197c
                    adc $197f
                    sta $197c
                    lda $197d
                    adc $197e
                    sta $197d
                    jmp L12c3
                    
L12dc               ldy $1956
                    lda $197c
                    sta d400_sVoc1FreqLo,y
                    lda $197d
                    sta d401_sVoc1FreqHi,y
L12eb               ldx $ff
                    ldy $1956
                    lda $192a,x
                    sec
                    sbc $1927,x
                    cmp #$0f
                    bcc L1341
                    lda $193f,x
                    beq L1341
                    and #$03
                    cmp #$01
                    beq L1325
                    lda $1964
                    sec
                    lda $193c,x
                    sbc $1964
                    sta $193c,x
                    sta d400_sVoc1FreqLo,y
                    lda $1936,x
                    sbc $1965
                    sta $1936,x
                    sta d401_sVoc1FreqHi,y
                    jmp L1341
                    
L1325               lda $1964
                    clc
                    lda $193c,x
                    adc $1964
                    sta $193c,x
                    sta d400_sVoc1FreqLo,y
                    lda $1936,x
                    adc $1965
                    sta $1936,x
                    sta d401_sVoc1FreqHi,y
L1341               lda $1954
                    beq L13b2
                    and #$07
                    tay
                    dey
                    tya
                    asl a
                    asl a
                    tay
                    lda $1695,y
                    cmp $1942,x
                    bcc L1359
                    jmp L1363
                    
L1359               iny
                    iny
                    lda $1695,y
                    cmp $1942,x
                    bcc L136d
L1363               iny
                    lda $1695,y
                    sta $194e
                    jmp L1375
                    
L136d               lda $1954
                    and #$fc
                    sta $194e
L1375               lda $196f,x
                    bne L1397
                    lda $1945,x
                    sec
                    sbc $194e
                    sta $1945,x
                    lda $1948,x
                    sbc #$00
                    sta $1948,x
                    cmp #$01
                    bcs L13b2
                    lda #$01
                    sta $196f,x
                    bne L13b2
L1397               lda $1945,x
                    clc
                    adc $194e
                    sta $1945,x
                    lda $1948,x
                    adc #$00
                    sta $1948,x
                    cmp #$0f
                    bcc L13b2
                    lda #$00
                    sta $196f,x
L13b2               lda #$00
                    sta $13d4
                    lda $194b,x
                    and #$80
                    beq L13ca
                    lda $1942,x
                    and #$01
                    beq L13ca
                    lda #$b0
                    sta $13d4
L13ca               ldx $ff
                    ldy $1956
                    lda $1945,x
                    clc
                    adc #$00
                    sta d402_sVoc1PWidthLo,y
                    lda $1948,x
                    adc #$00
                    sta d403_sVoc1PWidthHi,y
                    lda $1955
                    and #$40
                    beq L13fb
                    ldx $ff
                    lda $1942,x
                    cmp #$03
                    bcc L13fb
                    and #$03
                    tax
                    lda $1632,x
                    ldx $ff
                    sta $1979,x
L13fb               sty $1967
                    lda $1955
                    and #$01
                    beq L142f
                    ldx $ff
                    stx $1975
                    lda #$89
                    sta $f9
                    lda #$16
                    sta $fa
                    ldx $ff
                    lda $1942,x
                    ldy #$0b
                    cmp ($f9),y
                    bcs L1450
                    ldy #$0a
L141f               cmp ($f9),y
                    bcs L145b
                    dey
                    cpy #$06
                    bne L141f
                    cmp ($f9),y
                    bcs L1432
                    jmp L147b
                    
L142f               jmp L146a
                    
L1432               lda $ff
                    asl a
                    bne L143a
                    clc
                    adc #$01
L143a               sta $1968
                    ldx $1972
                    txa
                    and $1968
                    bne L144e
                    txa
                    clc
                    adc $1968
                    sta d417_sFiltControl
L144e               ldy #$06
L1450               dey
                    dey
                    dey
                    dey
                    dey
                    dey
                    lda ($f9),y
                    jmp L1473
                    
L145b               dey
                    dey
                    dey
                    dey
                    dey
                    dey
                    lda $1969,x
                    clc
                    adc ($f9),y
                    jmp L1473
                    
L146a               lda $ff
                    cmp $1975
                    bne L147b
                    lda #$ff
L1473               ldx $ff
                    sta $1969,x
                    sta d416_sFiltFreqHi
L147b               ldy $1967
                    lda $1955
                    and #$10
                    beq L14e3
                    lda $1953
                    and #$0f
                    tax
                    lda $163e,x
                    sta $14af
                    lda $1640,x
                    sta $14b0
                    lda $1642,x
                    sta $14b7
                    lda $1644,x
                    sta $14b8
                    ldx $ff
                    lda $1942,x
                    cmp #$0f
                    bcs L14e0
                    tax
                    dex
                    lda $1676,x
                    ldy $ff
                    sta $1979,y
                    lda $1666,x
                    sta $1968
                    lda $1953
                    and #$10
                    beq L14cf
                    ldx $ff
                    lda $1930,x
                    clc
                    adc $1968
                    jmp L1542
                    
L14cf               ldy $1956
                    lda $1968
                    clc
                    adc #$0d
                    sta d401_sVoc1FreqHi,y
                    lda #$00
                    sta d400_sVoc1FreqLo,y
L14e0               jmp L1552
                    
L14e3               lda $1955
                    and #$80
                    beq L151e
                    ldx $ff
                    ldy $1956
                    lda $1942,x
                    cmp #$02
                    bcs L150a
                    lda #$48
                    sta d401_sVoc1FreqHi,y
                    lda #$00
                    sta d400_sVoc1FreqLo,y
                    ldx $ff
                    lda #$81
                    sta $1979,x
                    jmp L1552
                    
L150a               lda $193c,x
                    sta d400_sVoc1FreqLo,y
                    lda $1936,x
                    sta d401_sVoc1FreqHi,y
                    lda $192d,x
                    and #$fe
                    sta $1979,x
L151e               lda $1955
                    and #$04
                    beq L1552
                    dec $1961,x
                    bpl L152f
                    lda #$02
                    sta $1961,x
L152f               ldx $ff
                    lda $1961,x
                    tax
                    lda $1686,x
                    sta $41
                    ldx $ff
                    lda $1930,x
                    clc
                    adc $41
L1542               tax
                    ldy $1956
                    lda $1564,x
                    sta d400_sVoc1FreqLo,y
                    lda $15c4,x
                    sta d401_sVoc1FreqHi,y
L1552               ldx $ff
                    ldy $1956
                    lda $1979,x
                    sta d404_sVoc1Control,y
                    dex
                    bmi L1563
                    jmp L1045
                    
L1563               rts

	.binary "pop_one.bin"
                    
L1800               sei
                    lda #$7f
                    sta $dc0d
                    lda #$01
                    sta $d01a
                    lda #$fa
                    sta $d012
                    lda #$1b
                    sta $d011
                    lda #$24
                    sta $0314
                    lda #$18
                    sta $0315
                    jsr InitSid
                    cli
                    rts
                    
L1824               lda #$01
                    sta $d019
                    jsr PlaySid
L182c               jmp $ea31
                    
                    brk
L1830               lda $1953
                    beq L1848
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    tax
                    lda $1953
                    and #$0f
L183f               sta $1688
                    stx $1687
                    jmp L12eb
                    
L1848               lda #$18
                    ldx #$0c
                    bne L183f
                    brk

	.binary "pop_two.bin"
                    
S18d9               lda #$00
                    ldx #$62
L18dd               sta $1921,x
                    dex
                    bpl L18dd
                    lda #$00
                    sta $1972
L18e8               lda #$00
                    sta $1942
                    sta $1943
                    sta $1944
                    ldx #$02
L18f5               sta $1921,x
                    sta $1924,x
                    sta $1927,x
                    sta $1930,x
                    dex
                    bpl L18f5
                    sta $1974
                    rts
                    
L1908               jsr S18d9
L190b               ldx #$00
                    txa
L190e               sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$18
                    bne L190e
                    rts
                    
L1917               lda #$02
                    sta $1974
                    rts

	.binary "pop_data.bin"
