done = $00
sample = $01
flag = $02
zp_sd_address = $40         ; 2 bytes
zp_sd_currentsector = $42   ; 4 bytes
zp_fat32_variables = $46    ; 24 bytes

fat32_workspace = $200      ; two pages

buffer = $400               ; 512 bytes
endbuf = $600

SID = $b800

flagSeed = $55           ; flag seed, 8kHz
freq     = $80           ; CIA NMI timer delay, 8kHz
;flagSeed = $00          ; flag seed, 4Hz
;freq    = $100          ; CIA NMI timer delay, 4kHz

	.org $0f00
darn
	jmp ebutrocks

datname:
  .asciiz "CMC     RAW"  ; music file on SD card
dirname:
  .asciiz "FOLDER     "  ; folder

	.org $1000

	.include "hwconfig.s"
	.include "libsd.s" ; ah ye sd tim
	.include "libfat32.s"

ebutrocks:

;-------------------------------------------------------------------------------
; Initialize DIGI_Player

        PHA                     ; We need to save both A
        TXA                     ;
        PHA                     ; and X as we use them

        ; disable interrupts
        LDA #$00                ; was $7f in the_c64_digi.txt
        STA $B00D               ; ICR CIA #2
               ; read acks any pending interrupt
        LDA $B00D
        SEI                    ; disables maskable interrupts

        ; switch out kernal rom while sample playing
        LDA #$35                ;
        STA $01                 ; 6510 banking register
				; hold on les fix da sd
  ; Open root directory
  jsr fat32_openroot

  ; Find subdirectory by name
  ldx #<dirname
  ldy #>dirname
  jsr fat32_finddirent
  bcc foundsubdir

error:
  rts
  rts
  rts
  rts

foundsubdir

  ; Open subdirectory
  jsr fat32_opendirent
				; ok dats don


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
        LDA #<NMI_HANDLER       ; set NMI handler address low byte
        STA $7FFF               ;
        LDA #>NMI_HANDLER       ; set NMI handler address hi byte
        STA $7FFE               ;

        LDA #<DATASTART         ; low byte
	STA fat32_address
        LDA #>DATASTART         ; high byte
	STA fat32_address+1

        LDA #flagSeed           ; initialize flag used for
        STA flag                ; indicating which nibble to play
	
	; get the missle
	LDX #<datname		; low byte
	LDY #>datname		; high byte
	JSR fat32_finddirent	; do it
	JSR fat32_opendirent	; ignore errors >:)
	JSR fat32_file_readbyte ; one. yes just one bomb for now.
	STA DATASTART		; load the missle
	STA sample		; all right.
	JSR wee			; prepare the cannons.

        LDA #$81                ; ICR set to TMR A underflow
        STA $B00D               ; ICR CIA #2
        LDA #$11                ;
        STA $B00E               ; CRA interrupt enable

        LDA #$00                ;
        STA done                ; reset player done flag

pause
        LDA done                ; player sets'done' flag when finished, pause
        BEQ pause               ; until then for clean return to BASIC

        PLA                     ; Let's get our saved
        TAX                     ; X register and
        PLA                     ; A register back
        CLI                     ; enable maskable interrutps again
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


;-------------------------------------------------------------------------------
; NMI handler routine, plays one 4bit sample per pass
; Path A -> Play Lower, shift upper down. 3+19+13+23=58 cycles
; Path B -> Play upper, load new sample. 3+19+8+25=55 cycles
; Path C -> Play upper. load sample, new page. 3+19+8+14+21=65 cycles
; Sample's lower nybble holds the 4-bit sample to played on the "even" NMIs
; The upper nybble holds the next nybble to be played on "odd" NMIs
NMI_HANDLER        
        ; start with saving state       
        PHA                     ; 3- (3) will restore when returning

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

        ; loadnew+1,+2 is self-modifying ptr to sample, gets set in init
loadnew
        JSR fat32_file_readbyte ; manny! read da bite.
        STA sample              ; 3- save to temp location
        BCS stop               ; 2-3- if thats it then stop

        PLA                     ; 3- local exit code is smaller and
        RTI                     ; 6- (14-25)faster than jumps/branches


stop
        LDA #$08                ; 2- turn off NMI (IRQ AAAAAA)
        STA $B00E               ; 4- timer A stop-CRA, CIA #1 DC0E
        LDA #$4F                ; 2- disable all CIA-2 NMIs 
        STA $B00D               ; 4- ICR - interrupt control / status
        LDA $B00D               ; 4- (16) sta/lda to ack any pending int

        LDA #$37                ; 2- reset kernal banking
        STA $01                 ; 3- (5)

        INC done                ; set player done flag
        
        PLA                     ; 3- local exit code is smaller and
        RTI                     ; 6- faster than jumps/branches

DATASTART 
	.byte $00		; smol... ah ye its actually many MB. haha
DATASTOP
