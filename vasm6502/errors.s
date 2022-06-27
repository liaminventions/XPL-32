error_sound:
  lda #$55
  sta donefact
  stz irqcount	; reset irq count

runthesound:
  sei		; turn off irqs
  lda #<irq
  sta $7ffe
  lda #>irq
  sta $7fff	; store vectors
  lda #$c0
  sta $b00e	
  lda #0 ; Song Number
  jsr InitSid
  lda #$40
  sta $b00d
  cli
  jmp startupsoundloop

irq:
  lda #$40
  sta $b00d
  jsr putbut		; refresh timers
  inc irqcount		; a irq has occurred
  lda irqcount
  cmp #$40		; if $32 irqs (end of the error sound)
  bne continue24542 	; end the stream
  stz donefact		; its done, tell the loop
continue24542:
  jsr $1006
  rti			; exit

putbut:
		ldx #$9e
		stx $b004
		stx $b006
		ldx #$0f  ; 250Hz IRQ
		stx $b005
		stx $b007
		rts
InitSid		jsr putbut
		jmp $1103

  .org $1006

  .include "errorsound.s"

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
  rts
  rts
  rts
  rts

clear_sid
  ldx #$18
csid
  stz $b800,x
  dex
  bne csid
  rts


