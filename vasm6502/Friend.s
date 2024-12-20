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

  .org $1000

InitSid             jmp L10f8
                    
PlaySid             jmp L10fc
                    
S1006               lda $178f,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $1404,x
                    tya
L1013               sta $13db,x
                    lda $13ca,x
                    sta $13da,x
                    rts
                    
L101d               sta $141e,x
                    rts
                    
L1021               sta $141f,x
                    rts
                    
L1025               sta $13de,x
                    rts
                    
L1029               sta $13dd,x
                    lda #$00
                    sta $1406,x
                    rts
                    
L1032               sta $13df,x
                    lda #$00
                    sta $13e0,x
                    rts
                    
L103b               ldy #$00
                    sty $1144
L1040               sta L113f + 1
                    rts
                    
L1044               sta $118e
                    beq L1040
                    rts
                    
L104a               sta L1188 + 1
                    rts
                    
L104e               sta $1195
                    rts
                    
L1052               tay
                    lda $1bce,y
                    sta $13c3
                    lda $1bdf,y
                    sta $13c4
                    lda #$00
                    beq L1065
                    bmi L106f
L1065               sta $13f1
                    sta $13f8
                    sta $13ff
                    rts
                    
L106f               and #$7f
                    sta $13f1,x
                    rts
                    
L1075               dec $1405,x
L1078               jmp L12d8
                    
L107b               beq L1078
                    lda $1405,x
                    bne L1075
                    lda #$00
                    sta $ff
                    lda $1404,x
                    bmi L1094
                    cmp $1bce,y
                    bcc L1095
                    beq L1094
                    eor #$ff
L1094               clc
L1095               adc #$02
                    sta $1404,x
                    lsr a
                    bcc L10cb
                    bcs L10e2
                    tya
                    beq L10f2
                    lda $1bce,y
                    sta $ff
                    lda $13da,x
                    cmp #$02
                    bcc L10cb
                    beq L10e2
                    ldy $13f3,x
                    lda $1419,x
                    sbc $1432,y
                    pha
                    lda $141a,x
                    sbc $1492,y
                    tay
                    pla
                    bcs L10db
                    adc $fe
                    tya
                    adc $ff
                    bpl L10f2
L10cb               lda $1419,x
                    adc $fe
                    sta $1419,x
                    lda $141a,x
                    adc $ff
                    jmp L12d5
                    
L10db               sbc $fe
                    tya
                    sbc $ff
                    bmi L10f2
L10e2               lda $1419,x
                    sbc $fe
                    sta $1419,x
                    lda $141a,x
                    sbc $ff
                    jmp L12d5
                    
L10f2               ldy $13f3,x
                    jmp L12c7
                    
L10f8               sta $110c
                    rts
                    
L10fc               ldx #$00
L10fe               lda $1419,x
                    sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$19
                    bne L10fe
                    ldx #$00
                    ldy #$00
                    bmi L113f
                    txa
                    ldx #$29
L1112               sta $13c5,x
                    dex
                    bpl L1112
                    sta $142e
                    sta $118e
                    sta L113f + 1
                    stx $110c
                    tax
                    jsr S112f
                    ldx #$07
                    jsr S112f
                    ldx #$0e
S112f               lda #$05
                    sta $13f1,x
                    lda #$01
                    sta $13f2,x
                    sta $13f4,x
                    jmp L13a4
                    
L113f               ldy #$00
                    beq L1188
                    lda #$00
                    bne L116a
                    lda $1a9b,y
                    beq L115e
                    bpl L1167
                    asl a
                    sta $1193
                    lda $1b34,y
                    sta $118e
                    lda $1a9c,y
                    bne L117c
                    iny
L115e               lda $1b34,y
                    sta L1188 + 1
                    jmp L1179
                    
L1167               sta $1144
L116a               lda $1b34,y
                    clc
                    adc L1188 + 1
                    sta L1188 + 1
                    dec $1144
                    bne L118a
L1179               lda $1a9c,y
L117c               cmp #$ff
                    iny
                    tya
                    bcc L1185
                    lda $1b34,y
L1185               sta L113f + 1
L1188               lda #$00
L118a               sta $142f
                    lda #$00
                    sta $1430
                    lda #$00
                    ora #$0f
                    sta $1431
                    jsr S11a3
                    ldx #$07
                    jsr S11a3
                    ldx #$0e
S11a3               dec $13f2,x
                    beq L11c2
                    bpl L11bf
                    lda $13f1,x
                    cmp #$02
                    bcs L11bc
                    tay
                    eor #$01
                    sta $13f1,x
                    lda $13c3,y
                    sbc #$00
L11bc               sta $13f2,x
L11bf               jmp L1276
                    
L11c2               ldy $13ca,x
                    lda $13ae,y
                    sta $126b
                    sta $1274
                    lda $13c8,x
                    bne L1203
                    ldy $13ef,x
                    lda $14f2,y
                    sta $fe
                    lda $14f5,y
                    sta $ff
                    ldy $13c5,x
                    lda ($fe),y
                    cmp #$ff
                    bcc L11ef
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L11ef               cmp #$e0
                    bcc L11fb
                    sbc #$f0
                    sta $13c6,x
                    iny
                    lda ($fe),y
L11fb               sta $13f0,x
                    iny
                    tya
                    sta $13c5,x
L1203               ldy $13f4,x
                    lda $17fb,y
                    sta $140a,x
                    lda $13dc,x
                    beq L1270
                    sec
                    sbc #$60
                    sta $13f3,x
                    lda #$00
                    sta $13da,x
                    sta $13dc,x
                    lda $17c5,y
                    sta $1405,x
                    lda $178f,y
                    sta $13db,x
                    lda $13ca,x
                    cmp #$03
                    beq L1270
                    lda $1831,y
                    sta $13de,x
                    inc $13f5,x
                    lda $16ed,y
                    sta $13dd,x
                    lda $1723,y
                    beq L124e
                    sta $13df,x
                    lda #$00
                    sta $13e0,x
L124e               lda $1759,y
                    beq L125b
                    sta L113f + 1
                    lda #$00
                    sta $1144
L125b               lda $1681,y
                    sta $141e,x
                    lda $16b7,y
                    sta $141f,x
                    lda $13cb,x
                    jsr S1006
                    jmp L13a4
                    
L1270               lda $13cb,x
                    jsr S1006
L1276               ldy $13dd,x
                    beq L12ab
                    lda $1867,y
                    cmp #$10
                    bcs L128c
                    cmp $1406,x
                    beq L1291
                    inc $1406,x
                    bne L12ab
L128c               sbc #$10
                    sta $13de,x
L1291               lda $1868,y
                    cmp #$ff
                    iny
                    tya
                    bcc L129e
                    clc
                    lda $194c,y
L129e               sta $13dd,x
                    lda #$00
                    sta $1406,x
                    lda $194b,y
                    bne L12bf
L12ab               ldy $13da,x
                    lda $13be,y
                    sta $12bd
                    ldy $13db,x
                    lda $1bdf,y
                    sta $fe
                    jmp L107b
                    
L12bf               bpl L12c6
                    adc $13f3,x
                    and #$7f
L12c6               tay
L12c7               lda #$00
                    sta $1404,x
                    lda $1432,y
                    sta $1419,x
                    lda $1492,y
L12d5               sta $141a,x
L12d8               ldy $13df,x
                    beq L131e
                    lda $13e0,x
                    bne L12f6
                    lda $1a31,y
                    bpl L12f3
                    sta $141c,x
                    lda $1a66,y
                    sta $141b,x
                    jmp L130f
                    
L12f3               sta $13e0,x
L12f6               lda $1a66,y
                    clc
                    bpl L12ff
                    dec $141c,x
L12ff               adc $141b,x
                    sta $141b,x
                    bcc L130a
                    inc $141c,x
L130a               dec $13e0,x
                    bne L131e
L130f               lda $1a32,y
                    cmp #$ff
                    iny
                    tya
                    bcc L131b
                    lda $1a66,y
L131b               sta $13df,x
L131e               lda $13f2,x
                    cmp $140a,x
                    beq L1329
                    jmp L13a4
                    
L1329               ldy $13f0,x
                    lda $14f8,y
                    sta $fe
                    lda $15bd,y
                    sta $ff
                    ldy $13c8,x
                    lda ($fe),y
                    cmp #$40
                    bcc L1357
                    cmp #$60
                    bcc L1361
                    cmp #$c0
                    bcc L1375
                    lda $13c9,x
                    bne L134e
                    lda ($fe),y
L134e               adc #$00
                    sta $13c9,x
                    beq L139b
                    bne L13a4
L1357               sta $13f4,x
                    iny
                    lda ($fe),y
                    cmp #$60
                    bcs L1375
L1361               cmp #$50
                    and #$0f
                    sta $13ca,x
                    beq L1370
                    iny
                    lda ($fe),y
                    sta $13cb,x
L1370               bcs L139b
                    iny
                    lda ($fe),y
L1375               cmp #$bd
                    bcc L137f
                    beq L139b
                    ora #$f0
                    bne L1398
L137f               adc $13c6,x
                    sta $13dc,x
                    lda $13ca,x
                    cmp #$03
                    beq L139b
                    lda #$ff
                    sta $141e,x
                    lda #$00
                    sta $141f,x
                    lda #$fe
L1398               sta $13f5,x
L139b               iny
                    lda ($fe),y
                    beq L13a1
                    tya
L13a1               sta $13c8,x
L13a4               lda $13de,x
                    and $13f5,x
                    sta $141d,x
                    rts

  .binary "Friend_Data.bin"
