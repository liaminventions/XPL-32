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
  jmp reset
irq:
  phy
  phx
  pha
  jsr putbut
check:
  sei
  lda $8001
  and #$08
  beq cont
  jmp clear
cont:
  jsr PlaySid
  cli
  pla
  plx
  ply
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
                    jmp InitSid2

	.org $1000
InitSid2            jmp L10d6
                    
PlaySid             jmp L10da
                    
S1006               lda $15c6,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $13ff,x
                    tya
L1013               sta $13d6,x
                    lda $13c5,x
                    sta $13d5,x
                    rts
                    
L101d               sta $1419,x
                    rts
                    
L1021               sta $141a,x
                    rts
                    
L1025               sta $13d9,x
                    rts
                    
L1029               sta $13d8,x
                    lda #$00
                    sta $1401,x
                    rts
                    
L1032               sta $13da,x
                    lda #$00
                    sta $13db,x
                    rts
                    
L103b               ldy #$00
                    sty $1122
L1040               sta L111d + 1
                    rts
                    
L1044               sta $116c
                    beq L1040
                    rts
                    
L104a               sta $13ec
                    sta $13f3
                    sta $13fa
                    rts
                    
L1054               dec $1400,x
L1057               jmp L12b0
                    
L105a               beq L1057
                    lda $1400,x
                    bne L1054
                    lda #$00
                    sta $fc
                    lda $13ff,x
                    bmi L1073
                    cmp $17c5,y
                    bcc L1074
                    beq L1073
                    eor #$ff
L1073               clc
L1074               adc #$02
                    sta $13ff,x
                    lsr a
                    bcc L10a9
                    bcs L10c0
                    tya
                    beq L10d0
                    lda $17c5,y
                    sta $fc
                    lda #$00
                    cmp #$02
                    bcc L10a9
                    beq L10c0
                    ldy $13ee,x
                    lda $1414,x
                    sbc $1425,y
                    pha
                    lda $1415,x
                    sbc $147d,y
                    tay
                    pla
                    bcs L10b9
                    adc $fb
                    tya
                    adc $fc
                    bpl L10d0
L10a9               lda $1414,x
                    adc $fb
                    sta $1414,x
                    lda $1415,x
                    adc $fc
                    jmp L12ad
                    
L10b9               sbc $fb
                    tya
                    sbc $fc
                    bmi L10d0
L10c0               lda $1414,x
                    sbc $fb
                    sta $1414,x
                    lda $1415,x
                    sbc $fc
                    jmp L12ad
                    
L10d0               ldy $13ee,x
                    jmp L129f
                    
L10d6               sta $10ea
                    rts
                    
L10da               ldx #$00
L10dc               lda $1414,x
                    sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$19
                    bne L10dc
                    ldx #$00
                    ldy #$00
                    bmi L111d
                    txa
                    ldx #$29
L10f0               sta $13c0,x
                    dex
                    bpl L10f0
                    sta $1429
                    sta $116c
                    sta L111d + 1
                    stx $10ea
                    tax
                    jsr S110d
                    ldx #$07
                    jsr S110d
                    ldx #$0e
S110d               lda #$05
                    sta $13ec,x
                    lda #$01
                    sta $13ed,x
                    sta $13ef,x
                    jmp L1376
                    
L111d               ldy #$00
                    beq L1166
                    lda #$00
                    bne L1148
                    lda $1778,y
                    beq L113c
                    bpl L1145
                    asl a
                    sta $1171
                    lda $179e,y
                    sta $116c
                    lda $1779,y
                    bne L115a
                    iny
L113c               lda $179e,y
                    sta L1166 + 1
                    jmp L1157
                    
L1145               sta $1122
L1148               lda $179e,y
                    clc
                    adc L1166 + 1
                    sta L1166 + 1
                    dec $1122
                    bne L1168
L1157               lda $1779,y
L115a               cmp #$ff
                    iny
                    tya
                    bcc L1163
                    lda $179e,y
L1163               sta L111d + 1
L1166               lda #$00
L1168               sta $142a
                    lda #$00
                    sta $142b
                    lda #$00
                    ora #$0f
                    sta $142c
                    jsr S1181
                    ldx #$07
                    jsr S1181
                    ldx #$0e
S1181               dec $13ed,x
                    beq L1191
                    bpl L118e
                    lda $13ec,x
                    sta $13ed,x
L118e               jmp L1241
                    
L1191               ldy $13c5,x
                    lda $13ab,y
                    sta $1233
                    sta $123f
                    lda $13c3,x
                    bne L11d2
                    ldy $13ea,x
                    lda $14dd,y
                    sta $fb
                    lda $14e0,y
                    sta $fc
                    ldy $13c0,x
                    lda ($fb),y
                    cmp #$ff
                    bcc L11be
                    iny
                    lda ($fb),y
                    tay
                    lda ($fb),y
L11be               cmp #$e0
                    bcc L11ca
                    sbc #$f0
                    sta $13c1,x
                    iny
                    lda ($fb),y
L11ca               sta $13eb,x
                    iny
                    tya
                    sta $13c0,x
L11d2               ldy $13ef,x
                    lda $13d7,x
                    beq L123b
                    sec
                    sbc #$60
                    sta $13ee,x
                    lda #$00
                    sta $13d5,x
                    sta $13d7,x
                    lda $15e0,y
                    sta $1400,x
                    lda $15c6,y
                    sta $13d6,x
                    lda $13c5,x
                    cmp #$03
                    beq L123b
                    lda #$09
                    sta $13d9,x
                    inc $13f0,x
                    lda $1578,y
                    sta $13d8,x
                    lda $1592,y
                    beq L1216
                    sta $13da,x
                    lda #$00
                    sta $13db,x
L1216               lda $15ac,y
                    beq L1223
                    sta L111d + 1
                    lda #$00
                    sta $1122
L1223               lda $1544,y
                    sta $1419,x
                    lda $155e,y
                    sta $141a,x
                    lda $13c6,x
                    jsr S1006
                    jmp L1376
                    
L1238               jmp L1380
                    
L123b               lda $13c6,x
                    jsr S1006
L1241               ldy $13d8,x
                    beq L1280
                    lda $15fa,y
                    cmp #$10
                    bcs L1257
                    cmp $1401,x
                    beq L1260
                    inc $1401,x
                    bne L1280
L1257               sbc #$10
                    cmp #$e0
                    bcs L1260
                    sta $13d9,x
L1260               lda $15fb,y
                    cmp #$ff
                    iny
                    tya
                    bcc L126c
                    lda $169f,y
L126c               sta $13d8,x
                    lda #$00
                    sta $1401,x
                    lda $15f9,y
                    cmp #$e0
                    bcs L1238
                    lda $169e,y
                    bne L1297
L1280               ldy $13d5,x
                    sty $1087
                    lda $13bb,y
                    sta $1295
                    ldy $13d6,x
L128f               lda $17cf,y
                    sta $fb
                    jmp L105a
                    
L1297               bpl L129e
                    adc $13ee,x
                    and #$7f
L129e               tay
L129f               lda #$00
                    sta $13ff,x
                    lda $1425,y
                    sta $1414,x
                    lda $147d,y
L12ad               sta $1415,x
L12b0               ldy $13da,x
                    beq L12f1
                    lda $13db,x
                    bne L12ce
                    lda $1744,y
                    bpl L12cb
                    lda $175e,y
                    sta $1416,x
                    sta $1417,x
                    jmp L12e2
                    
L12cb               sta $13db,x
L12ce               lda $1416,x
                    clc
                    adc $175e,y
                    adc #$00
                    sta $1416,x
                    sta $1417,x
                    dec $13db,x
                    bne L12f1
L12e2               lda $1745,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12ee
                    lda $175e,y
L12ee               sta $13da,x
L12f1               lda $13ed,x
                    cmp #$02
                    beq L12fb
                    jmp L1376
                    
L12fb               ldy $13eb,x
                    lda $14e3,y
                    sta $fb
                    lda $1514,y
                    sta $fc
                    ldy $13c3,x
                    lda ($fb),y
                    cmp #$40
                    bcc L1329
                    cmp #$60
                    bcc L1333
                    cmp #$c0
                    bcc L1347
                    lda $13c4,x
                    bne L1320
                    lda ($fb),y
L1320               adc #$00
                    sta $13c4,x
                    beq L136d
                    bne L1376
L1329               sta $13ef,x
                    iny
                    lda ($fb),y
                    cmp #$60
                    bcs L1347
L1333               cmp #$50
                    and #$0f
                    sta $13c5,x
                    beq L1342
                    iny
                    lda ($fb),y
                    sta $13c6,x
L1342               bcs L136d
                    iny
                    lda ($fb),y
L1347               cmp #$bd
                    bcc L1351
                    beq L136d
                    ora #$f0
                    bne L136a
L1351               adc $13c1,x
                    sta $13d7,x
                    lda $13c5,x
                    cmp #$03
                    beq L136d
                    lda #$ff
                    sta $1419,x
                    lda #$00
                    sta $141a,x
                    lda #$fe
L136a               sta $13f0,x
L136d               iny
                    lda ($fb),y
                    beq L1373
                    tya
L1373               sta $13c3,x
L1376               lda $13d9,x
                    and $13f0,x
                    sta $1418,x
                    rts
                    
L1380               and #$0f
                    sta $fb
                    lda $169e,y
                    sta $fc
                    ldy $fb
                    cpy #$05
                    bcs L139d
                    sty $1087
                    lda $13bb,y
                    sta $1295
                    ldy $fc
                    jmp L128f
                    
L139d               lda $13ab,y
                    sta $13a6
                    lda $fc
                    jsr S1006
                    jmp L12b0

	.binary "mded.bin"
