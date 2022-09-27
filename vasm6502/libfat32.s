; FAT32/SD interface library
;
; This module requires some RAM workspace to be defined elsewhere:
; 
; fat32_workspace    - a large page-aligned 512-byte workspace
; zp_fat32_variables - 24 bytes of zero-page storage for variables etc

fat32_readbuffer = fat32_workspace

fat32_fatstart          	= zp_fat32_variables + $00  ; 4 bytes
fat32_datastart         	= zp_fat32_variables + $04  ; 4 bytes
fat32_rootcluster       	= zp_fat32_variables + $08  ; 4 bytes
fat32_sectorspercluster 	= zp_fat32_variables + $0c  ; 1 byte
fat32_pendingsectors    	= zp_fat32_variables + $0d  ; 1 byte
fat32_address           	= zp_fat32_variables + $0e  ; 2 bytes
fat32_nextcluster       	= zp_fat32_variables + $10  ; 4 bytes
fat32_bytesremaining    	= zp_fat32_variables + $14  ; 4 bytes   	
fat32_lastfoundfreecluster	= zp_fat32_variables + $18  ; 4 bytes
fat32_result			= zp_fat32_variables + $1c  ; 2 bytes
fat32_dwcount			= zp_fat32_variables + $1e  ; 2 bytes

fat32_errorstage        = fat32_bytesremaining  ; only used during initialization
fat32_filenamepointer   = fat32_bytesremaining  ; only used when searching for a file
fat32_lba		= fat32_bytesremaining  ; only used when making a dirent

fat32_init:
  ; Initialize the module - read the MBR etc, find the partition,
  ; and set up the variables ready for navigating the filesystem

  ; Read the MBR and extract pertinent information

  lda #0
  sta fat32_errorstage

  ; Sector 0
  lda #0
  sta zp_sd_currentsector
  sta zp_sd_currentsector+1
  sta zp_sd_currentsector+2
  sta zp_sd_currentsector+3

  ; Target buffer
  lda #<fat32_readbuffer
  sta zp_sd_address
  lda #>fat32_readbuffer
  sta zp_sd_address+1

  ; Do the read
  jsr sd_readsector


  inc fat32_errorstage ; stage 1 = boot sector signature check

  ; Check some things
  lda fat32_readbuffer+510 ; Boot sector signature 55
  cmp #$55
  bne ufail
  lda fat32_readbuffer+511 ; Boot sector signature aa
  cmp #$aa
  bne ufail


  inc fat32_errorstage ; stage 2 = finding partition

  ; Find a FAT32 partition
FSTYPE_FAT32 = 12
  ldx #0
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq ufoundpart
  ldx #16
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq ufoundpart
  ldx #32
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq ufoundpart
  ldx #48
  lda fat32_readbuffer+$1c2,x
  cmp #FSTYPE_FAT32
  beq ufoundpart

ufail:
  jmp uerror

ufoundpart:

  ; Read the FAT32 BPB
  lda fat32_readbuffer+$1c6,x
  sta zp_sd_currentsector
  lda fat32_readbuffer+$1c7,x
  sta zp_sd_currentsector+1
  lda fat32_readbuffer+$1c8,x
  sta zp_sd_currentsector+2
  lda fat32_readbuffer+$1c9,x
  sta zp_sd_currentsector+3

  jsr sd_readsector


  inc fat32_errorstage ; stage 3 = BPB signature check

  ; Check some things
  lda fat32_readbuffer+510 ; BPB sector signature 55
  cmp #$55
  bne ufail
  lda fat32_readbuffer+511 ; BPB sector signature aa
  cmp #$aa
  bne ufail

  inc fat32_errorstage ; stage 4 = RootEntCnt check

  lda fat32_readbuffer+17 ; RootEntCnt should be 0 for FAT32
  ora fat32_readbuffer+18
  bne ufail

  inc fat32_errorstage ; stage 5 = TotSec16 check

  lda fat32_readbuffer+19 ; TotSec16 should be 0 for FAT32
  ora fat32_readbuffer+20
  bne ufail

  inc fat32_errorstage ; stage 6 = SectorsPerCluster check

  ; Check bytes per filesystem sector, it should be 512 for any SD card that supports FAT32
  lda fat32_readbuffer+11 ; low byte should be zero
  bne ufail
  lda fat32_readbuffer+12 ; high byte is 2 (512), 4, 8, or 16
  cmp #2
  bne ufail


  ; Calculate the starting sector of the FAT
  clc
  lda zp_sd_currentsector
  adc fat32_readbuffer+14    ; reserved sectors lo
  sta fat32_fatstart
  sta fat32_datastart
  lda zp_sd_currentsector+1
  adc fat32_readbuffer+15    ; reserved sectors hi
  sta fat32_fatstart+1
  sta fat32_datastart+1
  lda zp_sd_currentsector+2
  adc #0
  sta fat32_fatstart+2
  sta fat32_datastart+2
  lda zp_sd_currentsector+3
  adc #0
  sta fat32_fatstart+3
  sta fat32_datastart+3

  ; Calculate the starting sector of the data area
  ldx fat32_readbuffer+16   ; number of FATs
uskipfatsloop:
  clc
  lda fat32_datastart
  adc fat32_readbuffer+36 ; fatsize 0
  sta fat32_datastart
  lda fat32_datastart+1
  adc fat32_readbuffer+37 ; fatsize 1
  sta fat32_datastart+1
  lda fat32_datastart+2
  adc fat32_readbuffer+38 ; fatsize 2
  sta fat32_datastart+2
  lda fat32_datastart+3
  adc fat32_readbuffer+39 ; fatsize 3
  sta fat32_datastart+3
  dex
  bne uskipfatsloop

  ; Sectors-per-cluster is a power of two from 1 to 128
  lda fat32_readbuffer+13
  sta fat32_sectorspercluster

  ; Remember the root cluster
  lda fat32_readbuffer+44
  sta fat32_rootcluster
  lda fat32_readbuffer+45
  sta fat32_rootcluster+1
  lda fat32_readbuffer+46
  sta fat32_rootcluster+2
  lda fat32_readbuffer+47
  sta fat32_rootcluster+3

  ; Set the last fount free cluster to 0.
  lda #0
  sta fat32_lastfoundfreecluster
  sta fat32_lastfoundfreecluster+1
  sta fat32_lastfoundfreecluster+2
  sta fat32_lastfoundfreecluster+3
  clc
  rts

uerror:
  sec
  rts


fat32_seekcluster:
  ; Gets ready to read fat32_nextcluster, and advances it according to the FAT
  
  ; FAT sector = (cluster*4) / 512 = (cluster*2) / 256
  lda fat32_nextcluster
  asl
  lda fat32_nextcluster+1
  rol
  sta zp_sd_currentsector
  lda fat32_nextcluster+2
  rol
  sta zp_sd_currentsector+1
  lda fat32_nextcluster+3
  rol
  sta zp_sd_currentsector+2
  ; note: cluster numbers never have the top bit set, so no carry can occur

  ; Add FAT starting sector
  lda zp_sd_currentsector
  adc fat32_fatstart
  sta zp_sd_currentsector
  lda zp_sd_currentsector+1
  adc fat32_fatstart+1
  sta zp_sd_currentsector+1
  lda zp_sd_currentsector+2
  adc fat32_fatstart+2
  sta zp_sd_currentsector+2
  lda #0
  adc fat32_fatstart+3
  sta zp_sd_currentsector+3

  ; Target buffer
  lda #<fat32_readbuffer
  sta zp_sd_address
  lda #>fat32_readbuffer
  sta zp_sd_address+1

  ; Read the sector from the FAT
  jsr sd_readsector

  ; Before using this FAT data, set currentsector ready to read the cluster itself
  ; We need to multiply the cluster number minus two by the number of sectors per 
  ; cluster, then add the data region start sector

  ; Subtract two from cluster number
  sec
  lda fat32_nextcluster
  sbc #2
  sta zp_sd_currentsector
  lda fat32_nextcluster+1
  sbc #0
  sta zp_sd_currentsector+1
  lda fat32_nextcluster+2
  sbc #0
  sta zp_sd_currentsector+2
  lda fat32_nextcluster+3
  sbc #0
  sta zp_sd_currentsector+3
  
  ; Multiply by sectors-per-cluster which is a power of two between 1 and 128
  lda fat32_sectorspercluster
uspcshiftloop:
  lsr
  bcs uspcshiftloopdone
  asl zp_sd_currentsector
  rol zp_sd_currentsector+1
  rol zp_sd_currentsector+2
  rol zp_sd_currentsector+3
  jmp uspcshiftloop
uspcshiftloopdone:

  ; Add the data region start sector
  clc
  lda zp_sd_currentsector
  adc fat32_datastart
  sta zp_sd_currentsector
  lda zp_sd_currentsector+1
  adc fat32_datastart+1
  sta zp_sd_currentsector+1
  lda zp_sd_currentsector+2
  adc fat32_datastart+2
  sta zp_sd_currentsector+2
  lda zp_sd_currentsector+3
  adc fat32_datastart+3
  sta zp_sd_currentsector+3

  ; That's now ready for later code to read this sector in - tell it how many consecutive
  ; sectors it can now read
  lda fat32_sectorspercluster
  sta fat32_pendingsectors

  ; Now go back to looking up the next cluster in the chain
  ; Find the offset to this cluster's entry in the FAT sector we loaded earlier

  ; Offset = (cluster*4) & 511 = (cluster & 127) * 4
  lda fat32_nextcluster
  and #$7f
  asl
  asl
  tay ; Y = low byte of offset

  ; Add the potentially carried bit to the high byte of the address
  lda zp_sd_address+1
  adc #0
  sta zp_sd_address+1

  ; Copy out the next cluster in the chain for later use
  lda (zp_sd_address),y
  sta fat32_nextcluster
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+1
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+2
  iny
  lda (zp_sd_address),y
  and #$0f
  sta fat32_nextcluster+3

  ; See if it's the end of the chain
  ora #$f0
  and fat32_nextcluster+2
  and fat32_nextcluster+1
  cmp #$ff
  bne unotendofchain
  lda fat32_nextcluster
  cmp #$f8
  bcc unotendofchain

  ; It's the end of the chain, set the top bits so that we can tell this later on
  sta fat32_nextcluster+3
unotendofchain:

  rts


fat32_readnextsector:
  ; Reads the next sector from a cluster chain into the buffer at fat32_address.
  ;
  ; Advances the current sector ready for the next read and looks up the next cluster
  ; in the chain when necessary.
  ;
  ; On return, carry is clear if data was read, or set if the cluster chain has ended.

  ; Maybe there are pending sectors in the current cluster
  lda fat32_pendingsectors
  bne ureadsector

  ; No pending sectors, check for end of cluster chain
  lda fat32_nextcluster+3
  bmi uendofchain

  ; Prepare to read the next cluster
  jsr fat32_seekcluster

ureadsector:
  dec fat32_pendingsectors

  ; Set up target address  
  lda fat32_address
  sta zp_sd_address
  lda fat32_address+1
  sta zp_sd_address+1

  ; Read the sector
  jsr sd_readsector

  ; Advance to next sector
  inc zp_sd_currentsector
  bne usectorincrementdone
  inc zp_sd_currentsector+1
  bne usectorincrementdone
  inc zp_sd_currentsector+2
  bne usectorincrementdone
  inc zp_sd_currentsector+3
usectorincrementdone:

  ; Success - clear carry and return
  clc
  rts

uendofchain:
  ; End of chain - set carry and return
  sec
  rts

fat32_writenextsector:
  ; Writes the next sector from a cluster chain into the buffer at fat32_address.
  ;
  ; Advances the current sector ready for the next write and looks up the next cluster
  ; in the chain when necessary.
  ;
  ; On return, carry is set if its the end of the chain.

  ; Maybe there are pending sectors in the current cluster
  lda fat32_pendingsectors
  bne writesector

  ; No pending sectors, check for end of cluster chain
  lda fat32_nextcluster+3
  bmi endofchainn

  ; Prepare to write the next cluster
  jsr fat32_seekcluster
  ; BUG do i use this? or do i need to make a whole other thing so that I can use fat32_file_write..?

writesector:
  dec fat32_pendingsectors

  ; Set up target address
  lda fat32_address
  sta zp_sd_address
  lda fat32_address+1
  sta zp_sd_address+1

  ; Write the sector
  jsr sd_writesector

  ; Advance to next sector
  inc zp_sd_currentsector
  bne ursectorincrementdone
  inc zp_sd_currentsector+1
  bne ursectorincrementdone
  inc zp_sd_currentsector+2
  bne ursectorincrementdone
  inc zp_sd_currentsector+3
ursectorincrementdone:

  ; Success - clear carry and return
  clc
  rts

endofchainn:
  ; End of chain - set carry and return
  sec
  rts

fat32_openroot:
  ; Prepare to read the root directory

  lda fat32_rootcluster
  sta fat32_nextcluster
  lda fat32_rootcluster+1
  sta fat32_nextcluster+1
  lda fat32_rootcluster+2
  sta fat32_nextcluster+2
  lda fat32_rootcluster+3
  sta fat32_nextcluster+3

  jsr fat32_seekcluster

  ; Set the pointer to a large value so we always read a sector the first time through
  lda #$ff
  sta zp_sd_address+1

  rts

fat32_opendirent:
  ; Prepare to read/write a file or directory based on a dirent
  ;
  ; Point zp_sd_address at the dirent

  ; Remember file size in bytes remaining
  ldy #28
  lda (zp_sd_address),y
  sta fat32_bytesremaining
  iny
  lda (zp_sd_address),y
  sta fat32_bytesremaining+1
  iny
  lda (zp_sd_address),y
  sta fat32_bytesremaining+2
  iny
  lda (zp_sd_address),y
  sta fat32_bytesremaining+3

  ; Seek to first cluster
  ldy #26
  lda (zp_sd_address),y
  sta fat32_nextcluster
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+1
  ldy #20
  lda (zp_sd_address),y
  sta fat32_nextcluster+2
  iny
  lda (zp_sd_address),y
  sta fat32_nextcluster+3

  jsr fat32_seekcluster

  ; Set the pointer to a large value so we always read a sector the first time through
  lda #$ff
  sta zp_sd_address+1

  rts

fat32_writedirent:
  ; Write a directory entry from the open directory
  ; requires:
  ;   fat32bytesremaining (2 bytes) = file size in bytes (little endian)
  ;   and the processes of:
  ;     fat32_finddirent
  ;     fat32_findnextfreecluster
  ; Increment pointer by 32 to point to next entry
  clc
  lda zp_sd_address
  adc #32
  sta zp_sd_address
  lda zp_sd_address+1
  adc #0
  sta zp_sd_address+1

  ; If it's not at the end of the buffer, we have data already
  cmp #>(fat32_readbuffer+$200)
  bcc wgotdata

  ; Read another sector
  lda #<fat32_readbuffer
  sta fat32_address
  lda #>fat32_readbuffer
  sta fat32_address+1

  jsr fat32_readnextsector
  bcc wgotdata

endofdirectoryy:
  sec
  rts

wgotdata:
  ; Check first character
  clc
  ldy #0
  lda (zp_sd_address),y
  pha
  bne wdirlpstart
  ; End of directory => tell loop
  sec
wdirlpstart:
  php
wdirlp:
  lda (fat32_filenamepointer),y	; copy filename
  sta (zp_sd_address),y
  iny
  cpy #$0b
  bne wdirlp
  ; The full Short filename is #11 bytes long so,
  ; this start at 0x0b - File type
  lda #$20		; File Type: ARCHIVE
  sta (zp_sd_address),y
  iny ; 0x0c - Checksum/File accsess password
  lda #$10		            ; No checksum or password
  sta (zp_sd_address),y
  pla	; 0x0d - Previous byte at 0x00
  sta (zp_sd_address),y
  iny	; 0x0e-0x11 - File creation time/date
  lda #0
  sta (zp_sd_address),y	; No time/date because I don't have an RTC
  iny
  sta (zp_sd_address),y
  iny
  sta (zp_sd_address),y
  iny
  sta (zp_sd_address),y
  ; if you have an RTC, refer to https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#File_Allocation_Table 
  ; look at "Directory entry" at 0x0E onward on the table.
  iny ; 0x12-0x13 - User ID
  lda #0
  sta (zp_sd_address),y	; No ID
  iny
  sta (zp_sd_address),y
  iny ; 0x14-0x15 - File start cluster (high word)
  lda fat32_lastfoundfreecluster ; WARNING latfoundfreeclster is in this goofy ahh byte order stated here: http://6502.org/source/integers/ummodfix/ummodfix.htm
  sta (zp_sd_address),y
  iny ; the byte order works well here though ig...
  lda fat32_lastfoundfreecluster+1
  sta (zp_sd_address),y
  iny ; 0x16-0x19 - File modifiaction date
  lda #0
  sta (zp_sd_address),y
  iny
  sta (zp_sd_address),y   ; no rtc aaaaa
  iny
  sta (zp_sd_address),y
  iny
  sta (zp_sd_address),y
  iny ; 0x1a-0x1b - File start cluster low word
  lda fat32_lastfoundfreecluster+2
  sta (zp_sd_address),y
  iny
  lda fat32_lastfoundfreecluster+3
  sta (zp_sd_address),y
  iny ; 0x1c-0x1f File size in bytes
  lda fat32_bytesremaining
  sta (zp_sd_address),y
  iny
  lda fat32_bytesremaining+1
  sta (zp_sd_address),y
  iny
  lda #0
  sta (zp_sd_address),y ; Not bigger that 64k
  iny
  sta (zp_sd_address),y
  iny
  ; are we over the buffer?
  lda zp_sd_address+1
  cmp #>(fat32_readbuffer+$200)
  bcc wdontt
  jsr fat32_writenextsector ; if so, write the current sector
  jsr fat32_readnextsector  ; then read the next one.
  bcs wdfail
  ldy #0
  lda #<fat32_readbuffer
  sta zp_sd_address
  lda #>fat32_readbuffer
  sta zp_sd_address+1
wdontt:
  ; is this the end of the table?
  plp
  bcc wdnot
  php
  ; if so, next entry is 0
  lda #0
  sta (zp_sd_address),y
  jmp wdobut
wdnot:
  php
wdobut:
  jsr fat32_writenextsector ; write the data
  clc
  rts

wdfail:
  ; Card Full
  sec
  rts

jmpskipdiv:
  jmp skipdiv

fat32_findnextfreecluster:
; Find next free cluster
; 
; This program will search the FAT for an empty entry, and
; save the 32-bit index (from fat_start) to fat32_lastfoundfreecluter.
;
; Also returns a 1 in the carry bit if the SD card is full.
;
  lda fat32_fatstart
  sta fat32_lba
  lda fat32_fatstart+1
  sta fat32_lba+1			; copy fat_start to lba
  lda fat32_fatstart+2
  sta fat32_lba+2
  lda fat32_fatstart+3
  sta fat32_lba+3
  clc
  lda fat32_lastfoundfreecluster	; if there is no previously found free cluster
  adc fat32_lastfoundfreecluster+1
  adc fat32_lastfoundfreecluster+2
  adc fat32_lastfoundfreecluster+3
  beq jmpskipdiv				; then skip the division
  lda fat32_lastfoundfreecluster
  pha
  lda fat32_lastfoundfreecluster+1
  pha
  lda fat32_lastfoundfreecluster+2	; save original states of the last found sector
  pha					; (division clobbers it)
  lda fat32_lastfoundfreecluster+3
  pha
  lda $00				; extra variable usage for division
  pha
  lda $01
  pha
; BUG is the math right?
  ; result = lastfoundfreecluster / 128
  ; 32-bit division from http://6502.org/source/integers/ummodfix/ummodfix.htm
  SEC            			                  	; Detect overflow or /0 condition.
  LDA     fat32_lastfoundfreecluster      ; Divisor must be more than high cell of dividend.  To
  SBC     #128                        		; find out, subtract divisor from high cell of dividend;
  LDA     fat32_lastfoundfreecluster+1    ; if carry flag is still set at the end, the divisor was
  SBC     #0                         			; not big enough to avoid overflow. This also takes care
  BCS     oflo                      			;	 of any /0 condition.  Branch if overflow or /0 error.
                                    			; We will loop 16 times; but since we shift the dividend
  LDX     #$11    	                  		; over at the same time as shifting the answer in, the
                   	                  		; operation must start AND finish with a shift of the
                   	                  		; low cell of the dividend (which ends up holding the
                   		                  	; quotient), so we start with 17 (11H) in X.
divloop:
  ROL     fat32_lastfoundfreecluster+2    ; Move low cell of dividend left one bit, also shifting
  ROL     fat32_lastfoundfreecluster+3    ; answer in. The 1st rotation brings in a 0, which later
                        	            		; gets pushed off the other end in the last rotation.
  DEX
  BEQ     enddiv    		                  ; Branch to the end if finished.

  ROL     fat32_lastfoundfreecluster      ; Shift high cell of dividend left one bit, also
  ROL     fat32_lastfoundfreecluster+1    ; shifting next bit in from high bit of low cell.
  LDA     #0
  STA     $00   		                   		; Zero old bits of CARRY so subtraction works right.
  ROL     $00   		                  		; Store old high bit of dividend in CARRY.  (For STZ
                   	                  		; one line up, NMOS 6502 will need LDA #0, STA CARRY.)
  SEC                               			; See if divisor will fit into high 17 bits of dividend
  LDA     fat32_lastfoundfreecluster      ; by subtracting and then looking at carry flag.
  SBC     #128       		                	; First do low byte.
  STA     $01     	                  		; Save difference low byte until we know if we need it.
  LDA     fat32_lastfoundfreecluster+1    ;
  SBC     #0     	                  			; Then do high byte.
  TAY             		                   	; Save difference high byte until we know if we need it.
  LDA     $00   			                  	; Bit 0 of CARRY serves as 17th bit.
  SBC     #0      		                  	; Complete the subtraction by doing the 17th bit before
  BCC     divloop 	 	                  	; determining if the divisor fit into the high 17 bits
                  	                  		; of the dividend.  If so, the carry flag remains set.
  LDA     $01                        			; If divisor fit into dividend high 17 bits, update
  STA     fat32_lastfoundfreecluster      ; dividend high cell to what it would be after
  STY     fat32_lastfoundfreecluster+1    ; subtraction.
  BCS     divloop    		                	; Branch If Carry Set.  CMOS WDC65C02 could use BCS here. CA65 doesent allow it though.

oflo:  
  LDA     #$FF    			                  ; If overflow occurred, put FF
  STA     fat32_lastfoundfreecluster      ; in remainder low byte
  STA     fat32_lastfoundfreecluster+1    ; and high byte,
  STA     fat32_lastfoundfreecluster+2    ; and in quotient low byte
  STA     fat32_lastfoundfreecluster+3    ; and high byte.
enddiv:
	LDA	fat32_lastfoundfreecluster+2
	STA	fat32_result			; store quotient into fat32_result
	LDA	fat32_lastfoundfreecluster+3
	STA	fat32_result+1
	PLA
	STA	$01
	PLA
	STA	$00
	PLA					; restore variables
	STA	fat32_lastfoundfreecluster+3
	PLA
	STA	fat32_lastfoundfreecluster+2
	PLA
	STA	fat32_lastfoundfreecluster+1
	PLA
	STA	fat32_lastfoundfreecluster
	; add the result to lba
	CLC
	LDA	fat32_lba
	ADC	fat32_result
	STA	fat32_lba
	LDA	fat32_lba+1
	ADC	fat32_result+1
	STA	fat32_lba+1
	LDA	fat32_lba+2
	ADC	#0
	STA	fat32_lba+2
	LDA	fat32_lba+3
	ADC	#0
	STA	fat32_lba+3
skipdiv:
  ; now we have preformed LBA=+LASTFOUNDSECTOR/128
  ; LBA - FATSTART = RESULT
  sec
  lda fat32_lba
  sbc fat32_fatstart
  sta fat32_dwcount
  lda fat32_lba+1
  sbc fat32_fatstart+1
  sta fat32_dwcount+1
  lda fat32_lba+2
  sbc fat32_fatstart+2
  sta fat32_dwcount+2
  lda fat32_lba+3
  sbc fat32_fatstart+3
  sta fat32_dwcount+3
  ; Save zp_sd_address for later
  lda zp_sd_address
  pha
  lda zp_sd_address+1
  pha 
  ; Now we will find a free cluster. (finally)
findfreeclusterloop:
  ; We will read at sector LBA
  lda fat32_lba
  sta zp_sd_currentsector
  lda fat32_lba+1
  sta zp_sd_currentsector+1
  lda fat32_lba+2
  sta zp_sd_currentsector+2
  lda fat32_lba+3
  sta zp_sd_currentsector+3
  ; Target buffer
  lda #<fat32_readbuffer
  sta zp_sd_address
  lda #>fat32_readbuffer
  sta zp_sd_address+1
  ; Read sector
  jsr sd_readsector
  ; Now Check each entry in the sector.
  ldx #0
  ldy #0
ffcinner:
  lda (zp_sd_address),y
  and #$0f			; First 4 bits are reserved.
  iny
  clc
  adc (zp_sd_address),y
  iny
  adc (zp_sd_address),y
  iny
  adc (zp_sd_address),y
  beq gotfreecluster		; If the FAT entry is 0x00000000, we've got the next free cluster

  ; Increment the last found free cluster count
  inc fat32_lastfoundfreecluster
  bne ffcdontinc
  inc fat32_lastfoundfreecluster+1
  bne ffcdontinc
  inc fat32_lastfoundfreecluster+2
  bne ffcdontinc
  inc fat32_lastfoundfreecluster+3
ffcdontinc:
  ; Now check if the disk is full.
  lda fat32_lastfoundfreecluster
  cmp #$ff
  bne ffcskip
  lda fat32_lastfoundfreecluster
  cmp #$ff
  bne ffcskip
  lda fat32_lastfoundfreecluster
  cmp #$ff
  bne ffcskip
  lda fat32_lastfoundfreecluster
  cmp #$f7
  bne ffcskip
  jmp diskfull	; Disk full
ffcskip:
  inx
  cpx #129 	; Sector read?
  bne ffcinner	; If not go back to read another FAT entry
  ; Increment LBA
  inc fat32_lba
  bne dontinclba
  inc fat32_lba+1
  bne dontinclba
  inc fat32_lba+2
  bne dontinclba
  inc fat32_lba+3
dontinclba:
  ; Out of disk space?
  ; BUG i should by comparing this with sectors per FAT, not per cluster...
  ; are they the same? (i dont think so...)
  dec fat32_sectorspercluster
  lda fat32_dwcount
  cmp fat32_sectorspercluster
  bcs dontsubtractdw
  inc fat32_sectorspercluster
  jmp diskfull ; Disk Full
dontsubtractdw:
  inc fat32_sectorspercluster
  ; Increment fat32_dwcount
  inc fat32_dwcount
  bne dontincdw
  inc fat32_dwcount+1
dontincdw:
  jmp findfreeclusterloop
gotfreecluster:
; Got the free cluster. Carry clear.
  pla
  sta zp_sd_address+1
  pla
  sta zp_sd_address
  clc
  rts

diskfull:
; The disk is full. Set carry bit.
  pla
  sta zp_sd_address+1
  pla
  sta zp_sd_address
  sec
  rts

fat32_readdirent:
  ; Read a directory entry from the open directory
  ;
  ; On exit the carry is set if there were no more directory entries.
  ;
  ; Otherwise, A is set to the file's attribute byte and
  ; zp_sd_address points at the returned directory entry.
  ; LFNs and empty entries are ignored automatically.

  ; Increment pointer by 32 to point to next entry
  clc
  lda zp_sd_address
  adc #32
  sta zp_sd_address
  lda zp_sd_address+1
  adc #0
  sta zp_sd_address+1

  ; If it's not at the end of the buffer, we have data already
  cmp #>(fat32_readbuffer+$200)
  bcc ugotdata

  ; Read another sector
  lda #<fat32_readbuffer
  sta fat32_address
  lda #>fat32_readbuffer
  sta fat32_address+1

  jsr fat32_readnextsector
  bcc ugotdata

uendofdirectory:
  sec
  rts

ugotdata:
  ; Check first character
  ldy #0
  lda (zp_sd_address),y

  ; End of directory => abort
  beq uendofdirectory

  ; Empty entry => start again
  cmp #$e5
  beq fat32_readdirent

  ; Check attributes
  ldy #11
  lda (zp_sd_address),y
  and #$3f
  cmp #$0f ; LFN => start again
  beq fat32_readdirent

  ; Yield this result
  clc
  rts


fat32_finddirent:
  ; Finds a particular directory entryu  X,Y point to the 11-character filename to seek.
  ; The directory should already be open for iteration.

  ; Form ZP pointer to user's filename
  stx fat32_filenamepointer
  sty fat32_filenamepointer+1
  
  ; Iterate until name is found or end of directory
udirentloop:
  jsr fat32_readdirent
  ldy #10
  bcc ucomparenameloop
  rts ; with carry set

ucomparenameloop:
  lda (zp_sd_address),y
  cmp (fat32_filenamepointer),y
  bne udirentloop ; no match
  dey
  bpl ucomparenameloop

  ; Found it
  clc
  rts


fat32_file_readbyte:
  ; Read a byte from an open file
  ;
  ; The byte is returned in A with C clear; or if end-of-file was reached, C is set instead

  sec

  ; Is there any data to read at all?
  lda fat32_bytesremaining
  ora fat32_bytesremaining+1
  ora fat32_bytesremaining+2
  ora fat32_bytesremaining+3
  beq urts

  ; Decrement the remaining byte count
  lda fat32_bytesremaining
  sbc #1
  sta fat32_bytesremaining
  lda fat32_bytesremaining+1
  sbc #0
  sta fat32_bytesremaining+1
  lda fat32_bytesremaining+2
  sbc #0
  sta fat32_bytesremaining+2
  lda fat32_bytesremaining+3
  sbc #0
  sta fat32_bytesremaining+3
  
  ; Need to read a new sector?
  lda zp_sd_address+1
  cmp #>(fat32_readbuffer+$200)
  bcc uegotdata

  ; Read another sector
  lda #<fat32_readbuffer
  sta fat32_address
  lda #>fat32_readbuffer
  sta fat32_address+1

  jsr fat32_readnextsector
  bcs urts                    ; this shouldn't happen

uegotdata:
  ldy #0
  lda (zp_sd_address),y

  inc zp_sd_address
  bne urts
  inc zp_sd_address+1
  bne urts
  inc zp_sd_address+2
  bne urts
  inc zp_sd_address+3

urts:
  rts


fat32_file_read:
  ; Read a whole file into memory.  It's assumed the file has just been opened 
  ; and no data has been read yet.
  ;
  ; Also we read whole sectors, so data in the target region beyond the end of the 
  ; file may get overwritten, up to the next 512-byte boundary.
  ;
  ; And we don't properly support 64k+ files, as it's unnecessary complication given
  ; the 6502's small address space

  ; Round the size up to the next whole sector
  lda fat32_bytesremaining
  cmp #1                      ; set carry if bottom 8 bits not zero
  lda fat32_bytesremaining+1
  adc #0                      ; add carry, if any
  lsr                         ; divide by 2
  adc #0                      ; round up

  ; No data?
  beq udone

  ; Store sector count - not a byte count any more
  sta fat32_bytesremaining

  ; Read entire sectors to the user-supplied buffer
uwholesectorreadloop:
  ; Read a sector to fat32_address
  jsr fat32_readnextsector

  ; Advance fat32_address by 512 bytes
  lda fat32_address+1
  adc #2                      ; carry already clear
  sta fat32_address+1

  ldx fat32_bytesremaining    ; note - actually loads sectors remaining
  dex
  stx fat32_bytesremaining    ; note - actually stores sectors remaining

  bne uwholesectorreadloop

udone:
  rts

fat32_file_write:
  ; Write a whole file from memory.  It's assumed the file has just been opened 
  ; and no data has been written yet.
  ;
  ; Also we write whole sectors, so data in the target region beyond the end of the 
  ; file may get overwritten, up to the next 512-byte boundary.
  ;
  ; And we don't properly support 64k+ files, as it's unnecessary complication given
  ; the 6502's small address space

  ; Round the size up to the next whole sector
  lda fat32_bytesremaining
  cmp #1                      ; set carry if bottom 8 bits not zero
  lda fat32_bytesremaining+1
  adc #0                      ; add carry, if any
  lsr                         ; divide by 2
  adc #0                      ; round up

  ; No data?
  beq urdone

  ; Store sector count - not a byte count any more
  sta fat32_bytesremaining

  ; Write entire sectors from the user-supplied buffer
wholesectorwriteloop:
  ; Write a sector from fat32_address
  jsr fat32_writenextsector

  ; Advance fat32_address by 512 bytes
  lda fat32_address+1
  adc #2                      ; carry already clear
  sta fat32_address+1

  ldx fat32_bytesremaining    ; note - actually loads sectors remaining
  dex
  stx fat32_bytesremaining    ; note - actually stores sectors remaining

  bne wholesectorwriteloop

urdone:
  rts
