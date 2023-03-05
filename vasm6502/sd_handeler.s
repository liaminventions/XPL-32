; XPL-32 <FOLDER> type loading code
; (c) 2022-2023 Waverider

charbuffer = $601            ; 1 byte
seed = $01
donefact = $02		     ; vars
irqcount = $03

  .org $0900
jumptoit:
  jmp sdstart

  .include "hwconfig.s"
  .include "kernal_def.s"

dirname:
  .asciiz "ROOT       "	     ; standard directory name, SHORT format

errormsg:
  .byte $0d, $0a, "ERROR!", $0d, $0a, $00	; error msg

sdstart:
  stz $00		; 0

  lda #$55		; shftable value
  sta seed
	
  jsr cleardisplay	; clear display

  ldx  #<loadmsg	; title screen
  ldy  #>loadmsg
  jsr  w_acia_full

  ldx  #<lodmm
  ldy  #>lodmm
  jsr  w_acia_full

  jsr rootsetup		; setup sd card

findrau:
  jmp type		; start "type" program

rootsetup:		; setup <ROOT>
  pha
  phx
  phy

  ; Open root directory
  jsr fat32_openroot

  ; Find the subdirectory by name
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
  jsr fat32_opendirent	; open folder

  ply
  plx 
  pla
  rts


type:			; typing a filename
  ldx #<typemsg		; Filename:_
  ldy #>typemsg
  jsr w_acia_full
  ldx #0
  lda #' '
  sta $04		; I frogor
  jmp typeloop		; start loop

rxpol:
  lda $8001
  and #$08		; non-irq rx polling code
  beq rxpol
  rts

rxput:
  lda $8001
  and #$08		; it loops
  beq typelop
  rts
typelop:
  jmp typeloop

lodmsg:
  .byte $0d, $0a, "Loading...", $0d, $0a, $00
donemsg:
  .byte $0c, $00

loadmsg:
  .byte "          -------- SD Loader --------     ", $0d, $0a, $00
lodmm:
  .byte "          Press (l) to list <FOLDER>      ", $0d, $0a, $0d, $0a, $00

typemsg:
  .byte "Type the filename in all caps.", $0d, $0a, "The filename is up to 8 characters long.", $0d, $0a, " Filename: ", $02, "_", $00

loadbuf:
  .byte $20, $20, $20, $20, $20, $20, $20, $20
  .byte "XPL"

other:
  jsr txpoll		; Write a letter of the filename currently being read
  lda (zp_sd_address),y
  sta $8000
  iny
  rts

list:			; list file dir
  jsr fat32_readdirent	; files?
  bcs nofiles
  and #$40
  beq arc
dir:
  lda #'D'		; directorys show up as 
  jmp ebut		; D YOURFILENAME     D TEST      D FOLDER  ...Etc
arc:
  lda #'F'		; files show up as
ebut:			; F TEST.XPL         F MUSIC.XPL        F FILE.BIN  ...Etc
  jsr print_chara	; f or d
  lda #$20		; space
  jsr print_chara
  ; At this point, we know that there are no files, files, or a suddir
  ; Now for the name
  ldy #0
nameloop:
  cpy #8
  beq dot
  jsr other
  jmp nameloop
dot:
  lda #'.'		; shows a file extention
  jsr print_chara
lopii:
  cpy #11
  beq endthat		; print 3-letter file extention
  jsr other
  jmp lopii
endthat:
  lda #$09 ; Tab
  jsr print_chara	; tab
  jmp list ; go again	; next file if there are any left
nofiles:		; if not,
endlist:		; exit listing code
  jsr crlf
  jmp type

jumptolist:
  jsr crlf
  jmp list

typeloop:		; loop to type filenames

  jsr rxpol		; read a charactor
  lda $8000
  sta charbuffer

  cmp #$0d		; enter?
  beq exitloop		; if so, load
			; if not...
  lda charbuffer	
  cmp #'l'		; check if it's "l"
  beq jumptolist	; if so, list files
			; if not,
  lda charbuffer	; echo back
  sta $8000

  lda charbuffer	; and store it in the filename buffer
  sta loadbuf,x
  inx
  jmp typeloop

exitloop:

  jsr crlf
  jsr rootsetup
  
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

  jsr fat32_file_read  ; Yes. It is finally time to read the file.

end:
  ldx #<donemsg
  ldy #>donemsg
  jsr w_acia_full
  jsr $0f00
  rts
  rts
  rts
  rts

;clear_sid
;  ldx #$18
;csid
;  stz $b800,x
;  dex
;  bne csid
;  rts

  .include "errors.s"
