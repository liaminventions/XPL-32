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
  jsr putbut
  lda #0 ; Song Number
  jsr InitSid
  cli
  nop

; You can put code you want to run in the backround here.

loop:
  jmp loop

irq:
  lda #$40
  sta $b00d
  jsr putbut
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

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

  .org $1000

InitSid             jmp L113d
                    
PlaySid             jmp L1141
                    
L1006               jmp L108c

  .binary "64_ASCII.bin"
                    
S1040               lda $1722,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $14e4,x
                    tya
L104d               sta $14bb,x
                    lda $14aa,x
                    sta $14ba,x
                    rts
                    
L1057               sta $14f9,x
                    rts
                    
L105b               sta $14fa,x
                    rts
                    
L105f               sta $14be,x
                    rts
                    
L1063               sta $14bd,x
                    lda #$00
                    sta $14e6,x
                    rts
                    
L106c               sta $14bf,x
                    lda #$00
                    sta $14c0,x
                    rts
                    
L1075               ldy #$00
                    sty $117c
L107a               sta L1177 + 1
                    rts
                    
L107e               sta $11c6
                    beq L107a
                    rts
                    
L1084               sta L11c0 + 1
                    rts
                    
L1088               cmp #$10
                    bcs L1090
L108c               sta $11cd
                    rts
                    
L1090               sta $103f
                    rts
                    
L1094               tay
                    lda $1a1b,y
                    sta $101e
                    lda $1a2c,y
                    sta $101f
                    lda #$00
                    beq L10a7
                    bmi L10b1
L10a7               sta $14d1
                    sta $14d8
                    sta $14df
                    rts
                    
L10b1               and #$7f
                    sta $14d1,x
                    rts
                    
L10b7               dec $14e5,x
L10ba               jmp L1373
                    
L10bd               beq L10ba
                    lda $14e5,x
                    bne L10b7
                    lda $1a1b,y
                    bmi L10cd
                    ldy #$00
                    sty $fd
L10cd               and #$7f
                    sta $10d8
                    lda $14e4,x
                    bmi L10df
                    cmp #$00
                    bcc L10e0
                    beq L10df
                    eor #$ff
L10df               clc
L10e0               adc #$02
                    sta $14e4,x
                    lsr a
                    bcc L1110
                    bcs L1127
                    tya
                    beq L1137
                    lda #$00
                    cmp #$02
                    bcc L1110
                    beq L1127
                    ldy $14d3,x
                    lda $14e7,x
                    sbc $150e,y
                    pha
                    lda $14e8,x
                    sbc $156e,y
                    tay
                    pla
                    bcs L1120
                    adc $fc
                    tya
                    adc $fd
                    bpl L1137
L1110               lda $14e7,x
                    adc $fc
                    sta $14e7,x
                    lda $14e8,x
                    adc $fd
                    jmp L1370
                    
L1120               sbc $fc
                    tya
                    sbc $fd
                    bmi L1137
L1127               lda $14e7,x
                    sbc $fc
                    sta $14e7,x
                    lda $14e8,x
                    sbc $fd
                    jmp L1370
                    
L1137               lda $14d3,x
                    jmp L135e
                    
L113d               sta $1144
                    rts
                    
L1141               ldx #$00
                    ldy #$00
                    bmi L1177
                    txa
                    ldx #$29
L114a               sta $14a5,x
                    dex
                    bpl L114a
                    sta d415_sFiltFreqLo
                    sta $11c6
                    sta L1177 + 1
                    stx $1144
                    tax
                    jsr S1167
                    ldx #$07
                    jsr S1167
                    ldx #$0e
S1167               lda #$05
                    sta $14d1,x
                    lda #$01
                    sta $14d2,x
                    sta $14d4,x
                    jmp L146a
                    
L1177               ldy #$00
                    beq L11c0
                    lda #$00
                    bne L11a2
                    lda $1970,y
                    beq L1196
                    bpl L119f
                    asl a
                    sta $11cb
                    lda $19c5,y
                    sta $11c6
                    lda $1971,y
                    bne L11b4
                    iny
L1196               lda $19c5,y
                    sta L11c0 + 1
                    jmp L11b1
                    
L119f               sta $117c
L11a2               lda $19c5,y
                    clc
                    adc L11c0 + 1
                    sta L11c0 + 1
                    dec $117c
                    bne L11c2
L11b1               lda $1971,y
L11b4               cmp #$ff
                    iny
                    tya
                    bcc L11bd
                    lda $19c5,y
L11bd               sta L1177 + 1
L11c0               lda #$00
L11c2               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S11db
                    ldx #$07
                    jsr S11db
                    ldx #$0e
S11db               dec $14d2,x
                    beq L120b
                    bpl L11f7
                    lda $14d1,x
                    cmp #$02
                    bcs L11f4
                    tay
                    eor #$01
                    sta $14d1,x
                    lda $101e,y
                    sbc #$00
L11f4               sta $14d2,x
L11f7               jmp L12ce
                    
L11fa               sbc #$d0
                    inc $14a7,x
                    cmp $14a7,x
                    bne L1250
                    lda #$00
                    sta $14a7,x
                    beq L124b
L120b               ldy $14aa,x
                    lda $1009,y
                    sta $12c0
                    sta $12cc
                    lda $14a8,x
                    bne L1250
                    ldy $14cf,x
                    lda $15ce,y
                    sta $fc
                    lda $15d1,y
                    sta $fd
                    ldy $14a5,x
                    lda ($fc),y
                    cmp #$ff
                    bcc L1238
                    iny
                    lda ($fc),y
                    tay
                    lda ($fc),y
L1238               cmp #$e0
                    bcc L1244
                    sbc #$f0
                    sta $14a6,x
                    iny
                    lda ($fc),y
L1244               cmp #$d0
                    bcs L11fa
                    sta $14d0,x
L124b               iny
                    tya
                    sta $14a5,x
L1250               ldy $14d4,x
                    lda $1770,y
                    sta $14fe,x
                    lda $14bc,x
                    beq L12c8
                    sec
                    sbc #$60
                    sta $14d3,x
                    lda #$00
                    sta $14ba,x
                    sta $14bc,x
                    lda $1749,y
                    sta $14e5,x
                    lda $1722,y
                    sta $14bb,x
                    lda $14aa,x
                    cmp #$03
                    beq L12c8
                    lda $1797,y
                    beq L1290
                    cmp #$fe
                    bcs L128d
                    sta $14be,x
                    lda #$ff
L128d               sta $14d5,x
L1290               lda $16d4,y
                    beq L129d
                    sta $14bf,x
                    lda #$00
                    sta $14c0,x
L129d               lda $16fb,y
                    beq L12aa
                    sta L1177 + 1
                    lda #$00
                    sta $117c
L12aa               lda $16ad,y
                    sta $14bd,x
                    lda $1686,y
                    sta $14fa,x
                    lda $165f,y
                    sta $14f9,x
                    lda $14ab,x
                    jsr S1040
                    jmp L1446
                    
L12c5               jmp L147a
                    
L12c8               lda $14ab,x
                    jsr S1040
L12ce               ldy $14bd,x
                    beq L130d
                    lda $17be,y
                    cmp #$10
                    bcs L12e4
                    cmp $14e6,x
                    beq L12ed
                    inc $14e6,x
                    bne L130d
L12e4               sbc #$10
                    cmp #$e0
                    bcs L12ed
                    sta $14be,x
L12ed               lda $17bf,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12f9
                    lda $1854,y
L12f9               sta $14bd,x
                    lda #$00
                    sta $14e6,x
                    lda $17bd,y
                    cmp #$e0
                    bcs L12c5
                    lda $1853,y
                    bne L1357
L130d               ldy $14ba,x
                    sty $10ee
                    lda $1019,y
                    sta L1354 + 1
                    ldy $14bb,x
L131c               lda $1a1b,y
                    bmi L132b
                    sta $fd
                    lda $1a2c,y
                    sta $fc
                    jmp L1354
                    
L132b               lda $1a2c,y
                    sta $1347
                    sty L1350 + 1
                    ldy $14ff,x
                    lda $150f,y
                    sec
                    sbc $150e,y
                    sta $fc
                    lda $156f,y
                    sbc $156e,y
                    ldy #$00
                    beq L1350
L134a               lsr a
                    ror $fc
                    dey
                    bne L134a
L1350               ldy #$00
                    sta $fd
L1354               jmp L10bd
                    
L1357               bpl L135e
                    adc $14d3,x
                    and #$7f
L135e               sta $14ff,x
                    tay
                    lda #$00
                    sta $14e4,x
                    lda $150e,y
                    sta $14e7,x
                    lda $156e,y
L1370               sta $14e8,x
L1373               ldy $14bf,x
                    beq L13b9
                    lda $14c0,x
                    bne L1391
                    lda $18ea,y
                    bpl L138e
                    sta $14ea,x
                    lda $192d,y
                    sta $14e9,x
                    jmp L13aa
                    
L138e               sta $14c0,x
L1391               lda $192d,y
                    clc
                    bpl L139a
                    dec $14ea,x
L139a               adc $14e9,x
                    sta $14e9,x
                    bcc L13a5
                    inc $14ea,x
L13a5               dec $14c0,x
                    bne L13b9
L13aa               lda $18eb,y
                    cmp #$ff
                    iny
                    tya
                    bcc L13b6
                    lda $192d,y
L13b6               sta $14bf,x
L13b9               lda $14d2,x
                    cmp $14fe,x
                    beq L13c4
                    jmp L1446
                    
L13c4               ldy $14d0,x
                    lda $15d4,y
                    sta $fc
                    lda $161a,y
                    sta $fd
                    ldy $14a8,x
                    lda ($fc),y
                    cmp #$40
                    bcc L13f2
                    cmp #$60
                    bcc L13fc
                    cmp #$c0
                    bcc L1410
                    lda $14a9,x
                    bne L13e9
                    lda ($fc),y
L13e9               adc #$00
                    sta $14a9,x
                    beq L143d
                    bne L1446
L13f2               sta $14d4,x
                    iny
                    lda ($fc),y
                    cmp #$60
                    bcs L1410
L13fc               cmp #$50
                    and #$0f
                    sta $14aa,x
                    beq L140b
                    iny
                    lda ($fc),y
                    sta $14ab,x
L140b               bcs L143d
                    iny
                    lda ($fc),y
L1410               cmp #$bd
                    bcc L141a
                    beq L143d
                    ora #$f0
                    bne L143a
L141a               adc $14a6,x
                    sta $14bc,x
                    lda $14aa,x
                    cmp #$03
                    beq L143d
                    lda $14d4,x
                    cmp #$24
                    bcs L1474
                    lda #$00
                    sta $14fa,x
                    lda #$0f
                    sta $14f9,x
L1438               lda #$fe
L143a               sta $14d5,x
L143d               iny
                    lda ($fc),y
                    beq L1443
                    tya
L1443               sta $14a8,x
L1446               lda $14e9,x
                    sta d402_sVoc1PWidthLo,x
                    lda $14ea,x
                    sta d403_sVoc1PWidthHi,x
                    lda $14fa,x
                    sta d406_sVoc1SusRel,x
                    lda $14f9,x
                    sta d405_sVoc1AttDec,x
                    lda $14e7,x
                    sta d400_sVoc1FreqLo,x
                    lda $14e8,x
                    sta d401_sVoc1FreqHi,x
L146a               lda $14be,x
                    and $14d5,x
                    sta d404_sVoc1Control,x
                    rts
                    
L1474               cmp #$24
                    bcc L1438
                    bcs L143d
L147a               and #$0f
                    sta $fc
                    lda $1853,y
                    sta $fd
                    ldy $fc
                    cpy #$05
                    bcs L1497
                    sty $10ee
                    lda $1019,y
                    sta L1354 + 1
                    ldy $fd
                    jmp L131c
                    
L1497               lda $1009,y
                    sta $14a0
                    lda $fd
                    jsr S1040
                    jmp L1373
                    
  .binary "64_Data.bin"
