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
  sta $b00d

  lda #0 ; Song Numbehr
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
  rti

putbut
                    ldx #$63
                    stx $b004
                    stx $b006
                    ldx #$26
                    stx $b005
                    stx $b007
                    rts
                    
  .org $0ff6

InitSid             ldx #$63
                    stx $b004
                    ldx #$26
                    stx $b005
                    jmp L111c

PlaySid             jmp L1120
                    
L1006               jmp L1083
                    
                      .binary "Aaah_ASCII.bin" 
S1040               lda $16ae,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $1455,x
                    tya
L104d               sta $142c,x
                    lda $141b,x
                    sta $142b,x
                    rts
                    
L1057               sta $146a,x
                    rts
                    
L105b               sta $146b,x
                    rts
                    
L105f               sta $142e,x
                    rts
                    
L1063               sta $1430,x
                    lda #$00
                    sta $1431,x
                    rts
                    
L106c               ldy #$00
                    sty $115b
L1071               sta L1156 + 1
                    rts
                    
L1075               sta $11a5
                    beq L1071
                    rts
                    
L107b               sta L119f + 1
                    rts
                    
L107f               cmp #$10
                    bcs L1087
L1083               sta $11ac
                    rts
                    
L1087               sta $103f
                    rts
                    
L108b               sta $1442
                    sta $1449
                    sta $1450
                    rts
                    
L1095               dec $1456,x
L1098               jmp L130a
                    
L109b               beq L1098
                    lda $1456,x
                    bne L1095
                    lda $19bd,y
                    bmi L10ab
                    ldy #$00
                    sty $fc
L10ab               and #$7f
                    sta $10b6
                    lda $1455,x
                    bmi L10bd
                    cmp #$00
                    bcc L10be
                    beq L10bd
                    eor #$ff
L10bd               clc
L10be               adc #$02
                    sta $1455,x
                    lsr a
                    bcc L10ef
                    bcs L1106
                    tya
                    beq L1116
                    lda $142b,x
                    cmp #$02
                    bcc L10ef
                    beq L1106
                    ldy $1444,x
                    lda $1458,x
                    sbc $147f,y
                    pha
                    lda $1459,x
                    sbc $14df,y
                    tay
                    pla
                    bcs L10ff
                    adc $fb
                    tya
                    adc $fc
                    bpl L1116
L10ef               lda $1458,x
                    adc $fb
                    sta $1458,x
                    lda $1459,x
                    adc $fc
                    jmp L1307
                    
L10ff               sbc $fb
                    tya
                    sbc $fc
                    bmi L1116
L1106               lda $1458,x
                    sbc $fb
                    sta $1458,x
                    lda $1459,x
                    sbc $fc
                    jmp L1307
                    
L1116               lda $1444,x
                    jmp L12f5
                    
L111c               sta $1123
                    rts
                    
L1120               ldx #$00
                    ldy #$00
                    bmi L1156
                    txa
                    ldx #$29
L1129               sta $1416,x
                    dex
                    bpl L1129
                    sta d415_sFiltFreqLo
                    sta $11a5
                    sta L1156 + 1
                    stx $1123
                    tax
                    jsr S1146
                    ldx #$07
                    jsr S1146
                    ldx #$0e
S1146               lda #$0b
                    sta $1442,x
                    lda #$01
                    sta $1443,x
                    sta $1445,x
                    jmp L1406
                    
L1156               ldy #$00
                    beq L119f
                    lda #$00
                    bne L1181
                    lda $198e,y
                    beq L1175
                    bpl L117e
                    asl a
                    sta $11aa
                    lda $19a5,y
                    sta $11a5
                    lda $198f,y
                    bne L1193
                    iny
L1175               lda $19a5,y
                    sta L119f + 1
                    jmp L1190
                    
L117e               sta $115b
L1181               lda $19a5,y
                    clc
                    adc L119f + 1
                    sta L119f + 1
                    dec $115b
                    bne L11a1
L1190               lda $198f,y
L1193               cmp #$ff
                    iny
                    tya
                    bcc L119c
                    lda $19a5,y
L119c               sta L1156 + 1
L119f               lda #$00
L11a1               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S11ba
                    ldx #$07
                    jsr S11ba
                    ldx #$0e
S11ba               dec $1443,x
                    beq L11ca
                    bpl L11c7
                    lda $1442,x
                    sta $1443,x
L11c7               jmp L1280
                    
L11ca               ldy $141b,x
                    lda $1009,y
                    sta $1275
                    sta $127e
                    lda $1419,x
                    bne L120b
                    ldy $1440,x
                    lda $153f,y
                    sta $fb
                    lda $1542,y
                    sta $fc
                    ldy $1416,x
                    lda ($fb),y
                    cmp #$ff
                    bcc L11f7
                    iny
                    lda ($fb),y
                    tay
                    lda ($fb),y
L11f7               cmp #$e0
                    bcc L1203
                    sbc #$f0
                    sta $1417,x
                    iny
                    lda ($fb),y
L1203               sta $1441,x
                    iny
                    tya
                    sta $1416,x
L120b               ldy $1445,x
                    lda $1702,y
                    sta $146f,x
                    lda $142d,x
                    beq L127a
                    sec
                    sbc #$60
                    sta $1444,x
                    lda #$00
                    sta $142b,x
                    sta $142d,x
                    lda $16d8,y
                    sta $1456,x
                    lda $16ae,y
                    sta $142c,x
                    lda $141b,x
                    cmp #$03
                    beq L127a
                    lda $172c,y
                    sta $142f,x
                    lda #$ff
                    sta $1446,x
                    lda $165a,y
                    beq L1252
                    sta $1430,x
                    lda #$00
                    sta $1431,x
L1252               lda $1684,y
                    beq L125f
                    sta L1156 + 1
                    lda #$00
                    sta $115b
L125f               lda $1630,y
                    sta $142e,x
                    lda $1606,y
                    sta $146b,x
                    lda $15dc,y
                    sta $146a,x
                    lda $141c,x
                    jsr S1040
                    jmp L13e2
                    
L127a               lda $141c,x
                    jsr S1040
L1280               ldy $142e,x
                    beq L12a2
                    lda $1756,y
                    beq L128d
                    sta $142f,x
L128d               lda $1757,y
                    cmp #$ff
                    iny
                    tya
                    bcc L129a
                    clc
                    lda $1842,y
L129a               sta $142e,x
                    lda $1841,y
                    bne L12ee
L12a2               lda $1443,x
                    beq L130d
                    ldy $142b,x
                    lda $1019,y
                    sta L12eb + 1
                    ldy $142c,x
                    lda $19bd,y
                    bmi L12c2
                    sta $fc
                    lda $19d5,y
                    sta $fb
                    jmp L12eb
                    
L12c2               lda $19d5,y
                    sta $12de
                    sty L12e7 + 1
                    ldy $1470,x
                    lda $1480,y
                    sec
                    sbc $147f,y
                    sta $fb
                    lda $14e0,y
                    sbc $14df,y
                    ldy #$00
                    beq L12e7
L12e1               lsr a
                    ror $fb
                    dey
                    bne L12e1
L12e7               ldy #$00
                    sta $fc
L12eb               jmp L109b
                    
L12ee               bpl L12f5
                    adc $1444,x
                    and #$7f
L12f5               sta $1470,x
                    tay
                    lda #$00
                    sta $1455,x
                    lda $147f,y
                    sta $1458,x
                    lda $14df,y
L1307               sta $1459,x
L130a               lda $1443,x
L130d               cmp $146f,x
                    beq L1360
                    ldy $1430,x
                    beq L135d
                    ora $1419,x
                    beq L135d
                    lda $1431,x
                    bne L1335
                    lda $192e,y
                    bpl L1332
                    sta $145b,x
                    lda $195e,y
                    sta $145a,x
                    jmp L134e
                    
L1332               sta $1431,x
L1335               lda $195e,y
                    clc
                    bpl L133e
                    dec $145b,x
L133e               adc $145a,x
                    sta $145a,x
                    bcc L1349
                    inc $145b,x
L1349               dec $1431,x
                    bne L135d
L134e               lda $192f,y
                    cmp #$ff
                    iny
                    tya
                    bcc L135a
                    lda $195e,y
L135a               sta $1430,x
L135d               jmp L13e2
                    
L1360               ldy $1441,x
                    lda $1545,y
                    sta $fb
                    lda $1591,y
                    sta $fc
                    ldy $1419,x
                    lda ($fb),y
                    cmp #$40
                    bcc L138e
                    cmp #$60
                    bcc L1398
                    cmp #$c0
                    bcc L13ac
                    lda $141a,x
                    bne L1385
                    lda ($fb),y
L1385               adc #$00
                    sta $141a,x
                    beq L13d9
                    bne L13e2
L138e               sta $1445,x
                    iny
                    lda ($fb),y
                    cmp #$60
                    bcs L13ac
L1398               cmp #$50
                    and #$0f
                    sta $141b,x
                    beq L13a7
                    iny
                    lda ($fb),y
                    sta $141c,x
L13a7               bcs L13d9
                    iny
                    lda ($fb),y
L13ac               cmp #$bd
                    bcc L13b6
                    beq L13d9
                    ora #$f0
                    bne L13d6
L13b6               adc $1417,x
                    sta $142d,x
                    lda $141b,x
                    cmp #$03
                    beq L13d9
                    lda $1445,x
                    cmp #$2b
                    bcs L1410
                    lda #$00
                    sta $146b,x
                    lda #$0f
                    sta $146a,x
L13d4               lda #$fe
L13d6               sta $1446,x
L13d9               iny
                    lda ($fb),y
                    beq L13df
                    tya
L13df               sta $1419,x
L13e2               lda $145a,x
                    sta d402_sVoc1PWidthLo,x
                    lda $145b,x
                    sta d403_sVoc1PWidthHi,x
                    lda $146b,x
                    sta d406_sVoc1SusRel,x
                    lda $146a,x
                    sta d405_sVoc1AttDec,x
                    lda $1458,x
                    sta d400_sVoc1FreqLo,x
                    lda $1459,x
                    sta d401_sVoc1FreqHi,x
L1406               lda $142f,x
                    and $1446,x
                    sta d404_sVoc1Control,x
                    rts
                    
L1410               cmp #$2c
                    bcc L13d4
                    bcs L13d9
                    brk

  .binary "Aaah.bin"
