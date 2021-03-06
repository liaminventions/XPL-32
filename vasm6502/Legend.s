d400_sVoc1FreqLo = $b800
d401_sVoc1FreqHi = $b801
d402_sVoc1PWidthLo = $b802
d403_sVoc1PWidthHi = $b803
d404_sVoc1Control = $b804
d405_sVoc1AttDec = $b805
d406_sVoc1SusRel = $b806
d40b_sVoc2Control = $b80b
d412_sVoc3Control = $b812
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
  lda #0 ; Song Number
  jsr InitSid2
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

InitSid2	    phx
		    jsr putbut
		    plx
		    jsr InitSid
		    rts

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

  .org $0fff

InitSid             tay
                    jmp L10c9
                    
PlaySid             nop
                    nop
                    nop
                    nop
                    nop
                    nop
                    jmp L1135
                    
  .binary "Legend_data.bin"

L10c9               lda $18ba,y
                    tay
                    lda $1b91,y
                    sta $1043
                    lda $1b92,y
                    sta $1044
                    lda #$0f
                    sta $104a
                    ldx #$00
L10e0               iny
                    iny
                    lda $1b91,y
                    sta $1069,x
                    sta $106c,x
                    lda $1b92,y
                    sta $1075,x
                    lda $1b93,y
                    sta $1078,x
                    lda #$01
                    sta $1040
                    sta $104b,x
                    sta $1042
                    lda #$00
                    sta $1072,x
                    sta $106f,x
                    sta $107b,x
                    sta $1057,x
                    iny
                    inx
                    cpx #$03
                    bne L10e0
                    sta $10c8
                    sta $1048
                    sta $1049
                    sta $1041
L1122               sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    sta $1045
S112e               sta $1046
                    sta $1047
                    rts
                    
L1135               lda $1040
                    beq L1122
                    cld
                    ldx #$02
                    lda $1046
                    beq L1152
                    ldy $104a
                    beq L1152
                    dec $1047
                    bne L1152
                    sta $1047
                    dec $104a
L1152               dec $1042
                    bpl L115f
                    lda $1044
                    sta $1042
                    bne L1173
L115f               dec $1041
                    bpl L1173
                    lda $1043
                    sta $1041
                    dec $104b
                    dec $104c
                    dec $104d
L1173               stx $103e
                    lda $104b,x
                    beq L117e
                    jmp L13ed
                    
L117e               lda $1075,x
                    sta $fe
                    lda $1078,x
                    sta $ff
                    ldy $1072,x
                    lda ($fe),y
                    bpl L11d2
                    cmp #$ff
                    bne L119e
                    iny
                    lda ($fe),y
                    sta $1072,x
                    tay
                    lda ($fe),y
                    bpl L11d2
L119e               cmp #$c0
                    bcs L11b2
                    and #$3f
                    adc $1069,x
                    sta $106c,x
                    inc $1072,x
                    iny
                    lda ($fe),y
                    bpl L122d
L11b2               cmp #$e0
                    bcs L11c3
                    and #$1f
                    sta $1057,x
                    inc $1072,x
                    iny
                    lda ($fe),y
                    bpl L122d
L11c3               cmp #$fb
                    bcs L11d6
                    and #$1f
                    sta $107b,x
                    inc $1072,x
                    iny
                    lda ($fe),y
L11d2               bpl L122d
                    cmp #$fb
L11d6               bne L11fa
                    inc $1072,x
                    iny
                    lda ($fe),y
                    sta $1041
                    sta $1043
                    inc $1072,x
                    iny
                    lda ($fe),y
                    sta $1044
                    lda #$00
                    sta $1042
                    inc $1072,x
                    iny
                    lda ($fe),y
                    bpl L122d
L11fa               cmp #$fc
                    bne L120d
                    lda $1045
                    bne L121f
                    jsr S112e
                    lda #$0f
                    sta $104a
                    bne L121f
L120d               cmp #$fd
                    bne L1227
                    inc $1072,x
                    iny
                    lda $1045
                    bne L121f
                    lda ($fe),y
                    jsr S112e
L121f               inc $1072,x
                    iny
                    lda ($fe),y
                    bpl L122d
L1227               lda #$00
                    sta $1040
                    rts
                    
L122d               tay
                    lda $1bd6,y
                    sta $fe
                    lda $1bea,y
                    sta $ff
                    lda #$00
                    sta $1051,x
                    sta $109f,x
                    sta $1093,x
                    sta $10c5,x
                    ldy $106f,x
                    bne L1257
                    sta $1090,x
                    sta $1066,x
                    sta $105a,x
                    sta $105d,x
L1257               lda ($fe),y
                    bpl L1299
                    cmp #$81
                    bcs L126a
                    iny
                    lda ($fe),y
                    sta $1066,x
                    iny
                    lda ($fe),y
                    bpl L1299
L126a               cmp #$c0
                    bcs L1283
                    and #$3f
L1270               sta $104e,x
                    iny
                    lda ($fe),y
                    bpl L1299
                    cmp #$c0
                    bcs L1283
                    and #$3f
                    adc $104e,x
                    bne L1270
L1283               cmp #$e0
                    bcs L129b
                    and #$1f
                    adc $1057,x
                    tax
                    lda $18ba,x
                    ldx $103e
                    sta $1054,x
                    iny
                    lda ($fe),y
L1299               bpl L12fc
L129b               cmp #$f8
                    bcs L12b4
                    and #$1f
L12a1               sta $1090,x
                    iny
                    lda ($fe),y
                    bpl L12fc
                    cmp #$f8
                    bcs L12b4
                    and #$1f
                    adc $1090,x
                    bne L12a1
L12b4               bne L12c0
                    lda #$00
                    sta $1048
                    iny
                    lda ($fe),y
                    bpl L12fc
L12c0               cmp #$f9
                    bne L12cf
                    iny
                    lda ($fe),y
                    sta $105a,x
                    iny
                    lda ($fe),y
                    bpl L12fc
L12cf               cmp #$fa
                    bne L12de
                    iny
                    lda ($fe),y
                    sta $105d,x
                    iny
                    lda ($fe),y
                    bpl L12fc
L12de               cmp #$fb
                    beq L12e8
                    cmp #$fc
                    bne L12f0
                    lda #$01
L12e8               sta $10c5,x
                    iny
                    lda ($fe),y
                    bpl L12fc
L12f0               cmp #$fe
                    beq L12f6
                    lda #$00
L12f6               sta $10c8
                    iny
                    lda ($fe),y
L12fc               cmp #$60
                    beq L1316
                    bcs L130a
                    adc $106c,x
                    sta $1063,x
                    bpl L1335
L130a               and #$1f
                    sta $104b,x
                    lda #$00
                    sta $1060,x
                    beq L1341
L1316               iny
                    lda ($fe),y
                    sta $109c,x
                    iny
                    lda ($fe),y
                    sta $109f,x
                    iny
                    lda ($fe),y
                    clc
                    adc $106c,x
                    sta $1063,x
                    iny
                    lda ($fe),y
                    adc $106c,x
                    sta $10a2,x
L1335               lda $1054,x
                    sta $1060,x
                    lda $104e,x
                    sta $104b,x
L1341               iny
                    lda ($fe),y
                    cmp #$ff
                    bne L1357
                    lda $107b,x
                    bne L1352
                    inc $1072,x
                    bne L1355
L1352               dec $107b,x
L1355               ldy #$00
L1357               tya
                    sta $106f,x
                    lsr $1084,x
                    asl $1084,x
                    lda $1084,x
                    ldy $18b4,x
                    sta d404_sVoc1Control,y
                    ldy $1060,x
                    lda $1a7f,y
                    sta $fe
                    lda $1a7e,y
                    sta $108d,x
                    and #$08
                    beq L138f
                    lda $1063,x
                    sec
                    sbc $106c,x
                    sta $1063,x
                    lda $10a2,x
                    sbc $106c,x
                    sta $10a2,x
L138f               lda $10c5,x
                    bmi L13ac
                    lda $108d,x
                    and #$01
                    bne L139e
                    lda $1a77,y
L139e               sta $1084,x
                    lda $1a7d,y
                    sta $10b1,x
                    and #$0f
                    sta $10b5,x
L13ac               lda $105a,x
                    bne L13b4
                    lda $1a79,y
L13b4               sta $107e,x
                    lda $105d,x
                    bne L13bf
                    lda $1a7a,y
L13bf               sta $1081,x
                    ldy $fe
                    beq L13e7
                    lda $10c8
                    bmi L13e7
                    lda $1afa,y
                    sta $10b4
                    lda $1afb,y
                    sta $10b8
                    lda $1afc,y
                    clc
                    adc $18b7,x
                    sta $1048
                    lda $1afd,y
                    sta $1049
L13e7               jsr S1615
                    jmp L1544
                    
L13ed               lda $108d,x
                    and #$04
                    beq L1403
                    lda $1051,x
                    cmp #$00
                    bcc L1403
                    lda $1099,x
                    beq L1403
                    dec $1099,x
L1403               lda $108d,x
                    and #$02
                    beq L1431
                    jsr S1615
                    lda $1051,x
                    cmp #$00
                    bcc L1431
                    cmp #$20
                    bcs L1431
                    lsr a
                    bcc L1460
                    rol a
                    sec
                    sbc #$00
                    lsr a
                    sta $fe
                    inc $fe
                    lda $1099,x
                    sec
                    sbc $fe
                    bcc L1431
                    sta $1099,x
                    bcs L1460
L1431               ldy $109f,x
                    beq L1444
                    lda $1051,x
                    cmp $109c,x
                    bcc L1444
                    jsr S167c
                    jmp L1460
                    
L1444               ldy $1060,x
                    lda $1a80,y
                    beq L1460
                    lsr a
                    tay
                    lda $1051,x
                    lsr a
                    bne L1457
                    sta $10ae,x
L1457               rol a
                    cmp $1ae8,y
                    bcc L1460
                    jsr S16e1
L1460               ldy $1060,x
                    lda $1a81,y
                    beq L1475
                    tay
                    lda $1051,x
                    lsr a
                    bne L1472
                    jsr S17a3
L1472               jsr S17b7
L1475               ldy $1060,x
                    lda $1a7f,y
                    beq L1491
                    tay
                    lda $1051,x
                    lsr a
                    bne L1489
                    ldx #$03
                    jsr S17a3
L1489               ldx #$03
                    jsr S17b7
                    ldx $103e
L1491               ldy $1090,x
                    beq L14a0
                    lda $108d,x
                    and #$10
                    bne L14a0
                    jsr S161a
L14a0               lda $108d,x
                    bpl L14b4
                    lda $1051,x
                    lsr a
                    bne L14b1
                    sta $1087,x
                    sta $108a,x
L14b1               jsr S15b3
L14b4               lda $108d,x
                    and #$20
                    beq L14f9
                    lda $1051,x
                    cmp #$03
                    bcc L14f9
                    lda $1041
                    sta $fe
                    lda $104b,x
                    sta $ff
                    ldy $1042
                    dey
                    bpl L14d7
                    ldy $1044
                    bne L14e4
L14d7               dec $fe
                    bpl L14e4
                    lda $1043
                    sta $fe
                    dec $ff
                    beq L14f4
L14e4               dey
                    bpl L14ec
                    ldy $1044
                    bne L14f9
L14ec               dec $fe
                    bpl L14f9
                    dec $ff
                    bne L14f9
L14f4               lda #$00
                    sta $1081,x
L14f9               ldy $1060,x
                    lda $1051,x
                    cmp #$02
                    bcs L1519
                    lsr a
                    bne L1539
                    lda $108d,x
                    and #$40
                    beq L1539
                    ldy $18b4,x
                    lda #$81
                    sta $1084,x
                    lda #$f9
                    bne L155c
L1519               lda $1051,x
                    cmp $1a7b,y
                    bcc L1539
                    lda $1a7c,y
                    beq L1538
                    cmp $104b,x
                    bcc L1539
                    lda $108d,x
                    bpl L1538
                    lsr $1084,x
                    asl $1084,x
                    bcc L1544
L1538               iny
L1539               lda $108d,x
                    bmi L1544
                    lda $1a77,y
                    sta $1084,x
L1544               ldy $18b4,x
                    lda $10b5,x
                    sta d403_sVoc1PWidthHi,y
                    lda $10b1,x
                    sta d402_sVoc1PWidthLo,y
                    lda $1096,x
                    sta d400_sVoc1FreqLo,y
                    lda $1099,x
L155c               sta d401_sVoc1FreqHi,y
                    lda $1081,x
                    sta d406_sVoc1SusRel,y
                    lda $107e,x
                    sta d405_sVoc1AttDec,y
                    lda $10c5,x
                    beq L1578
                    bmi L157e
                    lsr $1084,x
                    asl $1084,x
L1578               lda $1084,x
                    sta d404_sVoc1Control,y
L157e               inc $1051,x
                    bne L1586
                    dec $1051,x
L1586               dex
                    bmi L158c
                    jmp L1173
                    
L158c               lda $10b4
                    sta d415_sFiltFreqLo
                    lsr a
                    lsr a
                    lsr a
                    sta $fe
                    lda $10b8
                    lsr a
                    ror a
                    ror a
                    ror a
                    ora $fe
                    sta d416_sFiltFreqHi
                    lda $1048
                    sta d417_sFiltControl
                    lda $104a
                    ora $1049
                    sta d418_sFiltMode
                    rts
                    
S15b3               ldy $1060,x
                    lda $1a78,y
                    sta $103f
                    tay
                    lda $1a34,y
                    sta $fe
                    lda $1a38,y
                    sta $ff
                    ldy $1087,x
                    lda ($fe),y
                    cmp #$fe
                    beq L15e0
                    bcc L15d8
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L15d8               sta $1084,x
                    iny
                    tya
                    sta $1087,x
L15e0               ldy $103f
                    lda $1a3c,y
                    sta $fe
                    lda $1a40,y
                    sta $ff
                    ldy $108a,x
                    lda ($fe),y
                    cmp #$fd
                    bcc L1606
                    beq L1612
                    cmp #$fe
                    beq L1611
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
                    cmp #$fd
                    beq L1612
L1606               sta $1099,x
                    sta $1096,x
                    iny
                    tya
                    sta $108a,x
L1611               rts
                    
L1612               inc $108a,x
S1615               ldy $1063,x
                    bpl L1642
S161a               lda $1990,y
                    sta $fe
                    lda $19a3,y
                    sta $ff
                    ldy $1093,x
                    iny
                    lda ($fe),y
                    bpl L1637
                    cmp #$81
                    beq L1633
                    bcs L1637
                    rts
                    
L1633               iny
                    lda ($fe),y
                    tay
L1637               tya
                    sta $1093,x
                    lda ($fe),y
                    clc
                    adc $1063,x
                    tay
L1642               lda $18d1,y
                    sta $1096,x
                    sec
                    sbc $18d0,y
                    sta $fe
                    lda $1931,y
                    sta $1099,x
                    sbc $1930,y
                    ldy $1066,x
                    beq L167b
                    lsr a
                    ror $fe
                    lsr a
                    ror $fe
                    lsr a
                    sta $ff
                    ror $fe
L1667               lda $1096,x
                    sec
                    sbc $fe
                    sta $1096,x
                    lda $1099,x
                    sbc $ff
                    sta $1099,x
                    dey
                    bne L1667
L167b               rts
                    
S167c               sty $fe
                    lda #$00
                    asl $fe
                    rol a
                    asl $fe
                    rol a
                    sta $ff
                    ldy $10a2,x
                    tya
                    cmp $1063,x
                    bcs L16c0
                    lda $1096,x
                    sec
                    sbc $fe
                    sta $1096,x
                    lda $1099,x
                    sbc $ff
                    sta $1099,x
                    lda $1096,x
                    sec
                    sbc $18d1,y
                    lda $1099,x
                    sbc $1931,y
                    bcs L16e0
L16b1               lda #$00
                    sta $109f,x
                    sta $10ae,x
                    tya
                    sta $1063,x
                    jmp L1642
                    
L16c0               lda $1096,x
                    clc
                    adc $fe
                    sta $1096,x
                    lda $1099,x
                    adc $ff
                    sta $1099,x
                    lda $18d1,y
                    sec
                    sbc $1096,x
                    lda $1931,y
                    sbc $1099,x
                    bcc L16b1
L16e0               rts
                    
S16e1               lda $10ae,x
                    bne L1724
                    sta $10a5,x
                    inc $10ae,x
                    lda $1aed,y
                    sta $fe
                    lda $1063,x
                    clc
                    adc $1aec,y
                    tay
                    sta $ff
                    lda $18d1,y
                    sec
                    ldy $1063,x
                    sbc $18d1,y
                    sta $10a8,x
                    ldy $ff
                    lda $1931,y
                    ldy $1063,x
                    sbc $1931,y
                    sta $10ab,x
                    ldy $fe
                    beq L1723
L171a               lsr $10ab,x
                    ror $10a8,x
                    dey
                    bne L171a
L1723               rts
                    
L1724               lda $1051,x
                    cmp $1ae9,y
                    bcc L1743
                    cmp $1aef,y
                    bcs L1743
                    lda $10a8,x
                    clc
                    adc $1aee,y
                    sta $10a8,x
                    lda $10ab,x
                    adc #$00
                    sta $10ab,x
L1743               sty $103f
                    jsr S1615
                    ldy $103f
                    lda $1aea,y
                    sta $fe
                    lda $1aeb,y
                    sta $ff
L1756               ldy $10a5,x
                    lda ($fe),y
                    beq L179f
                    tay
                    bpl L1771
                    cmp #$81
                    bne L1789
                    inc $10a5,x
                    ldy $10a5,x
                    lda ($fe),y
                    sta $10a5,x
                    bpl L1756
L1771               lda $1096,x
                    clc
                    adc $10a8,x
                    sta $1096,x
                    lda $1099,x
                    adc $10ab,x
                    sta $1099,x
                    dey
                    bne L1771
                    beq L179f
L1789               lda $1096,x
                    sec
                    sbc $10a8,x
                    sta $1096,x
                    lda $1099,x
                    sbc $10ab,x
                    sta $1099,x
                    iny
                    bne L1789
L179f               inc $10a5,x
                    rts
                    
S17a3               lda $10c5,x
                    bmi L17b6
                    sta $10bd,x
                    sta $10c1,x
                    lda $1afe,y
                    and #$04
                    sta $10b9,x
L17b6               rts
                    
S17b7               lda $1b01,y
                    beq L182f
                    sta $ff
                    lda $1b00,y
                    sta $fe
                    sty $103f
                    ldy $10bd,x
                    lda $10c1,x
                    bne L17e8
                    lda ($fe),y
                    bpl L181d
                    cmp #$fe
                    bcc L17e0
                    beq L182c
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
                    bpl L181d
L17e0               and #$7f
                    sta $10c1,x
                    jsr S1826
L17e8               dec $10c1,x
                    bne L17f0
                    inc $10bd,x
L17f0               lda $10b9,x
                    bmi L186d
                    bne L180a
                    lda ($fe),y
                    clc
                    adc $10b1,x
                    sta $10b1,x
                    ldy $103f
                    bcc L184c
                    inc $10b5,x
                    bcs L184c
L180a               lda $10b1,x
                    sec
                    sbc ($fe),y
                    sta $10b1,x
                    ldy $103f
                    bcs L1884
                    dec $10b5,x
                    bcc L1884
L181d               sta $10b5,x
                    iny
                    lda ($fe),y
                    sta $10b1,x
S1826               iny
                    tya
                    sta $10bd,x
                    rts
                    
L182c               ldy $103f
L182f               lda $10b9,x
                    bmi L186d
                    bne L186e
                    lda $10b1,x
                    clc
                    adc $1b08,y
                    sta $10b1,x
                    lda $10b5,x
                    adc $1b09,y
                    sta $10b5,x
                    lda $10b1,x
L184c               sec
                    sbc $1b04,y
                    lda $10b5,x
                    sbc $1b05,y
                    bmi L186d
                    lda $1aff,y
                    lsr a
                    bcs L18ae
                    lsr a
                    bcc L18a6
                    lda $1b02,y
                    sta $10b1,x
                    lda $1b03,y
                    sta $10b5,x
L186d               rts
                    
L186e               lda $10b1,x
                    sec
                    sbc $1b06,y
                    sta $10b1,x
                    lda $10b5,x
                    sbc $1b07,y
                    sta $10b5,x
                    lda $10b1,x
L1884               sec
                    sbc $1b02,y
                    lda $10b5,x
                    sbc $1b03,y
                    bpl L186d
                    lda $1afe,y
                    lsr a
                    bcs L18ae
                    lsr a
                    bcc L18aa
                    lda $1b04,y
                    sta $10b1,x
                    lda $1b05,y
                    sta $10b5,x
                    rts
                    
L18a6               lda #$01
                    bne L18b0
L18aa               lda #$00
                    beq L18b0
L18ae               lda #$ff
L18b0               sta $10b9,x
                    rts
                    
  .binary "Legend_last.bin"
