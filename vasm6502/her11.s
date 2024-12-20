d400_sVoc1FreqLo = $b800
d404_sVoc1Control = $b804
d40b_sVoc2Control = $b80b
d412_sVoc3Control = $b812

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

putbut              ldx #$1f
                    stx $b004
                    stx $b006
                    ldx #$3e	;60Hz IRQ
                    stx $b005
                    stx $b007
                    rts

InitSid             jsr putbut
                    jmp InitSid2

  .org $1006
PlaySid             ldx #$18
L1008               lda $04,x
                    sta d400_sVoc1FreqLo,x
                    dex
                    bpl L1008
                    dec $02
                    bmi L1015
                    rts
                    
L1015               stx $02
                    lda $03
                    bne L1033
                    jsr $001f
                    beq L1038
                    cmp #$a0
                    bcs L102e
                    sta $2a
                    jsr $001f
                    sta $29
                    jmp L1076
                    
L102e               sec
                    sbc #$9f
                    sta $03
L1033               dec $03
                    jmp L1076
                    
L1038               jsr $001f
                    cmp #$fd
                    beq L106b
                    cmp #$fe
                    beq L1060
                    cmp #$ff
                    beq L104a
                    sta $02
                    rts
                    
L104a               lda #$00
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    lda #$5e
                    sta $26
                    lda #$10
                    sta $27
                    rts
                    
                      .byte $ff, $00 
L1060               lda $1d
                    sta $26
                    lda $1e
                    sta $27
                    jmp L1015
                    
L106b               lda $26
                    sta $1d
                    lda $27
                    sta $1e
                    jmp L1015
                    
L1076               jsr S10a1
                    lda #$f8
L107b               clc
                    adc #$07
                    pha
                    tax
                    jsr $001f
                    lsr a
                    php
L1085               inx
                    lsr a
                    bcs L1093
                    bne L1085
                    plp
                    pla
                    bcs L107b
                    jsr S10a1
                    rts
                    
L1093               pha
                    ldy $ffff,x
                    jsr $001f
                    sta $0004,y
                    pla
                    jmp L1085
                    
S10a1               ldy $26
                    ldx $29
                    sty $29
                    stx $26
                    ldy $27
                    ldx $2a
                    sty $2a
                    stx $27
                    rts
                    
L10b2               sty $26
                    stx $27
                    ldx #$06
L10b8               lda $10c6,x
                    sta $1f,x
                    dex
                    bpl L10b8
                    lda #$60
                    sta $28
                    bne L10d0
                    inc $26
                    bne L10cc
                    inc $27
L10cc               lda $ffff
                    rts
                    
L10d0               jsr $001f
                    sta $dc04
                    jsr $001f
                    sta $dc05
                    jsr $001f
                    sta $29
                    jsr $001f
                    sta $2a
                    inc $26
                    bne L10ec
                    inc $27
L10ec               lda $26
                    sta $1095
                    lda $27
                    sta $1096
                    ldx #$1c
                    lda #$00
L10fa               sta $02,x
                    dex
                    bpl L10fa
                    jsr S10a1
                    rts
                    
InitSid2            ldy #$09
                    ldx #$11
                    jmp L10b2

  .binary "her11_data.bin"
;          ^^^^^^^^^^^
; put your data file here.
