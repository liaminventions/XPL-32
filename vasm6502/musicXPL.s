VIA      = $b000
PB      = VIA
PA      = VIA + 1
DDRB   = VIA + 2
DDRA   = VIA + 3
T2CL   = VIA + 8
T2CH   = VIA + 9
SR      = VIA + 10
ACR      = VIA + 11
PCR      = VIA + 12
IFR      = VIA + 13
IER      = VIA + 14

ACIA = $8000
ACIA_DATA = ACIA
ACIA_STATUS = ACIA + 1
ACIA_COMMAND = ACIA + 2
ACIA_CONTROL = ACIA + 3

TUNE_PTR_LO      =   $42
TUNE_PTR_HI      =   $43

    .org $1000

reset:
   ldx #$ff                ; Initatlize stack pointer to FF
   txs
main:
   jsr init_via  
   jsr reset_ay

   jsr init_tune
   jsr play_tune
   jmp loop

loop:
  jmp loop

init_via:
   ;   Set DDR registers on VIA
   lda   #$FF
   sta DDRA

   lda #$07
   sta DDRB
   rts

init_tune:
   lda #<tune
   sta TUNE_PTR_LO
   lda #>tune
   sta TUNE_PTR_HI
   rts

;   This play loop is not optimized or finished yet.  Currently depends
;   on a WORD aligned data stream in the form of REGISTER then DATA.  $FF terminates.
play_tune:
   ldy #0
play_loop:
   lda (TUNE_PTR_LO), Y
   cmp #$FF
   bne play_next
   rts 
play_next:
   lda (TUNE_PTR_LO), Y
   jsr setreg
   iny
   lda (TUNE_PTR_LO), Y
   cmp #$FF
   bne play_next2
   rts
play_next2:
   jsr writedata
   iny
   jmp play_loop


;------------------------------------------------------------------------------
;   RESET AY
;------------------------------------------------------------------------------
reset_ay:
   lda #$00
   sta PB
   lda #$04
   sta PB
   rts

;------------------------------------------------------------------------------
;   SETREG
;
;   Sets the register of AY which should be located in A prior to calling
;------------------------------------------------------------------------------
setreg:
   jsr inactive    ;   NACT
   sta PA         ;   get register from A (OUTPUT ADDRESS)
   jsr latch       ;   INTAK
   jsr inactive    ;   NACT
   rts

;------------------------------------------------------------------------------
;   WRITEDATA
;
;   Sets the data value which should be located in A prior to calling
;------------------------------------------------------------------------------
writedata:
   jsr inactive    ;   NACT
   sta PA
   jsr write       ;   DWS
   jsr inactive
   rts


;------------------------------------------------------------------------------
;   INACTIVE
;
;   BDIR   LOW
;   BC1      LOW
;------------------------------------------------------------------------------
inactive:
   txa
   pha         ;   preserve X
   ldx #$04
   stx PB
   pla
   tax         ;   pull X back off stack
   rts


;------------------------------------------------------------------------------
;   LATCH ADDRESS
;
;   BDIR   HIGH
;   BC1      HIGH
;------------------------------------------------------------------------------
latch:
   txa
   pha         ;   preserve X
   ldx #$07
   stx PB
   pla
   tax         ;   pull X back off stack
   rts


;------------------------------------------------------------------------------
;   WRITE DATA
;
;   BDIR   HIGH
;   BC1      LOW
;------------------------------------------------------------------------------
write:
   txa 
   pha         ;   preserve X
   ldx #$06
   stx PB
   pla
   tax         ;   pull X back off stack
   rts



tune:
   .BYTE $00, $00
   .BYTE $01, $03
   .BYTE $07, $FC
   .BYTE $08, $0F
   .BYTE $FF         ; END
