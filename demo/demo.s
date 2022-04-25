;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                     ;
;      Modified_VDP.s                 ;
;      Written in 6502 assembly       ;
;      Started 7/27/21 by tramlaw101  ;
;                                     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; TMS9918A
VDP_VRAM               = $8800		; address to set MODE low for a video ram operation on the TMS9918A Video Display Processor
VDP_REG                = $8801		; address to set MODE high for a video register operation on the TMS9918A Video Display Processor
VDP_WRITE_VRAM_BIT     = %01000000  	; pattern of second vram address write: 01AAAAAA
VDP_REGISTER_BITS      = %10000000  	; pattern of second register write: 10000RRR

VDP_NAME_TABLE_BASE = $0000
VDP_PATTERN_TABLE_BASE = $0800

TEXT_LOC		= $00FF

; zero page addresses
VDP_PATTERN_INIT    	= $30
VDP_PATTERN_INIT_HI 	= $31

VDP_NAME_POINTER        = $32

  .org $0f00
  .include "sys.s"
  .include "text.s"

;  .macro vdp_write_vram			; macro to store address in vdp_reg for write
;  pha
;  lda #<(\1)
;  sta VDP_REG
;  lda #(VDP_WRITE_VRAM_BIT | >\1)
;  sta VDP_REG
;  pla
;  .endm
;;;;;;;;;;;;;;;;;;; reset ;;;;;;;;;;;;;;;;;;;

reset:

;;;;;;;;;;;;;;;;;;; setup subroutines ;;;;;;;;;;;;;;;;;;;;;;;

  jmp textstart

wait:
	phx
	phy
        ldy  #$ff
        ldx  #$ff
delay   dex          ; (2 cycles)
        bne  delay   ; (3 cycles in loop, 2 cycles at end)
        dey          ; (2 cycles)
        bne  delay   ; (3 cycles in loop, 2 cycles at end)
	ply
	plx
	rts


