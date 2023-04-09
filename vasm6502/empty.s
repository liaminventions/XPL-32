; THIS IS A TAPE FILE ONLY

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

  .org $0f7e
  .byte $82, $0f, $01, $12
  .include "kernal_def.s"

init:
  sei
  ldx #<secret
  ldy #>secret
  jsr w_acia_full
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff
  lda #$c0
  sta $b00e
  jsr putbut
  lda #0 ; Song Number
  jsr InitSid
  lda #$40
  sta $b00d
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp loop
irq:
  pha
  phx
  phy
  jsr putbut
  jsr PlaySid
  ply
  plx
  pla
  rti

putbut
  ldx #$1e
  stx $b004
  stx $b006
  ldx #$4e    ;50Hz IRQ
  stx $b005
  stx $b007
  rts 

secret:
	.byte "you found the easter egg!", $0d, $0a, $0d, $0a, "now playing 4MAT - EMPTY", $0d, $0a, $00

	.org $1001

L1001               jmp L1007
                    
PlaySid             jmp L10b7
                    
L1007               ldx #$00
L1009               lda #$01
                    sta $80
                    txa
                    tay
L100f               lda $80
                    sta $18ab,y
                    asl a
                    sta $80
                    lda $1130,x
                    sta $192b,y
                    rol a
                    sta $1130,x
                    bcc L1029
                    lda $80
                    adc #$00
                    sta $80
L1029               clc
                    tya
                    adc #$0c
                    tay
                    bpl L100f
                    inx
                    cpx #$0c
                    bne L1009
                    ldy #$0e
                    sty d418_sFiltMode
                    ldx #$02
L103c               lda $11ea,x
                    sta $182f,y
                    lda #$0e
                    sta $181a,y
                    tya
                    sbc #$07
                    tay
                    dex
                    bne L103c
                    rts
                    
L104f               ldy $1815,x
                    lda $1802,x
                    adc $1174,y
                    cmp $1802,x
                    sta $1802,x
                    bcs L1063
                    inc $1803,x
L1063               tya
                    asl a
                    asl a
                    adc $1816,x
                    sbc $1815,x
                    tay
                    lda $1151,y
                    sta $1804,x
                    lda $113c,y
                    cmp #$f0
                    bcc L108c
                    and #$0f
                    adc $1818,x
                    adc $182c,x
                    tay
                    lda $192a,y
                    sta $1800,x
                    lda $18aa,y
L108c               sta $1801,x
L108f               inc $1816,x
                    lda $1816,x
                    and #$03
                    bne L10a3
                    ldy $1815,x
                    lda $116d,y
                    lsr a
                    lsr a
                    lsr a
                    lsr a
L10a3               sta $1816,x
L10a6               ldy #$07
L10a8               lda $1800,x
                    sta d400_sVoc1FreqLo,x
                    inx
                    dey
                    bne L10a8
                    cpx #$15
                    bne L10b9
                    rts
                    
L10b7               ldx #$00
L10b9               dec $182e,x
                    bpl L104f
                    lda #$06
                    sta $182e,x
                    dec $182a,x
                    bpl L104f
L10c8               inc $1819,x
L10cb               ldy $1819,x
                    lda $181b,x
                    sta $182a,x
                    lda $117b,y
                    beq L10a6
                    bmi L10f9
                    sta $1818,x
                    lda #$00
                    sta $1816,x
                    ldy $1815,x
                    lda $116d,y
                    sta $1803,x
                    lda $1166,y
                    sta $1806,x
                    lda #$09
                    sta $1804,x
                    bpl L108f
L10f9               cmp #$ff
                    beq L110d
                    cmp #$df
                    and #$0f
                    bcc L1108
                    sta $1815,x
                    bpl L10c8
L1108               sta $181b,x
                    bpl L10c8
L110d               inc $181a,x
L1110               ldy $181a,x
                    lda $11bd,y
                    bmi L111d
                    sta $1819,x
                    bpl L10cb
L111d               cmp #$ff
                    beq L1128
                    and #$0f
                    sta $182c,x
                    bpl L110d
L1128               lda $182f,x
                    sta $181a,x
                    bpl L1110
                    .byte $0c, $1c, $2d, $3e, $51, $66, $7b, $91, $a9, $c3, $dd, $fa, $f3, $f7, $f0, $f4 
                    .byte $f7, $f0, $10, $af, $06, $f0, $f0, $f0, $14, $0c, $e0, $fc, $ef, $f0, $fc, $fc 
                    .byte $f0, $41, $41, $41, $41, $41, $41, $41, $81, $40, $41, $41, $40, $41, $41, $80 
                    .byte $11, $81, $40, $11, $21, $40, $6f, $6f, $95, $ec, $a9, $79, $6e, $15, $18, $38 
                    .byte $30, $38, $3b, $36, $1c, $0c, $00, $15, $00, $74, $a5, $00, $ff, $81, $e3, $11 
                    .byte $1d, $82, $e4, $55, $82, $e3, $11, $81, $1d, $e4, $55, $e3, $18, $ff, $e2, $55 
                    .byte $e5, $30, $35, $3a, $41, $35, $3a, $29, $ff, $8f, $e0, $35, $e1, $33, $31, $00 
                    .byte $e0, $35, $e1, $33, $e0, $2e, $00, $ff, $e6, $82, $38, $37, $87, $ff, $33, $80 
                    .byte $2e, $2c, $ff, $31, $8f, $00, $81, $00, $ff, $8f, $2e, $00, $ff, $f0, $02, $02 
                    .byte $f5, $02, $02, $f8, $02, $fa, $02, $f1, $02, $02, $ff, $13, $ff, $1e, $1e, $2d 
                    .byte $33, $2d, $33, $2d, $38, $2d, $33, $2d, $33, $3e, $2d, $f7, $33, $f0, $2d, $f9 
                    .byte $33, $f0, $2d, $38, $2d, $33, $2d, $33, $3e, $ff, $00, $0e, $10
InitSid             ldx #$00
                    txa
L11f0               sta $1800,x
                    inx
                    bne L11f0
                    jmp L1001

