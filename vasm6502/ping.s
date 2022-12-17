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
  sta $b00b
  lda #0 ; Song Number 
  jsr InitSid
  cli
  nop

; You can put code you want to run in the background here.

loop:
  jmp loop

irq:
  lda #$40
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

  .org $0fc0

InitSid             lda #$cb
                    sta $b004
                    lda #$0c
                    sta $b005
                    ldx #$00
                    stx $0fff
                    jmp L1000
                    
PlaySid             lda $0fff
                    bne L0fdd
                    inc $0fff
                    jmp L1003
                    
L0fdd               inc $0fff
                    lda $0fff
                    cmp #$06
                    bne L0fec
                    lda #$00
                    sta $0fff
L0fec               jmp L1009
                    
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
		    .byte $00, $00, $00, $00, $00, $00

L1000               jmp L22c8
                    
L1003               jmp L1981
                    
L1006               jmp L232f
                    
L1009               jmp L197c


		    .binary "ping1.bin"

                    
L197c               lda #$00
                    sta $1991
L1981               ldx #$02
                    lda #$07
                    beq L19b6
L1987               lda $21f7,x
                    sta $1cd4
                    stx $1be0
                    lda #$07
                    beq L19b3
                    lda $223d,x
                    beq L19a3
                    dec $223d,x
                    bne L19a3
                    lda #$fe
                    sta $22b1,x
L19a3               lda $221e,x
                    bpl L19b3
                    lda #$01
                    beq L19c2
                    cmp #$02
                    bne L19b3
                    jmp L1b99
                    
L19b3               jmp L1cc7
                    
L19b6               sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    jmp L2030
                    
L19c2               lda $221a,x
                    sta $221e,x
                    lda $1984
                    and $21fa,x
                    beq L19b3
                    lda $2236,x
                    and #$7f
                    beq L19b3
                    cmp #$5f
                    bne L19ed
                    lda $2257,x
                    beq L19b3
                    lsr a
                    lsr a
                    sta $226d,x
                    lda #$00
                    sta $2276,x
                    jmp L1dd0
                    
L19ed               tay
                    lda $2257,x
                    sta $2254,x
                    bne L1a05
                    sta $2261,x
                    sta $2264,x
                    tya
                    sta $2233,x
                    sta $225e,x
                    bpl L1a09
L1a05               tya
                    sta $225b,x
L1a09               lda #$00
                    sta $2276,x
                    lda $22ba,x
                    sta $22b7,x
                    bmi L1a20
                    sta $22be,x
                    tay
                    lda $128b,y
                    sta $22c1,x
L1a20               lda $2222,x
                    bne L1a28
                    jmp L1f17
                    
L1a28               sta $22b1,x
                    lda $222c,x
                    sta $2229,x
                    tay
                    lda $2247,x
                    cmp #$01
                    lda $1069,y
                    bcc L1a41
                    and #$0f
                    ora $2247,x
L1a41               pha
                    and #$f0
                    sta $2240,x
                    ldy $1cd4
                    ora #$0f
                    sta d406_sVoc1SusRel,y
                    lda $22a0,x
                    and $22b1,x
                    sta d404_sVoc1Control,y
                    ldy $2229,x
                    lda $1079,y
                    and #$1f
                    asl a
                    sta $223d,x
                    lda $2250,x
                    bmi L1a93
                    lda $10a9,y
                    sta $2250,x
                    asl a
                    bne L1a7c
                    bcs L1a93
                    lda L20e8 + 1
                    and $21fe,x
                    bcc L1a90
L1a7c               lda #$00
                    sta $2073
                    lda $2250,x
                    sta L2069 + 1
                    sty $2083
                    lda L20e8 + 1
                    ora $21fa,x
L1a90               sta L20e8 + 1
L1a93               lda $1089,y
                    sta $226d,x
                    lda $1059,y
                    pha
                    lda $1099,y
                    beq L1aaf
                    bpl L1ab6
                    and #$7f
                    ldy $1cd4
                    sta d402_sVoc1PWidthLo,y
                    sta d403_sVoc1PWidthHi,y
L1aaf               lda $2282,x
                    ora #$80
                    bne L1adf
L1ab6               sta $fe
                    asl a
                    asl a
                    tay
                    bit $fe
                    bvc L1ac7
                    lda $2229,x
                    cmp $2230,x
                    beq L1ae2
L1ac7               lda #$00
                    sta $2285,x
                    sta $2288,x
                    lda $124b,y
                    ldy $1cd4
                    sta d402_sVoc1PWidthLo,y
                    sta d403_sVoc1PWidthHi,y
                    lda $fe
                    and #$3f
L1adf               sta $2282,x
L1ae2               pla
                    ldy $2247,x
                    beq L1aea
                    lda #$00
L1aea               ldy $1cd4
                    sta d405_sVoc1AttDec,y
                    pla
                    sta d406_sVoc1SusRel,y
                    lda $22a0,x
                    ora #$01
                    sta d404_sVoc1Control,y
                    lda #$00
                    sta $2222,x
                    sta $22ae,x
                    sta $22ab,x
                    lda $2229,x
                    sta $2230,x
                    tay
                    lda $1049,y
                    tay
                    clc
                    adc #$01
                    sta $22b4,x
                    jmp L201d
                    
S1b1b               ldy $2225,x
                    bne L1b98
                    sty L1b83 + 1
                    dec $220a,x
                    bpl L1b33
                    inc $220a,x
                    inc $220e,x
                    bne L1b33
                    inc $2212,x
L1b33               lda $220e,x
                    sta $fe
                    lda $2212,x
                    sta $ff
                    lda ($fe),y
                    bpl L1b83
                    cmp #$f7
                    bcc L1b6c
                    bne L1b4e
                    lda #$80
                    sta L1b83 + 1
                    lda #$00
L1b4e               and #$07
                    sta $1b63
                    iny
                    lda $2202,x
                    clc
                    adc ($fe),y
                    sta $220e,x
                    sta $fe
                    lda $2206,x
                    adc #$00
                    sta $2212,x
                    sta $ff
                    dey
                    lda ($fe),y
L1b6c               cmp #$c0
                    bcc L1b7a
                    and #$3f
                    sta $220a,x
                    iny
                    lda ($fe),y
                    bpl L1b83
L1b7a               sec
                    sbc #$a0
                    sta $2216,x
                    iny
                    lda ($fe),y
L1b83               ora #$00
                    sta $224b,x
                    sty $fe
                    lda $220e,x
                    clc
                    adc $fe
                    sta $220e,x
                    bcc L1b98
                    inc $2212,x
L1b98               rts
                    
L1b99               lda #$00
                    sta $2257,x
                    ldy $224b,x
                    bpl L1bac
                    lda $1984
                    and $21fe,x
                    sta $1984
L1bac               lda $145b,y
                    sta $fe
                    lda $148b,y
                    sta $ff
                    lda #$ff
                    sta $22a7,x
                    ldy $2225,x
                    lda ($fe),y
                    cmp #$5f
                    beq L1c0a
                    cmp #$f0
                    bcc L1bcf
                    and #$0f
                    sta $2243,x
                    bpl L1c0a
L1bcf               cmp #$c0
                    bcc L1be3
                    and #$3f
                    asl a
                    sta $22ba,x
                    tax
                    lda $128c,x
                    and #$3f
                    ldx #$00
                    bpl L1bfc
L1be3               cmp #$a0
                    bcc L1bf0
                    and #$1f
                    asl a
                    asl a
                    sta $2257,x
                    bpl L1c0a
L1bf0               cmp #$80
                    bcc L1c1c
                    sta $22ba,x
                    and #$3f
                    sta $22a7,x
L1bfc               sta $222c,x
                    sta $2250,x
                    lda #$00
                    sta $22a3,x
                    sta $2247,x
L1c0a               iny
                    lda ($fe),y
                    cmp #$e0
                    bcc L1c1c
                    beq L1c17
                    adc #$3f
                    bne L1c26
L1c17               iny
                    lda ($fe),y
                    bne L1c26
L1c1c               cmp #$80
                    bcs L1c37
                    cmp #$60
                    bcc L1c37
                    and #$1f
L1c26               sta $221a,x
                    iny
                    lda ($fe),y
                    cmp #$f0
                    bcc L1c37
                    and #$0f
                    sta $2243,x
                    lda #$5f
L1c37               pha
                    iny
                    lda ($fe),y
                    bne L1c3e
                    tay
L1c3e               tya
                    sta $2225,x
                    pla
                    cpx #$03
                    bne L1c4f
                    cmp #$5f
                    beq L1c4e
                    sta $2239
L1c4e               rts
                    
L1c4f               cmp #$5f
                    bne L1c58
                    sta $2236,x
                    beq L1c83
L1c58               tay
                    and #$7f
                    sta $223a,x
                    bne L1c6a
                    tya
                    and #$80
                    bmi L1c75
                    sta $2236,x
                    beq L1c83
L1c6a               clc
                    adc #$00
                    clc
                    adc $2239
                    clc
                    adc $2216,x
L1c75               sta $2236,x
                    tya
                    bpl L1c89
                    lda $22a7,x
                    bmi L1c83
                    sta $22a3,x
L1c83               jsr S1b1b
                    jmp L1f17
                    
L1c89               dec $2222,x
                    ldy $222c,x
                    lda $1079,y
                    cmp #$c0
                    bcs L1cb0
                    cmp #$80
                    and #$20
                    beq L1cab
                    bcc L1ca0
                    lda #$01
L1ca0               ldy $1cd4
                    sta d406_sVoc1SusRel,y
                    lda #$0f
                    sta d405_sVoc1AttDec,y
L1cab               lda #$fe
                    sta $22b1,x
L1cb0               lda $2243,x
                    bmi L1cbc
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $2247,x
L1cbc               lda #$ff
                    sta $2243,x
                    jsr S1b1b
                    jmp L200e
                    
L1cc7               lda $1991
                    bne L1cce
                    beq L1cf5
L1cce               lda $2243,x
                    bmi L1ce3
                    ldy #$00
                    ora $2240,x
                    sta d406_sVoc1SusRel,y
                    lda #$fe
                    sta $2243,x
                    sta $22b1,x
L1ce3               lda $2236,x
                    beq L1cf0
                    cmp #$80
                    bne L1cf5
                    lda #$fe
                    bne L1cf2
L1cf0               lda #$ff
L1cf2               sta $22b1,x
L1cf5               lda $2285,x
                    beq L1d17
                    dec $2279,x
                    bne L1d0d
                    lda $227f,x
                    sta $2279,x
                    lda $227c,x
                    eor #$01
                    sta $227c,x
L1d0d               lda $227c,x
                    beq L1d17
                    txa
                    clc
                    adc #$03
                    tax
L1d17               lda $2282,x
                    bmi L1d1e
                    bne L1d24
L1d1e               ldx $1be0
                    jmp L1dd0
                    
L1d24               asl a
                    asl a
                    tay
                    sty $fe
                    stx $ff
                    lda $2288,x
                    bne L1d48
                    lda #$02
                    sta $2288,x
                    bcs L1d48
                    lda $124b,y
                    pha
                    and #$f0
                    sta $2294,x
                    pla
                    and #$0f
                    sta $229a,x
                    bpl L1dbe
L1d48               lda $124c,y
                    pha
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    tax
                    stx $1d8a
                    pla
                    and #$0f
                    cmp $1d8a
                    bcc L1d60
                    sta $1d8a
                    .byte $a9 ; (hidden byte?) 
L1d60               tax
                    stx $1da1
                    ldx $ff
                    lda #$90
                    dec $2288,x
                    bne L1d6f
                    lda #$b0
L1d6f               sta $1d78
                    inc $2288,x
                    lda $2294,x
                    bcc L1d8f
                    clc
                    adc $124d,y
                    sta $2294,x
                    lda $229a,x
                    adc #$00
                    sta $229a,x
                    cmp #$0e
                    bcs L1da7
                    bcc L1dbe
L1d8f               sec
                    sbc $124d,y
                    sta $2294,x
                    lda $229a,x
                    sbc #$00
                    sta $229a,x
                    bcc L1da4
                    cmp #$01
                    bcs L1dbe
L1da4               inc $229a,x
L1da7               lda #$00
                    sta $2294,x
                    lda $124e,y
                    bpl L1db4
                    dec $2288,x
L1db4               dec $2288,x
                    bne L1dbe
                    and #$7f
                    sta $2282,x
L1dbe               ldy $1cd4
                    lda $2294,x
                    sta d402_sVoc1PWidthLo,y
                    lda $229a,x
                    sta d403_sVoc1PWidthHi,y
                    ldx $1be0
L1dd0               lda $1991
                    bne L1dd8
                    jmp L1f17
                    
L1dd8               lda $2254,x
                    bne L1de0
                    jmp L1e6c
                    
L1de0               bmi L1dec
                    ora #$80
                    sta $2254,x
                    and #$7f
                    jmp L1e9a
                    
L1dec               ldy $225e,x
                    lda $2261,x
                    clc
                    adc $2137,y
                    sta $fe
                    lda $2264,x
                    adc $2197,y
                    pha
                    ldy $225b,x
                    lda $fe
                    sec
                    sbc $2137,y
                    pla
                    sbc $2197,y
                    lda $2261,x
                    bcc L1e21
                    sbc $2267,x
                    sta $2261,x
                    lda $2264,x
                    sbc $226a,x
                    ldy #$b0
                    bne L1e2f
L1e21               adc $2267,x
                    sta $2261,x
                    lda $2264,x
                    adc $226a,x
                    ldy #$90
L1e2f               sty $1e55
                    sta $2264,x
                    ldy $225e,x
                    lda $2261,x
                    clc
                    adc $2137,y
                    sta $fe
                    lda $2264,x
                    adc $2197,y
                    pha
                    sec
                    ldy $225b,x
                    lda $fe
                    sbc $2137,y
                    pla
                    sbc $2197,y
                    bcc L1e69
                    tya
                    sta $2233,x
                    sta $225e,x
                    lda #$00
                    sta $2254,x
                    sta $2261,x
                    sta $2264,x
L1e69               jmp L1f17
                    
L1e6c               lda $226d,x
                    beq L1ebd
                    asl a
                    adc $226d,x
                    tay
                    lda $2276,x
                    bne L1ec0
                    sta $2261,x
                    sta $2264,x
                    lda $129d,y
                    cmp #$80
                    and #$7f
                    sta $2270,x
                    ror a
                    sta $2273,x
                    lda $129c,y
                    sta $2276,x
                    lda $129e,y
                    and #$7f
L1e9a               sta $fe
                    lda #$00
                    sta $226a,x
                    lda $2233,x
                    lsr a
                    clc
                    adc $fe
                    cmp #$60
                    bcc L1eae
                    and #$1f
L1eae               tay
                    lda $2197,y
                    bcc L1eba
                    sta $226a,x
                    lda $2137,y
L1eba               sta $2267,x
L1ebd               jmp L1f17
                    
L1ec0               cmp #$ff
                    beq L1ecc
                    dec $2276,x
                    bne L1ecc
                    inc $226d,x
L1ecc               lda $129e,y
                    bpl L1edf
                    and #$03
                    and #$27
                    bne L1edf
                    sta $1ff4
                    sta $1ffc
                    beq L1f23
L1edf               lda $2261,x
                    ldy $2273,x
                    bmi L1ef7
                    clc
                    adc $2267,x
                    sta $2261,x
                    lda $2264,x
                    adc $226a,x
                    jmp L1f04
                    
L1ef7               sec
                    sbc $2267,x
                    sta $2261,x
                    lda $2264,x
                    sbc $226a,x
L1f04               sta $2264,x
                    dey
                    tya
                    sta $fe
                    bit $fe
                    bvc L1f14
                    eor #$7f
                    ora $2270,x
L1f14               sta $2273,x
L1f17               lda $2261,x
                    sta $1ff4
                    lda $2264,x
                    sta $1ffc
L1f23               ldy $22b4,x
                    lda $10c9,y
                    cmp #$ff
                    bne L1f37
                    lda $118c,y
                    sta $22b4,x
                    tay
                    lda $10c9,y
L1f37               cmp #$fe
                    bne L1f48
                    lda $118c,y
                    sta $22ae,x
                    inc $22b4,x
                    iny
                    lda $10c9,y
L1f48               cmp #$fd
                    bcc L1f81
                    lda $2243,x
                    cmp #$fe
                    beq L1f78
                    lda $118c,y
                    cmp #$80
                    and #$7f
                    sta $223d,x
                    bcs L1f64
                    lda #$ff
                    sta $22b1,x
L1f64               iny
                    ldx $1cd4
                    lda $10c9,y
                    sta d405_sVoc1AttDec,x
                    lda $118c,y
                    sta d406_sVoc1SusRel,x
                    ldx $1be0
                    .byte $24 ; i dont even know 
L1f78               iny
                    iny
                    tya
                    sta $22b4,x
                    lda $10c9,y
L1f81               cmp #$fb
                    bne L1fa5
                    lda $118c,y
                    sta $2285,x
                    lda #$00
                    sta $228b,x
                    iny
                    lda $10c9,y
                    sta $227c,x
                    lda $118c,y
                    sta $227f,x
                    iny
                    tya
                    sta $22b4,x
                    lda $10c9,y
L1fa5               cmp #$90
                    bcc L1fab
                    and #$7f
L1fab               sta $22a0,x
                    bcc L1fe0
                    lda $22b7,x
                    bmi L1fe0
                    tay
                    sec
                    lda $22be,x
                    sbc #$40
                    bcs L1fc1
                    lda $128c,y
L1fc1               sta $22be,x
                    ldy $22c1,x
                    bcs L1fcc
                    inc $22c1,x
L1fcc               lda $128f,y
                    bpl L1fe5
                    bcs L1fe5
                    pha
                    ldy $22b7,x
                    lda $128b,y
                    sta $22c1,x
                    pla
                    bne L1fe5
L1fe0               lda $118c,y
                    bmi L1fe9
L1fe5               clc
                    adc $2233,x
L1fe9               and #$7f
                    tay
                    ldx $1cd4
                    lda $2137,y
                    clc
                    adc #$00
                    sta d400_sVoc1FreqLo,x
                    lda $2197,y
                    adc #$00
                    sta d401_sVoc1FreqHi,x
                    ldx $1be0
                    dec $22ae,x
                    bpl L200e
                    inc $22ae,x
                    inc $22b4,x
L200e               ldy $1cd4
                    lda $22b1,x
                    and $22a0,x
                    ora $22a3,x
                    sta d404_sVoc1Control,y
L201d               dex
                    bmi L2023
                    jmp L1987
                    
L2023               inc $1ed4
                    lda #$01
                    ldy $1991
                    bne L2030
                    jmp L2133
                    
L2030               lda #$00
                    beq L2069
                    dec $224f
                    bpl L2069
                    clc
                    adc #$01
                    lsr a
                    sta $224f
                    ldy #$00
                    bcc L2055
                    lda #$07
                    sta $1984
                    lda $20f0
                    cmp #$0f
                    bcc L2066
                    sty L2030 + 1
                    bcs L2069
L2055               dec $20f0
                    bpl L2069
                    lda $1984
                    sta $2045
                    sty $1984
                    sty L2030 + 1
L2066               inc $20f0
L2069               lda #$05
                    and #$7f
                    beq L20e8
                    asl a
                    asl a
                    tay
                    lda #$02
                    bne L209b
                    lda #$02
                    sta $2073
                    lda #$b0
                    sta $20b9
                    bcs L209b
                    ldx #$0d
                    lda $10b9,x
                    pha
                    asl a
                    asl a
                    asl a
                    asl a
                    sta $20eb
                    pla
                    and #$f0
                    sta $20f2
                    lda $126f,y
                    sta $20b8
L209b               lda $1270,y
                    pha
                    asl a
                    asl a
                    asl a
                    asl a
                    tax
                    stx $20c0
                    pla
                    and #$f0
                    cmp $20c0
                    bcc L20b3
                    sta $20c0
                    .byte $a9 ; what
L20b3               tax
                    stx $20ca
                    lda #$8d
                    bcs L20c5
                    clc
                    adc $1271,y
                    cmp #$c0
                    bcc L20e2
                    bcs L20cd
L20c5               sec
                    sbc $1271,y
                    cmp #$40
                    bcs L20e2
L20cd               ldx $1272,y
                    bpl L20d5
                    dec $2073
L20d5               dec $2073
                    bne L20dd
                    stx L2069 + 1
L20dd               ldx #$90
                    stx $20b9
L20e2               sta $20b8
                    sta d416_sFiltFreqHi
L20e8               lda #$04
                    ora #$f0
                    sta d417_sFiltControl
                    lda #$0f
                    ora #$30
                    sta d418_sFiltMode
                    lda $1984
                    beq L2133
                    dec $19a9
                    bpl L2133
                    dec $221e
                    dec $221f
                    dec $2220
                    dec $2221
                    lda #$00
                    bmi L2125
                    tay
                    lda $129e,y
                    clc
                    adc #$00
                    tay
                    lda $129d,y
                    bpl L2122
                    ldy #$ff
                    sty $2116
L2122               inc $2116
L2125               and #$7f
                    sta $19a9
                    cmp #$03
                    bcc L2130
                    lda #$02
L2130               sta $19ad
L2133               sta $1991
                    rts
                    
                    .binary "ping2.bin"
                    
L22c8               lda $12a8,x
                    sta $1984
                    sta $2045
                    lda $12a9,x
                    sta $210d
                    ldy $12aa,x
                    ldx #$03
L22dc               lda $1984
                    and $21fa,x
                    beq L2325
                    lda #$01
                    sta $1991
                    sta $19a9
                    sta $19ad
                    sta $220a,x
                    lda #$00
                    sta $2116
                    sta $221a,x
                    sta $2225,x
                    sta $2216,x
                    lda #$fe
                    sta $22b1,x
                    sta $2230,x
                    sta $221e,x
                    lda $12ab,y
                    sta $2202,x
                    sta $220e,x
                    lda $12ae,y
                    sta $2206,x
                    sta $2212,x
                    dey
                    tya
                    pha
                    jsr S1b1b
                    pla
                    tay
L2325               dex
                    bpl L22dc
                    lda #$0f
                    sta $20f0
                    lda #$00
L232f               sta L2030 + 1
                    sta $224f
                    rts
                    
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $ff 
