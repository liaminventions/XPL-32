  .org $03

  .macro movei_w 
       lda \1
       sta \2
       lda \1+1
       sta \2+1                    
  .endmacro

; only works in Zeropage!
fastmove:
        ldy     #0
        movei_w src,smcs+1 
        movei_w dst,smcd+1 
        ldx     len+1
        beq     last
loop:
smcs:           lda     $f000,y         
smcd:           sta     $f000,y         
        iny
        bne     loop
        inc     smcs+2
        inc     smcd+2
        dex
        bne     loop
last:
        lda     (smcs+1),y
        sta     (smcd+1),y
        iny
        cpy     #len
        bne     last 
        rts   

src = $e0
dst = $e2
len = $e4
