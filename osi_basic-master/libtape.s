;
;       ------------------ KCS Cassete Tape Library -------------------
;
; assumes that PA7 is connected to MIC and PA6 is connected to the tape card's output.
;
; ZP usage:
; cnt		  - 16 bit start address. at the end of a routine, this value equals "len".
; len		  - 16 bit end address.
; thing		  - 8 bit temorary bitmask variable
;
; Included Routines:
; tsave		  - Saves to a cassette tape. Start address in "cnt" and end address in "len". also uses "thing"
; tload		  - Load from a cassette tape. "cnt" and "len" are also used.

cnt = $00
len = $02
thing = $04

tsave:
  pha
  txa
  pha
  tya
  pha

  lda #%10111111
  sta DDRA
  lda #0
  sta $b00e
  ;sta tapest

  lda #$8f
  sta $b818

  ldx #0
tlp1:
  lda treg,x
  sta $b810,x
  inx
  cpx #5
  bne tlp1
  lda #$4c
  sta $b80e
  lda #$9d
  sta $b80f

  ldx #<tsavemsg
  ldy #>tsavemsg	; press rec and play
  jsr w_acia_full

  lda #$18		; 4 seconds
  jsr tape_delay	; (ye fumble)

  ldx #<saving_msg	; Saving...
  ldy #>saving_msg
  jsr w_acia_full

  ldy #$40
  jsr inout		; intro sound

  lda #1
  sta thing
  ldy #0
tbeginn:
  jsr zero
tbegin: 
  lda cnt,y		; read in the address param
  and thing
  bne thead1
  jsr zero
thead:
  lda thing
  cmp #$80
  beq theader_done
  asl thing
  jmp tbegin
thead1:
  jsr one
  jmp thead
theader_done:
  lda #1
  sta thing
  jsr one
  jsr one
  iny
  cpy #$04
  bne tbeginn
  ldy #$20
  jsr inout
  ; now to send the actual data
  jsr zero
  ldx #0
  lda #1
  ldy #0
  sta thing		; first bit
twop: 
  lda (cnt),y		; load data
  and thing		; mask it
  bne tjsrone		; one
  jsr zero		; or zero
toner:
  lda thing		; load the bitmask
  cmp #$80		; end of byte?
  beq tnoo
  asl thing
  jmp twop		; next bit
tjsrone:
  jsr one		; a one
  jmp toner
tnoo:
  lda #1		; byte done
  sta thing
  jsr one
  jsr one
  inc cnt		; inc pointer
  bne tnotcnt
  inc cnt+1
tnotcnt:
  lda cnt		; are we done?
  cmp len
  beq tnearly
  jsr zero
  jmp twop		; if not, go again for another byte
tnearly:
  lda cnt+1
  cmp len+1
  beq tsavedone
  jsr zero
  jmp twop
tsavedone:
  ldy #$40
  jsr inout		; we are done, ending sound  

  lda #0
  sta PORTA

  ; done
  ldx #<msg2
  ldy #>msg2		; "Done!"
  jsr w_acia_full

  pla
  tay
  pla
  tax
  pla
  rts			; return
  rts
  rts
  rts

; subroutines

inout:
touter:
  ldx #$10		; $40 * $10 times make the sound
tstarter:
  jsr one		; sound
  dex
  bne tstarter
  dey
  bne touter
  rts

one:			; 2400hz sound 8 cyc
  php
  pha
  ;jsr togtap ; 1
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 2
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 3
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 4
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 5
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 6
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 7
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  ;jsr togtap ; 8
  ;jsr onefreq
  ;jsr togtap
  ;jsr onefreq
  lda #$4c
  sta $b80e
  lda #$9d
  sta $b80f
  jsr tx_delay
  jsr tx_delay
  pla
  plp
  rts

treg:
  .byte $00, $08, $41, $00, $f0

;togtap:
;  lda tapest
;  eor #%10000000 	; data out on PA7
;  sta tapest
;  sta PORTA
;  rts

zero: 			; 1200hz sound 4 cyc
  php
  pha 
  ;jsr togtap ; 1
  ;jsr zerofreq
  ;jsr togtap
  ;jsr zerofreq
  ;jsr togtap ; 2
  ;jsr zerofreq
  ;jsr togtap
  ;jsr zerofreq
  ;jsr togtap ; 3
  ;jsr zerofreq
  ;jsr togtap
  ;jsr zerofreq
  ;jsr togtap ; 4
  ;jsr zerofreq
  ;jsr togtap
  ;jsr zerofreq
  lda #$a6
  sta $b80e
  lda #$4e
  sta $b80f
  jsr tx_delay
  jsr tx_delay
  pla
  plp
  rts

;onefreq:
;  stz $b00b
;  lda #$ae
;  sta $b004		; freq
;  lda #$00
;  sta $b005
;intro:
;  bit $b00d		; delay complete?
;  bvc intro
;  rts

;zerofreq:
;  stz $b00b
;  lda #$3f
;  sta $b004
;  lda #$01
;  sta $b005
;intro2:
;  bit $b00d
;  bvc intro2
;  rts

tx_delay:
  txa
  pha
  ldx #$7e
tx_delay_inner:
  lda $b81b
  sta PORTA
  dex
  bne tx_delay_inner
  pla
  tax
  rts

tape_delay:
  ldx #$ff		; wait for ye fumble.
rd1:
  lda #$7a		; (Y times through inner loop,
rd2:     
  sbc #$01		;  Y * $FF * 650uS = uS / 1e-6 = S )
  bne rd2
rd3:
  dex
  bne rd1
  dey
  bne tape_delay
  rts

tsavemsg:
  .byte $02, $ff, "Press Record And play on Tape.", $0d, $0a, $00
tloadmsg:
  .byte $02, $ff, "Press Play On Tape.", $0d, $0a, $00
loading_msg:
  .byte "Loading...", $00
saving_msg:
  .byte "Saving...", $00
msg2:
  .byte "Done!", $0d, $0a, $02, $5f, $00
loadedmsg:
  .byte "Loaded from ", $00
tomsg:
  .byte " to ", $00

; Load from a cassette tape.
;
; Needs no arguments because start and end addresses are encoded in tape.
;

tload:
  pha
  txa
  pha
  tya
  pha

  lda #%10111111
  sta DDRA
  lda #%11111111
  sta DDRB

  ldx #<tloadmsg	; PRESS PLAY ON TAPE
  ldy #>tloadmsg
  jsr w_acia_full

  lda #$18		; ye fumble
  jsr tape_delay	; 4 second delay

  ldx #<loading_msg	; Loading...
  ldy #>loading_msg
  jsr w_acia_full

  ldy #0

  ; thanks to ben eater for help with this code

rx_wait_start:
  bit PORTA	; wait until PORTB.6 = 0 (start bit)
  bvs rx_wait_start

  jsr rx_delay  ; half-bit delay
  ldx #8
read_bita:
  jsr rx_delay	; run full-bit delay for 300 baud serial stream
  jsr rx_delay
  bit PORTA	; read in the state
  bvs recv_1a	; if it's not a one,
  clc		; it's a zero.
  jmp rx_donea
recv_1a:	; otherwise,
  sec		; it's a one.
  nop		; nops for timing
  nop
rx_donea:
  ror		; rotate carry into accumulator
  dex
  bne read_bita	; repeat until 8 bits read
  sta cnt,y
  iny
  cpy #$04
  beq got_len
  lda cnt
  pha
  lda cnt+1
  pha
  jsr rx_delay
  jsr rx_delay
  jmp rx_wait_start
got_len:
  jsr rx_delay
  jsr rx_delay
  ldy #0
rx_wait:
  bit PORTA	; wait until PORTB.6 = 0 (start bit)
  bvs rx_wait
  jsr rx_delay
  ldx #8
read_bit:
  jsr rx_delay	; run bit delay for 300 baud serial stream
  jsr rx_delay
  bit PORTA	; read in the state
  bvs recv_1	; if it's not a one,
  clc		; it's a zero.
  jmp rx_done
recv_1:
  sec		; it's a one.
  nop		; nops for timing
  nop
rx_done:
  ror		; rotate carry into accumulator
  dex
  bne read_bit	; repeat until 8 bits read
  sta (cnt),y	; store data
  jsr rx_delay
  jsr rx_delay
  inc cnt
  bne declen
  inc cnt+1
declen:
  lda cnt		; are we done?
  cmp len
  bne rx_wait_delay
  lda cnt+1
  cmp len+1
  bne rx_wait_delay	; if not, get another byte
  ldx #<loadedmsg	; Done! print "Loaded from X to Y"
  ldy #>loadedmsg
  jsr w_acia_full
  pla
  jsr print_hex_acia
  pla
  jsr print_hex_acia
  ldx #<tomsg
  ldy #>tomsg
  jsr w_acia_full
  lda len+1
  jsr print_hex_acia
  lda len
  jsr print_hex_acia
  jsr crlf
  pla
  tay
  pla
  tax
  pla
  rts
  rts
  rts
  rts

rx_wait_delay:
  jsr rx_delay
  jsr rx_delay
  jmp rx_wait

rx_delay:
  txa
  pha
  tya
  pha
  ldy #$02
rx_delay_outer:
  ldx #$A4
rx_delay_inner:
  dex
  bne rx_delay_inner
  dey
  bne rx_delay_outer
  pla
  tay
  pla
  tax
  rts
