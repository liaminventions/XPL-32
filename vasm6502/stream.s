done = $00
sample = $01
flag = $02
zp_sd_address = $40         ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables = $46    ; 32 bytes

bytepointer = $66	    ; 4 bytes
readcounter = $6a           ; 2 bytes

buffer = $400               ; 512 bytes
endbuf = $600

SID = $b800

flagSeed = $55           ; flag seed, 8kHz
freq     = $80           ; CIA NMI timer delay, 8kHz
;flagSeed = $00          ; flag seed, 4Hz
;freq    = $100          ; CIA NMI timer delay, 4kHz

	.org $0f00
darn
	jmp begin

;datname:
;  .asciiz "FASTCMC RAW"  ; music file on SD card
;dirname:
;  .asciiz "FOLDER     "  ; folder

	.include "hwconfig.s"
        .include "libacia.s"
	.include "libsd.s" ; ah ye sd tim
	;.include "libfat32.s"
	; no filesystem

jmpfailed:
	jmp failed

begin:
; init sd card (it was just plugged in)
        
	jsr sd_init
        bcs jmpfailed

	lda #0
	sta bytepointer
	sta bytepointer+1
	sta bytepointer+2
	sta bytepointer+3

        lda #0
        sta readcounter
        sta readcounter+1
;-------------------------------------------------------------------------------
; Initialize DIGI_Player

        ; disable interrupts
        LDA #$00                ; was $7f in the_c64_digi.txt
        STA $B00D               ; ICR CIA #2
               ; read acks any pending interrupt
        LDA $B00D
        SEI                     ; disables maskable interrupts

				; hold on les fix da sd
;  lda #SD_MOSI
;  sta PORTA
;  ; Command 16, arg is size in bytes, crc not checked
;  lda #$50                    ; CMD16 - SET_BLOCKLEN
;  jsr sd_writebyte
;  lda #0		      ; byte 24:31
;  jsr sd_writebyte
;  lda #0		      ; byte 16:23
;  jsr sd_writebyte
;  lda #0		      ; byte 8:15
;  jsr sd_writebyte
;  lda #1                      ; byte 0:7
;  jsr sd_writebyte
;  lda #$01                    ; crc (not checked)
;  jsr sd_writebyte
;
;  jsr sd_waitresult
;  cmp #$00
;  bne jmpfailed        BUG i don't think this works on SDHC or SDXC, only on SD.
  
;  ; Open root directory                we dont want fat32 here
;  jsr fat32_openroot
;
;  ; Find subdirectory by name
;  ldx #<dirname
;  ldy #>dirname
;  jsr fat32_finddirent
;  bcc foundsubdir
;
;error:
;  plx
;  pla
;  rts
;  rts
;  rts
;  rts
;
;foundsubdir
;
;  ; Open subdirectory
;  jsr fat32_opendirent
;				; ok dats don


        ; initialize SID
        LDA #$00                ; zeros out all SID registers
        LDX #$00                ;
SIDCLR                          
        STA SID,x               ; 
        INX                     ;
        BNE SIDCLR             

        ; SID voices modulated too, increases volume on 8580 SIDs
        LDA #$00                ; 
        STA SID+$05             ; voice 1 Attach/Decay 
        LDA #$F0                ;
        STA SID+$06             ;         Systain/Release 
        LDA #$01                ;
        STA SID+$04             ;         ctrl 
        LDA #$00 
        STA SID+$0C             ; voice 2 Attach/Decay 
        LDA #$F0                ;
        STA SID+$0D             ;         Systain/Release 
        LDA #$01                ;
        STA SID+$0B             ;         ctrl 
        LDA #$00        
        STA SID+$13             ; voice 3 Attach/Decay 
        LDA #$F0                ;
        STA SID+$14             ;         Systain/Release 
        LDA #$01                ;
        STA SID+$12             ;         ctrl 
        LDA #$00 
        STA SID+$15             ; filter  lo 
        LDA #$10                ;
        STA SID+$16             ; filter  hi 
        LDA #$F7                ;
        STA SID+$17             ; filter  voices+reso 

        ; point to our player routine
        LDA #<IRQ_HANDLER       ; set NMI handler address low byte
        STA $7FFF               ;
        LDA #>IRQ_HANDLER       ; set NMI handler address hi byte
        STA $7FFE               ;

        ;LDA #<DATASTART         ; low byte
	;STA fat32_address
        ;LDA #>DATASTART         ; high byte
	;STA fat32_address+1

        LDA #flagSeed           ; initialize flag used for
        STA flag                ; indicating which nibble to play
	
	;; get the missle
	;LDX #<datname		; low byte
	;LDY #>datname		; high byte
	;JSR fat32_finddirent	; do it
	;JSR fat32_opendirent	; ignore errors >:)
	;JSR fat32_file_readbyte ; one. yes just one bomb for now.

	; Command 17, arg is sector number, crc not checked
  	lda #$51                    ; CMD17 - READ_SINGLE_BLOCK
  	jsr sd_writebyte
  	lda bytepointer+3	    ; sector 24:31
  	jsr sd_writebyte
  	lda bytepointer+2	    ; sector 16:23
  	jsr sd_writebyte
  	lda bytepointer+1	    ; sector 8:15
 	jsr sd_writebyte
 	lda bytepointer+0           ; sector 0:7
 	jsr sd_writebyte
 	lda #$01                    ; crc (not checked)
 	jsr sd_writebyte

	jsr sd_waitresult
	cmp #$00
	bne failed

	jsr sd_readbyte

;	STA DATASTART		; load the missle      we don't need this
	STA sample		; all right.
	JSR wee			; prepare the cannons.

        LDA #$40                ; ICR set to TMR A underflow
        STA $B00D               ; ICR CIA #2
        LDA #$c0                ;
        STA $B00E               ; CRA interrupt enable

	cli

        LDA #$00                ;
        STA done                ; reset player done flag

pause
        LDA done                ; player sets'done' flag when finished, pause
        BEQ pause               ; until then for clean return to BASIC

        SEI                     ; set interuppts again
        RTS                     ; and return
wee
        ; setup VIA, watch out as it will lunch da cannon!!
        LDA #<freq              ; interrupt freq
        STA $B004               ; TA LO
        LDA #>freq              ;
        STA $B005               ; TA HI
        LDA #<freq              ; interrupt freq
        STA $B006               ; TA LO
        LDA #>freq              ;
        STA $B007               ; TA HI
	RTS

failed:
  sei
  rts

;-------------------------------------------------------------------------------
; IRQ handler routine, plays one 4bit sample per pass
; Path A -> Play Lower, shift upper down. 3+19+13+23=58 cycles
; Path B -> Play upper, load new sample. 3+19+8+25=55 cycles
; Path C -> Play upper. load sample, new page. 3+19+8+14+21=65 cycles
; Sample's lower nybble holds the 4-bit sample to played on the "even" IRQs
; The upper nybble holds the next nybble to be played on "odd" IRQs
IRQ_HANDLER        
        ; start with saving state       
        PHA                     ; 3- (3) will restore when returning

	lda #$40
	sta $b00d		; ack

	JSR wee			; prepare next missle

        ; play 4-bit sample, first sample byte saved during Init
        LDA sample              ; 3- load sample byte
        ORA #$10                ; 2- make sure wee no ded filter settings
        AND #$1F                ; 2- git rid of any put bits
        STA SID+$18             ; 4- save to ta regsiter
        LDA $B00D               ; 4- (19)clear gobut

        ; flag init to $AA or $55, We shift alternating pattern though flag byte
        ASL flag                ; 5- shift patten left thru flag byte
        BCC loadnew             ; 2-3 
        INC flag                ; 5 (8-13) so skip ahead to load new byte
   
shftupr
        LDA sample              ; 3- *1 shift upper nibble down
        LSR a                   ; 2-
        LSR a                   ; 2-
        LSR a                   ; 2-
        LSR a                   ; 2-
        STA sample              ; 3- store it back to play next pass

        PLA                     ; 3- local exit code is smaller and 
        RTI                     ; 6- (23) faster than jumps/branches


loadnew
	; manny! read da bite.

        inc readcounter
        bne yee
        inc readcounter+1
        lda readcounter+1
        cmp #$02
        beq werwer
yee
        jsr sd_readbyte
        sta sample
        pla
        rti
werwer
 	lda #SD_MOSI
  	sta PORTA

	inc bytepointer
	bne newcontinue
	inc bytepointer+1
	bne newcontinue
	inc bytepointer+2
	bne newcontinue
	inc bytepointer+3

newcontinue:

  	; Command 17, arg is sector number, crc not checked
  	lda #$51                    ; CMD17 - READ_SINGLE_BLOCK
  	jsr sd_writebyte
  	lda bytepointer+3	    ; sector 24:31
  	jsr sd_writebyte
  	lda bytepointer+2	    ; sector 16:23
  	jsr sd_writebyte
  	lda bytepointer+1	    ; sector 8:15
 	jsr sd_writebyte
 	lda bytepointer+0           ; sector 0:7
 	jsr sd_writebyte
 	lda #$01                    ; crc (not checked)
 	jsr sd_writebyte

	jsr sd_waitresult
	cmp #$00
	bne stop

        lda #0
        sta readcounter
        sta readcounter+1

	jsr sd_readbyte

        STA sample              ; 3- save to temp location
	;STA DATASTART
        ;BCS stop               ; 2-3- if thats it then stop
	; BUG cannot stop sample when reading sd RAW
        lda #SD_CS | SD_MOSI
        sta PORTA

        PLA                     ; 3- local exit code is smaller and
        RTI                     ; 6- (14-25)faster than jumps/branches


stop
        LDA #$08                ; 2- turn off IRQ
        STA $B00E               ; 4- timer A stop-CRA, CIA #1 DC0E
        LDA #$4F                ; 2- disable all CIA-2 IRQs 
        STA $B00D               ; 4- ICR - interrupt control / status
        LDA $B00D               ; 4- (16) sta/lda to ack any pending int

        INC done                ; set player done flag
        
        PLA                     ; 3- local exit code is smaller and
        RTI                     ; 6- faster than jumps/branches

;DATASTART 
;	.byte $00		; smol... ah ye its actually many MB. haha
;DATASTOP  
