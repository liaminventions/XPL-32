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

InitSid             jmp L111a
                    
PlaySid             jmp L111e
                    
L1006               jmp L1086
                    
	.binary "mush_data_1.bin"
                    
S1040               lda $15dd,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $1438,x
                    tya
L104d               sta $140f,x
                    lda $13fe,x
                    sta $140e,x
                    rts
                    
L1057               sta d405_sVoc1AttDec,x
                    rts
                    
L105b               sta d406_sVoc1SusRel,x
                    rts
                    
L105f               sta $1412,x
                    rts
                    
L1063               sta $1411,x
                    lda #$00
                    sta $143a,x
                    rts
                    
L106c               sta $1413,x
                    lda #$00
                    sta $1414,x
                    rts
                    
L1075               ldy #$00
                    sty $1159
                    sta L1154 + 1
                    rts
                    
L107e               sta L119d + 1
                    rts
                    
L1082               cmp #$10
                    bcs L108a
L1086               sta $11aa
                    rts
                    
L108a               sta $103f
                    rts
                    
L108e               sta $1425
                    sta $142c
                    sta $1433
                    rts
                    
L1098               dec $1439,x
L109b               jmp L12ee
                    
L109e               beq L109b
                    lda $1439,x
                    bne L1098
                    lda #$00
                    sta $ff
                    lda $1438,x
                    bmi L10b7
                    cmp $1768,y
                    bcc L10b8
                    beq L10b7
                    eor #$ff
L10b7               clc
L10b8               adc #$02
                    sta $1438,x
                    lsr a
                    bcc L10ed
                    bcs L1104
                    tya
                    beq L1114
                    lda $1768,y
                    sta $ff
                    lda #$00
                    cmp #$02
                    bcc L10ed
                    beq L1104
                    ldy $1427,x
                    lda $143b,x
                    sbc $1462,y
                    pha
                    lda $143c,x
                    sbc $14c2,y
                    tay
                    pla
                    bcs L10fd
                    adc $fe
                    tya
                    adc $ff
                    bpl L1114
L10ed               lda $143b,x
                    adc $fe
                    sta $143b,x
                    lda $143c,x
                    adc $ff
                    jmp L12eb
                    
L10fd               sbc $fe
                    tya
                    sbc $ff
                    bmi L1114
L1104               lda $143b,x
                    sbc $fe
                    sta $143b,x
                    lda $143c,x
                    sbc $ff
                    jmp L12eb
                    
L1114               ldy $1427,x
                    jmp L12dd
                    
L111a               sta $1121
                    rts
                    
L111e               ldx #$00
                    ldy #$00
                    bmi L1154
                    txa
                    ldx #$29
L1127               sta $13f9,x
                    dex
                    bpl L1127
                    sta d415_sFiltFreqLo
                    sta $11a3
                    sta L1154 + 1
                    stx $1121
                    tax
                    jsr S1144
                    ldx #$07
                    jsr S1144
                    ldx #$0e
S1144               lda #$05
                    sta $1425,x
                    lda #$01
                    sta $1426,x
                    sta $1428,x
                    jmp L13b8
                    
L1154               ldy #$00
                    beq L119d
                    lda #$00
                    bne L117f
                    lda $170d,y
                    beq L1173
                    bpl L117c
                    asl a
                    sta $11a8
                    lda $173a,y
                    sta $11a3
                    lda $170e,y
                    bne L1191
                    iny
L1173               lda $173a,y
                    sta L119d + 1
                    jmp L118e
                    
L117c               sta $1159
L117f               lda $173a,y
                    clc
                    adc L119d + 1
                    sta L119d + 1
                    dec $1159
                    bne L119f
L118e               lda $170e,y
L1191               cmp #$ff
                    iny
                    tya
                    bcc L119a
                    lda $173a,y
L119a               sta L1154 + 1
L119d               lda #$00
L119f               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S11b8
                    ldx #$07
                    jsr S11b8
                    ldx #$0e
S11b8               dec $1426,x
                    beq L11c8
                    bpl L11c5
                    lda $1425,x
                    sta $1426,x
L11c5               jmp L127f
                    
L11c8               ldy $13fe,x
                    lda $1009,y
                    sta $1274
                    sta $127d
                    lda $13fc,x
                    bne L1209
                    ldy $1423,x
                    lda $1522,y
                    sta $fe
                    lda $1525,y
                    sta $ff
                    ldy $13f9,x
                    lda ($fe),y
                    cmp #$ff
                    bcc L11f5
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L11f5               cmp #$e0
                    bcc L1201
                    sbc #$f0
                    sta $13fa,x
                    iny
                    lda ($fe),y
L1201               sta $1424,x
                    iny
                    tya
                    sta $13f9,x
L1209               ldy $1428,x
                    lda $1605,y
                    sta $1452,x
                    lda $1410,x
                    beq L1279
                    sec
                    sbc #$60
                    sta $1427,x
                    lda #$00
                    sta $140e,x
                    sta $1410,x
                    lda $15f1,y
                    sta $1439,x
                    lda $15dd,y
                    sta $140f,x
                    lda $13fe,x
                    cmp #$03
                    beq L1279
                    lda $1619,y
                    sta $1412,x
                    sta d404_sVoc1Control,x
                    inc $1429,x
                    lda $15a1,y
                    sta $1411,x
                    lda $15b5,y
                    beq L1257
                    sta $1413,x
                    lda #$00
                    sta $1414,x
L1257               lda $15c9,y
                    beq L1264
                    sta L1154 + 1
                    lda #$00
                    sta $1159
L1264               lda $1579,y
                    sta d405_sVoc1AttDec,x
                    lda $158d,y
                    sta d406_sVoc1SusRel,x
                    lda $13ff,x
                    jmp S1040
                    
L1276               jmp L13ce
                    
L1279               lda $13ff,x
                    jsr S1040
L127f               ldy $1411,x
                    beq L12be
                    lda $162d,y
                    cmp #$10
                    bcs L1295
                    cmp $143a,x
                    beq L129e
                    inc $143a,x
                    bne L12be
L1295               sbc #$10
                    cmp #$e0
                    bcs L129e
                    sta $1412,x
L129e               lda $162e,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12aa
                    lda $167d,y
L12aa               sta $1411,x
                    lda #$00
                    sta $143a,x
                    lda $162c,y
                    cmp #$e0
                    bcs L1276
                    lda $167c,y
                    bne L12d5
L12be               ldy $140e,x
                    sty $10cb
                    lda $1019,y
                    sta $12d3
                    ldy $140f,x
L12cd               lda $176d,y
                    sta $fe
                    jmp L109e
                    
L12d5               bpl L12dc
                    adc $1427,x
                    and #$7f
L12dc               tay
L12dd               lda #$00
                    sta $1438,x
                    lda $1462,y
                    sta $143b,x
                    lda $14c2,y
L12eb               sta $143c,x
L12ee               ldy $1413,x
                    beq L1332
                    lda $1414,x
                    bne L1309
                    lda $16cd,y
                    bpl L1306
                    lda $16ed,y
                    sta $143d,x
                    jmp L131a
                    
L1306               sta $1414,x
L1309               lda $143d,x
                    clc
                    adc $16ed,y
                    adc #$00
                    sta $143d,x
                    dec $1414,x
                    bne L132c
L131a               lda $16ce,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1326
                    lda $16ed,y
L1326               sta $1413,x
                    lda $143d,x
L132c               sta d402_sVoc1PWidthLo,x
                    sta d403_sVoc1PWidthHi,x
L1332               lda $1426,x
                    cmp $1452,x
                    beq L133d
                    jmp L13b8
                    
L133d               ldy $1424,x
                    lda $1528,y
                    sta $fe
                    lda $1551,y
                    sta $ff
                    ldy $13fc,x
                    lda ($fe),y
                    cmp #$40
                    bcc L136b
                    cmp #$60
                    bcc L1375
                    cmp #$c0
                    bcc L1389
                    lda $13fd,x
                    bne L1362
                    lda ($fe),y
L1362               adc #$00
                    sta $13fd,x
                    beq L13af
                    bne L13b8
L136b               sta $1428,x
                    iny
                    lda ($fe),y
                    cmp #$60
                    bcs L1389
L1375               cmp #$50
                    and #$0f
                    sta $13fe,x
                    beq L1384
                    iny
                    lda ($fe),y
                    sta $13ff,x
L1384               bcs L13af
                    iny
                    lda ($fe),y
L1389               cmp #$bd
                    bcc L1393
                    beq L13af
                    ora #$f0
                    bne L13ac
L1393               adc $13fa,x
                    sta $1410,x
                    lda $13fe,x
                    cmp #$03
                    beq L13af
                    lda #$ff
                    sta d405_sVoc1AttDec,x
                    lda #$00
                    sta d406_sVoc1SusRel,x
                    lda #$fe
L13ac               sta $1429,x
L13af               iny
                    lda ($fe),y
                    beq L13b5
                    tya
L13b5               sta $13fc,x
L13b8               lda $1412,x
                    and $1429,x
                    sta d404_sVoc1Control,x
                    lda $143b,x
                    sta d400_sVoc1FreqLo,x
                    lda $143c,x
                    sta d401_sVoc1FreqHi,x
                    rts
                    
L13ce               and #$0f
                    sta $fe
                    lda $167c,y
                    sta $ff
                    ldy $fe
                    cpy #$05
                    bcs L13eb
                    sty $10cb
                    lda $1019,y
                    sta $12d3
                    ldy $ff
                    jmp L12cd
                    
L13eb               lda $1009,y
                    sta $13f4
                    lda $ff
                    jsr S1040
                    jmp L12ee

	.binary "mush_data_2.bin"
