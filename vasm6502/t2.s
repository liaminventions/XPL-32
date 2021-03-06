color = $00
temp = $01

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

DDRA = $b001
PA = $b003

REG = $8801

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
  lda #0 ; Song Number
  jsr InitSid
  lda #$40
  sta $b00d
  cli
  nop
; You can put code you want to run in the backround here.
  jmp code
irq:
  pha
  phx
  phy
  jsr putbut
check:
  sei
  lda poll
  and #$08
  beq cont
  jmp clear
cont:
  jsr PlaySid
  ply
  plx
  pla
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

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

InitSid             jsr putbut
                    jsr InitSid2
                    rts

  .org $1000
InitSid2            jmp L10f4
                    
PlaySid             jmp L10fc
                    
L1006               jmp $08f8
                    
S1009               lda $175f,y
                    jmp L1016
                    
L100f               tay
                    lda #$00
                    sta $14a5,x
                    tya
L1016               sta $147c,x
                    lda $146b,x
                    sta $147b,x
                    rts
                    
S1020               sta $14ba,x
                    rts
                    
L1024               sta $14bb,x
                    rts
                    
L1028               sta $147f,x
                    rts
                    
L102c               sta $147e,x
                    lda #$00
                    sta $14a7,x
                    rts
                    
L1035               sta $1480,x
                    lda #$00
                    sta $1481,x
                    rts
                    
L103e               ldy #$00
                    sty $1137
                    sta L1132 + 1
                    rts
                    
L1047               sta L117b + 1
                    rts
                    
L104b               tay
                    lda $1aca,y
                    sta $1464
                    lda $1ae2,y
                    sta $1465
                    lda #$00
                    beq L105e
                    bmi L1068
L105e               sta $1492
                    sta $1499
                    sta $14a0
                    rts
                    
L1068               and #$7f
                    sta $1492,x
                    rts
                    
L106e               dec $14a6,x
L1071               jmp L131e
                    
L1074               beq L1071
                    lda $14a6,x
                    bne L106e
                    lda $1aca,y
                    bmi L1084
                    ldy #$00
                    sty $81
L1084               and #$7f
                    sta $108f
                    lda $14a5,x
                    bmi L1096
                    cmp #$02
                    bcc L1097
                    beq L1096
                    eor #$ff
L1096               clc
L1097               adc #$02
                    sta $14a5,x
                    lsr a
                    bcc L10c7
                    bcs L10de
                    tya
                    beq L10ee
                    lda #$00
                    cmp #$02
                    bcc L10c7
                    beq L10de
                    ldy $1494,x
                    lda $14a8,x
                    sbc $14cf,y
                    pha
                    lda $14a9,x
                    sbc $152f,y
                    tay
                    pla
                    bcs L10d7
                    adc $80
                    tya
                    adc $81
                    bpl L10ee
L10c7               lda $14a8,x
                    adc $80
                    sta $14a8,x
                    lda $14a9,x
                    adc $81
                    jmp L131b
                    
L10d7               sbc $80
                    tya
                    sbc $81
                    bmi L10ee
L10de               lda $14a8,x
                    sbc $80
                    sta $14a8,x
                    lda $14a9,x
                    sbc $81
                    jmp L131b
                    
L10ee               lda $1494,x
                    jmp L1309
                    
L10f4               sta $10ff
                    rts

L10f8               sta $0988
                    rts
                    
L10fc               ldx #$00
                    ldy #$ff
                    bmi L1132
                    txa
                    ldx #$29
L1105               sta $1466,x
                    dex
                    bpl L1105
                    sta d415_sFiltFreqLo
                    sta $1181
                    sta L1132 + 1
                    stx $10ff
                    tax
                    jsr S1122
                    ldx #$07
                    jsr S1122
                    ldx #$0e
S1122               lda #$05
                    sta $1492,x
                    lda #$01
                    sta $1493,x
                    sta $1495,x
                    jmp L141a
                    
L1132               ldy #$9f
                    beq L117b
                    lda #$00
                    bne L115d
                    lda $197f,y
                    beq L1151
                    bpl L115a
                    asl a
                    sta $1186
                    lda $1a24,y
                    sta $1181
                    lda $1980,y
                    bne L116f
                    iny
L1151               lda $1a24,y
                    sta L117b + 1
                    jmp L116c
                    
L115a               sta $1137
L115d               lda $1a24,y
                    clc
                    adc L117b + 1
                    sta L117b + 1
                    dec $1137
                    bne L117d
L116c               lda $1980,y
L116f               cmp #$ff
                    iny
                    tya
                    bcc L1178
                    lda $1a24,y
L1178               sta L1132 + 1
L117b               lda #$40
L117d               sta d416_sFiltFreqHi
                    lda #$f1
                    sta d417_sFiltControl
                    lda #$60
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S1196
                    ldx #$07
                    jsr S1196
                    ldx #$0e
S1196               dec $1493,x
                    beq L11b5
                    bpl L11b2
                    lda $1492,x
                    cmp #$02
                    bcs L11af
                    tay
                    eor #$01
                    sta $1492,x
                    lda $1464,y
                    sbc #$00
L11af               sta $1493,x
L11b2               jmp L1274
                    
L11b5               ldy $146b,x
                    lda $144f,y
                    sta $1266
                    sta $1272
                    lda $1469,x
                    bne L11f6
                    ldy $1490,x
                    lda $158f,y
                    sta $80
                    lda $1592,y
                    sta $81
                    ldy $1466,x
                    lda ($80),y
                    cmp #$ff
                    bcc L11e2
                    iny
                    lda ($80),y
                    tay
                    lda ($80),y
L11e2               cmp #$e0
                    bcc L11ee
                    sbc #$f0
                    sta $1467,x
                    iny
                    lda ($80),y
L11ee               sta $1491,x
                    iny
                    tya
                    sta $1466,x
L11f6               ldy $1495,x
                    lda $17b5,y
                    sta $14bf,x
                    lda $147d,x
                    beq L126e
                    sec
                    sbc #$60
                    sta $1494,x
                    lda #$00
                    sta $147b,x
                    sta $147d,x
                    lda $178a,y
                    sta $14a6,x
                    lda $175f,y
                    sta $147c,x
                    lda $146b,x
                    cmp #$03
                    beq L126e
                    lda $17e0,y
                    beq L1236
                    cmp #$fe
                    bcs L1233
                    sta $147f,x
                    lda #$ff
L1233               sta $1496,x
L1236               lda $1709,y
                    beq L1243
                    sta $1480,x
                    lda #$00
                    sta $1481,x
L1243               lda $1734,y
                    beq L1250
                    sta L1132 + 1
                    lda #$00
                    sta $1137
L1250               lda $16de,y
                    sta $147e,x
                    lda $16b3,y
                    sta $14bb,x
                    lda $1688,y
                    sta $14ba,x
                    lda $146c,x
                    jsr S1009
                    jmp L13f6
                    
L126b               jmp L1424
                    
L126e               lda $146c,x
                    jsr S1009
L1274               ldy $147e,x
                    beq L12b3
                    lda $180b,y
                    cmp #$10
                    bcs L128a
                    cmp $14a7,x
                    beq L1293
                    inc $14a7,x
                    bne L12b3
L128a               sbc #$10
                    cmp #$e0
                    bcs L1293
                    sta $147f,x
L1293               lda $180c,y
                    cmp #$ff
                    iny
                    tya
                    bcc L129f
                    lda $1879,y
L129f               sta $147e,x
                    lda #$00
                    sta $14a7,x
                    lda $180a,y
                    cmp #$e0
                    bcs L126b
                    lda $1878,y
                    bne L1302
L12b3               lda $1493,x
                    beq L1321
                    ldy $147b,x
                    sty $10a5
                    lda $145f,y
                    sta L12ff + 1
                    ldy $147c,x
L12c7               lda $1aca,y
                    bmi L12d6
                    sta $81
                    lda $1ae2,y
                    sta $80
                    jmp L12ff
                    
L12d6               lda $1ae2,y
                    sta $12f2
                    sty L12fb + 1
                    ldy $14c0,x
                    lda $14d0,y
                    sec
                    sbc $14cf,y
                    sta $80
                    lda $1530,y
                    sbc $152f,y
                    ldy #$03
                    beq L12fb
L12f5               lsr a
                    ror $80
                    dey
                    bne L12f5
L12fb               ldy #$0d
                    sta $81
L12ff               jmp L1074
                    
L1302               bpl L1309
                    adc $1494,x
                    and #$7f
L1309               sta $14c0,x
                    tay
                    lda #$00
                    sta $14a5,x
                    lda $14cf,y
                    sta $14a8,x
                    lda $152f,y
L131b               sta $14a9,x
L131e               lda $1493,x
L1321               cmp $14bf,x
                    beq L1374
                    ldy $1480,x
                    beq L1371
                    ora $1469,x
                    beq L1371
                    lda $1481,x
                    bne L1349
                    lda $18e7,y
                    bpl L1346
                    sta $14ab,x
                    lda $1933,y
                    sta $14aa,x
                    jmp L1362
                    
L1346               sta $1481,x
L1349               lda $1933,y
                    clc
                    bpl L1352
                    dec $14ab,x
L1352               adc $14aa,x
                    sta $14aa,x
                    bcc L135d
                    inc $14ab,x
L135d               dec $1481,x
                    bne L1371
L1362               lda $18e8,y
                    cmp #$ff
                    iny
                    tya
                    bcc L136e
                    lda $1933,y
L136e               sta $1480,x
L1371               jmp L13f6
                    
L1374               ldy $1491,x
                    lda $1595,y
                    sta $80
                    lda $160f,y
                    sta $81
                    ldy $1469,x
                    lda ($80),y
                    cmp #$40
                    bcc L13a2
                    cmp #$60
                    bcc L13ac
                    cmp #$c0
                    bcc L13c0
                    lda $146a,x
                    bne L1399
                    lda ($80),y
L1399               adc #$00
                    sta $146a,x
                    beq L13ed
                    bne L13f6
L13a2               sta $1495,x
                    iny
                    lda ($80),y
                    cmp #$60
                    bcs L13c0
L13ac               cmp #$50
                    and #$0f
                    sta $146b,x
                    beq L13bb
                    iny
                    lda ($80),y
                    sta $146c,x
L13bb               bcs L13ed
                    iny
                    lda ($80),y
L13c0               cmp #$bd
                    bcc L13ca
                    beq L13ed
                    ora #$f0
                    bne L13ea
L13ca               adc $1467,x
                    sta $147d,x
                    lda $146b,x
                    cmp #$03
                    beq L13ed
                    lda $1495,x
                    cmp #$2b
                    bcs L13e8
                    lda #$00
                    sta $14bb,x
                    lda #$0f
                    sta $14ba,x
L13e8               lda #$fe
L13ea               sta $1496,x
L13ed               iny
                    lda ($80),y
                    beq L13f3
                    tya
L13f3               sta $1469,x
L13f6               lda $14ba,x
                    sta d405_sVoc1AttDec,x
                    lda $14bb,x
                    sta d406_sVoc1SusRel,x
                    lda $14aa,x
                    sta d402_sVoc1PWidthLo,x
                    lda $14ab,x
                    sta d403_sVoc1PWidthHi,x
                    lda $14a8,x
                    sta d400_sVoc1FreqLo,x
                    lda $14a9,x
                    sta d401_sVoc1FreqHi,x
L141a               lda $147f,x
                    and $1496,x
                    sta d404_sVoc1Control,x
                    rts
                    
L1424               and #$0f
                    sta $80
                    lda $1878,y
                    sta $81
                    ldy $80
                    cpy #$05
                    bcs L1441
                    sty $10a5
                    lda $145f,y
                    sta L12ff + 1
                    ldy $81
                    jmp L12c7
                    
L1441               lda $144f,y
                    sta $144a
                    lda $81
                    jsr S1020
                    jmp L131e

		.binary "t2.bin"
code:
	lda #$ff
	sta DDRA
	sta PA
	stz color
	ldx #0
	ldy #$0f
	sty temp
	lda #$87
loop:
	inx
	stx REG
	sta REG
	cpx temp
	bne loop
	ldx #0
	jmp loop
