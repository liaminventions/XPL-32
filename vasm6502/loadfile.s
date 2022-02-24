  .org $1000

startjump:
  jmp reset

  .include "hwconfig.s"
  .include "libsd.s"
  .include "libfat32.s"
;  .include "liblcd.s"
  .include "libacia.s"


zp_sd_address = $40         ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables = $46    ; 24 bytes

fat32_workspace = $200      ; two pages

buffer = $400


subdirname:
  .asciiz "FOLDER     "
filename:
  .asciiz "CODE    XPL"
loadname:
  .asciiz "LOADADDRSAR"

fat_error:
  .byte "FAT32 Error At Stage ", $00

reset:
  ldx #$ff
  txs

  ; Initialise
  jsr acia_init
  jsr via_init
 ; jsr lcd_init
  jsr sd_init
  jsr fat32_init
  bcc .initsuccess
 
  ; Error during FAT32 initialization

  ldy #>fat_error
  ldx #<fat_error
  jsr w_acia_full
  lda fat32_errorstage
  jsr print_hex_acia
  lda #'!'
  jsr print_chara

 ; rts
 ; rts
 ; rts

  jmp loop

.initsuccess

  ; Open root directory
  jsr fat32_openroot

  ; Find subdirectory by name
  ldx #<subdirname
  ldy #>subdirname
  jsr fat32_finddirent
  bcc .foundsubdir

  ; Subdirectory not found
  ldy #>submsg
  ldx #<submsg
  jsr w_acia_full
  jmp loop

.foundsubdir

  ; Open subdirectory
  jsr fat32_opendirent

  ; Find file by name
  ldx #<loadname
  ldy #>loadname
  jsr fat32_finddirent
  bcc .foundfile

  ; File not found
  ldy #>filmsg
  ldx #<filmsg
  jsr w_acia_full
  jmp loop

.foundfile
 
  ; Open file
  jsr fat32_opendirent

  ; Read file contents into buffer
  lda #<buffer
  sta fat32_address
  lda #>buffer
  sta fat32_address+1

  jsr fat32_file_read

  ; Open root directory
  jsr fat32_openroot

  ; Find subdirectory by name
  ldx #<subdirname
  ldy #>subdirname
  jsr fat32_finddirent
  bcc .startload

  ; Subdirectory not found
  ldy #>submsg
  ldx #<submsg
  jsr w_acia_full
  jmp loop
 
.startload

  ; Open subdirectory
  jsr fat32_opendirent

  ldy #>lds
  ldx #<lds
  jsr w_acia_full

  ldx #<filename
  ldy #>filename
  jsr fat32_finddirent
  bcc .foundcode

  ldy #>filmsg2
  ldx #<filmsg2
  jsr w_acia_full
  jmp loop

.foundcode

  jsr fat32_opendirent

  lda buffer
  sta fat32_address
  lda buffer+1
  sta fat32_address+1


  jsr fat32_file_read

  ldy #>ends
  ldx #<ends
  jsr w_acia_full

  jmp (buffer+2)

loop:
  jmp loop

submsg:
  .byte "Directory Not Found!", $00
filmsg:
  .byte "'loadaddr.sar' Not Found!", $00
filmsg2:
  .byte "'code.xpl' Not Found!", $00
lds:
  .byte "Loading Code...", $00
ends:
  .byte "Finished Loading.", $0d, $0a, $0d, $0a, $00
