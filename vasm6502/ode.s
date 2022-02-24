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
InitSid             jmp L1173
                    
PlaySid             jmp L11d3
                    
L1006               jmp L11fe

  .binary "ode_ascii.bin"
                    
L1173               tay
                    lda #$0f
                    sta $11dc
                    lda #$03
                    sta $1170
                    sta $1171
                    lda #$01
                    sta $100b
                    lda $1172
                    sta L15cc + 1
                    sta $1239
                    lda $1a04,y
                    sta $1143
                    lda $1a05,y
                    sta $114a
                    lda $1a06,y
                    sta $1151
                    ldx #$00
                    jsr S11ad
                    ldx #$07
                    jsr S11ad
                    ldx #$0e
S11ad               lda #$01
                    sta $1132,x
                    sta $112d,x
                    sta $1159,x
                    lda #$02
                    sta $1103,x
                    lda #$04
                    sta $1106,x
                    lda #$00
                    sta $112c,x
                    sta $1107,x
                    sta $1141,x
                    sta $1130,x
                    jmp L1401
                    
L11d3               lda $fb
                    pha
                    lda $fc
                    pha
                    lda #$00
                    ora #$00
                    sta d418_sFiltMode
                    ldx #$0e
                    jsr S1367
                    ldx #$07
                    jsr S1367
                    ldx #$00
                    jsr S1367
                    pla
                    sta $fc
                    pla
                    sta $fb
                    rts
                    
L11f6               ldy #$17
L11f8               sta d400_sVoc1FreqLo,y
                    dey
                    bpl L11f8
L11fe               rts
                    
L11ff               lda #$ff
                    sta $112e,x
                    sta $1119,x
                    ldy $1107,x
                    lda $18fb,y
                    sta $1157,x
                    lda $1915,y
                    sta $1104,x
                    lda #$00
                    sta $1117,x
                    sta $1108,x
                    sta $112f,x
                    sta $111c,x
                    sta $111d,x
                    lda $197d,y
                    sta $111b,x
                    lda $1997,y
                    sta $111a,x
                    lda #$03
                    sta $1106,x
                    cpx #$00
                    bne L1255
                    lda $1963,y
                    sta d417_sFiltControl
                    lda $1949,y
                    and #$f0
                    sta $11da
                    lda $192f,y
                    sta $115c
                    lda #$00
                    sta $1163
L1255               lda $112c,x
                    cmp #$c0
                    beq L127f
                    lda $18e1,y
                    sta d406_sVoc1SusRel,x
                    sta $1011,x
                    lda $18c7,y
L1268               sta d405_sVoc1AttDec,x
                    sta $1010,x
                    lda #$09
                    sta d404_sVoc1Control,x
                    lda $1141,x
                    sta $1142,x
                    lda #$00
                    sta $112c,x
                    rts
                    
L127f               ldy $1156,x
                    lda $19f1,y
                    sta d406_sVoc1SusRel,x
                    sta $1011,x
                    lda $19de,y
                    jmp L1268
                    
L1291               lda #$ff
                    sta $112e,x
                    jmp L1318
                    
L1299               and #$1f
                    sta $1102,x
                    inc $1130,x
                    iny
                    jmp L1303
                    
L12a5               beq L1291
                    cmp #$fd
                    beq L12cc
                    bcs L1318
                    lda #$03
                    sta $1106,x
                    lda #$80
                    sta $1119,x
                    sty $116e
                    ldy $1107,x
                    lda $197d,y
                    sta $111b,x
                    lda $1997,y
                    sta $111a,x
                    ldy $116e
L12cc               inc $1130,x
                    iny
                    jmp L1303
                    
L12d3               and #$7f
                    sta $1107,x
                    inc $1130,x
                    iny
                    jmp L1303
                    
L12df               jsr L1465
                    lda $1141,x
                    sta $1142,x
                    jmp L12f6
                    
L12eb               lda $115a,x
                    sta $1103,x
                    lda $1132,x
                    beq L12df
L12f6               lda $100b,x
                    sta $fb
                    lda $100c,x
                    sta $fc
                    ldy $1130,x
L1303               lda ($fb),y
                    cmp #$fb
                    bcs L12a5
                    cmp #$b0
                    bcs L1354
                    cmp #$80
                    bcs L12d3
                    cmp #$60
                    bcs L1299
                    sta $1118,x
L1318               inc $1130,x
                    lda $1102,x
                    sta $112d,x
                    iny
                    lda ($fb),y
                    cmp #$ff
                    bne L1330
                    inc $1143,x
                    lda #$00
                    sta $1130,x
L1330               lda $1132,x
                    bne L133d
                    lda $112c,x
                    cmp #$10
                    beq L135b
                    rts
                    
L133d               jmp L11ff
                    
L1340               lda $1103,x
                    beq L12eb
                    cmp #$02
                    beq L1351
                    bcc L134e
                    jmp L1465
                    
L134e               jmp L143b
                    
L1351               jmp L13c6
                    
L1354               inc $1130,x
                    iny
                    jmp L1303
                    
L135b               lda $1156,x
                    sta $1119,x
                    lda #$00
                    sta $112c,x
                    rts
                    
S1367               dec $1103,x
                    lda $112d,x
                    beq L1340
                    lda $1103,x
                    beq L1377
                    jmp L1465
                    
L1377               lda #$03
                    sta $1103,x
                    dec $112d,x
                    jmp L1465
                    
L1382               cmp #$fe
                    beq L1397
                    cmp #$fb
                    beq L139c
                    cmp #$fa
                    beq L1393
                    lda #$00
                    sta $1132,x
L1393               iny
                    jmp L13e0
                    
L1397               lda #$fe
                    sta $112e,x
L139c               lda #$00
                    sta $1132,x
                    jmp L13ea
                    
L13a4               iny
                    cmp #$b0
                    bcc L13e0
                    sty $116e
                    sec
                    sbc #$b0
                    sta $1156,x
                    tay
                    lda $19cb,y
                    sta $112c,x
                    bmi L13c0
                    lda #$00
                    sta $1132,x
L13c0               ldy $116e
                    jmp L13e0
                    
L13c6               ldy $1130,x
                    beq L1401
L13cb               lda #$ff
                    sta $112e,x
                    sta $1132,x
                    lda $100b,x
                    sta $fb
                    lda $100c,x
                    sta $fc
                    ldy $1130,x
L13e0               lda ($fb),y
                    cmp #$fa
                    bcs L1382
                    cmp #$60
                    bcs L13a4
L13ea               lda $1132,x
                    beq L13fe
                    lda #$fe
                    sta $112e,x
                    lda #$00
                    sta $1011,x
                    lda #$ff
                    sta $1010,x
L13fe               jmp L1465
                    
L1401               lda $1144,x
                    sta $fb
                    lda $1145,x
                    sta $fc
                    ldy $1143,x
L140e               lda ($fb),y
                    bmi L142b
                    tay
                    lda $16a1,y
                    sta $100b,x
                    lda $16ee,y
                    sta $100c,x
                    jmp L13cb
                    
L1422               lda ($fb),y
                    sta $1143,x
                    tay
                    jmp L140e
                    
L142b               iny
                    cmp #$ff
                    beq L1422
                    and #$7f
                    sta $1141,x
                    inc $1143,x
                    jmp L140e
                    
L143b               lda #$03
                    sta $115a,x
                    jsr L1465
                    lda $112c,x
                    cmp #$40
                    bne L145e
                    lda #$00
                    sta $1106,x
                    sta $111c,x
                    sta $111d,x
                    sta $112c,x
                    lda $1156,x
                    sta $1131,x
L145e               rts
                    
L145f               dec $1108,x
                    jmp L14a3
                    
L1465               lda #$01
                    sta $112f,x
                    lda $1108,x
                    bne L145f
                    ldy $1107,x
                    lda $1949,y
                    and #$0f
                    sta $1108,x
                    ldy $1157,x
L147d               lda $173d,y
                    cmp #$fe
                    beq L14a3
                    bcc L1492
                    tya
                    sec
                    sbc $17a0,y
                    sta $1157,x
                    tay
                    jmp L147d
                    
L1492               sta $115b,x
                    and #$f7
                    sta $100f,x
                    lda $17a0,y
                    sta $1158,x
                    inc $1157,x
L14a3               ldy $1119,x
                    bmi L14bb
                    lda $111a,x
                    clc
                    adc $19f1,y
                    sta $111a,x
                    lda $111b,x
                    adc $19de,y
                    sta $111b,x
L14bb               lda $115b,x
                    and #$08
                    bne L14fc
                    lda $1118,x
                    clc
                    adc $1142,x
                    adc $1158,x
                    sta $fb
                    tay
                    lda $1042,y
                    clc
                    adc $111a,x
                    sta $116c
                    lda $10a2,y
                    adc $111b,x
                    sta $116d
                    lda $1106,x
                    beq L1512
                    cmp #$02
                    beq L150f
                    bcc L154f
                    lda $116c
                    sta d400_sVoc1FreqLo,x
                    lda $116d
                    sta d401_sVoc1FreqHi,x
                    jmp L15cc
                    
L14fc               lda $111a,x
                    sta d400_sVoc1FreqLo,x
                    lda $1158,x
                    clc
                    adc $111b,x
                    sta d401_sVoc1FreqHi,x
                    jmp L15cc
                    
L150f               jmp L158f
                    
L1512               ldy $fb
                    lda $1043,y
                    sec
                    sbc $1042,y
                    sta $fb
                    lda $10a3,y
                    sbc $10a2,y
                    sta $fc
                    ldy $1131,x
                    lda $19de,y
                    lsr a
                    adc #$00
                    sta $1117,x
                    lda $19f1,y
                    beq L153f
                    tay
                    dey
L1538               lsr $fc
                    ror $fb
                    dey
                    bpl L1538
L153f               inc $1106,x
                    lda $fb
                    sta $1146,x
                    lda $fc
                    sta $1147,x
                    jmp L15cc
                    
L154f               lda $111c,x
                    clc
                    adc $1146,x
                    sta $111c,x
                    lda $111d,x
                    adc $1147,x
                    sta $111d,x
                    lda $116c
                    clc
                    adc $111c,x
                    sta d400_sVoc1FreqLo,x
                    lda $116d
                    adc $111d,x
                    sta d401_sVoc1FreqHi,x
                    lda $1117,x
                    dec $1117,x
                    bne L15cc
                    ldy $1131,x
                    lda $19de,y
                    clc
                    adc #$01
                    sta $1117,x
                    inc $1106,x
                    jmp L15cc
                    
L158f               lda $111c,x
                    sec
                    sbc $1146,x
                    sta $111c,x
                    lda $111d,x
                    sbc $1147,x
                    sta $111d,x
                    lda $116c
                    clc
                    adc $111c,x
                    sta d400_sVoc1FreqLo,x
                    lda $116d
                    adc $111d,x
                    sta d401_sVoc1FreqHi,x
                    lda $1117,x
                    dec $1117,x
                    bne L15cc
                    ldy $1131,x
                    lda $19de,y
                    clc
                    adc #$01
                    sta $1117,x
                    dec $1106,x
L15cc               cpx #$00
                    bne L1628
                    ldy $115c
                    beq L1628
                    lda $1877,y
                    bne L15f5
                    lda $188b,y
                    sta $116a
                    sta d416_sFiltFreqHi
                    lda $18b3,y
                    beq L1628
                    sta $115c
                    tay
                    lda $1877,y
                    sta $116b
                    jmp L1628
                    
L15f5               ldy $115c
                    beq L1628
                    lda $188b,y
                    clc
                    adc $1163
                    sta $1163
                    lda $189f,y
                    adc $116a
                    sta $116a
                    sta d416_sFiltFreqHi
                    lda $1877,y
                    cmp $116b
                    dec $116b
                    bne L1628
                    lda $18b3,y
                    sta $115c
                    tay
                    lda $1877,y
                    sta $116b
L1628               ldy $1104,x
                    beq L168b
                    lda $1803,y
                    bne L1655
                    lda $1820,y
                    sta $100e,x
                    sta d403_sVoc1PWidthHi,x
                    and #$f0
                    sta $100d,x
                    sta d402_sVoc1PWidthLo,x
                    lda $185a,y
                    beq L168b
                    sta $1104,x
                    tay
                    lda $1803,y
                    sta $1105,x
                    jmp L168b
                    
L1655               ldy $1104,x
                    beq L168b
                    lda $1820,y
                    clc
                    adc $100d,x
                    sta $100d,x
                    sta d402_sVoc1PWidthLo,x
                    lda $183d,y
                    adc $100e,x
                    sta $100e,x
                    sta d403_sVoc1PWidthHi,x
                    lda $1803,y
                    cmp $1105,x
                    dec $1105,x
                    bne L168b
                    lda $185a,y
                    sta $1104,x
                    tay
                    lda $1803,y
                    sta $1105,x
L168b               lda $1011,x
                    sta d406_sVoc1SusRel,x
                    lda $1010,x
                    sta d405_sVoc1AttDec,x
                    lda $100f,x
                    and $112e,x
                    sta d404_sVoc1Control,x
                    rts
  .binary "ode.bin"
