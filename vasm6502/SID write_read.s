  .org $c000
rst:
	ldx	#$ff
	txs

	lda	#$aa
	sta	$b800
	lda	$b800
loop:
	jmp	loop

  .org $fffc
  .word rst
  .word $0000
