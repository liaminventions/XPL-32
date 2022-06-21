;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;  the main thread ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irqst = $04
framecount = $05
bitdex = $06
graph = $07  ; 2 bytes

textstart:
  sei
  stz irqst
  cli
  lda #1
a:cmp irqst		; allign main thread to IRQ
  bne a

  ldx #<text_01
  ldy #>text_01
  jsr w_acia_full	; first text

  jsr wait_beat

  jsr out

  ldx #<text_03
  ldy #>text_03
  jsr w_acia_full	; second text
  jsr wait_beat

  jsr out

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
  
  ldx #<text_02
  ldy #>text_02
  jsr w_acia_full

  jsr wait_beat

  ldx #<endtext
  ldy #>endtext
  jsr w_acia_full
  ldx #<endtext
  ldy #>endtext		; bUt!11
  jsr w_acia_full
  ldx #<endtext
  ldy #>endtext
  jsr w_acia_full
  ldx #<endtext
  ldy #>endtext
  jsr w_acia_full

  lda #$02
  jsr print_chara
  lda #0
  jsr print_chara

  ldx #<setup
  ldy #>setup
  jsr w_acia_full

  jsr graphics		; write a screen


  ; BUG the scroll is broke

  ;sei
  ;stz scroll		; scroll on+
  ;stz sco
  ;cli

  jsr rootsetup		; setup <FOLDER>

  ldy #>imagefile	; setup image load
  ldx #<imagefile
  jsr fat32_finddirent
  jsr fat32_opendirent  ; open filename addr
  lda #<poketable
  sta fat32_address	; host addr
  lda #>poketable
  sta fat32_address+1
  jsr fat32_file_read	; read
  jsr graphics
  jmp not

nono:			; ded
  lda "!"
  jsr print_chara
not:
  jmp not
         		; say goodbye!
  
ee:

  lda #<poketable
  sta fat32_address
  lda #>poketable
  sta fat32_address+1

  jsr fat32_file_read

  jsr graphics

  jmp reset		; done?


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; SUBROUTINES ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rootsetup:
  pha
  phx
  phy
  ; Open root directory
  jsr fat32_openroot

  ; Find subdirectory by name
  ldx #<dirname
  ldy #>dirname
  jsr fat32_finddirent
  bcc foundsubdir

error:
  clc
  rts
  rts
  rts
  rts

foundsubdir:

  ; Open subdirectory
  jsr fat32_opendirent
  sec
  ply
  plx 
  pla
  rts

; BUG AAAAAAAAAAAAAAAAAAAAAAA

graphics:
  php
  pha
  phx
  phy
  lda #$80
  sta bitdex
  ldx #<poketable	; addr setup
  stx graph
  ldy #>poketable
  sty graph+1
  ldx #0		; x0 y0
  ldy #0
gloop:
  lda (graph)		; take a pixel
  and bitdex
  beq zero		; zero?
  lda #$05		; no,
  jmp gloop1		; write a 1
zero:
  lda #$06		; ye, write a 0
gloop1:
  jsr print_chara	; place it
  txa			; at 
  jsr print_chara	; x
  tya			; ,
  jsr print_chara	; y
  inx			; next x
  cpx #160
  bne norm		; x=160? (x-max)
  ldx #0
  iny			; then inc col
  cpy #80		; are we done?
  beq endit		; then done!!11!
norm:
  lda bitdex
  cmp #1
  beq bytedone
  lsr
  sta bitdex
  jmp gloop
bytedone:
  lda #$80
  sta bitdex
  inc graph
  lda graph
  bne back
inchi:
  inc graph+1
back:
  jmp gloop
endit:
  ply
  plx
  pla
  plp
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait24:
  pha
  phx
  phy
  stz framecount
b:inc framecount
  lda framecount
  bne b
  ply
  plx
  pla
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;  DATA  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dirname:
  .asciiz "FOLDER     "

imagefile:
  .byte "IB      DAT"

text_pointers:
  .word text_data
  .word text_data1
  .word text_data2
  .word text_data3
  .word text_data4
  .word text_data5
  .word text_data6
  .word text_data7
  .word 0,0

text_data:
  .byte $0c
  .byte $18, $08, "40 character text", $0d, $0a;,0
text_data1:
  .byte $18, $01, "80 character text", $0d, $0a;,0
text_data2:
  .byte $18, $02, "40 character bold text", $0d, $0a;,0
text_data3:
  .byte $18, $03, "80 character bold text", $0d, $0a;,0
text_data4:
  .byte $18, $04, "40 character double height text", $0d, $0a;,0
text_data5:
  .byte $18, $05, "80 character double height text", $0d, $0a;,0
text_data6:
  .byte $18, $06, "40 character double height bold text", $0d, $0a;,0
text_data7:
  .byte $18, $07, "80 character double height bold text", $0d, $0a;,0
text_end:
  .byte 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

text_01:
;   empty cursor|clear| column | Row      |
  .byte $02, $ff, $18, $03, $0c, $0e, $0a, $0f, $0a, "This is a demonstration of the capabilities of the XPL-32.", $00
text_02:
  .byte $18, $06, $0c, $0e, $0c, $0f, $0c, "And graphics...", $00
text_03:
  .byte $18, $06, $0c, $0e, $0a, $0f, $0c, "Here's Text Mode...", $00
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
setup:
  .byte $1b, $2d, $0c, $0e, $4f, $0f, $18, $00

poketable:
  .binary "xpl.bin"
