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
  lda #$90
  sta $b00e
  ; IRQ Inits Go Here
  lda #0 ; Song Number
  sta $b00c
  jsr InitSid
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  ; IRQ code goes here
  lda #$10
  sta $b00d
  jsr PlaySid
  nop
  rti

	.org $1000

InitSid             jmp L113d
                    
PlaySid             jmp L1141

	.binary "hey_ffmmw.bin"
                    
S1040               lda $1652,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $14cb,x
                    tya
L104d               sta $14a2,x
                    lda $1491,x
                    sta $14a1,x
                    rts
                    
L1057               sta $14fa,x
                    rts
                    
L105b               sta $14fb,x
                    rts
                    
L105f               sta $14a5,x
                    rts
                    
L1063               sta $14a4,x
                    lda #$00
                    sta $14cd,x
                    rts
                    
L106c               sta $14a6,x
                    lda #$00
                    sta $14a7,x
                    rts
                    
L1075               ldy #$00
                    sty $1187
L107a               sta L1182 + 1
                    rts
                    
L107e               sta $11d1
                    beq L107a
                    rts
                    
L1084               sta L11cb + 1
                    rts
                    
L1088               cmp #$10
                    bcs L1090
                    sta $11d8
                    rts
                    
L1090               sta $103f
                    rts
                    
L1094               tay
                    lda $179f,y
                    sta $101b
                    lda $17a6,y
                    sta $101c
                    lda #$00
                    beq L10a7
                    bmi L10b1
L10a7               sta $14b8
                    sta $14bf
                    sta $14c6
                    rts
                    
L10b1               and #$7f
                    sta $14b8,x
                    rts
                    
L10b7               dec $14cc,x
L10ba               jmp L137e
                    
L10bd               beq L10ba
                    lda $14cc,x
                    bne L10b7
                    lda $179f,y
                    bmi L10cd
                    ldy #$00
                    sty $fd
L10cd               and #$7f
                    sta $10d8
                    lda $14cb,x
                    bmi L10df
                    cmp #$00
                    bcc L10e0
                    beq L10df
                    eor #$ff
L10df               clc
L10e0               adc #$02
                    sta $14cb,x
                    lsr a
                    bcc L1110
                    bcs L1127
                    tya
                    beq L1137
                    lda #$00
                    cmp #$02
                    bcc L1110
                    beq L1127
                    ldy $14ba,x
                    lda $14f5,x
                    sbc $150e,y
                    pha
                    lda $14f6,x
                    sbc $156e,y
                    tay
                    pla
                    bcs L1120
                    adc $fc
                    tya
                    adc $fd
                    bpl L1137
L1110               lda $14f5,x
                    adc $fc
                    sta $14f5,x
                    lda $14f6,x
                    adc $fd
                    jmp L137b
                    
L1120               sbc $fc
                    tya
                    sbc $fd
                    bmi L1137
L1127               lda $14f5,x
                    sbc $fc
                    sta $14f5,x
                    lda $14f6,x
                    sbc $fd
                    jmp L137b
                    
L1137               lda $14ba,x
                    jmp L1369
                    
L113d               sta $114f
                    rts
                    
L1141               ldx #$18
L1143               lda $14f5,x
                    sta d400_sVoc1FreqLo,x
                    dex
                    bpl L1143
                    ldx #$00
                    ldy #$00
                    bmi L1182
                    txa
                    ldx #$29
L1155               sta $148c,x
                    dex
                    bpl L1155
                    sta $150a
                    sta $11d1
                    sta L1182 + 1
                    stx $114f
                    tax
                    jsr S1172
                    ldx #$07
                    jsr S1172
                    ldx #$0e
S1172               lda #$05
                    sta $14b8,x
                    lda #$01
                    sta $14b9,x
                    sta $14bb,x
                    jmp L1451
                    
L1182               ldy #$00
                    beq L11cb
                    lda #$00
                    bne L11ad
                    lda $171e,y
                    beq L11a1
                    bpl L11aa
                    asl a
                    sta $11d6
                    lda $175e,y
                    sta $11d1
                    lda $171f,y
                    bne L11bf
                    iny
L11a1               lda $175e,y
                    sta L11cb + 1
                    jmp L11bc
                    
L11aa               sta $1187
L11ad               lda $175e,y
                    clc
                    adc L11cb + 1
                    sta L11cb + 1
                    dec $1187
                    bne L11cd
L11bc               lda $171f,y
L11bf               cmp #$ff
                    iny
                    tya
                    bcc L11c8
                    lda $175e,y
L11c8               sta L1182 + 1
L11cb               lda #$00
L11cd               sta $150b
                    lda #$00
                    sta $150c
                    lda #$00
                    ora #$0f
                    sta $150d
                    jsr S11e6
                    ldx #$07
                    jsr S11e6
                    ldx #$0e
S11e6               dec $14b9,x
                    beq L1216
                    bpl L1202
                    lda $14b8,x
                    cmp #$02
                    bcs L11ff
                    tay
                    eor #$01
                    sta $14b8,x
                    lda $101b,y
                    sbc #$00
L11ff               sta $14b9,x
L1202               jmp L12d9
                    
L1205               sbc #$d0
                    inc $148e,x
                    cmp $148e,x
                    bne L125b
                    lda #$00
                    sta $148e,x
                    beq L1256
L1216               ldy $1491,x
                    lda $1006,y
                    sta $12cb
                    sta $12d7
                    lda $148f,x
                    bne L125b
                    ldy $14b6,x
                    lda $15ce,y
                    sta $fc
                    lda $15d1,y
                    sta $fd
                    ldy $148c,x
                    lda ($fc),y
                    cmp #$ff
                    bcc L1243
                    iny
                    lda ($fc),y
                    tay
                    lda ($fc),y
L1243               cmp #$e0
                    bcc L124f
                    sbc #$f0
                    sta $148d,x
                    iny
                    lda ($fc),y
L124f               cmp #$d0
                    bcs L1205
                    sta $14b7,x
L1256               iny
                    tya
                    sta $148c,x
L125b               ldy $14bb,x
                    lda $1670,y
                    sta $14e5,x
                    lda $14a3,x
                    beq L12d3
                    sec
                    sbc #$60
                    sta $14ba,x
                    lda #$00
                    sta $14a1,x
                    sta $14a3,x
                    lda $1661,y
                    sta $14cc,x
                    lda $1652,y
                    sta $14a2,x
                    lda $1491,x
                    cmp #$03
                    beq L12d3
                    lda $167f,y
                    beq L129b
                    cmp #$fe
                    bcs L1298
                    sta $14a5,x
                    lda #$ff
L1298               sta $14bc,x
L129b               lda $1634,y
                    beq L12a8
                    sta $14a6,x
                    lda #$00
                    sta $14a7,x
L12a8               lda $1643,y
                    beq L12b5
                    sta L1182 + 1
                    lda #$00
                    sta $1187
L12b5               lda $1625,y
                    sta $14a4,x
                    lda $1616,y
                    sta $14fb,x
                    lda $1607,y
                    sta $14fa,x
                    lda $1492,x
                    jsr S1040
                    jmp L1451
                    
L12d0               jmp L1461
                    
L12d3               lda $1492,x
                    jsr S1040
L12d9               ldy $14a4,x
                    beq L1318
                    lda $168e,y
                    cmp #$10
                    bcs L12ef
                    cmp $14cd,x
                    beq L12f8
                    inc $14cd,x
                    bne L1318
L12ef               sbc #$10
                    cmp #$e0
                    bcs L12f8
                    sta $14a5,x
L12f8               lda $168f,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1304
                    lda $16c0,y
L1304               sta $14a4,x
                    lda #$00
                    sta $14cd,x
                    lda $168d,y
                    cmp #$e0
                    bcs L12d0
                    lda $16bf,y
                    bne L1362
L1318               ldy $14a1,x
                    sty $10ee
                    lda $1016,y
                    sta L135f + 1
                    ldy $14a2,x
L1327               lda $179f,y
                    bmi L1336
                    sta $fd
                    lda $17a6,y
                    sta $fc
                    jmp L135f
                    
L1336               lda $17a6,y
                    sta $1352
                    sty L135b + 1
                    ldy $14e6,x
                    lda $150f,y
                    sec
                    sbc $150e,y
                    sta $fc
                    lda $156f,y
                    sbc $156e,y
                    ldy #$00
                    beq L135b
L1355               lsr a
                    ror $fc
                    dey
                    bne L1355
L135b               ldy #$00
                    sta $fd
L135f               jmp L10bd
                    
L1362               bpl L1369
                    adc $14ba,x
                    and #$7f
L1369               sta $14e6,x
                    tay
                    lda #$00
                    sta $14cb,x
                    lda $150e,y
                    sta $14f5,x
                    lda $156e,y
L137b               sta $14f6,x
L137e               ldy $14a6,x
                    beq L13c4
                    lda $14a7,x
                    bne L139c
                    lda $16f2,y
                    bpl L1399
                    sta $14f8,x
                    lda $1708,y
                    sta $14f7,x
                    jmp L13b5
                    
L1399               sta $14a7,x
L139c               lda $1708,y
                    clc
                    bpl L13a5
                    dec $14f8,x
L13a5               adc $14f7,x
                    sta $14f7,x
                    bcc L13b0
                    inc $14f8,x
L13b0               dec $14a7,x
                    bne L13c4
L13b5               lda $16f3,y
                    cmp #$ff
                    iny
                    tya
                    bcc L13c1
                    lda $1708,y
L13c1               sta $14a6,x
L13c4               lda $14b9,x
                    cmp $14e5,x
                    beq L13cf
                    jmp L1451
                    
L13cf               ldy $14b7,x
                    lda $15d4,y
                    sta $fc
                    lda $15ee,y
                    sta $fd
                    ldy $148f,x
                    lda ($fc),y
                    cmp #$40
                    bcc L13fd
                    cmp #$60
                    bcc L1407
                    cmp #$c0
                    bcc L141b
                    lda $1490,x
                    bne L13f4
                    lda ($fc),y
L13f4               adc #$00
                    sta $1490,x
                    beq L1448
                    bne L1451
L13fd               sta $14bb,x
                    iny
                    lda ($fc),y
                    cmp #$60
                    bcs L141b
L1407               cmp #$50
                    and #$0f
                    sta $1491,x
                    beq L1416
                    iny
                    lda ($fc),y
                    sta $1492,x
L1416               bcs L1448
                    iny
                    lda ($fc),y
L141b               cmp #$bd
                    bcc L1425
                    beq L1448
                    ora #$f0
                    bne L1445
L1425               adc $148d,x
                    sta $14a3,x
                    lda $1491,x
                    cmp #$03
                    beq L1448
                    lda $14bb,x
                    cmp #$0c
                    bcs L145b
                    lda #$00
                    sta $14fb,x
                    lda #$0f
                    sta $14fa,x
L1443               lda #$fe
L1445               sta $14bc,x
L1448               iny
                    lda ($fc),y
                    beq L144e
                    tya
L144e               sta $148f,x
L1451               lda $14a5,x
                    and $14bc,x
                    sta $14f9,x
                    rts
                    
L145b               cmp #$0c
                    bcc L1443
                    bcs L1448
L1461               and #$0f
                    sta $fc
                    lda $16bf,y
                    sta $fd
                    ldy $fc
                    cpy #$05
                    bcs L147e
                    sty $10ee
                    lda $1016,y
                    sta L135f + 1
                    ldy $fd
                    jmp L1327
                    
L147e               lda $1006,y
                    sta $1487
                    lda $fd
                    jsr S1040
                    jmp L137e

	.binary "hey.bin"
