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
  lda #0 ; Song Numbehr
  jsr InitSid
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  pha
  phx
  phy
  ; IRQ code goes here
  lda #$40
  sta $b00d
  jsr putbut
  jsr PlaySid
  nop
  ply
  plx
  pla
  rti
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

InitSid2            jmp L115b
                    
PlaySid             jmp L11d7
                    
L1006               jmp $0f01

  .binary "U_Data1.bin"
                    
L115b               tax
                    lda #$00
                    ldy #$6d
L1160               sta L1006 + 2,y
                    dey
                    bne L1160
                    ldy #$1c
L1168               sta d400_sVoc1FreqLo,y
                    dey
                    bpl L1168
                    lda #$02
                    sta $100c
                    sta $100d
                    sta $100e
                    lda #$f9
                    sta $1012
                    sta $1013
                    sta $1014
                    lda #$09
                    sta $1015
                    sta $1016
                    sta $1017
                    lda $19e5,x
                    sta $1009
                    sta $1036
                    lda $19e6,x
                    sta $100a
                    sta $1037
                    lda $19e7,x
                    sta $100b
                    sta $1038
                    lda #$0f
                    sta $1072
                    sta $115a
                    rts
                    
L11b3               pla
                    sta $81
                    pla
                    sta $80
                    rts
                    
L11ba               inc $1073
                    jmp L12b7
                    
L11c0               lda $1045,x
                    bne L1209
                    lda #$00
                    sta $100f,x
                    lda #$f0
                    sta $1012,x
                    lda #$09
                    sta $1015,x
                    jmp L1222
                    
L11d7               lda $80
                    pha
                    lda $81
                    pha
                    ldx #$02
                    lda $115a
                    sta d418_sFiltMode
                    lda $1072
                    beq L11b3
                    lda $1073
                    beq L11ba
L11ef               ldy $106f,x
                    beq L11fc
                    lda #$00
                    sta $106f,x
                    jmp L1409
                    
L11fc               lda $106c,x
                    bne L1222
                    dec $100c,x
                    bne L1209
                    jmp L11c0
                    
L1209               lda $1042,x
                    beq L1211
                    jmp L14c5
                    
L1211               lda $1076,x
                    beq L121c
                    eor $0915,x
                    sta $0915,x
L121c               jmp L1560
                    
L121f               jmp $0ab3
                    
L1222               dex
                    bpl L11ef
                    lda $115a
                    beq L121f
                    lda $106c
                    bne L1259
                    lda $1021
                    sta d402_sVoc1PWidthLo
                    lda $1018
                    sta d403_sVoc1PWidthHi
                    lda $100f
                    sta d405_sVoc1AttDec
                    lda $1012
                    sta d406_sVoc1SusRel
                    lda $102a
                    sta d400_sVoc1FreqLo
                    lda $102d
                    sta d401_sVoc1FreqHi
                    lda $1015
                    sta d404_sVoc1Control
L1259               lda $106d
                    bne L1288
                    lda $1022
                    sta d409_sVoc2PWidthLo
                    lda $1019
                    sta d40a_sVoc2PWidthHi
                    lda $1010
                    sta d40c_sVoc2AttDec
                    lda $1013
                    sta d40d_sVoc2SusRel
                    lda $102b
                    sta d407_sVoc2FreqLo
                    lda $102e
                    sta d408_sVoc2FreqHi
                    lda $1016
                    sta d40b_sVoc2Control
L1288               lda $106e
                    bne L12b7
                    lda $1023
                    sta d410_sVoc3PWidthLo
                    lda $101a
                    sta d411_sVoc3PWidthHi
                    lda $1011
                    sta d413_sVoc3AttDec
                    lda $1014
                    sta d414_sVoc3SusRel
                    lda $102c
                    sta d40e_sVoc3FreqLo
                    lda $102f
                    sta d40f_sVoc3FreqHi
                    lda $1017
                    sta d412_sVoc3Control
L12b7               ldx #$02
L12b9               lda $106c,x
                    bne L12da
                    lda $100c,x
                    beq L1321
                    cmp $1069,x
                    beq L12cd
                    lda $100f,x
                    bne L12da
L12cd               lda $1045,x
                    bne L12da
                    lda $1015,x
                    and #$fe
                    sta $1015,x
L12da               dex
                    bpl L12b9
                    jmp L11b3
                    
L12e0               and #$7f
                    cmp #$30
                    bcc L12eb
                    sec
                    sbc #$31
                    eor #$ff
L12eb               sta $1027,x
                    inc $1009,x
                    jmp L132d
                    
L12f4               lda $1036,x
                    sta $1009,x
                    tay
                    jmp L1330
                    
L12fe               and #$3f
                    sta $0939,x
                    inc $0909,x
                    iny
                    jmp $0c30
                    
L130a               sta $096c,x
                    ldy $0c18,x
                    lda #$00
                    sta d404_sVoc1Control,y
                    jmp $0bda
                    
                      .byte $00, $07, $0e 
L131b               jsr $0f01
                    jmp $0ab3
                    
L1321               lda $107c,x
                    sta L1330 + 1
                    lda $107f,x
                    sta L1330 + 2
L132d               ldy $1009,x
L1330               lda $1234,y
                    cmp #$40
                    bcc L1378
                    cmp #$80
                    bcc L12fe
                    cmp #$fd
                    beq L130a
                    cmp #$fe
                    beq L131b
                    bcs L12f4
                    jmp L12e0
                    
L1348               iny
                    lda ($80),y
                    sta d416_sFiltFreqHi
                    sta $1075
                    iny
                    jmp L1386
                    
L1355               iny
                    lda ($80),y
                    sta d415_sFiltFreqLo
                    iny
                    jmp L1386
                    
L135f               iny
                    lda ($80),y
                    sta d417_sFiltControl
                    iny
                    jmp L1386
                    
L1369               iny
                    lda $115a
                    and #$0f
                    ora ($80),y
                    sta $115a
                    iny
                    jmp L1386
L1378               tay
                    lda $1664,y
                    sta $80
                    lda $1670,y
                    sta $81
                    ldy $1030,x
L1386               lda ($80),y
                    bpl L1390
                    sta $138e
                    jmp ($1082)
                    
L1390               sec
                    adc $1027,x
                    sta $106f,x
L1397               iny
                    tya
                    sta $1030,x
                    jmp L12da


L139f               lda $1069,x
                    asl a
                    sta $100c,x
                    jmp L1397
                    
L13a9               lda #$00
                    sta $104e,x
                    iny
                    jmp L1386
                    
L13b2               sta $1048,x
                    iny
                    jmp L1386
                    
L13b9               lda #$00
                    sta $1048,x
                    iny
                    jmp L1386
                    
L13c2               iny
                    lda ($80),y
                    sta $104e,x
                    beq L13d9
                    lsr a
                    lsr a
                    lsr a
                    lsr a
                    sta $1054,x
                    lda $104e,x
                    and #$0f
                    sta $1057,x
L13d9               iny
                    jmp L1386
                    
L13dd               iny
                    lda ($80),y
                    sta $1033,x
                    iny
                    jmp L1386
                    
L13e7               iny
                    lda ($80),y
                    sta $1069,x
                    iny
                    jmp L1386
                    
L13f1               lda $1039,x
                    beq L13fe
                    ldy #$00
                    dec $0939,x
                    jmp $0c86
                    
L13fe               lda #$00
                    sta $1030,x
                    inc $1009,x
                    jmp L132d
                    
L1409               dey
                    tya
                    sta $105a,x
                    lda $109a,y
                    sta $102a,x
                    lda $10fa,y
                    sta $102d,x
                    lda $1069,x
                    asl a
                    sta $100c,x
                    dec $100c,x
                    lda $1045,x
                    beq L142c
                    jmp L14ad
                    
L142c               ldy $1033,x
                    lda #$00
                    sta $1042,x
                    sta $103c,x
                    sta $1021,x
                    sta $1063,x
                    lda $198b,y
                    bne L144e
                    sta $0915,x
                    sta $092a,x
                    sta $092d,x
                    jmp $0b09
                    
L144e               sta $1015,x
                    bmi L1465
                    cmp #$40
                    bcc L1465
                    and #$38
                    lsr a
                    sta $1066,x
                    lda $1015,x
                    and #$c7
                    sta $1015,x
L1465               lda $1989,y
                    sta $100f,x
                    lda $198a,y
                    sta $1012,x
                    lda $198c,y
                    and #$0f
                    sta $1018,x
                    lda $198c,y
                    and #$30
                    sta $101e,x
                    beq L1490
                    lda $198c,y
                    and #$c0
                    lsr a
                    lsr a
                    lsr a
                    adc #$08
                    sta $101b,x
L1490               lda $198f,y
                    sta $103f,x
                    and #$f0
                    cmp #$80
                    bne L14a7
                    lda #$01
                    sta $1079,x
                    sta $1042,x
                    jmp L1209
                    
L14a7               lda $1990,y
                    sta $1076,x
L14ad               lda $1048,x
                    sta $1045,x
                    dec $1060,x
                    bne L14b8
L14b8               lda $104e,x
                    beq L14bf
                    lda #$04
L14bf               sta $1051,x
                    jmp L1209
                    
L14c5               ldy $103c,x
                    lda $103f,x
                    and #$03
                    beq L14d5
                    cmp #$02
                    beq L14d5
                    bcc L1507
L14d5               cpy #$06
                    bcc L14df
                    lda #$03
                    sta $093c,x
                    tay
L14df               lda $19c9,y
                    sta $102d,x
                    lda $19cf,y
L14e8               sta $1015,x
                    lda #$00
                    sta $102a,x
                    sta $1021,x
                    inc $103c,x
                    lda $1079,x
                    beq L1504
                    ora $1015,x
                    sta $1015,x
                    dec $1079,x
L1504               jmp L1222
                    
L1507               cpy #$08
                    bcc L1511
                    lda #$07
                    sta $093c,x
                    tay
L1511               lda $19d5,y
                    sta $102d,x
                    lda $19dd,y
                    jmp L14e8
                    
L151d               ldy $095a,x
                    lda #$00
                    sta $0921,x
                    lda $09fa,y
                    sta $092d,x
                    lda $099a,y
                    sta $092a,x
                    ldy $093c,x
                    lda $1234,y
                    sta $0915,x
                    bpl L1545
                    lda $1234,y
                    sta $092d,x
                    jmp $0df3
                    
L1545               lda $095a,x
                    clc
                    ldy $093c,x
                    adc $1234,y
                    bpl L1553
                    lda #$00
L1553               cmp #$60
                    bcc L1559
                    lda #$5f
L1559               sta $095a,x
                    tay
                    jmp $0df3

L1560               lda #$00
                    sta $80
                    lda $1051,x
                    beq L159b
                    cmp #$04
                    beq L1591
                    cmp #$02
                    bcc L1587
                    beq L157b
                    lda $1054,x
                    sta $80
                    jmp L1591
                    
L157b               lda $1057,x
                    sec
                    sbc $1054,x
                    sta $80
                    jmp L1591
                    
L1587               lda $1057,x
                    sec
                    sbc #$01
                    eor #$ff
                    sta $80
L1591               dec $1051,x
                    bne L159b
                    lda #$03
                    sta $1051,x
L159b               lda $80
                    beq L15be
                    clc
                    adc $105a,x
                    bpl L15a8
                    jmp $0eae
                    
L15a8               cmp #$60
                    bcc L15ae
                    lda #$5f
L15ae               sta $105a,x
                    tay
                    lda $109a,y
                    sta $102a,x
                    lda $10fa,y
                    sta $102d,x
L15be               lda $101e,x
                    beq L15fe
                    cmp #$10
                    bne L15d9
L15c7               lda $1021,x
                    clc
                    adc $101b,x
                    sta $1021,x
                    bcc L15fe
                    inc $1018,x
                    jmp L1222
                    
L15d9               cmp #$20
                    bne L15ef
L15dd               lda $1021,x
                    sec
                    sbc $101b,x
                    sta $1021,x
                    bcs L15fe
                    dec $1018,x
                    jmp L1222
                    
L15ef               lda $1063,x
                    sec
                    adc $1066,x
                    sta $1063,x
                    bmi L15dd
                    jmp L15c7
                    
L15fe               jmp L1222
                    
L1601               lda #$00
                    sta $0a5a
                    sta $0972
                    rts

                                                  
  .binary "U_Data2.bin"
