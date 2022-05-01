
  .org $0f00
  .include "sys.s"
  .include "text.s"
  .include "libacia.s"

reset:
  jmp reset

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


