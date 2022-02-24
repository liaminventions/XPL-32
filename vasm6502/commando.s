  .org $1000
SYS2064:
  lda #$40
  sta $b00b
  sta $b00d
  lda #$80
  sta $b00e

  lda #$24
  sta $b004
  lda $f4
  sta $b005
  
  lda #0
  jsr L5000
  cli

  jmp $c000

  .org $5000
L5000:
               jmp L5f0c
                    
S5003:
               jmp L5f42
                    
                    jmp $5f48 
                    jmp $5f4e 
                    jmp $53cf
 
L500f:
               jmp L5f56
                    
PlaySid:
             inc $5525
                    bit $5519
                    bmi L5038
                    bvc L5052
                    lda #$00
                    sta $5525
                    ldx #$02
L5023:
               sta $54ec,x
                    sta $54ef,x
                    sta $54f2,x
                    sta $54fb,x
                    dex
                    bpl L5023
                    sta $5519
                    jmp L5052
                    
L5038:
               bvc L504f
                    lda #$00
                    sta $b804
                    sta $b80b
                    sta $b812
                    lda #$0f
                    sta $b818
                    lda #$80
                    sta $5519
L504f:
               jmp L53a5
                    
L5052:
               ldx #$02
                    dec $5513
                    bpl L505f
                    lda $5517
                    sta $5513
L505f:
               lda $54e8,x
                    sta $54eb
                    tay
                    lda $5513
                    cmp $5517
                    bne L5083
                    lda $56f9,x
                    sta $5d
                    lda $56fc,x
                    sta $5e
                    dec $54f2,x
                    bmi L5086
                    jmp L5174
                    
                    jmp $538f 
L5083:
               jmp L519b
                    
L5086:
               ldy $54ec,x
                    lda ($5d),y
                    cmp #$ff
                    beq L5099
                    cmp #$fe
                    bne L50aa
                    jsr S5003
                    jmp L53a5
                    
L5099:
               lda #$00
                    sta $54f2,x
                    sta $54ec,x
                    sta $54ef,x
                    jmp L5086
                    
                    jmp $538f 
L50aa:
               tay
                    lda $5711,y
                    sta $5f
                    lda $573e,y
                    sta $60
                    lda #$00
                    sta $5520,x
                    ldy $54ef,x
                    lda #$ff
                    sta $5501
                    lda ($5f),y
                    sta $54f5,x
                    sta $5502
                    and #$1f
                    sta $54f2,x
                    bit $5502
                    bvs L5118
                    inc $54ef,x
                    lda $5502
                    bpl L50ed
                    iny
                    lda ($5f),y
                    bpl L50e7
                    sta $5520,x
                    jmp L50ea
                    
L50e7:
               sta $54fe,x
L50ea:
               inc $54ef,x
L50ed:
               iny
                    lda ($5f),y
                    sta $54fb,x
                    asl a
                    tay
                    lda $5528
                    bpl L511b
                    lda $5428,y
                    sta $5503
                    lda $5429,y
                    ldy $54eb
                    sta $b801,y
                    sta $551a,x
                    lda $5503
                    sta $b800,y
                    sta $551d,x
                    jmp L511b
                    
L5118:
               dec $5501
L511b:
               ldy $54eb
                    lda $54fe,x
                    stx $5504
                    asl a
                    asl a
                    asl a
                    tax
                    lda $5593,x
                    sta $5505
                    lda $5528
                    bpl L5154
                    lda $5593,x
                    and $5501
                    sta $b804,y
                    lda $5591,x
                    sta $b802,y
                    lda $5592,x
                    sta $b803,y
                    lda $5594,x
                    sta $b805,y
                    lda $5595,x
                    sta $b806,y
L5154:
               ldx $5504
                    lda $5505
                    sta $54f8,x
                    inc $54ef,x
                    ldy $54ef,x
                    lda ($5f),y
                    cmp #$ff
                    bne L5171
                    lda #$00
                    sta $54ef,x
                    inc $54ec,x
L5171:
               jmp L538f
                    
L5174:
               lda $5528
                    bmi L517c
                    jmp L538f
                    
L517c:
               ldy $54eb
                    lda $54f5,x
                    and #$20
                    bne L519b
                    lda $54f2,x
                    bne L519b
                    lda $54f8,x
                    and #$fe
                    sta $b804,y
                    lda #$00
                    sta $d405,y
                    sta $d406,y
L519b:
               lda $5528
                    bmi L51a3
                    jmp L538f
                    
L51a3:
               lda $54fe,x
                    asl a
                    asl a
                    asl a
                    tay
                    sty $5518
                    lda $5598,y
                    sta $5523
                    lda $5597,y
                    sta $5507
                    lda $5596,y
                    sta $5506
                    beq L5230
                    lda $5525
                    and #$07
                    cmp #$04
                    bcc L51cc
                    eor #$07
L51cc:
               sta $550c
                    lda $54fb,x
                    asl a
                    tay
                    sec
                    lda $542a,y
                    sbc $5428,y
                    sta $5508
                    lda $542b,y
                    sbc $5429,y
L51e4:
               lsr a
                    ror $5508
                    dec $5506
                    bpl L51e4
                    sta $5509
                    lda $5428,y
                    sta $550a
                    lda $5429,y
                    sta $550b
                    lda $54f5,x
                    and #$1f
                    cmp #$06
                    bcc L5221
                    ldy $550c
L5208:
               dey
                    bmi L5221
                    clc
                    lda $550a
                    adc $5508
                    sta $550a
                    lda $550b
                    adc $5509
                    sta $550b
                    jmp L5208
                    
L5221:
               ldy $54eb
                    lda $550a
                    sta $b800,y
                    lda $550b
                    sta $b801,y
L5230:
               lda $5523
                    and #$08
                    beq L524c
                    ldy $5518
                    lda $5591,y
                    adc $5507
                    sta $5591,y
                    ldy $54eb
                    sta $b802,y
                    jmp L52b3
                    
L524c:
               lda $5507
                    beq L52b3
                    ldy $5518
                    and #$1f
                    dec $550d,x
                    bpl L52b3
                    sta $550d,x
                    lda $5507
                    and #$e0
                    sta $5524
                    lda $5510,x
                    bne L5285
                    lda $5524
                    clc
                    adc $5591,y
                    pha
                    lda $5592,y
                    adc #$00
                    and #$0f
                    pha
                    cmp #$0e
                    bne L529c
                    inc $5510,x
                    jmp L529c
                    
L5285:
               sec
                    lda $5591,y
                    sbc $5524
                    pha
                    lda $5592,y
                    sbc #$00
                    and #$0f
                    pha
                    cmp #$08
                    bne L529c
                    dec $5510,x
L529c:
               stx $5504
                    ldx $54eb
                    pla
                    sta $5592,y
                    sta $b803,x
                    pla
                    sta $5591,y
                    sta $b802,x
                    ldx $5504
L52b3:
               ldy $54eb
                    lda $5520,x
                    beq L52fa
                    and #$7e
                    sta $5504
                    lda $5520,x
                    and #$01
                    beq L52e2
                    sec
                    lda $551d,x
                    sbc $5504
                    sta $551d,x
                    sta $b800,y
                    lda $551a,x
                    sbc #$00
                    sta $551a,x
                    sta $b801,y
                    jmp L52fa
                    
L52e2:
               clc
                    lda $551d,x
                    adc $5504
                    sta $551d,x
                    sta $b800,y
                    lda $551a,x
                    adc #$00
                    sta $551a,x
                    sta $b801,y
L52fa:
               lda $5523
                    and #$01
                    beq L5336
                    lda $551a,x
                    beq L5336
                    lda $54f2,x
                    beq L5336
                    lda $54f5,x
                    and #$1f
                    sec
                    sbc #$01
                    cmp $54f2,x
                    ldy $54eb
                    bcc L532b
                    lda $551a,x
                    dec $551a,x
                    sta $b801,y
                    lda $54f8,x
                    and #$fe
                    bne L5333
L532b:
               lda $551a,x
                    sta $b801,y
                    lda #$80
L5333:
               sta $b804,y
L5336:
               lda $5523
                    and #$02
                    beq L535e
                    lda $54f5,x
                    and #$1f
                    cmp #$03
                    bcc L535e
                    lda $5525
                    and #$01
                    beq L535e
                    lda $551a,x
                    beq L535e
                    inc $551a,x
                    inc $551a,x
                    ldy $54eb
                    sta $b801,y
L535e:
               lda $5523
                    and #$04
                    beq L538f
                    lda $5525
                    and #$01
                    beq L5375
                    lda $54fb,x
                    clc
                    adc #$0c
                    jmp L5378
                    
L5375:
               lda $54fb,x
L5378:
               asl a
                    tay
                    lda $5428,y
                    sta $5503
                    lda $5429,y
                    ldy $54eb
                    sta $b801,y
                    lda $5503
                    sta $b800,y
L538f:
               ldy #$ff
                    lda $5526
                    bne L539c
                    lda $5527
                    bmi L539c
                    iny
L539c:
               sty $5528
                    dex
                    bmi L53a5
                    jmp L505f
                    
L53a5:
               lda #$ff
                    sta $5528
                    lda $5526
                    bne L53b4
                    bit $5527
                    bpl L53b5
L53b4:
               rts
                    
L53b5:
               bvc L53ba
                    jsr S5531
L53ba:
               dec $552a
                    bpl L53b4
                    lda $5530
                    and #$0f
                    sta $552a
                    lda $5529
                    cmp $552b
                    bne L53de
                    ldx #$00
                    stx $b804
                    stx $b80b
                    dex
                    stx $5527
                    jmp L53b4
                    
L53de:
               dec $5529
                    asl a
                    tay
                    bit $5530
                    bmi L5408
                    bvs L53f6
                    lda $5428,y
                    sta $b800
                    lda $5429,y
                    sta $b801
L53f6:
               tya
                    sec
                    sbc $552c
                    tay
                    lda $5428,y
                    sta $b807
                    lda $5429,y
                    sta $b808
L5408:
               bit $552d
                    bpl L5418
                    lda $552e
                    eor #$01
                    sta $b804
                    sta $552e
L5418:
               bvc L5425
                    lda $552f
                    eor #$01
                    sta $b80b
                    sta $552f
L5425:
               jmp L53b4
                    
                    .byte                        $16, $01, $27, $01, $38, $01, $4b, $01
                    .byte $5f, $01, $73, $01, $8a, $01, $a1, $01, $ba, $01, $d4, $01, $f0, $01, $0e, $02 
                    .byte $2d, $02, $4e, $02, $71, $02, $96, $02, $bd, $02, $e7, $02, $13, $03, $42, $03 
                    .byte $74, $03, $a9, $03, $e0, $03, $1b, $04, $5a, $04, $9b, $04, $e2, $04, $2c, $05 
                    .byte $7b, $05, $ce, $05, $27, $06, $85, $06, $e8, $06, $51, $07, $c1, $07, $37, $08 
                    .byte $b4, $08, $37, $09, $c4, $09, $57, $0a, $f5, $0a, $9c, $0b, $4e, $0c, $09, $0d 
                    .byte $d0, $0d, $a3, $0e, $82, $0f, $6e, $10, $68, $11, $6e, $12, $88, $13, $af, $14 
                    .byte $eb, $15, $39, $17, $9c, $18, $13, $1a, $a1, $1b, $46, $1d, $04, $1f, $dc, $20 
                    .byte $d0, $22, $dc, $24, $10, $27, $5e, $29, $d6, $2b, $72, $2e, $38, $31, $26, $34 
                    .byte $42, $37, $8c, $3a, $08, $3e, $b8, $41, $a0, $45, $b8, $49, $20, $4e, $bc, $52 
                    .byte $ac, $57, $e4, $5c, $70, $62, $4c, $68, $84, $6e, $18, $75, $10, $7c, $70, $83 
                    .byte $40, $8b, $70, $93, $40, $9c, $78, $a5, $58, $af, $c8, $b9, $e0, $c4, $98, $d0 
                    .byte $08, $dd, $30, $ea, $20, $f8, $2e, $fd, $00, $07, $0e, $00, $00, $00, $00, $03 
                    .byte $0b, $0b, $05, $01, $05, $97, $03, $07, $41, $21, $41, $3d, $39, $15, $08, $09 
                    .byte $02, $ff, $03, $46, $01, $21, $ff, $03, $46, $00, $22, $25, $01, $00, $00, $00 
                    .byte $00, $00, $00, $01, $02, $03, $02, $03, $40, $00, $24, $16, $03, $dc, $46, $a9 
                    .byte $00, $00, $00, $08, $e0, $56, $00, $ff, $ff, $00, $00, $00, $00, $00, $00, $00 
                    .byte $00 

S5531:
               lda #$00
                    sta $b804
                    sta $b80b
                    sta $552a
                    lda $5527
                    and #$0f
                    sta $5527
                    asl a
                    asl a
                    asl a
                    asl a
                    tay
                    lda $55f9,y
                    sta $5530
                    lda $55fa,y
                    sta $5529
                    lda $5608,y
                    sta $552b
                    lda $5601,y
                    sta $552d
                    and #$3f
                    sta $552c
                    lda $55fe,y
                    sta $552e
                    lda $5605,y
                    sta $552f
                    ldx #$00
L5574:
               lda $55fa,y
                    sta $b800,x
                    iny
                    inx
                    cpx #$0e
                    bne L5574
                    lda $5530
                    and #$30
                    ldy #$ee
                    cmp #$20
                    beq L558d
                    ldy #$ce
L558d:
               sty L53de
                    rts
                    
               .binary "Commando Data.bin"              

L5f0c:
               ldy #$00
                    tax
                    lda $5514,x
                    sta $5517
                    txa
                    asl a
                    sta $5504
                    asl a
                    clc
                    adc $5504
                    tax
L5f20:
               lda $56ff,x
                    sta $56f9,y
                    inx
                    iny
                    cpy #$06
                    bne L5f20
                    lda #$00
                    sta $b804
                    sta $b80b
                    sta $b812
                    lda #$0f
                    sta $b818
                    lda #$40
                    sta $5519
                    rts
                    
L5f42:
               lda #$c0
                    sta $5519
                    rts
                    
                    lda #$00 
                    sta $5526 
                    rts
                    lda #$ff
                    sta $5526 
                    jmp $53cf
 
L5f56:
               ldx $5526
                    beq L5f5f
                    stx $5527
                    rts
                    
L5f5f:
               ora #$40
                    sta $5527
                    lda #$0f
                    sta $b818
                    rts
                    
                    .byte                              $00, $00, $00, $00, $00, $00 
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 

InitSid:
             cmp #$03
                    bcs L5f87
                    jmp L5000
                    
L5f87:
               pha
                    jsr L5f42
                    pla
                    sec
                    sbc #$03
                    tax
                    lda $5f98,x
                    jmp L500f
                    
                    .byte $00, $00, $00, $01, $02, $04, $05, $09, $0b, $0c 

irq:
  pha
  phx
  inc $0200
  lda $0200
  sbc #$20
  beq Norm_irq
  jmp reload
end_irq:
  pla
  plx
  rti
reload:
  lda #$24
  sta $b004
  lda #$f4
  sta $b005
  jmp end_irq
Norm_irq:
  lda #$24
  sta $b004
  lda #$f4
  sta $b005
  jsr $5003
  rti

  .org $7ffe
  .word irq

; end
