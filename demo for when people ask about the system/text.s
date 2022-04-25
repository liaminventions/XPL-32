
; text part of demo
;
;
;
; he he he ha

textstart:
  ldx #<text_01
  ldy #>text_01
  jsr w_acia_full	; first text
 ; jsr wait

;modify:
;  ldy #7		; load the amount of sayings (e)
;  ldx #0		; set x
;modit:
;  phx
;  phy
;  ldx #<mrbut
;  ldy #>mrbut
;  jsr w_acia_full
;  ply
;  plx
;modloop:
;  jsr txpoll		; send data
;  lda dat_1,x
;  sta $8000
;  inx			; inc
;  txa
;  clc
;  sbc #$14		; is x=15
;  bne modloop		; if ye,
;  jsr wait		; wait
;  dey			; dey
;  bne modit		; all namez!!?!???/!1!1
;
;  jsr wait		; ye...
;  jsr wait

  jsr wait_beat

  jsr out


  ldx #<text_03
  ldy #>text_03
  jsr w_acia_full	; second text
  jsr wait_beat
  jsr outslow
  

  ldx #0
text_ii:
  jsr txpoll
  lda text_data,x
  beq text_ii_end
  sta $8000
  inx
  jmp text_ii

text_ii_end:
  jsr wait_beat
  jsr wait
  jsr wait
  
  ldx #<text_02
  ldy #>text_02
  jsr w_acia_full

  jsr wait_beat
  jsr wait
  jsr wait

  ldx #$ff
doomed:
  ldx #<endtext
  ldy #>endtext
  jsr w_acia_full
  dex
  bne doomed

loope:
  jmp loope

out:
  pha
  phx
  ldx #64
downloop:
  jsr txpoll
  lda #$08
  sta $8000
  jsr txpoll
  lda #$14
  sta $8000
  dex
  bne downloop
  plx
  pla
  rts

outslow:
  pha
  phx
  phy
  ldx #64
downloop2:
  jsr txpoll
  lda #$08
  sta $8000
  jsr txpoll
  lda #$14
  sta $8000
  ldy #$ff
wait_fast:
  dey
  bne wait_fast

  dex
  bne downloop
  ply
  plx
  pla
  rts


wait_beat:
  phy
  ldy #9
waitloop:
  jsr wait
  dey
  bne waitloop
  ply
  rts

long_wait:
  phx
  phy
  pha
  ldx #$ff
long_loop
  jsr wait
  dex
  bne long_loop
  pla
  ply
  plx
  rts

text_data:
  .byte $0c
  .byte $18, $08, "40 character text", $0d, $0a
  .byte $18, $01, "80 character text", $0d, $0a
  .byte $18, $02, "40 character bold text", $0d, $0a
  .byte $18, $03, "80 character bold text", $0d, $0a
  .byte $18, $04, "40 character double height text", $0d, $0a
  .byte $18, $05, "80 character double height text", $0d, $0a
  .byte $18, $06, "40 character double height bold text", $0d, $0a
  .byte $18, $07, "80 character double height bold text", $0d, $0a
text_end:
  .byte $00

text_01:
;   empty cursor|clear| column | Row      |
  .byte $02, $ff, $18, $03, $0c, $0e, $0a, $0f, $0a, "This is a demonstration of the capabilities of the XPL-32.", $00
text_02:
  .byte $18, $06, $0c, $0e, $0c, $0f, $0c, "And graphics...", $00
text_03:
  .byte $18, $06, $0c, $0e, $0d, $0f, $0c, "Text Mode...", $00
;dat_1:
;  .byte "1Mhz WDC65c02        "
;dat_2:
;  .byte "1.8432 Mhz ACIA      "
;dat_3:
;  .byte "WDC65c22             "
;dat_4:
;  .byte "6581 SID             "
;dat_5:
;  .byte "An LCD screen        "
;dat_6:
;  .byte "A Serial text display"
;dat_7:
;  .byte "4 EXP ports          "
endtext:
  .byte $08, $16, $00
;mrbut:
;  .byte $0e, $0c, $0f, $44, $00
