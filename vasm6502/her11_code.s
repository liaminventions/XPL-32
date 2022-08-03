d400_sVoc1FreqLo = $b800
d404_sVoc1Control = $b804
d40b_sVoc2Control = $b80b
d412_sVoc3Control = $b812

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
  rts
irq:
  lda #$40
  sta $b00d
  jsr putbut
  jsr PlaySid
  cli
  rti

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
L1002               lda $04,x
                    sta d400_sVoc1FreqLo,x
                    dex
                    bpl L1002
                    dec $02
                    bmi L100f
                    rts
                    
L100f               lda #$00
                    sta $01
                    stx $02
                    lda $03
                    bne L1031
                    jsr $001f
                    beq L1036
                    sec
                    sbc $2b
                    bcc L102f
                    adc #$10
                    sta $2a
                    jsr $001f
                    sta $29
                    jmp L1077
                    
L102f               sta $03
L1031               inc $03
                    jmp L1077
                    
L1036               jsr $001f
                    cmp #$fd
                    beq L106c
                    cmp #$fe
                    beq L1061
                    sta $02
                    cmp #$ff
                    bne L105a
                    lda #$00
                    sta d404_sVoc1Control
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    lda #$5f
                    sta $26
                    lda #$10
                    sta $27
L105a               lda #$37
                    sta $01
                    rts
                    
                     .byte $ff, $00 
L1061               lda $1d
                    sta $26
                    lda $1e
                    sta $27
                    jmp L100f
                    
L106c               lda $26
                    sta $1d
                    lda $27
                    sta $1e
                    jmp L100f
                    
L1077               jsr S10a2
                    lda #$f8
L107c               clc
                    adc #$07
                    pha
                    tax
                    jsr $001f
                    lsr a
                    php
L1086               inx
                    lsr a
                    bcs L1094
                    bne L1086
                    plp
                    pla
                    bcs L107c
                    jsr S10a2
                    rts
                    
L1094               pha
                    ldy $ffff,x
                    jsr $001f
                    sta $0004,y
                    pla
                    jmp L1086
                    
S10a2               ldy $26
                    ldx $29
                    sty $29
                    stx $26
                    ldy $27
                    ldx $2a
                    sty $2a
                    stx $27
                    rts
                    
L10b3               sty $26
                    stx $27
                    ldx #$06
L10b9               lda $10c7,x
                    sta $1f,x
                    dex
                    bpl L10b9
                    lda #$60
                    sta $28
                    bne L10ce
                    inc $26
                    bne L10cd
                    inc $27
L10cd                 .byte $ad 
L10ce               jsr $001f
                    
                    sta $dc04
                    jsr $001f
                    sta $dc05
                    jsr $001f
                    sta $29
                    jsr $001f
                    sta $2a
                    jsr $001f
                    sta $2b
                    inc $26
                    bne L10ef
                    inc $27
L10ef               lda $26
                    sta $1096
                    lda $27
                    sta $1097
                    ldx #$1c
                    lda #$00
L10fd               sta $02,x
                    dex
                    bpl L10fd
                    jsr S10a2
                    rts
                    
InitSid2            ldy #$0c
                    ldx #$11
                    jmp L10b3

  .binary "her11_data.bin"
;          ^^^^^^^^^^^
; put your data file here.
