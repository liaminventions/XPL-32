donefact = $00
irqcount = $01

;;; Play a startup sound
;;;
;;;
;;; (du du du!)

dostartupsound:
  lda #$55
  sta donefact
  stz irqcount

  lda #$0f
  sta $b818

  cli			; enable irqs
  ldy #0		; reset counter
loopbring:		; write the sid to $1006
  lda sounddata,y	; disclaimer: THIS WILL OVERWRITE WHATEVER THE USER HAS AT $1006-$1300!
  sta $1006,y
  lda sounddata1,y
  sta $1006+$100,y
  lda sounddata2,y
  sta $1006+$200,y
  iny
  bne loopbring

runthesound:		; thats done, now to play the sound
  sei
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff
  lda #$c0
  sta $b00e
  lda #0 ; Song Number
  jsr InitSid
  lda #$40
  sta $b00d
  cli
  jmp startupsoundloop

irq:
  jsr putbut		; refresh timers
  sei
  inc irqcount		; a irq has occurred
  cmp #120     		; if this amount of irqs (end of the startup sound)
  bne continue24542 	; end the stream
  stz donefact		; its done, tell the loop
  sei
continue24542:
  jsr $1006
  cli
  rti			; exit

putbut:
		    ldx #$9e
                    stx $b004
                    stx $b006
		    ldx #$0f  ; 250Hz IRQ
                    stx $b005
                    stx $b007
                    rts
InitSid             jsr putbut
                    jmp $1103

sounddata:
          .BYTE $A2,$18,$B5,$04,$9D,$00,$B8,$CA,$10,$F8,$C6,$02,$30,$01,$60,$86
          .BYTE $02,$A5,$03,$D0,$18,$20,$1F,$00,$F0,$18,$C9,$A0,$B0,$0A,$85,$2A
          .BYTE $20,$1F,$00,$85,$29,$4C,$76,$10,$38,$E9,$9F,$85,$03,$C6,$03,$4C
          .BYTE $76,$10,$20,$1F,$00,$C9,$FD,$F0,$2C,$C9,$FE,$F0,$1D,$C9,$FF,$F0
          .BYTE $03,$85,$02,$60,$A9,$00,$8D,$04,$B8,$8D,$0B,$B8,$8D,$12,$B8,$A9
          .BYTE $5E,$85,$26,$A9,$10,$85,$27,$60,$FF,$00,$A5,$1D,$85,$26,$A5,$1E
          .BYTE $85,$27,$4C,$15,$10,$A5,$26,$85,$1D,$A5,$27,$85,$1E,$4C,$15,$10
          .BYTE $20,$A1,$10,$A9,$F8,$18,$69,$07,$48,$AA,$20,$1F,$00,$4A,$08,$E8
          .BYTE $4A,$B0,$0A,$D0,$FA,$28,$68,$B0,$EC,$20,$A1,$10,$60,$48,$BC,$FF
          .BYTE $FF,$20,$1F,$00,$99,$04,$00,$68,$4C,$85,$10,$A4,$26,$A6,$29,$84
          .BYTE $29,$86,$26,$A4,$27,$A6,$2A,$84,$2A,$86,$27,$60,$84,$26,$86,$27
          .BYTE $A2,$06,$BD,$C6,$10,$95,$1F,$CA,$10,$F8,$A9,$60,$85,$28,$D0,$0A
          .BYTE $E6,$26,$D0,$02,$E6,$27,$AD,$FF,$FF,$60,$20,$1F,$00,$8D,$04,$DC
          .BYTE $20,$1F,$00,$8D,$05,$DC,$20,$1F,$00,$85,$29,$20,$1F,$00,$85,$2A
          .BYTE $E6,$26,$D0,$02,$E6,$27,$A5,$26,$8D,$95,$10,$A5,$27,$8D,$96,$10
          .BYTE $A2,$1C,$A9,$00,$95,$02,$CA,$10,$FB,$20,$A1,$10,$60,$A0,$09,$A2
sounddata1:
          .BYTE $11,$4C,$B2,$10,$F0,$0F,$88,$11,$04,$05,$01,$00,$0D,$12,$0B,$14
          .BYTE $08,$09,$07,$06,$0C,$03,$0E,$0F,$10,$11,$17,$13,$0A,$15,$16,$18
          .BYTE $02,$00,$00,$00,$00,$00,$00,$00,$FF,$41,$0C,$0B,$9D,$F0,$20,$20
          .BYTE $FF,$F0,$00,$FD,$00,$00,$00,$07,$FF,$00,$00,$FD,$07,$60,$00,$07
          .BYTE $1E,$07,$05,$4F,$FD,$03,$21,$01,$01,$08,$4F,$02,$41,$07,$21,$00
          .BYTE $20,$00,$1E,$41,$0C,$0E,$A2,$1E,$41,$0C,$11,$66,$02,$40,$02,$20
          .BYTE $E7,$20,$00,$00,$08,$08,$43,$00,$00,$40,$00,$FF,$41,$0C,$0B,$9D
          .BYTE $F0,$20,$20,$9F,$F0,$00,$FD,$00,$07,$BF,$00,$00,$FD,$07,$60,$07
          .BYTE $06,$07,$05,$11,$2D,$00,$FD,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0
          .BYTE $11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11
          .BYTE $4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A
          .BYTE $A2,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0
          .BYTE $11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11
          .BYTE $4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A1,$11,$5C,$11,$4A,$A0
          .BYTE $11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11
          .BYTE $4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A
sounddata2:
          .BYTE $A0,$11,$4A,$A0,$11,$4A,$A0,$11,$4A,$11,$61,$A0,$11,$61,$A0,$11
          .BYTE $61,$A0,$11,$61,$A0,$11,$61,$A0,$11,$61,$A0,$11,$61,$A0,$11,$61
          .BYTE $A0,$11,$61,$A0,$11,$61,$A0,$11,$61,$A0,$11,$61,$A0,$11,$61,$A0
          .BYTE $11,$61,$A0,$11,$61,$11,$65,$A0,$00,$FE

startupsoundloop:	
  lda donefact		; loop only if the sound is not done
  bne startupsoundloop
  stz $b00e		; if done disable irqs
  stz $b00d
  sei
  lda $c0		; clear irq vectors
  sta $7fff
  stz $7ffe
  jsr clear_sid

