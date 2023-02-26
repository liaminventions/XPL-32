; Remove test
; 

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
  ; Set the last found free cluster to 0.
  lda #0
  sta fat32_lastfoundfreecluster
  sta fat32_lastfoundfreecluster+1
  sta fat32_lastfoundfreecluster+2
  sta fat32_lastfoundfreecluster+3
  sta fat32_lastcluster
  sta fat32_lastcluster+1
  sta fat32_lastcluster+2
  sta fat32_lastcluster+3

  ; Open the folder
  jsr rootsetup

  ldx #<delmsg
  ldy #>delmsg
  jsr w_acia_full

  ; Save filename pointer
  ldx #<sdbuffer
  ldy #>sdbuffer

  ; Find the file
  jsr fat32_finddirent
  bcc .found
  jmp transfer_error

.found

  ; Remove it.
  jsr fat32_deletefile

  ldx #<donemsg
  ldy #>donemsg
  jsr w_acia_full

  rts

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
doneloop:
  jmp doneloop

dirname:
  .asciiz "FOLDER     "
errormsg:
  .byte CR,LF,"ERROR!",CR,LF
  .byte 0
sdbuffer:
  .byte "SAVE    BAS" ; save.bas
delmsg:
  .byte "Deleting save.bas...", $00
donemsg:
  .byte "Done!", $0d, $0a, $00
failedmsg:
  .byte "Failed!",CR,LF,$00
