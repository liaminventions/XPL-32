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

putbut              ldx #$1e
                    stx $b004
                    stx $b006
                    ldx #$4e	;50Hz IRQ
                    stx $b005
                    stx $b007
                    rts

InitSid             jsr putbut
                    jmp InitSid2

  .org $1006
PlaySid             ldx #$18
L1008               lda $04,x	; ah, well. this is a register dump situation (lol)
                    sta d400_sVoc1FreqLo,x	; $04-$1c -> the sid
                    dex
                    bpl L1008
                    dec $02
                    bmi L1015
                    rts		; wow that can be very fast... (reg dump aaa)
                    		; kinda like playing a sample, its fast and ez, but takes up time and MEMORY...
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
                    
S10a1               ldy $26	; $29 and $26 are switched?
                    ldx $29
                    sty $29
                    stx $26
                    ldy $27	; and $2a and $27 are switched...
                    ldx $2a
                    sty $2a
                    stx $27
                    rts		; idk...
                    		; on init, these are
L10b2               sty $26	; #$09
                    stx $27	; #$11
                    ldx #$06
L10b8               lda $10c6,x	; hold up, wait a minute
                    sta $1f,x	; this is copying som cod 2 z zero pagee!!!1!1!!11
                    dex		; seems to copy code from $10c6-$10cc to the zp at $1f-$25
                    bpl L10b8	
                    lda #$60	; rts after this.
                    sta $28	; this aint the best code (kinda odd)
                    bne L10d0	; the equal bit is 0, so this is a BRanhAlways command for nmos 6502s!!!
                    inc $26	; this is $10c6 (huh location)
                    bne L10cc	; this seems to increment the 16-bit address in the lda abs command, then run that lda opcode.
                    inc $27
L10cc               lda $ffff	; $ffff is at $26,$27 and this becomes lda $1109!
                    rts

L10d0               jsr $001f	; so this does inc $26; bne L10cc; lda $1109; rts!
                    sta $dc04	; $dc04=$110a
                    jsr $001f
                    sta $dc05	; $dc05=$110b
                    jsr $001f
                    sta $29	; $29=$110c
                    jsr $001f
                    sta $2a	; $2a=$110d
                    inc $26
                    bne L10ec	; $110e
                    inc $27
L10ec               lda $26
                    sta $1095	; $1095 = $0e
                    lda $27
                    sta $1096	; $1096 = $11
                    ldx #$1c
                    lda #$00
L10fa               sta $02,x	; zero out $02-$1e?
                    dex
                    bpl L10fa
                    jsr S10a1	; switch the locations of the variables at $29 and $26, and $2a and $27 (??????????)
                    rts		; end init? this might be called by the play routine too...
                    
InitSid2            ldy #$09	; init $001f subroutine to $1109 
                    ldx #$11
                    jmp L10b2

  .binary "example.bin"
;          ^^^^^^^^^^^
; put your data file here.
