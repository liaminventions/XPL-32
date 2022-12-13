; The Kansas City Standard for the XPL-32
; 2400hz = 1
; 1200hz = 0
; data is encoded with 2400hz starting sound (for alignment)
; start bit is a 0
; end bit is =>2 1s
; a byte is LEAST SIGNIFICANT TO MOST SIGNIFICANT as in 0111 -> 1110

thing  = $00 ; 1byt
tapest = $01 ; 1byt
cnt    = $02 ; 2byt
len    = $04 ; 2byt

  .org $0f00

start:
  lda #%10111111
  sta DDRB
  stz $b00e
  stz tapest

  ldx #<msg
  ldy #>msg		; press rec and play
  jsr w_acia_full

  lda #$18		; 4 seconds
  jsr tape_delay		; (ye fumble)

  ldx #<saving_msg	; Saving...
  ldy #>saving_msg
  jsr w_acia_full

  ldy #$40
  jsr inout		; intro sound

  jsr zero

  lda #1
  sta thing
  ldy #2
begin:
  lda #100		; our data is 100 bytes long
  and thing
  bne head1
  jsr zero
head:
  lda thing
  cmp #$80
  beq header_done
  asl thing
  jmp begin
head1:
  jsr one
  jmp head
header_done:
  dey
  beq afterhead
  lda #0
  sta begin+1
  jmp begin
afterhead:
  ldy #$20
  jsr inout
  ; now to send the actual data
  ldx #0
  lda #1
  sta thing		; first bit
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
  jsr one
  jsr one
  lda dat,x
  beq savedone
  jsr zero
  inx			; next byte
  cpx #100 		; are we done reading the data?
  bne wop
savedone
  ldy #$40
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
outer:
  ldx #$10		; $40 * $10 times make the sound
starter:
  jsr one		; sound
  dex
  bne starter
  dey
  bne outer
  rts

one:			; 2400hz sound 8 cyc
  pha
  jsr togtap ; 1
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 2
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 3
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 4
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 5
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 6
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 7
  jsr onefreq
  jsr togtap
  jsr onefreq
  jsr togtap ; 8
  jsr onefreq
  jsr togtap
  jsr onefreq
  pla
  rts

togtap:
  lda tapest
  eor #%10000000 	; data out on PA7
  sta tapest
  sta PORTB
  rts

zero: 			; 1200hz sound 4 cyc
  pha 
  jsr togtap ; 1
  jsr zerofreq
  jsr togtap
  jsr zerofreq
  jsr togtap ; 2
  jsr zerofreq
  jsr togtap
  jsr zerofreq
  jsr togtap ; 3
  jsr zerofreq
  jsr togtap
  jsr zerofreq
  jsr togtap ; 4
  jsr zerofreq
  jsr togtap
  jsr zerofreq
  pla
  rts

onefreq:
  stz $b00b
  lda #$ae
  sta $b004		; freq
  lda #$00
  sta $b005
intro:
  bit $b00d		; delay complete?
  bvc intro
  rts

zerofreq:
  stz $b00b
  lda #$3f
  sta $b004
  lda #$01
  sta $b005
intro2:
  bit $b00d
  bvc intro2
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

  .include "hwtape.s"
  .include "libacia.s"
;     cursor off   |                               | CR | LF | NULL
msg:
  .byte $02, $ff, "Press Record And play on Tape.", $0d, $0a, $00
loading_msg:         ;NULL
  .byte "Loading...", $00
msg2:
;       |      | CR | LF |cursor on| NULL
  .byte "Done!", $0d, $0a, $02, $5f, $00
dat:
  .byte "Hello, World! This is a test of the Kansas City tape protocol. If your are reading this, yay!", $0d, $0a, $0d, $0a, $00

  .org $1200

clear:
  ldx #0
clearlop:
  stz dat,x
  inx
  cpx #100 ; our message is 100 bytes long
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

  .org $1300

load:
  lda #%10111111
  sta DDRB

  lda #$20
  sta cnt+1
  stz cnt

  ldx #<loadmsg		; PRESS PLAY ON TAPE
  ldy #>loadmsg
  jsr w_acia_full

  lda #$18		; ye fumble
  jsr tape_delay	; 4 second delay

  ldx #<loading_msg	; Loading...
  ldy #>loading_msg
  jsr w_acia_full

  ldy #2

  ; thanks to ben eater for this code

rx_wait_start:
  bit PORTB	; wait until PORTB.6 = 0 (start bit)
  bvs rx_wait_start

  jsr rx_delay
  ldx #8
  jmp rba
read_bita:
  jsr rx_delay	; run bit delay for 300 baud serial stream
  jsr rx_delay
rba:
  bit PORTB	; read in the state
  bvs recv_1a	; if it's not a one,
  clc		; it's a zero.
  jmp rx_donea
recv_1a:
  sec		; it's a one.
  nop		; nops for timing
  nop
rx_donea:
  ror		; rotate carry into accumulator
  stz PORTB
  dex
  bne read_bita	; repeat until 8 bits read
  dey
  beq got_len
  sta len
  jmp rx_wait_start
got_len:
  sta len+1

rx_wait:
  bit PORTB	; wait until PORTB.6 = 0 (start bit)
  bvs rx_wait

  jsr rx_delay
  ldx #8
  jmp rbb
read_bit:
  jsr rx_delay	; run bit delay for 300 baud serial stream
  jsr rx_delay
rbb:
  bit PORTB	; read in the state
  bvs recv_1	; if it's not a one,
  clc		; it's a zero.
  jmp rx_done
recv_1:
  sec		; it's a one.
  nop		; nops for timing
  nop
rx_done:
  ror		; rotate carry into accumulator
  stz PORTB
  dex
  bne read_bit	; repeat until 8 bits read

  sta (cnt)	; store data
  inc cnt
  bne declen
  inc cnt+1
declen:
  lda cnt	; are we done?
  cmp len
  bne rx_wait
  lda cnt+1
  cmp len+1
  bne rx_wait	; if not, get another byte
  ;jmp rx_wait

load_done:
  ldx #<msg2	; Done!
  ldy #>msg2
  jsr w_acia_full

  rts
  rts
  rts
  rts

rx_delay:
  phx
  phy
  ldy #$02
rx_delay_outer:
  ldx #$92
rx_delay_inner:
  dex
  bne rx_delay_inner
  dey
  bne rx_delay_outer
  ply
  plx
  lda #$01
  sta PORTB
  rts

loadmsg:
  .byte "Press Play On Tape.", $0d, $0a, $00
saving_msg:
  .byte "Saving...", $00

