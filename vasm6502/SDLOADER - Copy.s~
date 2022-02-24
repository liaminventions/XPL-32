zp_sd_address = $40         ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables = $46    ; 24 bytes

fat32_workspace = $200      ; two pages

buffer = $400               ; 512 bytes
endbuf = $600


  .org $0600
jumptoit:
  jmp sdstart
  .include "hwconfig.s"
  .include "libsd.s"
  .include "libfat32.s"
  .include "libacia.s"
  .include "errors.s"

dirname:
  .asciiz "FOLDER     "
wipname:
  .asciiz "WIP     XPL"
micname:
  .asciiz "MICRO   XPL"
snakename:
  .asciiz "SNAKE   XPL"
donkname:
  .asciiz "DONKY   XPL"
udinname:
  .asciiz "FILE    TXT"
battlename:
  .asciiz "BATTLE  XPL"
legendname:
  .asciiz "LEGEND  XPL"
commandoname:
  .asciiz "COMMANDOXPL"
udingname:
  .asciiz "UDING   XPL"

errormsg:
  .byte $0c, "ERROR! SD Inaccsessable!", $0d, $0a, $00

sdstart:
  stz $00

  jsr cleardisplay

  ldx  #<loadmsg
  ldy  #>loadmsg
  jsr  w_acia_full

  ldx  #<lodmm
  ldy  #>lodmm
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
  jsr error_sound
  rts
  rts
  rts
  rts

foundsubdir

  ; Open subdirectory
  jsr fat32_opendirent

findrau:
  lda $8001
  and #$08
  beq findrau

  lda $8000
  cmp #'1'
  beq load_microchess
  
  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'2'
  beq load_snake

  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'3'
  beq load_donky
  jmp cont

load_microchess:
  jmp lod_microchess

load_snake:
  jmp lod_snake

load_commando:
  jmp lod_commando

load_uding:
  jmp lod_uding 

load_donky:
  jmp lod_donky

load_udinn:
  jmp lod_udinn 

cont:

  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'4'
  beq load_udinn

  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'5'
  beq load_battle

  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'6'
  beq load_legend

  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'7'
  beq load_commando

  lda $8001
  and #$08
  bne findrau

  lda $8000
  cmp #'8'
  beq load_uding

  lda $8001
  and #$08
  bne findraue

  lda $8000
  cmp #'W'
  beq load_wip

  lda $8001
  and #$08
  bne findraue

  lda $8000
  cmp #'t'
  beq typejmp

  jmp findrau

typejmp:
  jmp type

findraue:
  jmp findrau

load_wip:
  jmp lodwip

load_battle:
  jmp lod_battle

load_legend:
  jmp lod_legend

lod_udinn:
  stz $00
  lda #$04
  ldx #<udinname
  ldy #>udinname
  jsr load_put
  jsr cleardisplay

  ldy #0
.printloop
  lda $0400,y
  beq lop
  jsr print_char_acia

  iny

  jmp .printloop

  rts
  rts
  rts
  rts
lop:
  rts
  rts
  rts
  rts

lodwip:
  stz $00
  lda #$0f
  ldx #<wipname
  ldy #>wipname
  jsr load_put
  jsr cleardisplay
  sei
  jmp $0f00

lod_commando:
  lda #$d0
  sta $00
  lda #$0f
  ldx #<commandoname
  ldy #>commandoname
  jsr load_put
  jsr cleardisplay
  sei
  jmp $0fd0

lod_uding:
  lda #$d0
  sta $00
  lda #$0f
  ldx #<udingname
  ldy #>udingname
  jsr load_put
  jsr cleardisplay
  sei
  jmp $0fd0

lod_battle:
  lda #$d0
  sta $00
  lda #$0f
  ldx #<battlename
  ldy #>battlename
  jsr load_put
  jsr cleardisplay
  sei
  jmp $0fd0

lod_legend:
  lda #$d0
  sta $00
  lda #$0f
  ldx #<legendname
  ldy #>legendname
  jsr load_put
  jsr cleardisplay
  sei
  jmp $0fd0

lod_snake:
  stz $00
  lda #$20
  ldx #<snakename
  ldy #>snakename
  jsr load_put
  jsr cleardisplay
  sei
  jmp ($00)

lod_donky:
  lda #$d0
  sta $00
  lda #$0f
  ldx #<donkname
  ldy #>donkname
  jsr load_put
  jsr cleardisplay
  sei
  jmp $0fe0


lod_microchess:
  ; Find file by name
  stz $00
  lda #$20
  ldx #<micname
  ldy #>micname
  jsr load_put
  jmp ($00)

load_put:
  sta $01
  jsr fat32_finddirent
  bcc foundfile
  
  ; File not found
  jmp error

foundfile
 
  ; Open file
  jsr fat32_opendirent

  ldx #<lodmsg
  ldy #>lodmsg
  jsr w_acia_full

  lda $00
  sta fat32_address
  lda $01
  sta fat32_address+1

  jsr fat32_file_read

  ldx #<donemsg
  ldy #>donemsg
  jsr w_acia_full

  rts

type:
  
  jsr cleardisplay
;  pha
;  phy 
;  phx
;  jsr load_udinn
;  plx
;  ply
;  pla

start_the_actual_type:
  ldx #<typemsg
  ldy #>typemsg
  jsr w_acia_full

  ldx #0

  lda #' '
  sta $04

;  ldy #3

;insert:
;  lda wipname,x
;  sta loadbuf,x
;  inx
;  dey
;  beq jmpins
;  jmp insert
;jmpins:
;  jmp exitloop

typeloop:

  jsr rxpol
  lda $8000
  sta $05
  lda $05

  sbc #$0d
  beq exitloop

;  lda $05
;  sbc #$7f
;  beq dexx

  lda $05
  sta $8000

  lda $05
  sta loadbuf,x
  inx
  jmp typeloop

;  dexx:
;  dex
;  lda $05
;  sta $8000
;  jmp typeloop

exitloop:
  jsr cleardisplay
  stz $00
  lda #$0f
  ldy #>loadbuf
  ldx #<loadbuf
  jsr load_put
  jmp $0f00

rxpol:
  lda $8001
  and #$08
  beq rxpol
  rts

rxput:
  lda $8001
  and #$08
  beq typelop
  rts
typelop:
  jmp typeloop

lodmsg:
  .byte $0c, "Loading...", $0d, $0a, $00
donemsg:
  .byte "Done.", $0d, $0a, $00

loadmsg:
  .byte "          -------- SD Loader --------     ", $0d, $0a
  .byte "       1. Microchess     |  2. Snake      ", $0d, $0a
  .byte "       3. Donky Kong SID |  4. file.txt   ", $0d, $0a
  .byte "       5. BattleBars SID |  6. Legend SID ", $0d, $0a
  .byte "       7. Commando SID   |  8. Uding SID  ", $0d, $0a, $00
lodmm:
  .byte "              Press (W) for wip.xpl       ", $0d, $0a
  .byte "         Press (t) to type the filename.  ", $0d, $0a, $02, $00

typemsg:
  .byte "Type the filename in all caps.", $0d, $0a, " Filename: ", $02, "_", $00

loadbuf:
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte "XPL"


