charbuffer = $601            ; 1 byte

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

errormsg:
  .byte $0d, $0a, "ERROR!", $0d, $0a, $00

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
  jmp type

type:
  
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
  jmp typeloop
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
  .byte $0d, $0a, "Loading...", $0d, $0a, $00
donemsg:
  .byte "Done. You can run this file using <RESET> 'go 0f00' <ENTER>", $0d, $0a, $00

loadmsg:
  .byte "          -------- SD Loader --------     ", $0d, $0a, $00
lodmm:
  .byte "          Press (l) to list <FOLDER>      ", $0d, $0a, $00

typemsg:
  .byte "Type the filename in all caps.", $0d, $0a, "The filename is up to 9 characters long.", $0d, $0a, " Filename: ", $02, "_", $00

loadbuf:
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte "XPL"

list:
  ldx #<listmsg
  ldy #>listmsg
  jsr w_acia_full
  ldx #<listmsg1
  ldy #>listmsg1
  jsr w_acia_full
  ldx #<listmsg2
  ldy #>listmsg2
  jsr w_acia_full
  ldx #<listmsg3
  ldy #>listmsg3
  jsr w_acia_full

  jmp type

typeloop:

  jsr rxpol
  lda $8000
  sta charbuffer

  cmp #$0d
  beq exitloop

  lda charbuffer
  cmp #'l'
  beq list

;  lda $05
;  sbc #$7f
;  beq dexx

  lda charbuffer
  sta $8000

  lda charbuffer
  sta loadbuf,x
  inx
  jmp typeloop

;  dexx:
;  dex
;  lda $05
;  sta $8000
;  jmp typeloop

exitloop:
  ldy #>loadbuf
  ldx #<loadbuf
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

  lda #$00
  sta fat32_address
  lda #$0f
  sta fat32_address+1

  jsr fat32_file_read

  ldx #<donemsg
  ldy #>donemsg
  jsr w_acia_full

end:
  jmp end

listmsg:
  .byte $0d, $0a, "!!!.xpl    amogus.xpl    demo.xpl     ero.xpl      ill.xpl       loadaddr.sar  noescape.xpl  sam.xpl     trapped.xpl", $0d, $0a, "0.xpl      arc.xpl       demo.xpl]    escape.xpl   in.xpl        man.xpl       ode.xpl       snake.xpl   trip.xpl", $0d, $0a, $00
listmsg1:
  .byte  "0demo.xpl  battle.xpl    dennis.xpl   evolver.xpl  insult.txt    mar.xpl       op.xpl        star.xpl    uding.xpl", $0d, $0a, "0loop.xpl  city.xpl      donky.xpl    file.txt     kind.xpl      mash.xpl      pop.xpl       star.xplpl  werd.xpl", $0d, $0a, $00
listmsg2:
  .byte "64.xpl     code.xpl      dream.xpl    final.xpl    kobutday.xpl  micro.xpl     rec.xpl       sus.xpl     wip.xpl", $0d, $0a, "FM.xpl     comic.xpl     dumbuto.xpl  friend.xpl   lab.xpl       mor.xpl       req.xpl       timer.xpl   yea.xpl", $0d, $0a, $00
listmsg3:
  .byte "aaah.xpl   commando.xpl  ear.xpl      hey.xpl      legend.xpl    music.xpl     return.xpl    tms.xpl     yealab.xpl", $0d, $0a, $00

