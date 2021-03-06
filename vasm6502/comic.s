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
  lda #$40
  sta $b00d
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

InitSid             jmp L1010
                    
PlaySid             jmp L106a
                    
                    	.binary "comic_data.bin"

L1010               cmp #$00
                    bne L101c
                    lda #$0e
                    sta $1006
                    jmp L1040
                    
L101c               cmp #$01
                    bne L1028
                    lda #$0a
                    sta $1006
                    jmp L1040
                    
L1028               cmp #$02
                    bne L1034
                    lda #$0c
                    sta $1006
                    jmp L1040
                    
L1034               tax
                    dex
                    dex
                    dex
                    txa
                    asl a
                    clc
                    adc #$10
                    sta $1006
L1040               lda #$00
                    sta $c008
                    sta $c009
                    sta $c00a
                    lda #$03
                    sta $c082
                    ldy #$06
                    ldx #$0f
                    jsr S1100
                    ldy #$02
                    jsr S1100
                    ldy #$08
                    ldx #$07
                    jsr S1100
                    ldy $1006
                    jsr S1100
                    rts
                    
L106a               ldy #$00
                    jsr S1100
                    rts

			.binary "comic_ascii.bin"
                    
S1100               lda $110f,y
                    sta $110d
                    lda $1110,y
                    sta $110e
                    jmp $82e3
                    
                    	.binary "comic_data1.bin"
L1135               lda #$59
                    ldy #$22
                    jsr S12d5
                    lda #$78
                    ldy #$22
                    ldx #$01
                    jsr S12d7
                    lda #$97
                    ldy #$22
                    ldx #$02
                    jmp S12d7
                    
L114e               lda #$9f
                    ldy #$21
                    jsr S12d5
                    lda #$be
                    ldy #$21
                    ldx #$01
                    jsr S12d7
                    lda #$dd
                    ldy #$21
                    ldx #$02
                    jmp S12d7
                    
L1167               lda #$1b
                    ldy #$22
                    jsr S12d5
                    lda #$fc
                    ldy #$21
                    ldx #$01
                    jsr S12d7
                    lda #$3a
                    ldy #$22
                    ldx #$02
                    jmp S12d7
                    
L1180               lda #$2b
                    ldy #$20
                    jsr S12d5
                    lda #$4a
                    ldy #$20
                    ldx #$01
                    jsr S12d7
                    lda #$69
                    ldy #$20
                    ldx #$02
                    jmp S12d7
                    
L1199               lda #$88
                    ldy #$20
                    jsr S12d5
                    lda #$a7
                    ldy #$20
                    ldx #$01
                    jsr S12d7
                    lda #$c6
                    ldy #$20
                    ldx #$02
                    jmp S12d7
                    
L11b2               lda #$e5
                    ldy #$20
                    jsr S12d5
                    lda #$04
                    ldy #$21
                    ldx #$01
                    jsr S12d7
                    lda #$23
                    ldy #$21
                    ldx #$02
                    jmp S12d7
                    
L11cb               lda #$ce
                    ldy #$1f
                    jsr S12d5
                    lda #$0c
                    ldy #$20
                    ldx #$02
                    jsr S12d7
                    lda #$ed
                    ldy #$1f
                    ldx #$01
                    jmp S12d7
                    
L11e4               lda #$42
                    ldy #$21
                    jsr S12d5
                    lda #$80
                    ldy #$21
                    ldx #$02
                    jsr S12d7
                    lda #$61
                    ldy #$21
                    ldx #$01
                    jmp S12d7
                    
L11fd               ldy #$23
                    bit $1da0
                    bit $17a0
                    bit $11a0
                    bit $0ba0
                    bit $05a0
                    ldx #$05
L1210               lda $1faa,y
                    sta $80,x
                    dey
                    dex
                    bpl L1210
                    lda #$3f
                    sta $89
                    ldx #$02
L121f               lda #$07
                    sta $8d,x
                    lda #$01
                    sta $8a,x
                    lda #$00
                    sta $1e7a,x
                    ldy $1e89,x
                    sta $1d63,y
                    sta $1d67,y
                    sta $1d6c,y
                    lda #$08
                    sta $1d6d,y
                    dex
                    bpl L121f
                    rts
                    
L1241               lda $f9
                    and #$07
                    ora $8d21
                    ora $8d48
                    ora $8d6f
                    rts
                    
L124f               lda #$38
                    sta $89
                    lda #$00
                    sta $1e21
                    sta $1e48
                    sta $1e6f
                    ldx #$14
L1260               sta d400_sVoc1FreqLo,x
                    dex
                    bpl L1260
                    rts
                    
L1267               stx $1e82
S126a               lda $1e82
                    ora $1e81
                    sta d418_sFiltMode
                    lda $1e7e
                    sta d415_sFiltFreqLo
                    lda $1e7f
                    sta d416_sFiltFreqHi
                    lda $1e80
                    sta d417_sFiltControl
                    rts
                    
L1286               stx $1e7d
                    rts
                    
S128a               ldx $1e1b
                    ldy $1e1c
                    stx $1e28
                    sty $1e29
S1296               lda $1e13
                    sta $1e2a
                    lda $1e14
                    sta $1e2b
                    rts
                    
S12a3               ldx $1e42
                    ldy $1e43
                    stx $1e4f
                    sty $1e50
S12af               lda $1e3a
                    sta $1e51
                    lda $1e3b
                    sta $1e52
                    rts
                    
S12bc               ldx $1e69
                    ldy $1e6a
                    stx $1e76
                    sty $1e77
S12c8               lda $1e61
                    sta $1e78
                    lda $1e62
                    sta $1e79
                    rts
                    
S12d5               ldx #$00
S12d7               sta $86
                    sty $87
                    stx $88
                    lda $1e8f,x
                    and $89
                    sta $89
                    lda $1e86,x
                    sta $12f4
                    sta L12fe + 1
                    ldx #$04
                    ldy #$1a
L12f1               lda #$00
                    sta d409_sVoc2PWidthLo,x
                    lda ($86),y
                    cpx #$02
                    bne L12fe
                    and #$f7
L12fe               sta d409_sVoc2PWidthLo,x
                    dey
                    dex
                    bpl L12f1
                    ldy #$1d
                    ldx $12f4
                    lda ($86),y
                    sta $d3fe,x
                    iny
                    lda ($86),y
                    sta $d3ff,x
                    ldy $88
                    ldx $1e83,y
                    ldy #$1b
                    lda ($86),y
                    sta $1e09,x
                    iny
                    lda ($86),y
                    sta $1e0a,x
                    ldy #$18
                    lda ($86),y
                    sta $1e08,x
                    ldy #$1e
                    lda ($86),y
                    sta $1e07,x
                    dey
                    lda ($86),y
                    sta $1e06,x
                    ldy #$17
L133d               lda ($86),y
                    sta $1e05,x
                    dex
                    dey
                    bpl L133d
                    inx
                    bne L137b
                    lda $1e16
                    beq L1356
                    jsr S128a
                    lda $1e12
                    beq L137a
L1356               ldx $1e1d
                    ldy $1e1e
                    stx $1e22
                    sty $1e23
S1362               lda $1e10
                    sta $1e27
                    lda $1e0f
                    sta $1e26
                    lda $1e0e
                    sta $1e25
                    lda $1e0d
                    sta $1e24
L137a               rts
                    
L137b               cpx #$4e
                    beq L13b1
                    lda $1e3d
                    beq L1387
                    jsr S12a3
L1387               lda $1e39
                    beq L13b0
S138c               ldx $1e44
                    ldy $1e45
                    stx $1e49
                    sty $1e4a
S1398               lda $1e37
                    sta $1e4e
                    lda $1e36
                    sta $1e4d
                    lda $1e35
                    sta $1e4c
                    lda $1e34
                    sta $1e4b
L13b0               rts
                    
L13b1               lda $1e64
                    beq L13b9
                    jsr S12bc
L13b9               lda $1e60
                    beq L13e2
S13be               ldx $1e6b
                    ldy $1e6c
                    stx $1e70
                    sty $1e71
S13ca               lda $1e5e
                    sta $1e75
                    lda $1e5d
                    sta $1e74
                    lda $1e5c
                    sta $1e73
                    lda $1e5b
                    sta $1e72
L13e2               rts
                    
L13e3               jsr S126a
                    jsr S1a32
                    jsr S170e
                    lda $89
                    lsr a
                    bcc L13f5
                    dec $8a
                    beq L1403
L13f5               jmp L15af
                    
L13f8               lda #$03
L13fa               clc
                    adc $80
                    sta $80
                    bcc L1403
                    inc $81
L1403               ldy #$00
                    lda ($80),y
                    cmp #$c0
                    bcc L1426
                    tax
                    lda $1e90,x
                    sta $1424
                    lda $1e91,x
                    sta $1425
                    iny
                    lda ($80),y
                    tax
                    sta $86
                    iny
                    lda ($80),y
                    sta $87
                    jmp $84a2
                    
L1426               sta $88
                    cmp #$60
                    bcc L142e
                    sbc #$60
L142e               cmp #$5f
                    beq L1440
                    cmp #$5e
                    beq L1439
                    adc $1e7a
L1439               tax
                    lda $1e7d
                    lsr a
                    bcs L1443
L1440               jmp L14bc
                    
L1443               lda $89
                    and #$08
                    beq L1440
                    ldy #$04
L144b               lda $1d6c,y
                    cpy #$02
                    bne L1459
                    ora #$08
                    sta d404_sVoc1Control
                    and #$f7
L1459               sta d402_sVoc1PWidthLo,y
                    dey
                    bpl L144b
                    lda $1d6e
                    sta $1e1f
                    ldy $1e92,x
                    lda $1ef1,x
                    sta $1e1d
                    sty $1e1e
                    sta d400_sVoc1FreqLo
                    sty d401_sVoc1FreqHi
                    lda $1d67
                    sta $1e16
                    beq L148d
                    ldy #$09
L1481               lda $1d64,y
                    sta $1e13,y
                    dey
                    bpl L1481
                    jsr S128a
L148d               ldy #$f2
L148f               lda $1c64,y
                    sta $1d13,y
                    iny
                    bmi L148f
                    and #$08
                    beq L14ad
                    lda $88
                    cmp #$60
                    bcc L14a5
                    sbc #$60
                    clc
L14a5               adc $1e7a
                    sta $1e0f
                    bne L14b0
L14ad               jsr L1356
L14b0               ldx $1d71
                    ldy $1d72
                    stx $1e20
                    sty $1e21
L14bc               ldy #$01
                    lda ($80),y
                    ldx $88
                    cpx #$60
                    bcs L14ca
                    tax
                    lda $1df4,x
L14ca               sta $8a
                    lda #$02
                    clc
                    adc $80
                    sta $80
                    bcc L14d7
                    inc $81
L14d7               jmp L15af
                    
L14da               inc $8d
                    ldy $8d
                    cpy #$08
                    beq L14ef
L14e2               ldx $1d73,y
                    lda $1d7b,y
                    stx $80
                    sta $81
                    jmp L1403
                    
L14ef               lda $89
                    and #$fe
                    sta $89
                    rts
                    
L14f6               ldx $8d
                    clc
                    tya
                    adc $80
                    sta $1d73,x
                    lda #$00
                    adc $81
                    sta $1d7b,x
                    lda $86
                    sta $1d83,x
                    dec $8d
                    tya
                    jmp L13fa
                    
L1511               ldx $8d
                    dec $1d84,x
                    beq L151d
                    inx
                    txa
                    tay
                    bpl L14e2
L151d               inc $8d
                    lda #$01
                    jmp L13fa
                    
L1524               ldy #$04
L1526               lda ($86),y
                    sta $1d6e,y
                    dey
                    bpl L1526
                    jmp L13f8
                    
L1531               ldy #$0d
                    bit $09a0
L1536               lda ($86),y
                    sta $1d56,y
                    dey
                    bpl L1536
                    jmp L13f8
                    
L1541               iny
                    sta $88
                    lda ($80),y
                    sta $86
                    iny
                    lda ($80),y
                    sta $87
                    ldy $88
L154f               lda ($86),y
                    sta $1d56,x
                    dex
                    dey
                    bpl L154f
                    lda #$05
                    jmp L13fa
                    
L155d               iny
                    lda ($80),y
                    sta $1e7a
                    lda $87
                    stx $80
                    sta $81
                    jmp L1403
                    
L156c               lda #$82
                    pha
                    lda #$f7
                    pha
                    jmp ($00f6)
                    
L1575               iny
                    lda ($80),y
                    sta $1e7a
                    lda #$04
L157d               ldy $8d
                    clc
                    adc $80
                    sta $1d73,y
                    lda #$00
                    adc $81
                    sta $1d7b,y
                    dec $8d
                    lda $87
                    stx $80
                    sta $81
                    jmp L1403
                    
L1597               lda #$03
                    bne L157d
                    stx $1e7a
                    tya
                    jmp L13fa
                    
L15a2               sta $1d56,x
                    jmp L13f8
                    
L15a8               sta $1e05,x
                    jmp L13f8
                    
L15ae               rts
                    
L15af               ldx $1e21
                    beq L15ae
                    lda $1e1f
                    and #$08
                    beq L15d1
                    lda $8a
                    cmp $1e20
                    bcs L15f7
                    lda #$00
                    sta $1e20
                    lda $1e1f
                    and #$f6
                    sta $1e1f
                    bne L15f4
L15d1               lda $1e20
                    bne L15ea
                    dec $1e21
                    bne L15f7
                    ldx #$06
L15dd               sta d400_sVoc1FreqLo,x
                    dex
                    bpl L15dd
                    lda #$08
                    ora $89
                    sta $89
                    rts
                    
L15ea               dec $1e20
                    bne L15f7
                    lda $1e1f
                    and #$f6
L15f4               sta d404_sVoc1Control
L15f7               lda $1e16
                    beq L1659
                    lda $1e15
                    beq L1607
                    dec $1e15
                    jmp L1659
                    
L1607               clc
                    ldx $1e28
                    ldy $1e29
                    lda $1e2a
                    beq L1623
                    txa
                    adc $1e17
                    tax
                    tya
                    adc $1e18
                    tay
                    dec $1e2a
                    jmp L164d
                    
L1623               lda $1e2b
                    beq L1638
                    txa
                    adc $1e19
                    tax
                    tya
                    adc $1e1a
                    tay
                    dec $1e2b
                    jmp L164d
                    
L1638               lda $1e16
                    and #$81
                    beq L164d
                    bpl L1647
                    jsr $818a
                    jmp $8507
                    
L1647               jsr S1296
                    jmp L1607
                    
L164d               stx $1e28
                    sty $1e29
                    stx d402_sVoc1PWidthLo
                    sty d403_sVoc1PWidthHi
L1659               lda $1e12
                    beq L167f
                    and #$08
                    bne L1680
                    ldx $1e22
                    ldy $1e23
                    tya
                    stx $88
                    ora $88
                    beq L167f
                    clc
                    lda $1e11
                    beq L169e
                    dec $1e11
                    lda $1e12
                    and #$02
                    bne L16e2
L167f               rts
                    
L1680               ldx $1e11
                    bpl L1688
                    ldx $1e10
L1688               lda $1e0f
                    clc
                    adc $1e05,x
                    dex
                    stx $1e11
                    tay
                    ldx $1ef1,y
                    lda $1e92,y
                    jmp L16eb
                    
L169d               clc
L169e               lda $1e24
                    beq L16b2
                    dec $1e24
                    txa
                    adc $1e05
                    tax
                    tya
                    adc $1e06
                    jmp L16eb
                    
L16b2               lda $1e25
                    beq L16c6
                    dec $1e25
                    txa
                    adc $1e07
                    tax
                    tya
                    adc $1e08
                    jmp L16eb
                    
L16c6               lda $1e26
                    beq L16da
                    dec $1e26
                    txa
                    adc $1e09
                    tax
                    tya
                    adc $1e0a
                    jmp L16eb
                    
L16da               lda $1e27
                    beq L16f9
                    dec $1e27
L16e2               txa
                    adc $1e0b
                    tax
                    tya
                    adc $1e0c
L16eb               tay
L16ec               stx d400_sVoc1FreqLo
                    sty d401_sVoc1FreqHi
                    stx $1e22
                    sty $1e23
                    rts
                    
L16f9               lda $1e12
                    and #$81
                    beq L16ec
                    bpl L1708
                    jsr L1356
                    jmp L169d
                    
L1708               jsr S1362
                    jmp L169d
                    
S170e               lda $89
                    and #$02
                    beq L1718
                    dec $8b
                    beq L1726
L1718               jmp L18d3
                    
L171b               lda #$03
L171d               clc
                    adc $82
                    sta $82
                    bcc L1726
                    inc $f3
L1726               ldy #$00
                    lda ($82),y
                    cmp #$c0
                    bcc L1749
                    tax
                    lda $1eae,x
                    sta $1747
                    lda $1eaf,x
                    sta $1748
                    iny
                    lda ($82),y
                    tax
                    sta $86
                    iny
                    lda ($82),y
                    sta $87
                    jmp $87bb
                    
L1749               sta $88
                    cmp #$60
                    bcc L1751
                    sbc #$60
L1751               cmp #$5f
                    beq L1764
                    cmp #$5e
                    beq L175c
                    adc $1e7b
L175c               tax
                    lda $1e7d
                    and #$02
                    bne L1767
L1764               jmp L17e0
                    
L1767               lda $89
                    and #$10
                    beq L1764
                    ldy #$04
L176f               lda $1da1,y
                    cpy #$02
                    bne L177d
                    ora #$08
                    sta d409_sVoc2PWidthLo
                    and #$f7
L177d               sta d409_sVoc2PWidthLo,y
                    dey
                    bpl L176f
                    lda $1da3
                    sta $1e46
                    ldy $1e92,x
                    lda $1ef1,x
                    sta $1e44
                    sty $1e45
                    sta d407_sVoc2FreqLo
                    sty d408_sVoc2FreqHi
                    lda $1d9c
                    sta $1e3d
                    beq L17b1
                    ldy #$09
L17a5               lda $1d99,y
                    sta $1e3a,y
                    dey
                    bpl L17a5
                    jsr S12a3
L17b1               ldy #$f2
L17b3               lda $1c99,y
                    sta $1d3a,y
                    iny
                    bmi L17b3
                    and #$08
                    beq L17d1
                    lda $88
                    cmp #$60
                    bcc L17c9
                    sbc #$60
                    clc
L17c9               adc $1e7b
                    sta $1e36
                    bne L17d4
L17d1               jsr S138c
L17d4               ldx $1da6
                    ldy $1da7
                    stx $1e47
                    sty $1e48
L17e0               ldy #$01
                    lda ($82),y
                    ldx $88
                    cpx #$60
                    bcs L17ee
                    tax
                    lda $1df4,x
L17ee               sta $8b
                    lda #$02
                    clc
                    adc $82
                    sta $82
                    bcc L17fb
                    inc $83
L17fb               jmp L18d3
                    
L17fe               inc $8e
                    ldy $8e
                    cpy #$08
                    beq L1813
L1806               ldx $1da8,y
                    lda $1db0,y
                    stx $82
                    sta $83
                    jmp L1726
                    
L1813               lda $89
                    and #$fd
                    sta $89
                    rts
                    
L181a               ldx $8e
                    clc
                    tya
                    adc $82
                    sta $1da8,x
                    lda $83
                    adc #$00
                    sta $1db0,x
                    lda $86
                    sta $1db8,x
                    dec $8e
                    tya
                    jmp L171d
                    
L1835               ldx $8e
                    dec $1db9,x
                    beq L1841
                    inx
                    txa
                    tay
                    bpl L1806
L1841               inc $8e
                    lda #$01
                    jmp L171d
                    
L1848               ldy #$04
L184a               lda ($86),y
                    sta $1da3,y
                    dey
                    bpl L184a
                    jmp L171b
                    
L1855               ldy #$0d
                    bit $09a0
L185a               lda ($86),y
                    sta $1d8b,y
                    dey
                    bpl L185a
                    jmp L171b
                    
L1865               iny
                    sta $88
                    lda ($82),y
                    sta $86
                    iny
                    lda ($82),y
                    sta $87
                    ldy $88
L1873               lda ($86),y
                    sta $1d8b,x
                    dex
                    dey
                    bpl L1873
                    lda #$05
                    jmp L171d
                    
L1881               iny
                    lda ($82),y
                    sta $1e7b
                    lda $87
                    stx $82
                    sta $83
                    jmp L1726
                    
L1890               lda #$86
                    pha
                    lda #$1a
                    pha
                    jmp ($00f6)
                    
L1899               iny
                    lda ($82),y
                    sta $1e7b
                    lda #$04
L18a1               ldy $8e
                    clc
                    adc $82
                    sta $1da8,y
                    lda #$00
                    adc $83
                    sta $1db0,y
                    dec $8e
                    lda $87
                    stx $82
                    sta $83
                    jmp L1726
                    
L18bb               lda #$03
                    bne L18a1
                    stx $1e7b
                    tya
                    jmp L171d
                    
L18c6               sta $1d8b,x
                    jmp L171b
                    
L18cc               sta $1e2c,x
                    jmp L171b
                    
L18d2               rts
                    
L18d3               ldx $1e48
                    beq L18d2
                    lda $1e46
                    and #$08
                    beq L18f5
                    lda $8b
                    cmp $1e47
                    bcs L191b
                    lda #$00
                    sta $1e47
                    lda $1e46
                    and #$f6
                    sta $1e46
                    bne L1918
L18f5               lda $1e47
                    bne L190e
                    dec $1e48
                    bne L191b
                    ldx #$06
L1901               sta d407_sVoc2FreqLo,x
                    dex
                    bpl L1901
                    lda #$10
                    ora $89
                    sta $89
                    rts
                    
L190e               dec $1e47
                    bne L191b
                    lda $1e46
                    and #$f6
L1918               sta d40b_sVoc2Control
L191b               lda $1e3d
                    beq L197d
                    lda $1e3c
                    beq L192b
                    dec $1e3c
                    jmp L197d
                    
L192b               clc
                    ldx $1e4f
                    ldy $1e50
                    lda $1e51
                    beq L1947
                    txa
                    adc $1e3e
                    tax
                    tya
                    adc $1e3f
                    tay
                    dec $1e51
                    jmp L1971
                    
L1947               lda $1e52
                    beq L195c
                    txa
                    adc $1e40
                    tax
                    tya
                    adc $1e41
                    tay
                    dec $1e52
                    jmp L1971
                    
L195c               lda $1e3d
                    and #$81
                    beq L1971
                    bpl L196b
                    jsr $81a3
                    jmp $882b
                    
L196b               jsr S12af
                    jmp L192b
                    
L1971               stx $1e4f
                    sty $1e50
                    stx d409_sVoc2PWidthLo
                    sty d40a_sVoc2PWidthHi
L197d               lda $1e39
                    beq L19a3
                    and #$08
                    bne L19a4
                    ldx $1e49
                    ldy $1e4a
                    tya
                    stx $88
                    ora $88
                    beq L19a3
                    clc
                    lda $1e38
                    beq L19c2
                    dec $1e38
                    lda $1e39
                    and #$02
                    bne L1a06
L19a3               rts
                    
L19a4               ldx $1e38
                    bpl L19ac
                    ldx $1e37
L19ac               lda $1e36
                    clc
                    adc $1e2c,x
                    dex
                    stx $1e38
                    tay
                    ldx $1ef1,y
                    lda $1e92,y
                    jmp L1a0f
                    
L19c1               clc
L19c2               lda $1e4b
                    beq L19d6
                    dec $1e4b
                    txa
                    adc $1e2c
                    tax
                    tya
                    adc $1e2d
                    jmp L1a0f
                    
L19d6               lda $1e4c
                    beq L19ea
                    dec $1e4c
                    txa
                    adc $1e2e
                    tax
                    tya
                    adc $1e2f
                    jmp L1a0f
                    
L19ea               lda $1e4d
                    beq L19fe
                    dec $1e4d
                    txa
                    adc $1e30
                    tax
                    tya
                    adc $1e31
                    jmp L1a0f
                    
L19fe               lda $1e4e
                    beq L1a1d
                    dec $8d4e
L1a06               txa
                    adc $1e32
                    tax
                    tya
                    adc $1e33
L1a0f               tay
L1a10               stx d407_sVoc2FreqLo
                    sty d408_sVoc2FreqHi
                    stx $1e49
                    sty $1e4a
                    rts
                    
L1a1d               lda $1e39
                    and #$81
                    beq L1a10
                    bpl L1a2c
                    jsr $828c
                    jmp $88c1
                    
L1a2c               jsr S1398
                    jmp L19c1
                    
S1a32               lda $89
                    and #$04
                    beq L1a3c
                    dec $8c
                    beq L1a4a
L1a3c               jmp L1bf7
                    
L1a3f               lda #$03
L1a41               clc
                    adc $84
                    sta $84
                    bcc L1a4a
                    inc $85
L1a4a               ldy #$00
                    lda ($84),y
                    cmp #$c0
                    bcc L1a6d
                    tax
                    lda $1ecc,x
                    sta $1a6b
                    lda $1ecd,x
                    sta $1a6c
                    iny
                    lda ($84),y
                    tax
                    sta $86
                    iny
                    lda ($84),y
                    sta $87
                    jmp $8aea
                    
L1a6d               sta $88
                    cmp #$60
                    bcc L1a75
                    sbc #$60
L1a75               cmp #$5f
                    beq L1a88
                    cmp #$5e
                    beq L1a80
                    adc $1e7c
L1a80               tax
                    lda $1e7d
                    and #$04
                    bne L1a8b
L1a88               jmp L1b04
                    
L1a8b               lda $89
                    and #$20
                    beq L1a88
                    ldy #$04
L1a93               lda $1dd6,y
                    cpy #$02
                    bne L1aa1
                    ora #$08
                    sta d412_sVoc3Control
                    and #$f7
L1aa1               sta d410_sVoc3PWidthLo,y
                    dey
                    bpl L1a93
                    lda $1dd8
                    sta $1e6d
                    ldy $1e92,x
                    lda $1ef1,x
                    sta $1e6b
                    sty $1e6c
                    sta d40e_sVoc3FreqLo
                    sty d40f_sVoc3FreqHi
                    lda $1dd1
                    sta $1e64
                    beq L1ad5
                    ldy #$09
L1ac9               lda $1dce,y
                    sta $1e61,y
                    dey
                    bpl L1ac9
                    jsr S12bc
L1ad5               ldy #$f2
L1ad7               lda $1cce,y
                    sta $1d61,y
                    iny
                    bmi L1ad7
                    and #$08
                    beq L1af5
                    lda $f8
                    cmp #$60
                    bcc L1aed
                    sbc #$60
                    clc
L1aed               adc $8d7c
                    sta $8d5d
                    bne L1af8
L1af5               jsr S13be
L1af8               ldx $1ddb
                    ldy $1ddc
                    stx $1e6e
                    sty $1e6f
L1b04               ldy #$01
                    lda ($84),y
                    ldx $88
                    cpx #$60
                    bcs L1b12
                    tax
                    lda $1df4,x
L1b12               sta $8c
                    lda #$02
                    clc
                    adc $84
                    sta $84
                    bcc L1b1f
                    inc $85
L1b1f               jmp L1bf7
                    
L1b22               inc $8f
                    ldy $8f
                    cpy #$08
                    beq L1b37
L1b2a               ldx $1ddd,y
                    lda $1de5,y
                    stx $84
                    sta $85
                    jmp L1a4a
                    
L1b37               lda $89
                    and #$fb
                    sta $89
                    rts
                    
L1b3e               ldx $8f
                    clc
                    tya
                    adc $84
                    sta $1ddd,x
                    lda #$00
                    adc $85
                    sta $1de5,x
                    lda $86
                    sta $1ded,x
                    dec $8f
                    tya
                    jmp L1a41
                    
L1b59               ldx $8f
                    dec $1dee,x
                    beq L1b65
                    inx
                    txa
                    tay
                    bpl L1b2a
L1b65               inc $8f
                    lda #$01
                    jmp L1a41
                    
L1b6c               ldy #$04
L1b6e               lda ($86),y
                    sta $1dd8,y
                    dey
                    bpl L1b6e
                    jmp L1a3f
                    
L1b79               ldy #$0d
                    bit $09a0
L1b7e               lda ($86),y
                    sta $1dc0,y
                    dey
                    bpl L1b7e
                    jmp L1a3f
                    
L1b89               iny
                    sta $88
                    lda ($84),y
                    sta $86
                    iny
                    lda ($84),y
                    sta $87
                    ldy $88
L1b97               lda ($86),y
                    sta $1dc0,x
                    dex
                    dey
                    bpl L1b97
                    lda #$05
                    jmp L1a41
                    
L1ba5               iny
                    lda ($84),y
                    sta $1e7c
                    lda $87
                    stx $84
                    sta $85
                    jmp L1a4a
                    
L1bb4               lda #$89
                    pha
                    lda #$3e
                    pha
                    jmp ($00f6)
                    
L1bbd               iny
                    lda ($84),y
                    sta $1e7c
                    lda #$04
L1bc5               ldy $8f
                    clc
                    adc $84
                    sta $1ddd,y
                    lda #$00
                    adc $85
                    sta $1de5,y
                    dec $8f
                    lda $87
                    stx $84
                    sta $85
                    jmp L1a4a
                    
L1bdf               lda #$03
                    bne L1bc5
                    stx $1e7c
                    tya
                    jmp L1a41
                    
L1bea               sta $1dc0,x
                    jmp L1a3f
                    
L1bf0               sta $1e53,x
                    jmp L1a3f
                    
L1bf6               rts
                    
L1bf7               ldx $1e6f
                    beq L1bf6
                    lda $1e6d
                    and #$08
                    beq L1c19
                    lda $8c
                    cmp $1e6e
                    bcs L1c3f
                    lda #$00
                    sta $1e6e
                    lda $1e6d
                    and #$f6
                    sta $1e6d
                    bne L1c3c
L1c19               lda $1e6e
                    bne L1c32
                    dec $1e6f
                    bne L1c3f
                    ldx #$06
L1c25               sta d40e_sVoc3FreqLo,x
                    dex
                    bpl L1c25
                    lda #$20
                    ora $89
                    sta $89
                    rts
                    
L1c32               dec $1e6e
                    bne L1c3f
                    lda $1e6d
                    and #$f6
L1c3c               sta d412_sVoc3Control
L1c3f               lda $1e64
                    beq L1ca1
                    lda $1e63
                    beq L1c4f
                    dec $1e63
                    jmp L1ca1
                    
L1c4f               clc
                    ldx $1e76
                    ldy $1e77
                    lda $1e78
                    beq L1c6b
                    txa
                    adc $1e65
                    tax
                    tya
                    adc $1e66
                    tay
                    dec $1e78
                    jmp L1c95
                    
L1c6b               lda $1e79
                    beq L1c80
                    txa
                    adc $1e67
                    tax
                    tya
                    adc $1e68
                    tay
                    dec $1e79
                    jmp L1c95
                    
L1c80               lda $1e64
                    and #$81
                    beq L1c95
                    bpl L1c8f
                    jsr $81bc
                    jmp $8b4f
                    
L1c8f               jsr S12c8
                    jmp L1c4f
                    
L1c95               stx $1e76
                    sty $1e77
                    stx d410_sVoc3PWidthLo
                    sty d411_sVoc3PWidthHi
L1ca1               lda $1e60
                    beq L1cc7
                    and #$08
                    bne L1cc8
                    ldx $1e70
                    ldy $1e71
                    tya
                    stx $88
                    ora $88
                    beq L1cc7
                    clc
                    lda $1e5f
                    beq L1ce6
                    dec $1e5f
                    lda $1e60
                    and #$02
                    bne L1d2a
L1cc7               rts
                    
L1cc8               ldx $8d5f
                    bpl L1cd0
                    ldx $8d5e
L1cd0               lda $8d5d
                    clc
                    adc $8d53,x
                    dex
                    stx $8d5f
                    tay
                    ldx $8df1,y
                    lda $8d92,y
                    jmp $8c33
                    
L1ce5               clc
L1ce6               lda $1e72
                    beq L1cfa
                    dec $1e72
                    txa
                    adc $1e53
                    tax
                    tya
                    adc $1e54
                    jmp L1d33
                    
L1cfa               lda $1e73
                    beq L1d0e
                    dec $1e73
                    txa
                    adc $1e55
                    tax
                    tya
                    adc $1e56
                    jmp L1d33
                    
L1d0e               lda $1e74
                    beq L1d22
                    dec $1e74
                    txa
                    adc $1e57
                    tax
                    tya
                    adc $1e58
                    jmp L1d33
                    
L1d22               lda $1e75
                    beq L1d41
                    dec $8d75
L1d2a               txa
                    adc $1e59
                    tax
                    tya
                    adc $1e5a
L1d33               tay
L1d34               stx d40e_sVoc3FreqLo
                    sty d40f_sVoc3FreqHi
                    stx $1e70
                    sty $1e71
                    rts
                    
L1d41               lda $1e60
                    and #$81
                    beq L1d34
                    bpl L1d50
                    jsr $82be
                    jmp $8be5
                    
L1d50               jsr S13ca
                    jmp L1ce5

	.binary "comic.bin"
