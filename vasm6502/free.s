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
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
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


  .org $1000

InitSid             jmp L10cd
                    
PlaySid             jmp L10d1
                    
S1006               lda $15d6,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $1412,x
                    tya
L1013               sta $13e9,x
                    lda $13d8,x
                    sta $13e8,x
                    rts
                    
L101d               sta $1427,x
                    rts
                    
L1021               sta $13ec,x
                    rts
                    
L1025               sta $13eb,x
                    lda #$00
                    sta $1414,x
                    rts
                    
L102e               ldy #$00
                    sty $110c
L1033               sta L1107 + 1
                    rts
                    
L1037               sta $1156
                    beq L1033
                    rts
                    
L103d               sta L1150 + 1
                    rts
                    
L1041               sta $13ff
                    sta $1406
                    sta $140d
                    rts
                    
L104b               dec $1413,x
L104e               jmp L129a
                    
L1051               beq L104e
                    lda $1413,x
                    bne L104b
                    lda #$00
                    sta $fd
                    lda $1412,x
                    bmi L106a
                    cmp $178f,y
                    bcc L106b
                    beq L106a
                    eor #$ff
L106a               clc
L106b               adc #$02
                    sta $1412,x
                    lsr a
                    bcc L10a0
                    bcs L10b7
                    tya
                    beq L10c7
                    lda $178f,y
                    sta $fd
                    lda #$00
                    cmp #$02
                    bcc L10a0
                    beq L10b7
                    ldy $1401,x
                    lda $1415,x
                    sbc $143c,y
                    pha
                    lda $1416,x
                    sbc $149c,y
                    tay
                    pla
                    bcs L10b0
                    adc $fc
                    tya
                    adc $fd
                    bpl L10c7
L10a0               lda $1415,x
                    adc $fc
                    sta $1415,x
                    lda $1416,x
                    adc $fd
                    jmp L1297
                    
L10b0               sbc $fc
                    tya
                    sbc $fd
                    bmi L10c7
L10b7               lda $1415,x
                    sbc $fc
                    sta $1415,x
                    lda $1416,x
                    sbc $fd
                    jmp L1297
                    
L10c7               ldy $1401,x
                    jmp L1289
                    
L10cd               sta $10d4
                    rts
                    
L10d1               ldx #$00
                    ldy #$00
                    bmi L1107
                    txa
                    ldx #$29
L10da               sta $13d3,x
                    dex
                    bpl L10da
                    sta d415_sFiltFreqLo
                    sta $1156
                    sta L1107 + 1
                    stx $10d4
                    tax
                    jsr S10f7
                    ldx #$07
                    jsr S10f7
                    ldx #$0e
S10f7               lda #$05
                    sta $13ff,x
                    lda #$01
                    sta $1400,x
                    sta $1402,x
                    jmp L1389
                    
L1107               ldy #$00
                    beq L1150
                    lda #$00
                    bne L1132
                    lda $1732,y
                    beq L1126
                    bpl L112f
                    asl a
                    sta $115b
                    lda $1760,y
                    sta $1156
                    lda $1733,y
                    bne L1144
                    iny
L1126               lda $1760,y
                    sta L1150 + 1
                    jmp L1141
                    
L112f               sta $110c
L1132               lda $1760,y
                    clc
                    adc L1150 + 1
                    sta L1150 + 1
                    dec $110c
                    bne L1152
L1141               lda $1733,y
L1144               cmp #$ff
                    iny
                    tya
                    bcc L114d
                    lda $1760,y
L114d               sta L1107 + 1
L1150               lda #$00
L1152               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S116b
                    ldx #$07
                    jsr S116b
                    ldx #$0e
S116b               dec $1400,x
                    beq L117b
                    bpl L1178
                    lda $13ff,x
                    sta $1400,x
L1178               jmp L122b
                    
L117b               ldy $13d8,x
                    lda $13be,y
                    sta $121d
                    sta $1229
                    lda $13d6,x
                    bne L11bc
                    ldy $13fd,x
                    lda $14fc,y
                    sta $fc
                    lda $14ff,y
                    sta $fd
                    ldy $13d3,x
                    lda ($fc),y
                    cmp #$ff
                    bcc L11a8
                    iny
                    lda ($fc),y
                    tay
                    lda ($fc),y
L11a8               cmp #$e0
                    bcc L11b4
                    sbc #$f0
                    sta $13d4,x
                    iny
                    lda ($fc),y
L11b4               sta $13fe,x
                    iny
                    tya
                    sta $13d3,x
L11bc               ldy $1402,x
                    lda $13ea,x
                    beq L1225
                    sec
                    sbc #$60
                    sta $1401,x
                    lda #$00
                    sta $13e8,x
                    sta $13ea,x
                    lda $15eb,y
                    sta $1413,x
                    lda $15d6,y
                    sta $13e9,x
                    lda $13d8,x
                    cmp #$03
                    beq L1225
                    lda #$09
                    sta $13ec,x
                    inc $1403,x
                    lda $15ac,y
                    beq L11fa
                    sta $13ed,x
                    lda #$00
                    sta $13ee,x
L11fa               lda $15c1,y
                    beq L1207
                    sta L1107 + 1
                    lda #$00
                    sta $110c
L1207               lda $1597,y
                    sta $13eb,x
                    lda $1582,y
                    sta $1428,x
                    lda $156d,y
                    sta $1427,x
                    lda $13d9,x
                    jsr S1006
                    jmp L1365
                    
L1222               jmp L1393
                    
L1225               lda $13d9,x
                    jsr S1006
L122b               ldy $13eb,x
                    beq L126a
                    lda $1600,y
                    cmp #$10
                    bcs L1241
                    cmp $1414,x
                    beq L124a
                    inc $1414,x
                    bne L126a
L1241               sbc #$10
                    cmp #$e0
                    bcs L124a
                    sta $13ec,x
L124a               lda $1601,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1256
                    lda $1683,y
L1256               sta $13eb,x
                    lda #$00
                    sta $1414,x
                    lda $15ff,y
                    cmp #$e0
                    bcs L1222
                    lda $1682,y
                    bne L1281
L126a               ldy $13e8,x
                    sty $107e
                    lda $13ce,y
                    sta $127f
                    ldy $13e9,x
L1279               lda $179a,y
                    sta $fc
                    jmp L1051
                    
L1281               bpl L1288
                    adc $1401,x
                    and #$7f
L1288               tay
L1289               lda #$00
                    sta $1412,x
                    lda $143c,y
                    sta $1415,x
                    lda $149c,y
L1297               sta $1416,x
L129a               ldy $13ed,x
                    beq L12e0
                    lda $13ee,x
                    bne L12b8
                    lda $1706,y
                    bpl L12b5
                    sta $1418,x
                    lda $171c,y
                    sta $1417,x
                    jmp L12d1
                    
L12b5               sta $13ee,x
L12b8               lda $171c,y
                    clc
                    bpl L12c1
                    dec $1418,x
L12c1               adc $1417,x
                    sta $1417,x
                    bcc L12cc
                    inc $1418,x
L12cc               dec $13ee,x
                    bne L12e0
L12d1               lda $1707,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12dd
                    lda $171c,y
L12dd               sta $13ed,x
L12e0               lda $1400,x
                    cmp #$02
                    beq L12ea
                    jmp L1365
                    
L12ea               ldy $13fe,x
                    lda $1502,y
                    sta $fc
                    lda $1538,y
                    sta $fd
                    ldy $13d6,x
                    lda ($fc),y
                    cmp #$40
                    bcc L1318
                    cmp #$60
                    bcc L1322
                    cmp #$c0
                    bcc L1336
                    lda $13d7,x
                    bne L130f
                    lda ($fc),y
L130f               adc #$00
                    sta $13d7,x
                    beq L135c
                    bne L1365
L1318               sta $1402,x
                    iny
                    lda ($fc),y
                    cmp #$60
                    bcs L1336
L1322               cmp #$50
                    and #$0f
                    sta $13d8,x
                    beq L1331
                    iny
                    lda ($fc),y
                    sta $13d9,x
L1331               bcs L135c
                    iny
                    lda ($fc),y
L1336               cmp #$bd
                    bcc L1340
                    beq L135c
                    ora #$f0
                    bne L1359
L1340               adc $13d4,x
                    sta $13ea,x
                    lda $13d8,x
                    cmp #$03
                    beq L135c
                    lda #$f0
                    sta $1428,x
                    lda #$0f
                    sta $1427,x
                    lda #$fe
L1359               sta $1403,x
L135c               iny
                    lda ($fc),y
                    beq L1362
                    tya
L1362               sta $13d6,x
L1365               lda $1427,x
                    sta d405_sVoc1AttDec,x
                    lda $1428,x
                    sta d406_sVoc1SusRel,x
                    lda $1417,x
                    sta d402_sVoc1PWidthLo,x
                    lda $1418,x
                    sta d403_sVoc1PWidthHi,x
                    lda $1415,x
                    sta d400_sVoc1FreqLo,x
                    lda $1416,x
                    sta d401_sVoc1FreqHi,x
L1389               lda $13ec,x
                    and $1403,x
                    sta d404_sVoc1Control,x
                    rts
                    
L1393               and #$0f
                    sta $fc
                    lda $1682,y
                    sta $fd
                    ldy $fc
                    cpy #$05
                    bcs L13b0
                    sty $107e
                    lda $13ce,y
                    sta $127f
                    ldy $fd
                    jmp L1279
                    
L13b0               lda $13be,y
                    sta $13b9
                    lda $fd
                    jsr S1006
                    jmp L129a
                    
                                                             
  .binary "free.bin"
