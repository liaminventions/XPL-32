	.org $0f00
start:
	jsr rxpoll
	sta $00
	jsr print_hex_acia
	rts
	rts
	rts
	rts
	
	.include "libacia.s"
