d400_sVoc1FreqLo = $b800
poll = $8001

loopstatus = $00 ; 1 byte
buffer = $01     ; 1 byte
loopx = $02      ; 1 byte
loopy = $03      ; 1 byte

  .org $0f00
init:
  sei
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff
  lda #$c0
  sta $b00e
  stz loopstatus
  ; IRQ Inits Go Here
  lda #0 ; Song Numbehr
  jsr InitSid
  cli
  nop
loop:
  jmp loop

irq:
  ; IRQ code goes here
  lda #$40
  sta $b00d

  lda loopstatus
  cmp #$03
  beq end_irq

  lda loopstatus
  cmp #$00
  beq one
  lda loopstatus
  cmp #$01
  beq two
  lda loopstatus
  cmp #$02
  beq three

end_irq:
  jmp check

one:
  jsr code
  jmp check
two:
  jsr startit
  jmp check
three:
  jsr write
  jmp check

InitSid             ldx #$63
                    stx $b004
                    ldx #$26
                    stx $b005
                    ldx #$63
                    stx $b006
                    ldx #$26
                    stx $b007
                    jmp L10d5

putbut              ldx #$63
                    stx $b004
                    ldx #$26
                    stx $b005
                    ldx #$63
                    stx $b006
                    ldx #$26
                    stx $b007
                    rts

  .org $1003

                    
PlaySid             jmp L10d9
                    
S1006               lda $15ec,y
                    jmp L1013
                    
L100c               tay
                    lda #$00
                    sta $1415,x
                    tya
L1013               sta $13ec,x
                    lda $13db,x
                    sta $13eb,x
                    rts
                    
L101d               sta $1444,x
                    rts
                    
L1021               sta $1445,x
                    rts
                    
L1025               sta $13ef,x
                    rts
                    
L1029               sta $13ee,x
                    lda #$00
                    sta $1417,x
                    rts
                    
L1032               sta $13f0,x
                    lda #$00
                    sta $13f1,x
                    rts
                    
L103b               ldy #$00
                    sty $1121
                    sta L111c + 1
                    rts
                    
L1044               bmi L1050
                    sta $1402
                    sta $1409
                    sta $1410
                    rts
                    
L1050               and #$7f
                    sta $1402,x
                    rts
                    
L1056               dec $1416,x
L1059               jmp L12de
                    
L105c               beq L1059
                    lda $1416,x
                    bne L1056
                    lda $174d,y
                    bmi L106c
                    ldy #$00
                    sty $ff
L106c               and #$7f
                    sta $1077
                    lda $1415,x
                    bmi L107e
                    cmp #$00
                    bcc L107f
                    beq L107e
                    eor #$ff
L107e               clc
L107f               adc #$02
                    sta $1415,x
                    lsr a
                    bcc L10a8
                    bcs L10bf
                    tya
                    beq L10cf
                    sec
                    ldy $1404,x
                    lda $143f,x
                    sbc $1458,y
                    pha
                    lda $1440,x
                    sbc $14b8,y
                    tay
                    pla
                    bcs L10b8
                    adc $fe
                    tya
                    adc $ff
                    bpl L10cf
L10a8               lda $143f,x
                    adc $fe
                    sta $143f,x
                    lda $1440,x
                    adc $ff
                    jmp L12db
                    
L10b8               sbc $fe
                    tya
                    sbc $ff
                    bmi L10cf
L10bf               lda $143f,x
                    sbc $fe
                    sta $143f,x
                    lda $1440,x
                    sbc $ff
                    jmp L12db
                    
L10cf               lda $1404,x
                    jmp L12c9
                    
L10d5               sta $10e9
                    rts
                    
L10d9               ldx #$00
L10db               lda $143f,x
                    sta d400_sVoc1FreqLo,x
                    inx
                    cpx #$19
                    bne L10db
                    ldx #$00
                    ldy #$00
                    bmi L111c
                    txa
                    ldx #$29
L10ef               sta $13d6,x
                    dex
                    bpl L10ef
                    sta $1454
                    sta $116b
                    sta L111c + 1
                    stx $10e9
                    tax
                    jsr S110c
                    ldx #$07
                    jsr S110c
                    ldx #$0e
S110c               lda #$0b
                    sta $1402,x
                    lda #$01
                    sta $1403,x
                    sta $1405,x
                    jmp L13b1
                    
L111c               ldy #$00
                    beq L1165
                    lda #$00
                    bne L1147
                    lda $16e4,y
                    beq L113b
                    bpl L1144
                    asl a
                    sta $1170
                    lda $1718,y
                    sta $116b
                    lda $16e5,y
                    bne L1159
                    iny
L113b               lda $1718,y
                    sta L1165 + 1
                    jmp L1156
                    
L1144               sta $1121
L1147               lda $1718,y
                    clc
                    adc L1165 + 1
                    sta L1165 + 1
                    dec $1121
                    bne L1167
L1156               lda $16e5,y
L1159               cmp #$ff
                    iny
                    tya
                    bcc L1162
                    lda $1718,y
L1162               sta L111c + 1
L1165               lda #$00
L1167               sta $1455
                    lda #$00
                    sta $1456
                    lda #$00
                    ora #$0f
                    sta $1457
                    jsr S1180
                    ldx #$07
                    jsr S1180
                    ldx #$0e
S1180               dec $1403,x
                    beq L1190
                    bpl L118d
                    lda $1402,x
                    sta $1403,x
L118d               jmp L1246
                    
L1190               ldy $13db,x
                    lda $13c1,y
                    sta $123b
                    sta $1244
                    lda $13d9,x
                    bne L11d1
                    ldy $1400,x
                    lda $1518,y
                    sta $fe
                    lda $151b,y
                    sta $ff
                    ldy $13d6,x
                    lda ($fe),y
                    cmp #$ff
                    bcc L11bd
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L11bd               cmp #$e0
                    bcc L11c9
                    sbc #$f0
                    sta $13d7,x
                    iny
                    lda ($fe),y
L11c9               sta $1401,x
                    iny
                    tya
                    sta $13d6,x
L11d1               ldy $1405,x
                    lda $160e,y
                    sta $142f,x
                    lda $13ed,x
                    beq L1240
                    sec
                    sbc #$60
                    sta $1404,x
                    lda #$00
                    sta $13eb,x
                    sta $13ed,x
                    lda $15fd,y
                    sta $1416,x
                    lda $15ec,y
                    sta $13ec,x
                    lda $13db,x
                    cmp #$03
                    beq L1240
                    lda $161f,y
                    sta $13ef,x
                    lda #$ff
                    sta $1406,x
                    lda $15b9,y
                    sta $13ee,x
                    lda $15ca,y
                    beq L121e
                    sta $13f0,x
                    lda #$00
                    sta $13f1,x
L121e               lda $15db,y
                    beq L122b
                    sta L111c + 1
                    lda #$00
                    sta $1121
L122b               lda $1597,y
                    sta $1444,x
                    lda $15a8,y
                    sta $1445,x
                    lda $13dc,x
                    jsr S1006
                    jmp L13b1
                    
L1240               lda $13dc,x
                    jsr S1006
L1246               ldy $13ee,x
                    beq L127b
                    lda $1630,y
                    cmp #$10
                    bcs L125c
                    cmp $1417,x
                    beq L1261
                    inc $1417,x
                    bne L127b
L125c               sbc #$10
                    sta $13ef,x
L1261               lda $1631,y
                    cmp #$ff
                    iny
                    tya
                    bcc L126e
                    clc
                    lda $1678,y
L126e               sta $13ee,x
                    lda #$00
                    sta $1417,x
                    lda $1677,y
                    bne L12c2
L127b               ldy $13eb,x
                    lda $13d1,y
                    sta L12bf + 1
                    ldy $13ec,x
                    lda $174d,y
                    bmi L1296
                    sta $ff
                    lda $1752,y
                    sta $fe
                    jmp L12bf
                    
L1296               lda $1752,y
                    sta $12b2
                    sty L12bb + 1
                    ldy $1430,x
                    lda $1459,y
                    sec
                    sbc $1458,y
                    sta $fe
                    lda $14b9,y
                    sbc $14b8,y
                    ldy #$00
                    beq L12bb
L12b5               lsr a
                    ror $fe
                    dey
                    bne L12b5
L12bb               ldy #$00
                    sta $ff
L12bf               jmp L105c
                    
L12c2               bpl L12c9
                    adc $1404,x
                    and #$7f
L12c9               sta $1430,x
                    tay
                    lda #$00
                    sta $1415,x
                    lda $1458,y
                    sta $143f,x
                    lda $14b8,y
L12db               sta $1440,x
L12de               ldy $13f0,x
                    beq L1324
                    lda $13f1,x
                    bne L12fc
                    lda $16c0,y
                    bpl L12f9
                    sta $1442,x
                    lda $16d2,y
                    sta $1441,x
                    jmp L1315
                    
L12f9               sta $13f1,x
L12fc               lda $16d2,y
                    clc
                    bpl L1305
                    dec $1442,x
L1305               adc $1441,x
                    sta $1441,x
                    bcc L1310
                    inc $1442,x
L1310               dec $13f1,x
                    bne L1324
L1315               lda $16c1,y
                    cmp #$ff
                    iny
                    tya
                    bcc L1321
                    lda $16d2,y
L1321               sta $13f0,x
L1324               lda $1403,x
                    cmp $142f,x
                    beq L132f
                    jmp L13b1
                    
L132f               ldy $1401,x
                    lda $151e,y
                    sta $fe
                    lda $155b,y
                    sta $ff
                    ldy $13d9,x
                    lda ($fe),y
                    cmp #$40
                    bcc L135d
                    cmp #$60
                    bcc L1367
                    cmp #$c0
                    bcc L137b
                    lda $13da,x
                    bne L1354
                    lda ($fe),y
L1354               adc #$00
                    sta $13da,x
                    beq L13a8
                    bne L13b1
L135d               sta $1405,x
                    iny
                    lda ($fe),y
                    cmp #$60
                    bcs L137b
L1367               cmp #$50
                    and #$0f
                    sta $13db,x
                    beq L1376
                    iny
                    lda ($fe),y
                    sta $13dc,x
L1376               bcs L13a8
                    iny
                    lda ($fe),y
L137b               cmp #$bd
                    bcc L1385
                    beq L13a8
                    ora #$f0
                    bne L13a5
L1385               adc $13d7,x
                    sta $13ed,x
                    lda $13db,x
                    cmp #$03
                    beq L13a8
                    lda $1405,x
                    cmp #$12
                    bcs L13bb
                    lda #$ff
                    sta $1444,x
                    lda #$00
                    sta $1445,x
L13a3               lda #$fe
L13a5               sta $1406,x
L13a8               iny
                    lda ($fe),y
                    beq L13ae
                    tya
L13ae               sta $13d9,x
L13b1               lda $13ef,x
                    and $1406,x
                    sta $1443,x
                    rts
                    
L13bb               cmp #$13
                    bcc L13a3
                    bcs L13a8
                    asl $0c

  .binary "ero.bin"

break_buffer:
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk
  brk

check:
  sei
  lda poll
  and #$08
  beq cont
  jmp clear
cont:
  jsr putbut
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

code
	sei
  lda #$01
  sta loopstatus
	ldx #78
	jsr spaces
	rts
spaces
	jsr txno
	lda #$20
	sta $8000
	dex
	bne spaces
	rts

startit
  lda #$02
  sta loopstatus
	ldx #0
  stx loopx
	ldy #$1c
  sty loopy
  rts
write
  ldx loopx
  ldy loopy
	jsr txpoll
	lda text,x
	sta $8000
	beq next
	jsr txno
	lda #$16
	sta $8000
	jsr txno
	lda #$1d
	sta $8000
	inx
	stx loopx
  rts

next
  lda #$04
  sta loopstatus
  rts

;delaysmol
;	phy
;	cli
;	ldy #$ff
;smol
;	dey
;	bne smol
;	ply
;	rts
txpoll
  pha
  phx
  phy

  jsr delay

	lda poll
	and #$10
	beq txpoll
  ply
  plx
  pla
	rts
txno:
	lda poll
	and #$10
	beq txno
	rts

delay
	cli
outer
	ldy #$ff
inner
	ldx #$ff

innerloop
	dex
	bne innerloop

	dey
	beq ende
	jmp inner
ende
	sei
	rts


text
	.byte "Hello and welcome to my first demo! :) This is some classic scroller text from many demos."
wop_ee
	brk
