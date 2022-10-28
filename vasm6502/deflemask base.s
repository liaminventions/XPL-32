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
L1008               lda $04,x			; ah, well. this is a register dump situation (lol)
                    sta d400_sVoc1FreqLo,x	; $04-$1c -> the sid
                    dex
                    bpl L1008
                    dec $02	; decrement $02
                    bmi L1015	; and if it's wrapped around to #$ff, then go to L1015
                    rts		; wow that can be very fast... (reg dump aaa)
                    		; kinda like playing a sample, its fast and ez, but takes up time and MEMORY...
L1015               stx $02	; zero out $02
                    lda $03
                    bne L1033	; if $03 is not zero, then go to L1033
                    jsr $001f	; incremental load...
                    beq L1038	; but if its zero then goto L1038
                    cmp #$a0
                    bcs L102e	; if a >= #$a0, then goto L102e
                    sta $2a	; otherwise, put it in $2a
                    jsr $001f
                    sta $29	; and the next into $29
                    jmp L1076	; 1076
                    
L102e               sec		; it was >= #$a0
                    sbc #$9f	; a = a - #$9f
                    sta $03	; that goes in $03
L1033               dec $03	; $03--
                    jmp L1076	; 1076
                    
L1038               jsr $001f	; load the next byte
                    cmp #$fd
                    beq L106b	; if its #$fd goto L106b
                    cmp #$fe
                    beq L1060	; if its #$fe goto L1060
                    cmp #$ff
                    beq L104a	; if its #$ff goto L104a
                    sta $02	; if its none of those, put the value in $02.
                    rts
                    
L104a               lda #$00			; if the value was $ff,
                    sta d404_sVoc1Control	; zero out the voice control bytes (???)
                    sta d40b_sVoc2Control
                    sta d412_sVoc3Control
                    lda #$5e
                    sta $26
                    lda #$10	; and set the current location to $105e
                    sta $27
                    rts
                    
                      .byte $ff, $00	; ???? 

L1060               lda $1d	; if the value was #$fe,
                    sta $26
                    lda $1e	; read from $1e1d (??????)
                    sta $27
                    jmp L1015	; then goto L1015
                    
L106b               lda $26	; if the value was #$fd,
                    sta $1d
                    lda $27	; $1d = the number at $26 and $1e = the number at $26
                    sta $1e
                    jmp L1015	; then goto L1015
                    
L1076               jsr S10a1	; switch some stuff around (??)
                    lda #$f8
L107b               clc
                    adc #$07	; add 7..?
                    pha		; then put it in the stack
                    tax		; and the x register?
                    jsr $001f	; read next byte
                    lsr a	; and shift it right into the carry bit
                    php		; save the carry bit for later
L1085               inx		; inc a+7
                    lsr a	; push a right into carry again?
                    bcs L1093	; a bit 0 is a 1?
                    bne L1085	; or a 0?
                    plp		; umm how does it get here... it can only be a 1 or a 0...
                    pla		; anyway, restore all the saved data
                    bcs L107b	; if the first lsr stated that bit 0 of a was a one, then go there
                    jsr S10a1	; if it was a zero, switch $29-$26 and $2a-$27 (what)
                    rts		; leave
                    
L1093               pha			; idk
                    ldy $ffff,x		; load $0000,(x-1)
                    jsr $001f		; next byte
                    sta $0004,y		; since when are we using y?!??
                    pla
                    jmp L1085		; go back to L1085???????
                    
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
                    inc $26	; this is $10c6 (huh location) also the same at $001f
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
