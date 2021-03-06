d400_sVoc1FreqLo = $b800
; Put Your SID Addr Here^

zp_sd_address = $00         ; 2 bytes
zp_sd_currentsector = $02   ; 4 bytes
zp_fat32_variables = $05    ; 24 bytes

fat32_workspace = $200      ; two pages


  .org $0900
jumptoit:
  jmp init
  .include "hwconfig.s"
  .include "libsd.s"
  .include "libfat32.s"
  .include "libacia.s"

init:
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff
  ; IRQ Inits Go Here
  lda #0 ; Song Number
  jsr InitSid
  cli
  nop
; You can put code you want to run in the backround here.
loop:
  jmp sdstart
irq:
  ; IRQ code goes here
  nop
  nop
  nop
  jsr PlaySid
  nop
  rti
dirname:
  .asciiz "FOLDER     "
micname:
  .asciiz "MICRO   XPL"
snakename:
  .asciiz "SNAKE   XPL"

errormsg:
  .byte $0c, "ERROR! SD Inaccsessable!", $0d, $0a, $00

sdstart:

  ldx  #<loadmsg
  ldy  #>loadmsg
  jsr  w_acia_full

  ; Open root directory
  jsr fat32_openroot

  ; Find subdirectory by name
  ldx #<dirname
  ldy #>dirname
  jsr fat32_finddirent
  bcc foundsubdir

error:

  ; Subdirectory not found
  ldy #>errormsg
  ldx #<errormsg
  jsr w_acia_full
  jmp $c000

foundsubdir

  ; Open subdirectory
  jsr fat32_opendirent

findrau:
  jsr rxpoll
  lda $8000
  and #'1'
  bne load_microchess
  lda $8000
  and #'2'
  bne load_snake
  jmp findrau

load_microchess:
  ; Find file by name
  ldx #<micname
  ldy #>micname
load_put:
  jsr fat32_finddirent
  bcc foundfile

  ; File not found
  jmp error

foundfile
 
  ; Open file
  jsr fat32_opendirent

  lda #$00
  sta fat32_address
  lda #$20
  sta fat32_address+1

  jsr fat32_file_read

  jmp $2000

load_snake:
  ldx #<snakename
  ldy #>snakename
  jmp load_put

lop:
  jmp lop


loadmsg:
  .byte "      -------- SD Loader --------      ", $0d, $0a
  .byte "       1. Microchess  |  2. Snake      ", $0d, $0a
  .byte "       3. <WIP>       |  4. <WIP>      ", $0d, $0a, $00

  .org $1000

InitSid:
             jmp L10fb
                    
PlaySid:
             jmp L10ff
                    
S1006:
               lda $16b2,y
                    jmp L1013

L100c:
               tay
                    lda #$00
                    sta $14a0,x
                    tya                    
L1013:
               sta $1477,x
                    lda $1466,x
                    sta $1476,x
                    rts
                    
L101d:
               sta $14cf,x
                    rts
                    
L1021:
               sta $14d0,x
                    rts
                    
L1025:
               sta $147a,x
                    rts
                    
L1029:
               sta $1479,x
                    lda #$00
                    sta $14a2,x
                    rts
                    
L1032:
               sta $147b,x
                    lda #$00
                    sta $147c,x
                    rts
                    
L103b:
               ldy #$00
                    sty $1145
L1040:
               sta L1140 + 1
                    rts
                    
L1044:
               sta $118f
                    beq L1040
                    rts
                    
L104a:
               sta L1189 + 1
                    rts
                    
L104e:
               sta $1196
                    rts
                    
L1052:
               tay
                    lda $17d9,y
                    sta $145f
                    lda $17e0,y
                    sta $1460
                    lda #$00
                    beq L1065
                    bmi L106f
L1065:
               sta $148d
                    sta $1494
                    sta $149b
                    rts
                    
L106f:
               and #$7f
                    sta $148d,x
                    rts
                    
L1075:
               dec $14a1,x
L1078:
               jmp L133c
                    
L107b:
               beq L1078
                    lda $14a1,x
                    bne L1075
                    lda $17d9,y
                    bmi L108b
                    ldy #$00
                    sty $fe
L108b:
               and #$7f
                    sta $1096
                    lda $14a0,x
                    bmi L109d
                    cmp #$03
                    bcc L109e
                    beq L109d
                    eor #$ff
L109d:
               clc
L109e:
               adc #$02
                    sta $14a0,x
                    lsr a
                    bcc L10ce
                    bcs L10e5
                    tya
                    beq L10f5
                    lda #$00
                    cmp #$02
                    bcc L10ce
                    beq L10e5
                    ldy $148f,x
                    lda $14ca,x
                    sbc $14e3,y
                    pha
                    lda $14cb,x
                    sbc $1543,y
                    tay
                    pla
                    bcs L10de
                    adc $fd
                    tya
                    adc $fe
                    bpl L10f5
L10ce:
               lda $14ca,x
                    adc $fe
                    sta $14ca,x
                    lda $14cb,x
                    adc $ff
                    jmp L1339
                    
L10de:
               sbc $fd
                    tya
                    sbc $fe
                    bmi L10f5
L10e5:
               lda $14ca,x
                    sbc $fe
                    sta $14ca,x
                    lda $14cb,x
                    sbc $ff
                    jmp L1339
                    
L10f5:
               lda $148f,x
                    jmp L1327
                    
L10fb:
               sta $110d
                    rts
                    
L10ff:
               ldx #$18
L1101:
               lda $14ca,x
                    sta d400_sVoc1FreqLo,x
                    dex
                    bpl L1101
                    ldx #$00
                    ldy #$ff
                    bmi L1140
                    txa
                    ldx #$29
L1113:
               sta $1461,x
                    dex
                    bpl L1113
                    sta $14df
                    sta $118f
                    sta L1140 + 1
                    stx $110d
                    tax
                    jsr S1130
                    ldx #$07
                    jsr S1130
                    ldx #$0e
S1130:
               lda #$05
                    sta $148d,x
                    lda #$01
                    sta $148e,x
                    sta $1490,x
                    jmp L140f
                    
L1140:
               ldy #$04
                    beq L1189
                    lda #$00
                    bne L116b
                    lda $178c,y
                    beq L115f
                    bpl L1168
                    asl a
                    sta $1194
                    lda $17b2,y
                    sta $118f
                    lda $178d,y
                    bne L117d
                    iny
L115f:
               lda $17b2,y
                    sta L1189 + 1
                    jmp L117a
                    
L1168:
               sta $1145
L116b:
               lda $17b2,y
                    clc
                    adc L1189 + 1
                    sta L1189 + 1
                    dec $1145
                    bne L118b
L117a:
               lda $178d,y
L117d:
               cmp #$ff
                    iny
                    tya
                    bcc L1186
                    lda $17b2,y
L1186:
               sta L1140 + 1
L1189:
               lda #$79
L118b:
               sta $14e0
                    lda #$f1
                    sta $14e1
                    lda #$30
                    ora #$0f
                    sta $14e2
                    jsr S11a4
                    ldx #$07
                    jsr S11a4
                    ldx #$0e
S11a4:
               dec $148e,x
                    beq L11d4
                    bpl L11c0
                    lda $148d,x
                    cmp #$02
                    bcs L11bd
                    tay
                    eor #$01
                    sta $148d,x
                    lda $145f,y
                    sbc #$00
L11bd:
               sta $148e,x
L11c0:
               jmp L1297
                    
L11c3:
               sbc #$d0
                    inc $1463,x
                    cmp $1463,x
                    bne L1219
                    lda #$00
                    sta $1463,x
                    beq L1214
L11d4:
               ldy $1466,x
                    lda $144a,y
                    sta $1289
                    sta $1295
                    lda $1464,x
                    bne L1219
                    ldy $148b,x
                    lda $15a3,y
                    sta $fe
                    lda $15a6,y
                    sta $ff
                    ldy $1461,x
                    lda ($fe),y
                    cmp #$ff
                    bcc L1201
                    iny
                    lda ($fe),y
                    tay
                    lda ($fe),y
L1201:
               cmp #$e0
                    bcc L120d
                    sbc #$f0
                    sta $1462,x
                    iny
                    lda ($fd),y
L120d:
               cmp #$d0
                    bcs L11c3
                    sta $148c,x
L1214:
               iny
                    tya
                    sta $1461,x
L1219:
               ldy $1490,x
                    lda $16ce,y
                    sta $14ba,x
                    lda $1478,x
                    beq L1291
                    sec
                    sbc #$60
                    sta $148f,x
                    lda #$00
                    sta $1476,x
                    sta $1478,x
                    lda $16c0,y
                    sta $14a1,x
                    lda $16b2,y
                    sta $1477,x
                    lda $1466,x
                    cmp #$03
                    beq L1291
                    lda $16dc,y
                    beq L1259
                    cmp #$fe
                    bcs L1256
                    sta $147a,x
                    lda #$ff
L1256:
               sta $1491,x
L1259:
               lda $1696,y
                    beq L1266
                    sta $147b,x
                    lda #$00
                    sta $147c,x
L1266:
               lda $16a4,y
                    beq L1273
                    sta L1140 + 1
                    lda #$00
                    sta $1145
L1273:
               lda $1688,y
                    sta $1479,x
                    lda $167a,y
                    sta $14d0,x
                    lda $166c,y
                    sta $14cf,x
                    lda $1467,x
                    jsr S1006
                    jmp L140f
                    
L128e:
               jmp L141f
                    
L1291:
               lda $1467,x
                    jsr S1006
L1297:
               ldy $1479,x
                    beq L12d6
                    lda $16ea,y
                    cmp #$10
                    bcs L12ad
                    cmp $14a2,x
                    beq L12b6
                    inc $14a2,x
                    bne L12d6
L12ad:
               sbc #$10
                    cmp #$e0
                    bcs L12b6
                    sta $147a,x
L12b6:
               lda $16eb,y
                    cmp #$ff
                    iny
                    tya
                    bcc L12c2
                    lda $1719,y
L12c2:
               sta $1479,x
                    lda #$00
                    sta $14a2,x
                    lda $16e9,y
                    cmp #$e0
                    bcs L128e
                    lda $1718,y
                    bne L1320
L12d6:
               ldy $1476,x
                    sty $10ac
                    lda $145a,y
                    sta L131d + 1
                    ldy $1477,x
L12e5:
               lda $17d9,y
                    bmi L12f4
                    sta $ff
                    lda $17e0,y
                    sta $fe
                    jmp L131d
                    
L12f4:
               lda $17e0,y
                    sta $1310
                    sty L1319 + 1
                    ldy $14bb,x
                    lda $14e4,y
                    sec
                    sbc $14e3,y
                    sta $fe
                    lda $1544,y
                    sbc $1543,y
                    ldy #$03
                    beq L1319
L1313:
               lsr a
                    ror $fe
                    dey
                    bne L1313
L1319:
               ldy #$01
                    sta $ff
L131d:
               jmp L107b
                    
L1320:
               bpl L1327
                    adc $148f,x
                    and #$7f
L1327:
               sta $14bb,x
                    tay
                    lda #$00
                    sta $14a0,x
                    lda $14e3,y
                    sta $14ca,x
                    lda $1543,y
L1339:
               sta $14cb,x
L133c:
               ldy $147b,x
                    beq L1382
                    lda $147c,x
                    bne L135a
                    lda $1748,y
                    bpl L1357
                    sta $14cd,x
                    lda $176a,y
                    sta $14cc,x
                    jmp L1373
                    
L1357:
               sta $147c,x
L135a:
               lda $176a,y
                    clc
                    bpl L1363
                    dec $14cd,x
L1363:
               adc $14cc,x
                    sta $14cc,x
                    bcc L136e
                    inc $14cd,x
L136e:
               dec $147c,x
                    bne L1382
L1373:
               lda $1749,y
                    cmp #$ff
                    iny
                    tya
                    bcc L137f
                    lda $176a,y
L137f:
               sta $147b,x
L1382:
               lda $148e,x
                    cmp $14ba,x
                    beq L138d
                    jmp L140f
                    
L138d:
               ldy $148c,x
                    lda $15a9,y
                    sta $fe
                    lda $160b,y
                    sta $ff
                    ldy $1464,x
                    lda ($fe),y
                    cmp #$40
                    bcc L13bb
                    cmp #$60
                    bcc L13c5
                    cmp #$c0
                    bcc L13d9
                    lda $1465,x
                    bne L13b2
                    lda ($fe),y
L13b2:
               adc #$00
                    sta $1465,x
                    beq L1406
                    bne L140f
L13bb:
               sta $1490,x
                    iny
                    lda ($fe),y
                    cmp #$60
                    bcs L13d9
L13c5:
               cmp #$50
                    and #$0f
                    sta $1466,x
                    beq L13d4
                    iny
                    lda ($fe),y
                    sta $1467,x
L13d4:
               bcs L1406
                    iny
                    lda ($fe),y
L13d9:
               cmp #$bd
                    bcc L13e3
                    beq L1406
                    ora #$f0
                    bne L1403
L13e3:
               adc $1462,x
                    sta $1478,x
                    lda $1466,x
                    cmp #$03
                    beq L1406
                    lda $1490,x
                    cmp #$0d
                    bcs L1419
                    lda #$00
                    sta $14d0,x
                    lda #$0f
                    sta $14cf,x
L1401:
               lda #$fe
L1403:
               sta $1491,x
L1406:
               iny
                    lda ($fe),y
                    beq L140c
                    tya
L140c:
               sta $1464,x
L140f:
               lda $147a,x
                    and $1491,x
                    sta $14ce,x
                    rts
                    
L1419:
               cmp #$0d
                    bcc L1401
                    bcs L1406
L141f:
               and #$0f
                    sta $fe
                    lda $1718,y
                    sta $ff
                    ldy $fe
                    cpy #$05
                    bcs L143c
                    sty $10ac
                    lda $145a,y
                    sta L131d + 1
                    ldy $ff
                    jmp L12e5
                    
L143c:
               lda $144a,y
                    sta $1445
                    lda $fe
                    jsr S1006
                    jmp L133c
                    
  .binary "Donky_Kong_Data.bin"
