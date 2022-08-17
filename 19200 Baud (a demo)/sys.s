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

init:
  sei
  lda #$55
  sta scroll
  stz count
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
  jmp textstart
irq:
  pha
  phx
  phy
  lda #1
  sta irqst
  inc framecount
  ; IRQ code goes here
  lda #$40
  sta $b00d
  jsr putbut
  jsr PlaySid
  stz scrollinfo
  lda scroll
  beq scrollercheck
  ply
  plx
  pla
  rti

scrollercheck:
  lda count
  sec
  sbc #10
  beq nott
  inc count
  ply
  plx
  pla
  rti
nott:
  lda #$55
  sta scrollinfo
  stz count
  ldx #<thingy
  ldy #>thingy
  jsr w_acia_full
  ldx sco
  ;lda scrollmsg,x
  ;beq endscroll
  ;jsr print_chara
  inc sco
  ply
  plx
  pla
  rti
endscroll:
  lda #$55
  sta scroll
  stz scrollinfo
  ply
  plx
  pla
  rti

thingy:
  .byte $16, $0e, 38, $00

InitSid             ldx #$63
                    stx $b004
                    stx $b007
                    ldy #$26
                    sty $b005
                    sty $b006

                    jmp initsid2

putbut              ldx #$63
                    stx $b004
                    stx $b007
                    ldy #$26
                    sty $b005
                    sty $b006
                    rts


	.org $1000

L1000               sei
                    lda #$01
                    sta $b800
                    lda #$7f
                    sta $dc0d
                    lda #$35
                    sta $01
                    lda #$00
                    ldx #$00
                    ldy #$00
                    jsr S1100
                    lda #$37
                    sta $01
                    lda #$34
                    sta $0314
                    lda #$10
                    sta $0315
                    lda #$3a
                    sta $b800
                    lda #$1b
                    sta $d011
                    cli
L1031               jmp L1031
                    
L1034               lda #$01
                    sta $b800
                    lda #$35
                    sta $01
                    dec $b800
                    jsr L1103
                    inc $b800
                    lda #$37
                    sta $01
                    inc $104e
                    lda #$78
                    and #$01
                    tax
                    lda $105b,x
                    sta $b800
                    jmp $ea7e

	.binary "sys1.bin"

S1100               jmp L1774
                    
L1103               jmp L11f2
                    
L1106               and $4d20
                    eor $53,x
                    eor #$43
                    jsr $5942
                    jsr $4d41
                    lsr a
                    bit $4e20
                    eor ($4d,x)
                    eor $44
                    jsr $5327
                    eor $3453,y
                    bmi L115c
                    rol $27,x
                    jsr S202d

	.binary "sys2.bin"

L115c		    rol $04
		    rol $9b,x

	.binary "sys3.bin"

L11f2               lda #$4f
                    sta d418_sFiltMode
                    bne L11fa
                    rts
                    
L11fa               ldx #$02
L11fc               stx $aa
                    lda $1159,x
                    sta $ab
                    tay
                    lda #$01
                    bne L1215
                    lda $1171,x
                    beq L1210
                    jmp L1353
                    
L1210               dec $1186,x
                    beq L1218
L1215               jmp L14ea
                    
L1218               sta $11bc,x
                    sta d406_sVoc1SusRel,y
                    lda $115f,x
                    sta $a5
                    lda $1162,x
                    sta $a6
                    ldy L115c,x
                    lda ($a5),y
                    beq L1264
                    jmp L12d1
                    
L1232               ldx $aa
                    dex
                    bpl L11fc
                    lda $1205
                    eor #$01
                    sta $1205
                    ldy $118c
                    lda #$01
                    ora #$f0
                    sta d417_sFiltControl
                    ldy #$ef
L124b               lda $246e,y
                    bne L1254
                    dey
                    lda $246e,y
L1254               cmp #$ff
                    bne L125c
                    ldy #$ea
                    beq L124b
L125c               sta d416_sFiltFreqHi
                    iny
                    sty $124a
                    rts
                    
L1264               sta L115c,x
                    sta $11d1,x
                    lda $1165,x
                    beq L1275
                    dec $1165,x
                    jmp L12cc
                    
L1275               lda $116b,x
                    sta $a7
                    lda $116e,x
                    sta $a8
                    ldy $1168,x
                    lda ($a7),y
                    bne L128f
                    iny
                    lda ($a7),y
                    sta $1168,x

                    tay
                    lda ($a7),y
L128f               bpl L12b3
                    cmp #$c0
                    bcc L12a9
                    cmp #$ff
                    bne L129f
                    lda #$00
                    sta L11f2 + 1
                    rts
                    
L129f               and #$3f
                    sta $1165,x
                    iny
                    lda ($a7),y
                    bne L12b3
L12a9               and #$1f
                    sta $1177,x
                    iny
                    lda ($a7),y
                    bmi L129f
L12b3               sta $a7
                    iny
                    tya
                    sta $1168,x
                    ldy $a7
                    lda $1874,y
                    sta $115f,x
                    sta $a5
                    lda $20c7,y
                    sta $1162,x
                    sta $a6
L12cc               ldy L115c,x
                    lda ($a5),y
L12d1               sta $1171,x
                    cmp #$60
                    bcc L132f
                    cmp #$80
                    bcc L1310
                    cmp #$c0
                    bcc L1302
L12e0               and #$3f
                    sta $11bc,x
                    sty $a9
                    tay
                    lda $20e6,y
                    sta $11bf,x
                    lda $20e7,y
                    sta $11c2,x
                    lda $20e8,y
                    sta $11c5,x
                    ldy $a9
                    iny
                    lda ($a5),y
                    jmp L132f
                    
L1302               and #$3f
                    sta $118c,x
                    iny
                    lda ($a5),y
                    bmi L12e0
                    cmp #$60
                    bcc L132f
L1310               and #$1f
                    sta $11d1,x
                    sty $a9
                    tay
                    lda $2434,y
                    tay
                    lda $2439,y
                    sta $11da,x
                    sta $11dd,x
                    iny
                    tya
                    sta $11d4,x
                    ldy $a9
                    iny
                    lda ($a5),y
L132f               sta $1174,x
                    clc
                    adc $1177,x
                    sta $117a,x
                    iny
                    lda ($a5),y
                    asl a
                    sec
                    sbc #$01
                    sta $1186,x
                    sta $1189,x
                    iny
                    tya
                    sta L115c,x
                    lda #$00
                    bne L1352
                    jmp L1232
                    
L1352               rts
                    
L1353               ldy $118c,x
                    sty $a9
                    lda $23a9,y
                    sta $a5
                    dex
                    bpl L137c
                    and #$07
                    sta $1243
                    lda $22e9,y
                    bmi L137c
                    tay
                    lda $244c,y
                    tay
                    lda $246e,y
                    sta L11f2 + 1
                    iny
                    sty $1259
                    sty $124a
L137c               ldx $a9
                    ldy $ab
                    lda $2269,x
                    sta d405_sVoc1AttDec,y
                    lda $22a9,x
                    sta d406_sVoc1SusRel,y
                    ldx $aa
                    lda #$00
                    sta $1183,x
                    sta $11b3,x
                    sta $1171,x
                    lda $a5
                    and #$20
                    bne L13b2
                    sta $1195,x
                    sta $119e,x
                    ldx $a9
                    lda $20e9,x
                    sta d403_sVoc1PWidthHi,y
                    ldx $aa
                    sta $1198,x
L13b2               ldy $a9
                    lda $a5
                    and #$10
                    sta $11e6,x
                    beq L142a
                    lda $2369,y
                    sta $11ef,x
                    beq L13f5
                    ldx $2329,y
                    lda $2569,x
                    ldx $aa
                    sta $11e9,x
                    sta $11ec,x
                    inc $11ec,x
                    tay
                    lda $256e,y
                    sta $a7
                    ldx $25e2,y
                    lda $17af,x
                    ldy $ab
                    sta d400_sVoc1FreqLo,y
                    lda $180f,x
                    sta d401_sVoc1FreqHi,y
                    lda $a7
                    sta d404_sVoc1Control,y
                    jmp L1232
                    
L13f5               ldx $2329,y
                    lda $2569,x
                    ldx $aa
                    sta $11e9,x
                    sta $11ec,x
                    inc $11ec,x
                    tay
                    lda $256e,y
                    sta $a7
                    lda $25e2,y
                    clc
                    adc $1174,x
                    tax
                    lda $17af,x
                    ldy $ab
                    sta d400_sVoc1FreqLo,y
                    lda $180f,x
                    sta d401_sVoc1FreqHi,y
                    lda $a7
                    sta d404_sVoc1Control,y
                    jmp L1232
                    
L142a               lda $a5
                    bpl L144f
                    lda #$81
                    ldy $ab
                    sta d404_sVoc1Control,y
                    lda #$bf
                    sta d400_sVoc1FreqLo,y
                    sta d401_sVoc1FreqHi,y
                    ldy $117a,x
                    lda $180f,y
                    sta $1192,x
                    lda $17af,y
                    sta $118f,x
                    jmp L1472
                    
L144f               lda $21a9,y
                    ldy $ab
                    sta d404_sVoc1Control,y
                    ldy $117a,x
                    lda $180f,y
                    sta $a7
                    lda $17af,y
                    ldy $ab
                    sta d400_sVoc1FreqLo,y
                    sta $118f,x
                    lda $a7
                    sta d401_sVoc1FreqHi,y
                    sta $1192,x
L1472               lda $a5
                    and #$40
                    sta $11a7,x
                    beq L1499
                    ldy $a9
                    lda $2329,y
                    sta $11aa,x
                    lda $2369,y
                    sta $a7
                    and #$0f
                    sta $11b0,x
                    sta $11b6,x
                    lda $a7
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $11ad,x
L1499               lda $11bc,x
                    beq L14aa
                    lda $11c5,x
                    sta $11cb,x
                    lda $11bf,x
                    sta $11c8,x
L14aa               lda $a5
                    ldy $a9
                    and #$20
                    bne L14c1
                    lda $2169,y
                    sta $11a1,x
                    sta $11a4,x
                    lda $2129,y
                    sta $119b,x
L14c1               lda $2229,y
                    sta $1180,x
                    lda $a5
                    and #$08
                    sta $117d,x
                    lda $11d1,x
                    sta $11ce,x
                    beq L14e7
                    lda $11d4,x
                    sta $11d7,x
                    tay
                    lda $2439,y
                    clc
                    adc $117a,x
                    sta $11e0,x
L14e7               jmp L1232
                    
L14ea               ldx $aa
                    lda $11e6,x
                    beq L154f
                    lda $11ef,x
                    bne L151c
                    ldy $11ec,x
                    lda $256e,y
                    beq L151c
                    sta $a7
                    inc $11ec,x
                    ldx $25e2,y
                    ldy $ab
                    lda $180f,x
                    sta d401_sVoc1FreqHi,y
                    lda $17af,x
                    sta d400_sVoc1FreqLo,y
                    lda $a7
                    sta d404_sVoc1Control,y
                    jmp L1232
                    
L151c               ldy $11ec,x
                    lda $256e,y
                    beq L1547
                    sta $a7
                    inc $11ec,x
                    lda $25e2,y
                    clc
                    adc $1174,x
                    tax
                    ldy $ab
                    lda $180f,x
                    sta d401_sVoc1FreqHi,y
                    lda $17af,x
                    sta d400_sVoc1FreqLo,y
                    lda $a7
                    sta d404_sVoc1Control,y
                    jmp L1232
                    
L1547               ldy $ab
                    sta d404_sVoc1Control,y
                    jmp L1232
                    
L154f               lda $118c,x
                    sta $a9
                    lda $119e,x
                    bne L1584
                    lda $1195,x
                    clc
                    adc $119b,x
                    ldy $ab
                    sta $1195,x
                    sta d402_sVoc1PWidthLo,y
                    lda $1198,x
                    adc #$00
                    sta $1198,x
                    sta d403_sVoc1PWidthHi,y
                    dec $11a4,x
                    bne L15ae
                    inc $119e,x
                    lda $11a1,x
                    sta $11a4,x
                    jmp L15ae
                    
L1584               lda $1195,x
                    sec
                    sbc $119b,x
                    ldy $ab
                    sta d402_sVoc1PWidthLo,y
                    sta $1195,x
                    lda $1198,x
                    adc #$ff
                    sta $1198,x
                    sta d403_sVoc1PWidthHi,y
                    dec $11a4,x
                    bne L15ae
                    lda #$00
                    sta $119e,x
                    lda $11a1,x
                    sta $11a4,x
L15ae               lda $118f,x
                    sta d400_sVoc1FreqLo,y
                    lda $1192,x
                    sta d401_sVoc1FreqHi,y
                    lda $1183,x
                    bne L15f4
                    lda $117d,x
                    bne L15e2
                    lda $1189,x
                    sec
                    sbc $1180,x
                    cmp $1186,x
                    beq L15d2
                    bne L15ea
L15d2               ldy $a9
                    lda $21e9,y
                    ldy $ab
                    sta d404_sVoc1Control,y
                    inc $1183,x
                    jmp L15f4
                    
L15e2               lda $1186,x
                    cmp $1180,x
                    beq L15d2
L15ea               ldy $a9
                    lda $21a9,y
                    ldy $ab
                    sta d404_sVoc1Control,y
L15f4               lda $11a7,x
                    bne L15fc
                    jmp L16b8
                    
L15fc               lda $11aa,x
                    beq L1607
                    dec $11aa,x
                    jmp L16b8
                    
L1607               ldy $11b3,x
                    beq L1644
                    dey
                    beq L1667
                    dey
                    beq L1615
                    jmp L168a
                    
L1615               ldy $117a,x
                    lda $11ad,x
                    sta $a7
                    lda $118f,x
L1620               sec
                    sbc $180e,y
                    bcs L1629
                    dec $1192,x
L1629               dec $a7
                    bpl L1620
                    sta $118f,x
                    dec $11b6,x
                    bmi L1638
                    jmp L16b8
                    
L1638               inc $11b3,x
                    lda $11b0,x
                    sta $11b6,x
                    jmp L16b8
                    
L1644               ldy $117a,x
                    lda $11ad,x
                    sta $a7
                    lda $118f,x
L164f               clc
                    adc $180f,y
                    bcc L1658
                    inc $1192,x
L1658               dec $a7
                    bpl L164f
                    sta $118f,x
                    dec $11b6,x
                    bmi L1638
                    jmp L16b8
                    
L1667               ldy $117a,x
                    lda $11ad,x
                    sta $a7
                    lda $118f,x
L1672               sec
                    sbc $180f,y
                    bcs L167b
                    dec $1192,x
L167b               dec $a7
                    bpl L1672
                    sta $118f,x
                    dec $11b6,x
                    bmi L1638
                    jmp L16b8
                    
L168a               ldy $117a,x
                    lda $11ad,x
                    sta $a7
                    lda $118f,x
L1695               clc
                    adc $180e,y
                    bcc L169e
                    inc $1192,x
L169e               dec $a7
                    bpl L1695
                    sta $118f,x
                    dec $11b6,x
                    bmi L16ad
                    jmp L16b8
                    
L16ad               lda #$00
                    sta $11b3,x
                    lda $11b0,x
                    sta $11b6,x
L16b8               lda $11bc,x
                    bne L16c0
                    jmp L1720
                    
L16c0               lda $11c8,x
                    beq L16cb
                    dec $11c8,x
                    jmp L1720
                    
L16cb               lda $11c2,x
                    bmi L16f7
                    sta $a7
                    ldy $117a,x
                    lda $118f,x
                    sec
L16d9               sbc $180f,y
                    bcs L16e2
                    sec
                    dec $1192,x
L16e2               dec $a7
                    bne L16d9
                    sta $118f,x
                    dec $11cb,x
                    lda $11cb,x
                    bne L16f4
                    sta $11bc,x
L16f4               jmp L1232
                    
L16f7               and #$7f
                    sta $a7
                    ldy $117a,x
                    lda $118f,x
                    clc
L1702               adc $180f,y
                    bcc L170b
                    inc $1192,x
                    clc
L170b               dec $a7
                    bpl L1702
                    sta $118f,x
                    dec $11cb,x
                    lda $11cb,x
                    bne L16f4
                    sta $11bc,x
L171d               jmp L1232
                    
L1720               lda $11ce,x
                    beq L171d
                    dec $11dd,x
                    beq L1730
                    lda $11e0,x
                    jmp L1748
                    
L1730               lda $11da,x
                    sta $11dd,x
                    inc $11d7,x
                    ldy $11d7,x
L173c               lda $2439,y
                    bmi L175a
                    clc
                    adc $117a,x
                    sta $11e0,x
L1748               tax
                    ldy $ab
                    lda $17af,x
                    sta d400_sVoc1FreqLo,y
                    lda $180f,x
                    sta d401_sVoc1FreqHi,y
                    jmp L1232
                    
L175a               and #$7f
                    beq L1768
                    lda $11d4,x
                    sta $11d7,x
                    tay
                    jmp L173c
                    
L1768               sta $11ce,x
                    lda $11e0,x
                    sta $117a,x
                    jmp L1232
                    
L1774               ldx #$17
L1776               lda #$00
                    sta d400_sVoc1FreqLo,x
                    dex
                    bpl L1776
                    ldx #$02
                    stx $134c
                    stx L11f2 + 1
L1786               stx $aa
                    lda $1872,x
                    sta $116b,x
                    lda $186f,x
                    sta $116e,x
                    sta $1171,x
                    lda #$00
                    sta $1165,x
                    sta $1168,x
                    sta $1177,x
                    jsr L1264
                    ldx $aa
                    dex
                    bpl L1786
                    inx
                    stx $134c
                    rts

	.binary "sys4.bin"

S202d               dey
                    eor ($06),y

	.binary "sys5.bin"

initsid2            jsr S1100
                    lda #$00
                    sta PlaySid + 1
                    rts
                    
PlaySid             lda #$00
                    inc PlaySid + 1
                    and #$01
                    asl a
                    tax
                    nop
                    lda $2681,x
                    sta $dc05
                    lda $2682,x
                    sta $dc04
                    jmp L1103

	.binary "sys6.bin"
