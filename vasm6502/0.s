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

InitSid             jmp L1119
                    
PlaySid             jmp L1121
                    
L1006               jmp $491d

  .binary "0_ASCII.bin"
                    
S1040               lda $15db,y
                    jmp L104d
                    
L1046               tay
                    lda #$00
                    sta $4c0c,x
                    tya
L104d               sta $13e3,x
                    lda $13d2,x
                    sta $13e2,x
                    rts
                    
L1057               sta d405_sVoc1AttDec,x
                    rts
                    
L105b               sta d406_sVoc1SusRel,x
                    rts
                    
L105f               sta $13e7,x
                    lda #$00
                    sta $13e8,x
                    rts
                    
L1068               ldy #$00
                    sty $115c
L106d               sta L1157 + 1
                    rts
                    
L1071               sta $11a6
                    beq L106d
                    rts
                    
L1077               sta L11a0 + 1
                    rts
                    
L107b               tay
                    lda $172a,y
                    sta $101e
                    lda $1736,y
                    sta $101f
                    lda #$00
                    beq L108e
                    bmi L1098
L108e               sta $13f9
                    sta $1400
                    sta $1407
                    rts
                    
L1098               and #$7f
                    sta $13f9,x
                    rts
                    
L109e               dec $140d,x
L10a1               jmp L12db
                    
L10a4               beq L10a1
                    lda $140d,x
                    bne L109e
                    lda #$00
                    sta $81
                    lda $140c,x
                    bmi L10bd
                    cmp $172a,y
                    bcc L10be
                    beq L10bd
                    eor #$ff
L10bd               clc
L10be               adc #$02
                    sta $140c,x
                    lsr a
                    bcc L10ec
                    bcs L1103
                    tya
                    beq L1113
                    lda $172a,y
                    sta $81
                    sec
                    ldy $13fb,x
                    lda $140f,x
                    sbc $1419,y
                    pha
                    lda $1410,x
                    sbc $1471,y
                    tay
                    pla
                    bcs L10fc
                    adc $80
                    tya
                    adc $81
                    bpl L1113
L10ec               lda $140f,x
                    adc $80
                    sta $140f,x
                    lda $1410,x
                    adc $81
                    jmp L12d8
                    
L10fc               sbc $80
                    tya
                    sbc $81
                    bmi L1113
L1103               lda $140f,x
                    sbc $80
                    sta $140f,x
                    lda $1410,x
                    sbc $81
                    jmp L12d8
                    
L1113               ldy $13fb,x
                    jmp L12ca
                    
L1119               sta $1124
                    rts
                    
                    sta $49ad
                    rts
 
L1121               ldx #$00
                    ldy #$00
                    bmi L1157
                    txa
                    ldx #$29
L112a               sta $13cd,x
                    dex
                    bpl L112a
                    sta d415_sFiltFreqLo
                    sta $11a6
                    sta L1157 + 1
                    stx $1124
                    tax
                    jsr S1147
                    ldx #$07
                    jsr S1147
                    ldx #$0e
S1147               lda #$05
                    sta $13f9,x
                    lda #$01
                    sta $13fa,x
                    sta $13fc,x
                    jmp L13c3
                    
L1157               ldy #$00
                    beq L11a0
                    lda #$00
                    bne L1182
                    lda $16af,y
                    beq L1176
                    bpl L117f
                    asl a
                    sta $11ab
                    lda $16ec,y
                    sta $11a6
                    lda $16b0,y
                    bne L1194
                    iny
L1176               lda $16ec,y
                    sta L11a0 + 1
                    jmp L1191
                    
L117f               sta $115c
L1182               lda $16ec,y
                    clc
                    adc L11a0 + 1
                    sta L11a0 + 1
                    dec $115c
                    bne L11a2
L1191               lda $16b0,y
L1194               cmp #$ff
                    iny
                    tya
                    bcc L119d
                    lda $16ec,y
L119d               sta L1157 + 1
L11a0               lda #$00
L11a2               sta d416_sFiltFreqHi
                    lda #$00
                    sta d417_sFiltControl
                    lda #$00
                    ora #$0f
                    sta d418_sFiltMode
                    jsr S11bb
                    ldx #$07
                    jsr S11bb
                    ldx #$0e
S11bb               dec $13fa,x
                    beq L11da
                    bpl L11d7
                    lda $13f9,x
                    cmp #$02
                    bcs L11d4
                    tay
                    eor #$01
                    sta $13f9,x
                    lda $101e,y
                    sbc #$00
L11d4               sta $13fa,x
L11d7               jmp L1287
                    
L11da               ldy $13d2,x
                    lda $1009,y
                    sta $127c
                    sta $1285
                    lda $13d0,x
                    bne L121b
                    ldy $13f7,x
                    lda $14d1,y
                    sta $80
                    lda $14d4,y
                    sta $81
                    ldy $13cd,x
                    lda ($80),y
                    cmp #$ff
                    bcc L1207
                    iny
                    lda ($80),y
                    tay
                    lda ($80),y
L1207               cmp #$e0
                    bcc L1213
                    sbc #$f0
                    sta $13ce,x
                    iny
                    lda ($80),y
L1213               sta $13f8,x
                    iny
                    tya
                    sta $13cd,x
L121b               ldy $13fc,x
                    lda $13e4,x
                    beq L1281
                    sec
                    sbc #$60
                    sta $13fb,x
                    lda #$00
                    sta $13e2,x
                    sta $13e4,x
                    lda $15f8,y
                    sta $140d,x
                    lda $15db,y
                    sta $13e3,x
                    lda $13d2,x
                    cmp #$03
                    beq L1281
                    lda #$09
                    sta $13e6,x
                    inc $13fd,x
                    lda $15a1,y
                    beq L1259
                    sta $13e7,x
                    lda #$00
                    sta $13e8,x
L1259               lda $15be,y
                    beq L1266
                    sta L1157 + 1
                    lda #$00
                    sta $115c
L1266               lda $1584,y
                    sta $13e5,x
                    lda $1567,y
                    sta d406_sVoc1SusRel,x
                    lda $154a,y
                    sta d405_sVoc1AttDec,x
                    lda $13d3,x
                    jsr S1040
                    jmp L13c3
                    
L1281               lda $13d3,x
                    jsr S1040
L1287               ldy $13e5,x
                    beq L12a9
                    lda $1615,y
                    beq L1294
                    sta $13e6,x
L1294               lda $1616,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12a1
                    clc
                    lda $163b,y
L12a1               sta $13e5,x
                    lda $163a,y
                    bne L12c2
L12a9               lda $13fa,x
                    beq L12de
                    ldy $13e2,x
                    lda $1019,y
                    sta $12c0
                    ldy $13e3,x
                    lda $1736,y
                    sta $80
                    jmp L10a4
                    
L12c2               bpl L12c9
                    adc $13fb,x
                    and #$7f
L12c9               tay
L12ca               lda #$00
                    sta $140c,x
                    lda $1419,y
                    sta $140f,x
                    lda $1471,y
L12d8               sta $1410,x
L12db               lda $13fa,x
L12de               cmp #$02
                    beq L133c
                    ldy $13e7,x
                    beq L1339
                    ora $13d0,x
                    beq L1339
                    lda $13e8,x
                    bne L1305
                    lda $1661,y
                    bpl L1302
                    sta $1412,x
                    lda $1688,y
                    sta $1411,x
                    jmp L131e
                    
L1302               sta $13e8,x
L1305               lda $1688,y
                    clc
                    bpl L130e
                    dec $1412,x
L130e               adc $1411,x
                    sta $1411,x
                    bcc L1319
                    inc $1412,x
L1319               dec $13e8,x
                    bne L1330
L131e               lda $1662,y
                    cmp #$ff
                    iny
                    tya
                    bcc L132a
                    lda $1688,y
L132a               sta $13e7,x
                    lda $1411,x
L1330               sta d402_sVoc1PWidthLo,x
                    lda $1412,x
                    sta d403_sVoc1PWidthHi,x
L1339               jmp L13b7
                    
L133c               ldy $13f8,x
                    lda $14d7,y
                    sta $80
                    lda $1511,y
                    sta $81
                    ldy $13d0,x
                    lda ($80),y
                    cmp #$40
                    bcc L136a
                    cmp #$60
                    bcc L1374
                    cmp #$c0
                    bcc L1388
                    lda $13d1,x
                    bne L1361
                    lda ($80),y
L1361               adc #$00
                    sta $13d1,x
                    beq L13ae
                    bne L13b7
L136a               sta $13fc,x
                    iny
                    lda ($80),y
                    cmp #$60
                    bcs L1388
L1374               cmp #$50
                    and #$0f
                    sta $13d2,x
                    beq L1383
                    iny
                    lda ($80),y
                    sta $13d3,x
L1383               bcs L13ae
                    iny
                    lda ($80),y
L1388               cmp #$bd
                    bcc L1392
                    beq L13ae
                    ora #$f0
                    bne L13ab
L1392               adc $13ce,x
                    sta $13e4,x
                    lda $13d2,x
                    cmp #$03
                    beq L13ae
                    lda #$00
                    sta d406_sVoc1SusRel,x
                    lda #$0f
                    sta d405_sVoc1AttDec,x
                    lda #$fe
L13ab               sta $13fd,x
L13ae               iny
                    lda ($80),y
                    beq L13b4
                    tya
L13b4               sta $13d0,x
L13b7               lda $140f,x
                    sta d400_sVoc1FreqLo,x
                    lda $1410,x
                    sta d401_sVoc1FreqHi,x
L13c3               lda $13e6,x
                    and $13fd,x
                    sta d404_sVoc1Control,x
                    rts
                      
  .binary "0_Data.bin"

