; SD card interface module
;
; Requires zero-page variable storage:
;   zp_sd_address - 2 bytes
;   zp_sd_currentsector - 4 bytes

cmsg:
  .byte "Command: ", $00

sd_init:
  ; Let the SD card boot up, by pumping the clock with SD CS disabled

  ; We need to apply around 80 clock pulses with CS and MOSI high2
  ; Normally MOSI doesn't matter when CS is high, but the card is
  ; not yet is SPI mode, and in this non-SPI state it does care2

  lda #SD_CS | SD_MOSI
  ldx #160               ; toggle the clock 160 times, so 80 low-high transitions
2preinitloop:
  eor #SD_SCK
  sta PORTA
  dex
  bne 2preinitloop
  

2cmd0: ; GO_IDLE_STATE - resets card to idle state, and SPI mode
  lda #<sd_cmd0_bytes
  sta zp_sd_address
  lda #>sd_cmd0_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
 ; cmp #$01
 ; bne 2initfailed

2cmd8: ; SEND_IF_COND - tell the card how we want it to operate (323V, etc)
  lda #<sd_cmd8_bytes
  sta zp_sd_address
  lda #>sd_cmd8_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne 2initfailed

  ; Read 32-bit return value, but ignore it
  jsr sd_readbyte
  jsr sd_readbyte
  jsr sd_readbyte
  jsr sd_readbyte

2cmd55: ; APP_CMD - required prefix for ACMD commands
  lda #<sd_cmd55_bytes
  sta zp_sd_address
  lda #>sd_cmd55_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne 2initfailed

2cmd41: ; APP_SEND_OP_COND - send operating conditions, initialize card
  lda #<sd_cmd41_bytes
  sta zp_sd_address
  lda #>sd_cmd41_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Status response $00 means initialised
  cmp #$00
  beq 2initialized

  ; Otherwise expect status response $01 (not initialized)
  cmp #$01
  bne 2initfailed

  ; Not initialized yet, so wait a while then try again2
  ; This retry is important, to give the card time to initialize2

  ldx #0
  ldy #0
2delayloop:
  dey
  bne 2delayloop
  dex
  bne 2delayloop

  jmp 2cmd55


2initialized:
;  ldy #>initmsg
;  ldx #<initmsg
;  jsr w_acia_full
;  rts

2initfailed:
;  ldy #>initfailedmsg
;  ldx #<initfailedmsg
;  jsr w_acia_full
2loop:
  jmp 2loop


sd_cmd0_bytes:
  .byte $40, $00, $00, $00, $00, $95
sd_cmd8_bytes:
  .byte $48, $00, $00, $01, $aa, $87
sd_cmd55_bytes:
  .byte $77, $00, $00, $00, $00, $01
sd_cmd41_bytes:
  .byte $69, $40, $00, $00, $00, $01



sd_readbyte:
  ; Enable the card and tick the clock 8 times with MOSI high, 
  ; capturing bits from MISO and returning them

  ldx #$fe    ; Preloaded with seven ones and a zero, so we stop after eight bits

2loop:

  lda #SD_MOSI                ; enable card (CS low), set MOSI (resting state), SCK low
  sta PORTA

  lda #SD_MOSI | SD_SCK       ; toggle the clock high
  sta PORTA

  lda PORTA                   ; read next bit
  and #SD_MISO

  clc                         ; default to clearing the bottom bit
  beq 2bitnotset              ; unless MISO was set
  sec                         ; in which case get ready to set the bottom bit
2bitnotset:

  txa                         ; transfer partial result from X
  rol                         ; rotate carry bit into read result, and loop bit into carry
  tax                         ; save partial result back to X
  
  bcs 2loop                   ; loop if we need to read more bits

  rts


sd_writebyte:
  ; Tick the clock 8 times with descending bits on MOSI
  ; SD communication is mostly half-duplex so we ignore anything it sends back here

  ldx #8                      ; send 8 bits

2loop:
  asl                         ; shift next bit into carry
  tay                         ; save remaining bits for later

  lda #0
  bcc 2sendbit                ; if carry clear, don't set MOSI for this bit
  ora #SD_MOSI

2sendbit:
  sta PORTA                   ; set MOSI (or not) first with SCK low
  eor #SD_SCK
  sta PORTA                   ; raise SCK keeping MOSI the same, to send the bit

  tya                         ; restore remaining bits to send

  dex
  bne 2loop                   ; loop if there are more bits to send

  rts


sd_waitresult:
  ; Wait for the SD card to return something other than $ff
  jsr sd_readbyte
  cmp #$ff
  beq sd_waitresult
  rts


sd_sendcommand:
  ; Debug print which command is being executed
 ; jsr lcd_cleardisplay
 ; jsr cleardisplay

;  phx
;  phy
;  ldx #<cmsg
;  ldy #>cmsg
;  jsr w_acia_full
;  ply
;  plx

;  ldx #0
;  lda (zp_sd_address,x)
;  jsr print_hex_acia

;  lda #$20
;  jsr print_chara
;  
;  lda #$20
;  jsr print_chara

  lda #SD_MOSI           ; pull CS low to begin command
  sta PORTA

  ldy #0
  lda (zp_sd_address),y    ; command byte
  jsr sd_writebyte
  ldy #1
  lda (zp_sd_address),y    ; data 1
  jsr sd_writebyte
  ldy #2
  lda (zp_sd_address),y    ; data 2
  jsr sd_writebyte
  ldy #3
  lda (zp_sd_address),y    ; data 3
  jsr sd_writebyte
  ldy #4
  lda (zp_sd_address),y    ; data 4
  jsr sd_writebyte
  ldy #5
  lda (zp_sd_address),y    ; crc
  jsr sd_writebyte

  jsr sd_waitresult
  pha

;  phy
;  phx
;  ldy #>respmsg
;  ldx #<respmsg
;  jsr w_acia_full
;  ply
;  plx

  ; Debug print the result code
;  jsr print_hex_acia

;  lda #$0d
;  jsr print_chara
;  
;  lda #$0a
;  jsr print_chara

  ; End command
  lda #SD_CS | SD_MOSI   ; set CS high again
  sta PORTA

  pla   ; restore result code
  rts


sd_readsector:
  ; Read a sector from the SD card2  A sector is 512 bytes2
  ;
  ; Parameters:
  ;    zp_sd_currentsector   32-bit sector number
  ;    zp_sd_address     address of buffer to receive data
  
  lda #SD_MOSI
  sta PORTA

  ; Command 17, arg is sector number, crc not checked
  lda #$51                    ; CMD17 - READ_SINGLE_BLOCK
  jsr sd_writebyte
  lda zp_sd_currentsector+3   ; sector 24:31
  jsr sd_writebyte
  lda zp_sd_currentsector+2   ; sector 16:23
  jsr sd_writebyte
  lda zp_sd_currentsector+1   ; sector 8:15
  jsr sd_writebyte
  lda zp_sd_currentsector     ; sector 0:7
  jsr sd_writebyte
  lda #$01                    ; crc (not checked)
  jsr sd_writebyte

  jsr sd_waitresult
  cmp #$00
  bne 2fail

  ; wait for data
  jsr sd_waitresult
  cmp #$fe
  bne 2fail

  ; Need to read 512 bytes - two pages of 256 bytes each
  jsr 2readpage
  inc zp_sd_address+1
  jsr 2readpage
  dec zp_sd_address+1

  ; End command
  lda #SD_CS | SD_MOSI
  sta PORTA

  rts


2fail:
;  ldx #<statusmsg
;  ldy #>statusmsg  ; Status:
;  jsr w_acia_full

;  ldx #<failedmsg
;  ldy #>failedmsg  ; Failed!
;  jsr w_acia_full
2failloop:
  jmp 2failloop


2readpage:
  ; Read 256 bytes to the address at zp_sd_address
  ldy #0
2readloop:
  jsr sd_readbyte
  sta (zp_sd_address),y
  iny
  bne 2readloop
  rts

statusmsg:
  .byte "Status: ", $00
initfailedmsg:
  .byte "Init "
failedmsg:
  .byte "Failed!", $0d, $0a, $00
respmsg:
  .byte "Response: ", $00
initmsg:
  .byte "Initialized!", $0d, $0a, $00
