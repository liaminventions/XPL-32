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

InitSid             jmp L124b
                    
PlaySid             jmp L1330
                    
L1006               jmp L137b

		.binary "evolver.bin"
                    
L124b               tax
                    lda #$00
                    tay
L124f               sta $11b7,y
                    iny
                    cpy #$90
                    bne L124f
                    lda #$00
                    sta $1a38
                    sta $12f4
                    sta $1a96
                    sta $1aab
                    sta L1aa7 + 1
                    sta $1aaf
                    sta $1aad
                    sta $12f9
                    lda $1bb9,x
                    sta $11e4
                    lda $1bba,x
                    sta $11e5
                    lda $1bbb,x
                    sta $11eb
                    lda $1bbc,x
                    sta $11ec
                    lda $1bbd,x
                    sta $11f2
                    lda $1bbe,x
                    sta $11f3
                    lda $1bb8,x
                    sta $1339
                    sta $1340
                    lda #$0f
                    sta S12ee + 1
                    lda #$04
                    sta $1624
                    lda #$80
                    sta L1a8f + 1
                    ldy #$02
                    sty L12bc + 1
                    lda $fb
                    sta $12ea
                    lda $fc
                    sta $12e6
L12bc               ldy #$02
                    ldx $1248,y
                    lda #$fe
                    sta $1220,x
                    sta $1225,x
                    sta $1238,x
                    lda #$09
                    sta $11f7,x
                    jsr L14d6
                    lda $11e1,x
                    sta $11e2,x
                    sta $11e3,x
                    jsr L13e6
                    dec L12bc + 1
                    bpl L12bc
                    lda #$00
                    sta $fc
                    lda #$00
                    sta $fb
                    rts
                    
S12ee               lda #$00
                    sta d418_sFiltMode
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    sta d416_sFiltFreqHi
                    ldy #$02
L12ff               ldx $1248,y
                    lda $11b8,x
                    sta d401_sVoc1FreqHi,x
                    lda $11b7,x
                    sta d400_sVoc1FreqLo,x
                    lda $11bd,x
                    sta d406_sVoc1SusRel,x
                    lda $11bc,x
                    sta d405_sVoc1AttDec,x
                    lda $11bb,x
                    sta d404_sVoc1Control,x
                    lda $11ba,x
                    sta d403_sVoc1PWidthHi,x
                    lda $11b9,x
                    sta d402_sVoc1PWidthLo,x
                    dey
                    bpl L12ff
                    rts
                    
L1330               jsr S12ee
                    dec $1624
                    bpl L1359
                    ldx #$00
                    ldy $203b,x
                    bpl L1347
                    lda #$00
                    sta $1339
                    jmp L134a
                    
L1347               inc $1339
L134a               tya
                    and #$7f
                    sta $1624
                    dec $1226
                    dec $122d
                    dec $1234
L1359               lda $fb
                    sta $1377
                    lda $fc
                    sta $1373
                    ldx #$00
                    jsr S161e
                    ldx #$07
                    jsr S161e
                    ldx #$0e
                    jsr S161e
                    lda #$00
                    sta $fc
                    lda #$00
                    sta $fb
                    rts
                    
L137b               jsr S12ee
                    lda $fb
                    sta $139c
                    lda $fc
                    sta $1398
                    ldx #$0e
                    jsr S13a0
                    ldx #$07
                    jsr S13a0
                    ldx #$00
                    jsr S13a0
                    lda #$00
                    sta $fc
                    lda #$00
                    sta $fb
L139f               rts
                    
S13a0               lda $1239,x
                    beq L139f
                    jmp L16ee
                    
L13a8               lda $2800,y
                    sta $12f4
                    lda $2840,y
                    beq L13b6
                    sta S12ee + 1
L13b6               jmp L13de
                    
L13b9               lda $1f9f,y
                    sta $11bc,x
                    lda $1fcd,y
                    sta $11bd,x
                    jmp L13de
                    
L13c8               lda $1238,x
                    bne L13d0
                    sta $120b,x
L13d0               ldy $1225,x
                    lda $1f71,y
                    cmp #$e0
                    beq L13b9
                    cmp #$b0
                    beq L13a8
L13de               lda #$ff
                    sta $1225,x
                    jmp L16ee
                    
L13e6               lda $1235,x
                    sta $1226,x
                    lda $1223,x
                    sta $1222,x
                    lda $1221,x
                    sta $1220,x
                    lda $11e2,x
                    sta $11e3,x
                    lda $11e1,x
                    sta $11e2,x
                    lda $1224,x
                    beq L13c8
                    lda #$00
                    sta $1239,x
                    sta $11cc,x
                    sta $11cd,x
                    sta $120b,x
                    sta $11fc,x
                    ldy $11ce,x
                    lda $1d1c,y
                    sta $11fa,x
                    lda $1c43,y
                    sta $11f6,x
                    lda $1cc4,y
                    cmp #$ff
                    beq L1438
                    sta $1236,x
                    lda #$00
                    sta $1237,x
L1438               lda $1c17,y
                    sta $11f8,x
                    and #$1f
                    sta $11fb,x
                    lda $1c6f,y
                    cmp #$ff
                    beq L1452
                    sta $11cf,x
                    lda #$00
                    sta $11d0,x
L1452               cpx L1a33 + 1
                    bne L1466
                    lda $1c9b,y
                    cmp #$ff
                    beq L1466
                    sta $1a38
                    lda #$00
                    sta $1241
L1466               ldy $1225,x
                    lda $1f71,y
                    cmp #$40
                    beq L1494
                    cmp #$10
                    beq L148f
                    cmp #$20
                    bne L1499
                    lda $1ffb,y
                    beq L1480
                    sta $11f6,x
L1480               lda $1f9f,y
                    sta $11bc,x
                    lda $1fcd,y
                    ldy $11ce,x
                    jmp L14a5
                    
L148f               lda #$04
                    jmp L1496
                    
L1494               lda #$01
L1496               sta $120b,x
L1499               ldy $11ce,x
                    lda $1bbf,y
                    sta $11bc,x
                    lda $1beb,y
L14a5               sta $11bd,x
                    lda #$ff
                    sta $1225,x
                    lda $1cf0,y
                    and #$0f
                    bne L14b7
                    jmp L16ee
                    
L14b7               sta $11bb,x
                    rts
                    
L14bb               lda $11d1,x
                    sta $fb
                    lda $11d2,x
                    sta $fc
                    ldy $11e7,x
                    lda ($fb),y
                    cmp #$ff
                    bne L14d6
                    lda #$00
                    sta $11e7,x
                    inc $11e6,x
L14d6               lda $11e4,x
                    sta $fb
                    lda $11e5,x
                    sta $fc
L14e0               ldy $11e6,x
L14e3               lda ($fb),y
                    cmp #$c0
                    bcc L1502
                    cmp #$ff
                    bne L14f7
                    iny
                    lda ($fb),y
                    sta $11e6,x
                    tay
                    jmp L14e3
                    
L14f7               and #$3f
                    sta $11e1,x
                    inc $11e6,x
                    jmp L14e0
                    
L1502               tay
                    lda $1ab4,y
                    sta $11d1,x
                    lda $1b36,y
                    sta $11d2,x
                    lda $1224,x
                    beq L1519
                    lda #$fe
                    sta $1220,x
L1519               ldy $1225,x
                    bmi L153e
                    lda $1f71,y
                    cmp #$40
                    bne L1584
                    lda $1f9f,y
                    beq L1538
                    sta $1210,x
                    lda #$01
                    sta $120b,x
                    lda $1fcd,y
                    sta $120f,x
L1538               lda $1ffb,y
                    sta $1211,x
L153e               jmp L16ee
                    
L1541               lda $2840,y
                    sta $1a96
                    lda $2800,y
                    sta L1a8f + 1
                    cmp #$80
                    bne L155c
                    lda $1a96
                    sta $1aaf
                    lda #$00
                    sta $1aab
L155c               jmp L1613
                    
L155f               lda $2840,y
                    beq L156c
                    sta $11cf,x
                    lda #$00
                    sta $11d0,x
L156c               lda $2880,y
                    beq L1579
                    sta $1a38
                    lda #$00
                    sta $1241
L1579               lda $2800,y
                    beq L1581
                    sta $11f6,x
L1581               jmp L1613
                    
L1584               jsr L16ee
                    ldy $1225,x
                    lda $1f71,y
                    cmp #$10
                    beq L15aa
                    cmp #$f0
                    beq L155f
                    cmp #$e0
                    beq L15bc
                    cmp #$d0
                    beq L15d1
                    cmp #$c0
                    beq L15df
                    cmp #$30
                    beq L1541
                    cmp #$70
                    beq L15c5
                    rts
                    
L15aa               lda $1f9f,y
                    sta $120d,x
                    lda $1fcd,y
                    sta $120c,x
                    lda #$04
                    sta $120b,x
                    rts
                    
L15bc               lda $1ffb,y
                    beq L15c4
                    sta $11f6,x
L15c4               rts
                    
L15c5               lda $2800,y
                    sta $1339
                    sta $1340
                    jmp L1613
                    
L15d1               lda $2800,y
                    sta $1236,x
                    lda #$00
                    sta $1237,x
                    jmp L1613
                    
L15df               lda $1222,x
                    cmp $1223,x
                    beq L1613
                    bcc L1619
                    lda #$03
L15eb               sta $120b,x
                    lda $2800,y
                    sta $120d,x
                    lda $2840,y
                    sta $120c,x
                    lda $11f9,x
                    and #$7f
                    clc
                    adc $1223,x
                    adc $11e3,x
                    tay
                    lda $1095,y
                    sta $11cc,x
                    lda $1156,y
                    sta $11cd,x
L1613               lda #$ff
                    sta $1225,x
                    rts
                    
L1619               lda #$06
                    jmp L15eb
                    
S161e               lda $1226,x
                    bne L162d
                    lda #$00
                    beq L1633
                    cmp #$02
                    beq L1680
                    bcc L1630
L162d               jmp L16ee
                    
L1630               jmp L14bb
                    
L1633               jmp L13e6
                    
L1636               lda #$00
                    sta $1238,x
                    sta $1224,x
                    iny
                    lda ($fb),y
                    jmp L16a2
                    
L1644               and #$1f
                    sta $1235,x
                    iny
                    lda ($fb),y
                    jmp L169e
                    
L164f               cmp #$df
                    beq L165d
                    cmp #$e0
                    beq L1636
                    sec
                    sbc #$a0
                    sta $1225,x
L165d               iny
                    lda ($fb),y
                    jmp L16a2
                    
L1663               cmp #$df
                    beq L166d
                    sec
                    sbc #$60
                    sta $11ce,x
L166d               iny
                    lda ($fb),y
                    jmp L16a6
                    
L1673               ora #$fe
                    sta $1221,x
                    lda #$00
                    sta $1224,x
                    jmp L16ad
                    
L1680               lda #$ff
                    sta $1224,x
                    sta $1221,x
                    sta $1238,x
                    lda $11d1,x
                    sta $fb
                    lda $11d2,x
                    sta $fc
                    ldy $11e7,x
                    lda ($fb),y
                    cmp #$e1
                    bcs L1644
L169e               cmp #$a0
                    bcs L164f
L16a2               cmp #$60
                    bcs L1663
L16a6               cmp #$5e
                    bcs L1673
                    sta $1223,x
L16ad               iny
                    tya
                    sta $11e7,x
                    lda #$01
                    sta $1235,x
                    ldy $1225,x
                    bmi L16c9
                    lda $1f71,y
                    bpl L16c9
                    lda #$00
                    sta $1224,x
                    jmp L16ee
                    
L16c9               lda $1224,x
                    beq L16ee
                    ldy $11ce,x
                    lda $1cf0,y
                    and #$40
                    beq L16dd
                    lda #$fe
                    sta $1220,x
L16dd               lda $1cf0,y
                    bpl L16ee
                    lda $2000,y
                    sta $11bc,x
                    lda $2040,y
                    sta $11bd,x
L16ee               lda #$01
                    sta $1239,x
L16f3               lda $1237,x
                    bne L1723
                    ldy $1236,x
L16fb               beq L1726
L16fd               lda $3cc0,y
                    beq L1726
                    cmp #$fe
                    beq L173c
                    bcs L1732
                    cmp #$fc
                    beq L175f
                    bcs L174b
                    cmp #$fa
                    beq L1783
                    bcs L1729
                    cmp #$f8
                    beq L172f
                    bcs L172c
                    sta $1237,x
                    inc $1236,x
                    jmp L16f3
                    
L1723               dec $1237,x
L1726               jmp L17d1
                    
L1729               jmp L179c
                    
L172c               jmp L17b4
                    
L172f               jmp L17c8
                    
L1732               lda $3dc0,y
                    sta $1236,x
                    tay
                    jmp L16fb
                    
L173c               lda $3dc0,y
                    sta $11bc,x
                    lda $3ec0,y
                    sta $11bd,x
                    jmp L177a
                    
L174b               lda $3dc0,y
                    sta $120d,x
                    lda $3ec0,y
                    sta $120c,x
                    lda #$04
                    sta $120b,x
                    jmp L177a
                    
L175f               lda $3ec0,y
                    sta $1a96
                    lda $3dc0,y
                    sta L1a8f + 1
                    cmp #$80
                    bne L177a
                    lda $1a96
                    sta $1aaf
                    lda #$00
                    sta $1aab
L177a               inc $1236,x
                    ldy $1236,x
                    jmp L16fd
                    
L1783               lda $3dc0,y
                    sta $1210,x
                    lda $3ec0,y
                    sta $120f,x
                    lda #$00
                    sta $1211,x
                    lda #$01
                    sta $120b,x
                    jmp L177a
                    
L179c               lda $3dc0,y
                    beq L17a4
                    sta $11f6,x
L17a4               lda $3ec0,y
                    beq L177a
                    sta $11cf,x
                    lda #$00
                    sta $11d0,x
                    jmp L177a
                    
L17b4               lda $3dc0,y
                    sta $11cd,x
                    lda $3ec0,y
                    sta $11cc,x
                    lda #$06
                    sta $120b,x
                    jmp L177a
                    
L17c8               lda $3dc0,y
                    sta $11fa,x
                    jmp L177a
                    
L17d1               lda $11fc,x
                    bne L1800
                    lda $11fb,x
                    sta $11fc,x
                    lda $11f8,x
                    bmi L180c
                    ldy $11f6,x
L17e4               beq L1826
                    lda $1d48,y
                    cmp #$ff
                    beq L17f6
                    sta $11f7,x
                    lda $1dfa,y
                    jmp L181e
                    
L17f6               lda $1dfa,y
                    sta $11f6,x
                    tay
                    jmp L17e4
                    
L1800               dec $11fc,x
                    jmp L1826
                    
L1806               lda $36c0,y
                    sta $11f6,x
L180c               ldy $11f6,x
                    beq L1826
                    lda $22c0,y
                    cmp #$ff
                    beq L1806
                    sta $11f7,x
                    lda $36c0,y
L181e               sta $11f9,x
                    iny
                    tya
                    sta $11f6,x
L1826               jmp L18a3
                    
L1829               lda $11b7,x
                    clc
                    adc $120c,x
                    sta $11b7,x
                    lda $11b8,x
                    adc $120d,x
                    sta $11b8,x
                    jmp L186b
                    
L183f               lda $11b8,x
                    cmp $11cd,x
                    beq L184b
                    bcs L1855
                    bcc L1888
L184b               lda $11b7,x
                    cmp $11cc,x
                    bcc L1888
                    beq L1888
L1855               jmp L19da
                    
L1858               lda $11b7,x
                    sec
                    sbc $120c,x
                    sta $11b7,x
                    lda $11b8,x
                    sbc $120d,x
                    sta $11b8,x
L186b               lda $120b,x
                    cmp #$03
                    beq L183f
                    lda $11b8,x
                    cmp $11cd,x
                    beq L187e
                    bcc L1855
                    bcs L1888
L187e               lda $11b7,x
                    cmp $11cc,x
                    bcc L1855
                    beq L1855
L1888               lda #$00
                    sta $120b,x
                    jmp L18e3
                    
L1890               lda $11cc,x
                    sec
                    sbc $120c,x
                    sta $11cc,x
                    lda $11cd,x
                    sbc $120d,x
                    jmp L1912
                    
L18a3               lda $120b,x
                    beq L18e3
                    bmi L1890
                    cmp #$02
                    beq L1902
                    bcc L18b9
                    cmp #$04
                    beq L18ec
                    bcc L1858
                    jmp L1829
                    
L18b9               lda $120f,x
                    lsr a
                    adc #$00
                    sta $120e,x
                    inc $120b,x
                    lda $11f9,x
                    and #$7f
                    clc
                    adc $1223,x
                    adc $11e3,x
                    adc $1210,x
                    tay
                    lda $1035,y
                    sta $120c,x
                    lda $10f6,y
                    sta $120d,x
                    lda #$00
L18e3               sta $11cc,x
                    sta $11cd,x
                    jmp L193a
                    
L18ec               lda $11cc,x
                    clc
                    adc $120c,x
                    sta $11cc,x
                    lda $11cd,x
                    adc $120d,x
                    sta $11cd,x
                    jmp L193a
                    
L1902               lda $11cc,x
                    clc
                    adc $120c,x
                    sta $11cc,x
                    lda $11cd,x
                    adc $120d,x
L1912               sta $11cd,x
                    dec $120e,x
                    bne L193a
                    lda $120b,x
                    eor #$80
                    sta $120b,x
                    lda $120f,x
                    sta $120e,x
                    lda $120c,x
                    clc
                    adc $1211,x
                    sta $120c,x
                    lda $120d,x
                    adc #$00
                    sta $120d,x
L193a               lda $11f7,x
                    tay
                    and #$f7
                    and $1220,x
                    sta $11bb,x
                    tya
                    and #$08
                    bne L198d
                    lda $11f9,x
                    and #$7f
                    clc
                    adc $1222,x
                    adc $11e3,x
                    sta $1970
                    tay
                    lda $1095,y
                    sta L19c9 + 1
                    lda $1156,y
                    sta $19d3
                    lda $11fa,x
                    beq L19b5
                    and #$7f
                    clc
                    adc #$00
                    tay
                    lda $11fa,x
                    bmi L19a2
                    lda L19c9 + 1
                    clc
                    adc $1035,y
                    sta L19c9 + 1
                    lda $19d3
                    adc $10f6,y
                    sta $19d3
                    jmp L19b5
                    
L198d               lda $11f9,x
                    and #$7f
                    tay
                    lda $1095,y
                    sta $11b7,x
                    lda $1156,y
                    sta $11b8,x
                    jmp L19da
                    
L19a2               lda L19c9 + 1
                    sec
                    sbc $1035,y
                    sta L19c9 + 1
                    lda $19d3
                    sbc $10f6,y
                    sta $19d3
L19b5               lda $11f9,x
                    bpl L19c9
                    lda L19c9 + 1
                    sta $11b7,x
                    lda $19d3
                    sta $11b8,x
                    jmp L19da
                    
L19c9               lda #$00
                    clc
                    adc $11cc,x
                    sta $11b7,x
                    lda #$00
                    adc $11cd,x
                    sta $11b8,x
L19da               ldy $11cf,x
L19dd               beq L1a33
                    lda $1eac,y
                    bmi L1a03
                    bne L19fe
                    lda $1ed0,y
                    sta $11ba,x
                    and #$f0
                    sta $11b9,x
                    jmp L1a2b
                    
L19f4               lda $1ed0,y
                    sta $11cf,x
                    tay
                    jmp L19dd
                    
L19fe               lda #$00
                    jmp L1a09
                    
L1a03               cmp #$ff
                    beq L19f4
                    lda #$ff
L1a09               sta $1a17
                    lda $1ed0,y
                    clc
                    adc $11b9,x
                    sta $11b9,x
                    lda #$00
                    adc $11ba,x
                    sta $11ba,x
                    inc $11d0,x
                    lda $1eac,y
                    and #$7f
                    cmp $11d0,x
                    bne L1a33
L1a2b               inc $11cf,x
                    lda #$00
                    sta $11d0,x
L1a33               cpx #$00
                    bne L1ab3
                    ldy #$00
L1a39               beq L1a8f
                    lda $1ef4,y
                    beq L1a4f
                    bpl L1a65
                    and #$7f
                    sta S12ee + 1
                    lda $1f48,y
                    sta $12f4
                    lda #$00
L1a4f               sta L1aa7 + 1
                    lda $1f1e,y
                    sta $1aad
                    jmp L1a87
                    
L1a5b               lda $1f1e,y
                    sta $1a38
                    tay
                    jmp L1a39
                    
L1a65               cmp #$7f
                    beq L1a5b
                    lda $1f48,y
                    clc
                    adc L1aa7 + 1
                    sta L1aa7 + 1
                    lda $1f1e,y
                    adc $1aad
                    sta $1aad
                    inc $1241
                    lda $1ef4,y
                    cmp $1241
                    bne L1a8f
L1a87               inc $1a38
                    lda #$00
                    sta $1241
L1a8f               lda #$00
                    cmp #$80
                    beq L1aa7
                    lda #$00
                    clc
                    adc $1aab
                    sta $1aab
                    lda L1a8f + 1
                    adc $1aaf
                    sta $1aaf
L1aa7               lda #$00
                    clc
                    adc #$00
                    lda #$00
                    adc #$00
                    sta $12f9
L1ab3               rts

		.binary "evolver_data.bin"
