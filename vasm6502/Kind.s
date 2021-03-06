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

InitSid             jmp L10fb
                    
PlaySid             jmp L10ff
 
  .binary "Kind_ASCII.bin"
                   
S1040               lda $15c5,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $13de,x
                    tya
L104d               sta $13b5,x
                    lda $13a4,x
                    sta $13b4,x
                    rts
                    
L1057               sta d406_sVoc1SusRel,x
                    rts
                    
L105b               ldy #$00
                    sty $113a
L1060               sta L1135 + 1
                    rts
                    
L1064               sta $1184
                    beq L1060
                    rts
                    
L106a               sta L117e + 1
                    rts
                    
L106e               sta $13cb
                    sta $13d2
                    sta $13d9
                    rts
                    
L1078               dec $13df,x
L107b               jmp L12ac
                    
L107e               beq L107b
                    lda $13df,x
                    bne L1078
                    lda #$00
                    sta $03
                    lda $13de,x
                    bmi L1097
                    cmp $17c0,y
                    bcc L1098
                    beq L1097
                    eor #$ff
L1097               clc
L1098               adc #$02
                    sta $13de,x
                    lsr a
                    bcc L10ce
                    bcs L10e5
                    tya
                    beq L10f5
                    lda $17c0,y
                    sta $03
                    lda $13b4,x
                    cmp #$02
                    bcc L10ce
                    beq L10e5
                    ldy $13cd,x
                    lda $13e1,x
                    sbc $13ff,y
                    pha
                    lda $13e2,x
                    sbc $1456,y
                    tay
                    pla
                    bcs L10de
                    adc $02
                    tya
                    adc $03
                    bpl L10f5
L10ce               lda $13e1,x
                    adc $02
                    sta $13e1,x
                    lda $13e2,x
                    adc $03
                    jmp L12a9
                    
L10de               sbc $02
                    tya
                    sbc $03
                    bmi L10f5
L10e5               lda $13e1,x
                    sbc $02
                    sta $13e1,x
                    lda $13e2,x
                    sbc $03
                    jmp L12a9
                    
L10f5               ldy $13cd,x
                    jmp L129b
                    
L10fb               sta $1102
                    rts
                    
L10ff               ldx #$00
                    ldy #$00
                    bmi L1135
                    txa
                    ldx #$29
L1108               sta $139f,x
                    dex
                    bpl L1108
                    sta d415_sFiltFreqLo
                    sta $1184
                    sta L1135 + 1
                    stx $1102
                    tax
                    jsr S1125
                    ldx #$07
                    jsr S1125
                    ldx #$0e
S1125               lda #$05
                    sta $13cb,x
                    lda #$01
                    sta $13cc,x
                    sta $13ce,x
                    jmp L1395
                    
L1135               ldy #$00
                    beq L117e
                    lda #$00
                    bne L1160
                    lda $1763,y
                    beq L1154
                    bpl L115d
                    asl a
                    sta $1189
                    lda $1791,y
                    sta $1184
                    lda $1764,y
                    bne L1172
                    iny
L1154               lda $1791,y
                    sta L117e + 1
                    jmp L116f
                    
L115d               sta $113a
L1160               lda $1791,y
                    clc
                    adc L117e + 1
                    sta L117e + 1
                    dec $113a
                    bne L1180
L116f               lda $1764,y
L1172               cmp #$ff
                    iny
                    tya
                    bcc L117b
                    lda $1791,y
L117b               sta L1135 + 1
L117e               lda #$00
L1180               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S1199
                    ldx #$07
                    jsr S1199
                    ldx #$0e
S1199               dec $13cc,x
                    beq L11a9
                    bpl L11a6
                    lda $13cb,x
                    sta $13cc,x
L11a6               jmp L125d
                    
L11a9               ldy $13a4,x
                    lda $1006,y
                    sta $1252
                    sta $125b
                    lda $13a2,x
                    bne L11ea
                    ldy $13c9,x
                    lda $14b6,y
                    sta $02
                    lda $14b9,y
                    sta $03
                    ldy $139f,x
                    lda ($02),y
                    cmp #$ff
                    bcc L11d6
                    iny
                    lda ($02),y
                    tay
                    lda ($02),y
L11d6               cmp #$e0
                    bcc L11e2
                    sbc #$f0
                    sta $13a0,x
                    iny
                    lda ($02),y
L11e2               sta $13ca,x
                    iny
                    tya
                    sta $139f,x
L11ea               ldy $13ce,x
                    lda $1605,y
                    sta $13f8,x
                    lda $13b6,x
                    beq L1257
                    sec
                    sbc #$60
                    sta $13cd,x
                    lda #$00
                    sta $13b4,x
                    sta $13b6,x
                    lda $15e5,y
                    sta $13df,x
                    lda $15c5,y
                    sta $13b5,x
                    lda $13a4,x
                    cmp #$03
                    beq L1257
                    lda $1625,y
                    sta $13b8,x
                    inc $13cf,x
                    lda $1585,y
                    beq L122f
                    sta $13b9,x
                    lda #$00
                    sta $13ba,x
L122f               lda $15a5,y
                    beq L123c
                    sta L1135 + 1
                    lda #$00
                    sta $113a
L123c               lda $1565,y
                    sta $13b7,x
                    lda $1545,y
                    sta d406_sVoc1SusRel,x
                    lda $1525,y
                    sta d405_sVoc1AttDec,x
                    lda $13a5,x
                    jsr S1040
                    jmp L1395
                    
L1257               lda $13a5,x
                    jsr S1040
L125d               ldy $13b7,x
                    beq L127f
                    lda $1645,y
                    beq L126a
                    sta $13b8,x
L126a               lda $1646,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1277
                    clc
                    lda $169e,y
L1277               sta $13b7,x
                    lda $169d,y
                    bne L1293
L127f               ldy $13b4,x
                    lda $1016,y
                    sta $1291
                    ldy $13b5,x
                    lda $17ca,y
                    sta $02
                    jmp L107e
                    
L1293               bpl L129a
                    adc $13cd,x
                    and #$7f
L129a               tay
L129b               lda #$00
                    sta $13de,x
                    lda $13ff,y
                    sta $13e1,x
                    lda $1456,y
L12a9               sta $13e2,x
L12ac               lda $13cc,x
                    cmp $13f8,x
                    beq L130e
                    ldy $13b9,x
                    beq L130b
                    ora $13a2,x
                    beq L130b
                    lda $13ba,x
                    bne L12d7
                    lda $16f7,y
                    bpl L12d4
                    sta $13e4,x
                    lda $172d,y
                    sta $13e3,x
                    jmp L12f0
                    
L12d4               sta $13ba,x
L12d7               lda $172d,y
                    clc
                    bpl L12e0
                    dec $13e4,x
L12e0               adc $13e3,x
                    sta $13e3,x
                    bcc L12eb
                    inc $13e4,x
L12eb               dec $13ba,x
                    bne L1302
L12f0               lda $16f8,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12fc
                    lda $172d,y
L12fc               sta $13b9,x
                    lda $13e3,x
L1302               sta d402_sVoc1PWidthLo,x
                    lda $13e4,x
                    sta d403_sVoc1PWidthHi,x
L130b               jmp L1389
                    
L130e               ldy $13ca,x
                    lda $14bc,y
                    sta $02
                    lda $14f1,y
                    sta $03
                    ldy $13a2,x
                    lda ($02),y
                    cmp #$40
                    bcc L133c
                    cmp #$60
                    bcc L1346
                    cmp #$c0
                    bcc L135a
                    lda $13a3,x
                    bne L1333
                    lda ($02),y
L1333               adc #$00
                    sta $13a3,x
                    beq L1380
                    bne L1389
L133c               sta $13ce,x
                    iny
                    lda ($02),y
                    cmp #$60
                    bcs L135a
L1346               cmp #$50
                    and #$0f
                    sta $13a4,x
                    beq L1355
                    iny
                    lda ($02),y
                    sta $13a5,x
L1355               bcs L1380
                    iny
                    lda ($02),y
L135a               cmp #$bd
                    bcc L1364
                    beq L1380
                    ora #$f0
                    bne L137d
L1364               adc $13a0,x
                    sta $13b6,x
                    lda $13a4,x
                    cmp #$03
                    beq L1380
                    lda #$00
                    sta d406_sVoc1SusRel,x
                    lda #$0f
                    sta d405_sVoc1AttDec,x
                    lda #$fe
L137d               sta $13cf,x
L1380               iny
                    lda ($02),y
                    beq L1386
                    tya
L1386               sta $13a2,x
L1389               lda $13e1,x
                    sta d400_sVoc1FreqLo,x
                    lda $13e2,x
                    sta d401_sVoc1FreqHi,x
L1395               lda $13b8,x
                    and $13cf,x
                    sta d404_sVoc1Control,x
                    rts

  .binary "Kind_Data.bin"

