; Save test
; 
; this code is just for debugging the sd card saving system.
; i will use ben eater's debugger for this.

ACIA = $8000
ACIAControl = ACIA+3
ACIACommand = ACIA+2
ACIAStatus = ACIA+1
ACIAData = ACIA

irqcount = $00
donefact = $01

; sd card:
zp_sd_address = $48         ; 2 bytes
zp_sd_currentsector = $4a   ; 4 bytes
zp_fat32_variables = $4f    ; 24 bytes
; only used during fat32 processing
path = $400		    ; page
fat32_workspace = $500      ; two pages
buffer = $700		    ; two pages
endbuf = $900

XYLODSAV2 = $64 ; 2

CR=13
LF=10

  .org $0f00

reset:
  ;jsr sd_init
  ;bcs sd_fail
  ; sd init done
  ;lda #'S'
  ;sta ACIAData
  ;jsr fat32_init
  ;bcs faterror
  ; fat32 init done
  ;jsr txpoll
  ;lda #'F'
  ;sta ACIAData
; Set the last found free cluster to 0.
  lda #0
  sta fat32_lastfoundfreecluster
  sta fat32_lastfoundfreecluster+1
  sta fat32_lastfoundfreecluster+2
  sta fat32_lastfoundfreecluster+3
  ; init done
;initdone:
  ; now make a dummy file.
  ldx #0
dummyloop:
  txa
  sta $0900,x
  inx
  bne dummyloop
  ; add an EOF
  lda #0
  sta $0a00
  ;sta $0701
  ;sta $0702

  jmp MEMORY_SAVE ; OK, here we go.

;faterror:
;  lda #'f'
;  jsr print_chara
;  jmp doneloop
;sd_fail:
;  lda #'s'
;  jsr print_chara
;  jmp doneloop

  .include "errors.s"
  .include "hwconfig.s"
  .include "libacia.s"
  .include "libsd.s"
  .include "libfat32.s"

rootsetup:		; setup <ROOT>

  ; Open root directory
  jsr fat32_openroot

  ; Find the subdirectory by name
  ldx #<dirname
  ldy #>dirname
  jsr fat32_finddirent
  bcc foundsub

  ; Subdirectory not found
  jmp transfer_error

foundsub:

  ; Open subdirectory
  jsr fat32_opendirent	; open folder
	
  rts			; done

transfer_error:
  ldy #>errormsg
  ldx #<errormsg
  jsr w_acia_full
  jsr error_sound
  jmp doneloop

;msincremaining:
;  inc fat32_bytesremaining
;  bne msinca
;  inc fat32_bytesremaining+1
;msinca:
;  inc XYLODSAV2
;  bne msincb
;  inc XYLODSAV2+1
;msincb:
;  rts

MEMORY_SAVE:
; finally. this is what we need to debug.
  ldx #<savmsg
  ldy #>savmsg
  jsr w_acia_full
  ; Allocate the first cluster for the data
  jsr fat32_allocatecluster
  ; Open the folder
  jsr rootsetup
  
  ;ldy #>sdbuffer
  ;ldx #<sdbuffer
  ;jsr fat32_finddirent
  ;bcs saveok
  ;jsr file_exists
  ;bcs doneloop
saveok:
; Now calculate file size and store it in fat32_bytesremaining.
; For now, just write it.
  lda #$01
  sta fat32_bytesremaining+1
  lda #$00
  sta fat32_bytesremaining
  sta fat32_bytesremaining+2
  sta fat32_bytesremaining+3

;  lda #$00
;  sta XYLODSAV2
;  lda #$07
;  sta XYLODSAV2+1
;  lda #0
;  sta fat32_bytesremaining
;  sta fat32_bytesremaining+1
;  ldy #0
;savecalclp:
;  lda (XYLODSAV2),y
;  beq mszero
;  jsr msincremaining
;  jmp savecalclp
;mszero:
;  jsr msincremaining

  ;lda (XYLODSAV2),y
  ;bne savecalclp
  ;jsr msincremaining
  ;lda (XYLODSAV2),y
  ;bne savecalclp

  ; Save filename pointer
  lda #<sdbuffer
  sta fat32_filenamepointer
  lda #>sdbuffer
  sta fat32_filenamepointer+1

  ; Great, now make a directory entry for this new file.
  jsr fat32_writedirent

  ; Now, let's write the file...
  lda #$00
  sta fat32_address
  lda #$09
  sta fat32_address+1
  jsr fat32_file_write  ; Yes. It is finally time to save the file.
  
  ; All done!
  ldx #<SAVE_DONE
  ldy #>SAVE_DONE
  jsr w_acia_full
doneloop:
  ;jmp doneloop
  rts
  rts
  rts
;file_exists:
  ; clc if 'y'
  ; sec if 'n'
;  ldx #<EXIST_MSG
;  ldy #>EXIST_MSG
;  jsr w_acia_full
;fexlp:
;  jsr rxpoll
;  lda ACIAData
;  pha
;  cmp #'y'
;  beq exy
;  cmp #'n'
;  beq exn
;  pla
;  jmp fexlp
;exy:
;  jsr crlf
;  clc
;  rts
;exn:
;  jsr crlf
;  sec
;  rts

dirname:
  .asciiz "FOLDER     "
errormsg:
  .byte CR,LF,"ERROR!",CR,LF
  .byte 0
sdbuffer:
  .byte "SAVE    BAS" ; save.bas
EXIST_MSG:
  .byte "File Exists. Overwrite? (y/n): ",$00
SAVE_DONE:
  .byte	CR,LF,"Save Complete.",CR,LF,$00
savmsg:
  .byte $0d, $0a, "Saving...", $0d, $0a, $00
failedmsg:
  .byte "Failed!",CR,LF,$00
