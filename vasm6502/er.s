thing  = $00
odd    = $01
buf    = $02
eorr   = $03
tapest = $04

  .org $0f00

start:
  jsr via_init		; init VIA
  stz $b00e
  stz tapest
  ldx #0
datlop:
  txa
  sta dat,x		; store data that counts
  inx
  bne datlop

  ldx #<msg
  ldy #>msg		; press rec and play
  jsr w_acia_full

  lda #$18		; 4 seconds
  jsr TDELAY		; (ye fumble)

  ldx #<saving_msg	; Saving...
  ldy #>saving_msg
  jsr w_acia_full

  jsr inout		; intro sound

  jsr zero
  jsr one

  ldy #1
  sty thing		; first bit
wop:
  lda dat,x		; load data
  and thing		; mask it
  bne jsrone		; one
  jsr zero		; or zero
oner:
  lda thing		; load the bitmask
  cmp #$80		; end of byte?
  beq noo
  asl thing
  jmp wop		; next bit
jsrone:
  jsr one		; a one
  jmp oner
noo:
  lda #1		; byte done
  sta thing
  jsr zero		; end prev. byte, start new byte
  jsr one
  inx			; next byte
  bne wop

  jsr inout		; we are done, ending sound  

  ; done
  ldx #<msg2
  ldy #>msg2		; "Done!"
  jsr w_acia_full

  rts
  rts
  rts			; return
  rts
  rts



; subs

inout:
  pha
  phx
  ldx #50		; 50 times make the sound
starter:
  jsr one		; sound
  inx
  bne starter
  plx
  pla
  rts

one:			; 2349 hz sound 8x (aprox. 3.33ms)
  pha
  phx
  lda #$55		; asl thing
  sta odd
  stz tapest
  stz PORTA		; 0
  ldx #8		; cycle 8 times
loop1:
  jsr onefreq
  jsr togtap
  dex			; a cycle is done
  bne loop1
  plx
  pla
  rts

togtap:
  lda tapest
  eor #$01
  sta tapest
  sta PORTA
  rts

zero:
  pha 
  phx
  lda #$55
  sta odd
  stz PORTA
  ldx #4
loop2:
  jsr zerofreq
  jsr togtap
  dex
  bne loop2
  plx
  pla
  rts

onefreq:
  stz $b00b
  lda #$f8
  sta $b004		; freq
  lda #$00
  sta $b005
intro:
  bit $b00d		; delay complete?
  bvc intro
  rts

zerofreq:
  stz $b00b
  lda #$f2
  sta $b004
  lda #$01
  sta $b005
intro2:
  bit $b00d
  bvc intro2
  rts

TDELAY  LDX     #$FF            ; wait for ye fumble.
RD1     LDA     #$7A            ; (Y times through inner loop,
RD2     SBC     #$01            ;  Y * $FF * 650uS = uS / 1e-6 = S )
        BNE     RD2
RD3     DEX
        BNE     RD1
        DEY
        BNE     TDELAY
        RTS

  .include "hwtape.s"
  .include "libacia.s"
;     cursor off   |                               | CR | LF | NULL
msg:
  .byte $02, $ff, "Press Record And play on Tape.", $0d, $0a, $00
loading_msg:         ;NULL
  .byte "Loading...", $00
saving_msg:
  .byte "Saving...", $00
msg2:
;       |      | CR | LF |cursor on| NULL
  .byte "Done!", $0d, $0a, $02, $5f, $00
dat:
  .byte $00

  .org $1200

clear:
  ldx #0
clearlop:
  stz dat,x
  dex
  bne clearlop
  ldx #<clearmsg
  ldy #>clearmsg
  jsr w_acia_full
  rts
  rts
  rts
  rts

clearmsg:
  .byte "Cleared!", $0d, $0a, $00

RDBYTE	LDX     #$08            ; Set up bit read counter (8 bits)
RDBYT2  PHA                     ; Preserve A (RD2BIT clobbers it)
        JSR     RD2BIT          ; Look for two tape state transitions
        PLA
        ROL                     ; Roll the read bit into A (from carry)
        LDY     #$3A            ; Set the compensated read width
        DEX
        BNE     RDBYT2          ; Keep going until 8 bits read.
        RTS

RD2BIT  JSR     RDBIT           ; Recursive call to self (two transitions)
RDBIT   DEY
        LDA     PORTA
        EOR     tapest
        BEQ     RDBIT           ; Keep looping until state changes.
        EOR     tapest
        STA     tapest
        CPY     #$80            ; If Y went negative, set carry (this is a '1')
        RTS

  .org $1300

load:
  stz PORTA
  stz DDRA

  ldx #<loadmsg		; PRESS PLAY ON TAPE
  ldy #>loadmsg
  jsr w_acia_full

  lda #$18		; ye fumble
  jsr TDELAY		; 4 second delay

  ldx #<loading_msg	; Loading...
  ldy #>loading_msg
  jsr w_acia_full

  jsr wait1
  jsr wait0		; header
  jsr wait1
  jsr RDBYTE
  sta dat
  ldx #1
loadloop
  jsr wait0
  jsr wait1
  jsr RDBYTE
  sta dat,x
  inx
  bne loadloop

  ldx #<msg2
  ldy #>msg2
  jsr w_acia_full

  rts
  rts
  rts
  rts
; subs

wait1:
  jsr RDBIT
  bcs wait1
  rts

wait0:
  jsr RDBIT
  bcc wait0
  rts

cyc3:
  jsr wait0
  jsr wait0
  jsr wait0
  rts

cyc7:
  jsr wait1
  jsr wait1
  jsr wait1
  jsr wait1
  jsr wait1
  jsr wait1
  jsr wait1  
  rts

loadmsg:
  .byte "Press Play On Tape.", $0d, $0a, $00
