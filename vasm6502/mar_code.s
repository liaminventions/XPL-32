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
  lda #$90
  sta $b00e
  stz $b00c
  lda #0 ; Song Number
  jsr InitSid
  cli
  nop
  jmp reset
irq:
  pha
  phx
  phy
  ; IRQ code goes here
  lda #$10
  sta $b00d
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

	.byte "How is this so smol ;-;"

	.org $1000

InitSid             jmp L1104
                    
PlaySid             jmp L110c
                    
L1006               jmp L1108

	.binary "mar_a.bin"
                    
S1040               lda $1614,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $140e,x
                    tya
L104d               sta $13e5,x
                    lda $13d4,x
                    sta $13e4,x
                    rts
                    
L1057               sta $1424,x
                    rts
                    
L105b               sta $13e7,x
                    lda #$00
                    sta $1410,x
                    rts
                    
L1064               ldy #$00
                    sty $1147
L1069               sta L1142 + 1
                    rts
                    
L106d               sta $1191
                    beq L1069
                    rts
                    
L1073               sta L118b + 1
                    rts
                    
L1077               sta $13fb
                    sta $1402
                    sta $1409
                    rts
                    
L1081               dec $140f,x
L1084               jmp L12df
                    
L1087               beq L1084
                    lda $140f,x
                    bne L1081
                    lda #$00
                    sta $fd
                    lda $140e,x
                    bmi L10a0
                    cmp $171d,y
                    bcc L10a1
                    beq L10a0
                    eor #$ff
L10a0               clc
L10a1               adc #$02
                    sta $140e,x
                    lsr a
                    bcc L10d7
                    bcs L10ee
                    tya
                    beq L10fe
                    lda $171d,y
                    sta $fd
                    lda $13e4,x
                    cmp #$02
                    bcc L10d7
                    beq L10ee
                    ldy $13fd,x
                    lda $1411,x
                    sbc $1436,y
                    pha
                    lda $1412,x
                    sbc $1496,y
                    tay
                    pla
                    bcs L10e7
                    adc $fc
                    tya
                    adc $fd
                    bpl L10fe
L10d7               lda $1411,x
                    adc $fc
                    sta $1411,x
                    lda $1412,x
                    adc $fd
                    jmp L12dc
                    
L10e7               sbc $fc
                    tya
                    sbc $fd
                    bmi L10fe
L10ee               lda $1411,x
                    sbc $fc
                    sta $1411,x
                    lda $1412,x
                    sbc $fd
                    jmp L12dc
                    
L10fe               ldy $13fd,x
                    jmp L12ce
                    
L1104               sta $110f
                    rts
                    
L1108               sta $1198
                    rts
                    
L110c               ldx #$00
                    ldy #$00
                    bmi L1142
                    txa
                    ldx #$29
L1115               sta $13cf,x
                    dex
                    bpl L1115
                    sta d415_sFiltFreqLo
                    sta $1191
                    sta L1142 + 1
                    stx $110f
                    tax
                    jsr S1132
                    ldx #$07
                    jsr S1132
                    ldx #$0e
S1132               lda #$05
                    sta $13fb,x
                    lda #$01
                    sta $13fc,x
                    sta $13fe,x
                    jmp L13c5
                    
L1142               ldy #$00
                    beq L118b
                    lda #$00
                    bne L116d
                    lda $16b8,y
                    beq L1161
                    bpl L116a
                    asl a
                    sta $1196
                    lda $16ea,y
                    sta $1191
                    lda $16b9,y
                    bne L117f
                    iny
L1161               lda $16ea,y
                    sta L118b + 1
                    jmp L117c
                    
L116a               sta $1147
L116d               lda $16ea,y
                    clc
                    adc L118b + 1
                    sta L118b + 1
                    dec $1147
                    bne L118d
L117c               lda $16b9,y
L117f               cmp #$ff
                    iny
                    tya
                    bcc L1188
                    lda $16ea,y
L1188               sta L1142 + 1
L118b               lda #$00
L118d               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S11a6
                    ldx #$07
                    jsr S11a6
                    ldx #$0e
S11a6               dec $13fc,x
                    beq L11c7
                    bpl L11b3
                    lda $13fb,x
                    sta $13fc,x
L11b3               jmp L1278
                    
L11b6               sbc #$d0
                    inc $13d1,x
                    cmp $13d1,x
                    bne L120c
                    lda #$00
                    sta $13d1,x
                    beq L1207
L11c7               ldy $13d4,x
                    lda $1009,y
                    sta $126d
                    sta $1276
                    lda $13d2,x
                    bne L120c
                    ldy $13f9,x
                    lda $14f6,y
                    sta $fc
                    lda $14f9,y
                    sta $fd
                    ldy $13cf,x
                    lda ($fc),y
                    cmp #$ff
                    bcc L11f4
                    iny
                    lda ($fc),y
                    tay
                    lda ($fc),y
L11f4               cmp #$e0
                    bcc L1200
                    sbc #$f0
                    sta $13d0,x
                    iny
                    lda ($fc),y
L1200               cmp #$d0
                    bcs L11b6
                    sta $13fa,x
L1207               iny
                    tya
                    sta $13cf,x
L120c               ldy $13fe,x
                    lda $13e6,x
                    beq L1272
                    sec
                    sbc #$60
                    sta $13fd,x
                    lda #$00
                    sta $13e4,x
                    sta $13e6,x
                    lda $1629,y
                    sta $140f,x
                    lda $1614,y
                    sta $13e5,x
                    lda $13d4,x
                    cmp #$03
                    beq L1272
                    lda $15ab,y
                    sta $1423,x
                    lda $15c0,y
                    sta $1424,x
                    lda $15ea,y
                    beq L124e
                    sta $13e9,x
                    lda #$00
                    sta $13ea,x
L124e               lda $15ff,y
                    beq L125b
                    sta L1142 + 1
                    lda #$00
                    sta $1147
L125b               lda #$09
                    sta $13e8,x
                    inc $13ff,x
                    lda $15d5,y
                    sta $13e7,x
                    lda $13d5,x
                    jsr S1040
                    jmp L13a4
                    
L1272               lda $13d5,x
                    jsr S1040
L1278               ldy $13e7,x
                    beq L12ad
                    lda $163e,y
                    cmp #$10
                    bcs L128e
                    cmp $1410,x
                    beq L1293
                    inc $1410,x
                    bne L12ad
L128e               sbc #$10
                    sta $13e8,x
L1293               lda $163f,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12a0
                    clc
                    lda $166f,y
L12a0               sta $13e7,x
                    lda #$00
                    sta $1410,x
                    lda $166e,y
                    bne L12c6
L12ad               lda $13fc,x
                    beq L12e2
                    ldy $13e4,x
                    lda $1019,y
                    sta $12c4
                    ldy $13e5,x
                    lda $1723,y
                    sta $fc
                    jmp L1087
                    
L12c6               bpl L12cd
                    adc $13fd,x
                    and #$7f
L12cd               tay
L12ce               lda #$00
                    sta $140e,x
                    lda $1436,y
                    sta $1411,x
                    lda $1496,y
L12dc               sta $1412,x
L12df               lda $13fc,x
L12e2               cmp #$02
                    beq L1329
                    ldy $13e9,x
                    beq L1326
                    ora $13d2,x
                    beq L1326
                    lda $13ea,x
                    bne L1306
                    lda $16a0,y
                    bpl L1303
                    lda $16ac,y
                    sta $1413,x
                    jmp L1317
                    
L1303               sta $13ea,x
L1306               lda $1413,x
                    clc
                    adc $16ac,y
                    adc #$00
                    sta $1413,x
                    dec $13ea,x
                    bne L1326
L1317               lda $16a1,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1323
                    lda $16ac,y
L1323               sta $13e9,x
L1326               jmp L13a4
                    
L1329               ldy $13fa,x
                    lda $14fc,y
                    sta $fc
                    lda $1554,y
                    sta $fd
                    ldy $13d2,x
                    lda ($fc),y
                    cmp #$40
                    bcc L1357
                    cmp #$60
                    bcc L1361
                    cmp #$c0
                    bcc L1375
                    lda $13d3,x
                    bne L134e
                    lda ($fc),y
L134e               adc #$00
                    sta $13d3,x
                    beq L139b
                    bne L13a4
L1357               sta $13fe,x
                    iny
                    lda ($fc),y
                    cmp #$60
                    bcs L1375
L1361               cmp #$50
                    and #$0f
                    sta $13d4,x
                    beq L1370
                    iny
                    lda ($fc),y
                    sta $13d5,x
L1370               bcs L139b
                    iny
                    lda ($fc),y
L1375               cmp #$bd
                    bcc L137f
                    beq L139b
                    ora #$f0
                    bne L1398
L137f               adc $13d0,x
                    sta $13e6,x
                    lda $13d4,x
                    cmp #$03
                    beq L139b
                    lda #$0f
                    sta $1423,x
                    lda #$00
                    sta $1424,x
                    lda #$fe
L1398               sta $13ff,x
L139b               iny
                    lda ($fc),y
                    beq L13a1
                    tya
L13a1               sta $13d2,x
L13a4               lda $1423,x
                    sta d405_sVoc1AttDec,x
                    lda $1424,x
                    sta d406_sVoc1SusRel,x
                    lda $1413,x
                    sta d402_sVoc1PWidthLo,x
                    sta d403_sVoc1PWidthHi,x
                    lda $1411,x
                    sta d400_sVoc1FreqLo,x
                    lda $1412,x
                    sta d401_sVoc1FreqHi,x
L13c5               lda $13e8,x
                    and $13ff,x
                    sta d404_sVoc1Control,x
                    rts

	.binary "mar_data.bin"
