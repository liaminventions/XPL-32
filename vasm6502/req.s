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


InitSid             jmp L10e2
                    
PlaySid             jmp L10e6
                    
  .binary "req_ascii.bin"

S1040               lda $16ae,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $13fb,x
                    tya
L104d               sta $13d2,x
                    lda $13c1,x
                    sta $13d1,x
                    rts
                    
L1057               sta $1415,x
                    rts
                    
L105b               sta $1416,x
                    rts
                    
L105f               sta $13d6,x
                    lda #$00
                    sta $13d7,x
                    rts
                    
L1068               ldy #$00
                    sty $112e
                    sta L1129 + 1
                    rts
                    
L1071               sta L1172 + 1
                    rts
                    
L1075               cmp #$10
                    bcs L107d
                    sta $117f
                    rts
                    
L107d               sta $103f
                    rts
                    
L1081               sta $13e8
                    sta $13ef
                    sta $13f6
                    rts
                    
L108b               dec $13fc,x
L108e               jmp L12b8
                    
L1091               beq L108e
                    lda $13fc,x
                    bne L108b
                    lda #$00
                    sta $ff
                    lda $13fb,x
                    bmi L10aa
                    cmp $1b33,y
                    bcc L10ab
                    beq L10aa
                    eor #$ff
L10aa               clc
L10ab               adc #$02
                    sta $13fb,x
                    lsr a
                    bcc L10c2
                    bcs L10d2
                    lda $1b33,y
                    sta $ff
                    lda #$00
                    cmp #$02
                    bcc L10c2
                    beq L10d2
L10c2               lda $1410,x
                    adc $fe
                    sta $1410,x
                    lda $1411,x
                    adc $ff
                    jmp L12b5
                    
L10d2               lda $1410,x
                    sbc $fe
                    sta $1410,x
                    lda $1411,x
                    sbc $ff
                    jmp L12b5
                    
L10e2               sta $10f6
                    rts
                    
L10e6               ldx #$00
L10e8               lda $1410,x
                    sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$19
                    bne L10e8
                    ldx #$00
                    ldy #$00
                    bmi L1129
                    txa
                    ldx #$29
L10fc               sta $13bc,x
                    dex
                    bpl L10fc
                    sta $1425
                    sta $1178
                    sta L1129 + 1
                    stx $10f6
                    tax
                    jsr S1119
                    ldx #$07
                    jsr S1119
                    ldx #$0e
S1119               lda #$05
                    sta $13e8,x
                    lda #$01
                    sta $13e9,x
                    sta $13eb,x
                    jmp L1381
                    
L1129               ldy #$00
                    beq L1172
                    lda #$00
                    bne L1154
                    lda $19ee,y
                    beq L1148
                    bpl L1151
                    asl a
                    sta $117d
                    lda $1a90,y
                    sta $1178
                    lda $19ef,y
                    bne L1166
                    iny
L1148               lda $1a90,y
                    sta L1172 + 1
                    jmp L1163
                    
L1151               sta $112e
L1154               lda $1a90,y
                    clc
                    adc L1172 + 1
                    sta L1172 + 1
                    dec $112e
                    bne L1174
L1163               lda $19ef,y
L1166               cmp #$ff
                    iny
                    tya
                    bcc L116f
                    lda $1a90,y
L116f               sta L1129 + 1
L1172               lda #$00
L1174               sta $1426
                    lda #$00
                    sta $1427
                    lda #$00
                    ora #$0f
                    sta $1428
                    jsr S118d
                    ldx #$07
                    jsr S118d
                    ldx #$0e
S118d               dec $13e9,x
                    beq L119d
                    bpl L119a
                    lda $13e8,x
                    sta $13e9,x
L119a               jmp L1249
                    
L119d               ldy $13c1,x
                    lda $1006,y
                    sta $123b
                    sta $1247
                    lda $13bf,x
                    bne L11d2
                    ldy $13e6,x
                    lda $14e9,y
                    sta $fe
                    lda $14ec,y
                    sta $ff
                    ldy $13bc,x
                    lda ($fe),y
                    cmp #$ff
                    bcc L11ca
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L11ca               sta $13e7,x
                    iny
                    tya
                    sta $13bc,x
L11d2               ldy $13eb,x
                    lda $1726,y
                    sta $1401,x
                    lda $13d3,x
                    beq L1243
                    sec
                    sbc #$60
                    sta $13ea,x
                    lda #$00
                    sta $13d1,x
                    sta $13d3,x
                    lda $16ea,y
                    sta $13fc,x
                    lda $16ae,y
                    sta $13d2,x
                    lda $1762,y
                    beq L120b
                    cmp #$fe
                    bcs L1208
                    sta $13d5,x
                    lda #$ff
L1208               sta $13ec,x
L120b               lda $15fa,y
                    sta $13d4,x
                    lda $1636,y
                    beq L121e
                    sta $13d6,x
                    lda #$00
                    sta $13d7,x
L121e               lda $1672,y
                    beq L122b
                    sta L1129 + 1
                    lda #$00
                    sta $112e
L122b               lda $1582,y
                    sta $1415,x
                    lda $15be,y
                    sta $1416,x
                    lda $13c2,x
                    jsr S1040
                    jmp L1381
                    
L1240               jmp L1391
                    
L1243               lda $13c2,x
                    jsr S1040
L1249               ldy $13d4,x
                    beq L1288
                    lda $179e,y
                    cmp #$10
                    bcs L125f
                    cmp $13fd,x
                    beq L1268
                    inc $13fd,x
                    bne L1288
L125f               sbc #$10
                    cmp #$e0
                    bcs L1268
                    sta $13d5,x
L1268               lda $179f,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1274
                    lda $1881,y
L1274               sta $13d4,x
                    lda #$00
                    sta $13fd,x
                    lda $179d,y
                    cmp #$e0
                    bcs L1240
                    lda $1880,y
                    bne L129f
L1288               ldy $13d1,x
                    sty $10bb
                    lda $1016,y
                    sta $129d
                    ldy $13d2,x
L1297               lda $1b40,y
                    sta $fe
                    jmp L1091
                    
L129f               bpl L12a6
                    adc $13ea,x
                    and #$7f
L12a6               tay
                    lda #$00
                    sta $13fb,x
                    lda $1429,y
                    sta $1410,x
                    lda $1489,y
L12b5               sta $1411,x
L12b8               ldy $13d6,x
                    beq L12fe
                    lda $13d7,x
                    bne L12d6
                    lda $1964,y
                    bpl L12d3
                    sta $1413,x
                    lda $19a9,y
                    sta $1412,x
                    jmp L12ef
                    
L12d3               sta $13d7,x
L12d6               lda $19a9,y
                    clc
                    bpl L12df
                    dec $1413,x
L12df               adc $1412,x
                    sta $1412,x
                    bcc L12ea
                    inc $1413,x
L12ea               dec $13d7,x
                    bne L12fe
L12ef               lda $1965,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12fb
                    lda $19a9,y
L12fb               sta $13d6,x
L12fe               lda $13e9,x
                    cmp $1401,x
                    beq L1309
                    jmp L1381
                    
L1309               ldy $13e7,x
                    lda $14ef,y
                    sta $fe
                    lda $1539,y
                    sta $ff
                    ldy $13bf,x
                    lda ($fe),y
                    cmp #$40
                    bcc L1337
                    cmp #$60
                    bcc L1341
                    cmp #$c0
                    bcc L1355
                    lda $13c0,x
                    bne L132e
                    lda ($fe),y
L132e               adc #$00
                    sta $13c0,x
                    beq L1378
                    bne L1381
L1337               sta $13eb,x
                    iny
                    lda ($fe),y
                    cmp #$60
                    bcs L1355
L1341               cmp #$50
                    and #$0f
                    sta $13c1,x
                    beq L1350
                    iny
                    lda ($fe),y
                    sta $13c2,x
L1350               bcs L1378
                    iny
                    lda ($fe),y
L1355               cmp #$bd
                    bcc L135f
                    beq L1378
                    ora #$f0
                    bne L1375
L135f               sta $13d3,x
                    lda $13eb,x
                    cmp #$32
                    bcs L138b
                    lda #$f8
                    sta $1415,x
                    lda #$06
                    sta $1416,x
L1373               lda #$fe
L1375               sta $13ec,x
L1378               iny
                    lda ($fe),y
                    beq L137e
                    tya
L137e               sta $13bf,x
L1381               lda $13d5,x
                    and $13ec,x
                    sta $1414,x
                    rts
                    
L138b               cmp #$33
                    bcc L1373
                    bcs L1378
L1391               and #$0f
                    sta $fe
                    lda $1880,y
                    sta $ff
                    ldy $fe
                    cpy #$05
                    bcs L13ae
                    sty $10bb
                    lda $1016,y
                    sta $129d
                    ldy $ff
                    jmp L1297
                    
L13ae               lda $1006,y
                    sta $13b7
                    lda $ff
                    jsr S1040
                    jmp L12b8

  .binary "req_data.bin"
