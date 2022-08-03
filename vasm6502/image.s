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

VDP_PATTERN_TABLE_BASE = $0000
VDP_SPRITE_PATTERN_TABLE_BASE = $1800
VDP_COLOR_TABLE_BASE = $2000
VDP_NAME_TABLE_BASE = $3800
VDP_SPR_ATT_TABLE_BASE = $3B00

TEXT_LOC		= $00FF

; zero page addresses
VDP_PATTERN_INIT    	= $30
VDP_PATTERN_INIT_HI 	= $31

VDP_NAME_POINTER        = $32

  .org $0f00
  .macro vdp_write_vram			; macro to store address in vdp_reg for write
  pha
  lda #<(\1)
  sta VDP_REG
  lda #(VDP_WRITE_VRAM_BIT | >\1)
  sta VDP_REG
  pla
  .endm
;;;;;;;;;;;;;;;;;;; reset ;;;;;;;;;;;;;;;;;;;

reset:

;;;;;;;;;;;;;;;;;;; setup subroutines ;;;;;;;;;;;;;;;;;;;;;;;

  sei
  ;stz $b00e     ; argguahububefhia! that darn via! short circut!!1!! this is d fix

  jsr vdp_set_registers
  jsr vdp_setup
  lda #255	; activate display
  sta $b003
  sta $b001
  lda #0
  jsr init
  cli
holding:
  ;;jsr changecolor
  ;lda VDP_REG
  ;and #$80
  ;beq holding
  ;lda #$0e
  ;sta VDP_REG
  ;lda #$87
  ;sta VDP_REG
  ;jsr PlaySid
  ;lda #$00
  ;sta VDP_REG
  ;lda #$87
  ;sta VDP_REG
  jmp holding

;;;;;;;;;;;;;;;;;;; vdp_setup subroutines ;;;;;;;;;;;;;;;;;;;;

vdp_setup:
  jsr vdp_initialize_name_table
  jsr vdp_initialize_color_table
  jsr vdp_initialize_pattern_table
  jsr vdp_enable_display
  rts

;;;;;;;;;;;;;;;;;;; vdp_set_registers ;;;;;;;;;;;;;;;;;;;;;;;;

vdp_set_registers:
  pha
  phx
  ldx #0
.loop:
  lda vdp_register_inits,x
  sta VDP_REG
  txa
  ora #VDP_REGISTER_BITS 				; combine the register number with the second write pattern
  sta VDP_REG
  inx
  cpx #8
  bne .loop
  plx
  pla
  rts

;wait:
;	phx
;	phy
;        tay          ; load secondary loop cycle count (A reg)
;        ldx  #$ff
;delay   dex          ; (2 cycles)
;        bne  delay   ; (3 cycles in loop, 2 cycles at end)
;        dey          ; (2 cycles)
;        bne  delay   ; (3 cycles in loop, 2 cycles at end)
;	ply
;	plx
;;	rts
;
;changecolor:
;  pha
;  inc vdp_register_7
;  lda vdp_register_7
;  sta VDP_REG
;  lda #$87
;  sta VDP_REG
;  pla
;  rts

;;;;;;;;;;;;;;;;;;; vdp_initialize_name_table ;;;;;;;;;;;;;;;;;;;

vdp_initialize_name_table:
  pha
  phx
  phy
  vdp_write_vram VDP_NAME_TABLE_BASE
  stz VDP_NAME_POINTER
  ;lda #$20
  ldy #0
vdp_name_table_loop:
  sty VDP_VRAM
  iny
  bne vdp_name_table_loop

  inc VDP_NAME_POINTER
  ldx VDP_NAME_POINTER
  cpx #3
  bne vdp_name_table_loop
  
  ply
  plx
  pla
  rts

;;;;;;;;;;;;;;;;;;; vdp_initialize_pattern_table ;;;;;;;;;;;;;;;;;;;

vdp_initialize_pattern_table:
  pha
  phx
  vdp_write_vram VDP_PATTERN_TABLE_BASE
  lda #<vdp_pattern                         ; load the start address of the patterns to zero page
  sta VDP_PATTERN_INIT
  lda #>vdp_pattern
  sta VDP_PATTERN_INIT_HI
vdp_pattern_table_loop:
  lda (VDP_PATTERN_INIT)                  ; load A with the value at VDP_PATTERN_INIT 
  sta VDP_VRAM                            ; and store it to VRAM
  inc VDP_PATTERN_INIT
  lda VDP_PATTERN_INIT
  bne wopeee
  inc VDP_PATTERN_INIT_HI
wopeee:
  lda VDP_PATTERN_INIT
  cmp #<vdp_pattern_end
  bne vdp_pattern_table_loop
  lda VDP_PATTERN_INIT_HI
  cmp #>vdp_pattern_end
  bne vdp_pattern_table_loop
  plx
  pla
  rts


  .include "her11_code.s"


;;;;;;;;;;;;;;;;;;; vdp_initialize_color_table ;;;;;;;;;;;;;;;;;;;

vdp_initialize_color_table:
  pha
  phx
  vdp_write_vram VDP_COLOR_TABLE_BASE
  lda #<vdp_color                         ; load the start address of the patterns to zero page
  sta VDP_PATTERN_INIT
  lda #>vdp_color
  sta VDP_PATTERN_INIT_HI
vdp_color_table_loop:
  lda (VDP_PATTERN_INIT)                  ; load A with the value at VDP_PATTERN_INIT 
  sta VDP_VRAM                            ; and store it to VRAM
  inc VDP_PATTERN_INIT
  lda VDP_PATTERN_INIT
  bne wopee
  inc VDP_PATTERN_INIT_HI
wopee:
  lda VDP_PATTERN_INIT
  cmp #<vdp_color_end
  bne vdp_color_table_loop
  lda VDP_PATTERN_INIT_HI
  cmp #>vdp_color_end
  bne vdp_color_table_loop
  plx
  pla
  rts


;;;;;;;;;;;;;;;;;;; vdp_enable_display ;;;;;;;;;;;;;;;;;;;;;;;;;

vdp_enable_display:
  pha
  lda #%11000010			; select 16k bytes of vram, enable the active display, disable vdp interrupt, set text mode
  sta VDP_REG
  lda #(VDP_REGISTER_BITS | 1)
  sta VDP_REG
  pla
  rts

text_vdp:
  ;.byte "Hello, World!", $00


vdp_register_inits:
vdp_register_0: .byte %00000010 ; 0  0  0  0  0  0  M3 EXTVDP
vdp_register_1: .byte %10000010 ;16k Bl IE M1 M2 0 Siz MAG
vdp_register_2: .byte $0e       ; Name table base / $400. $00 = $0000
vdp_register_3: .byte $ff       ; Color table base (currently unused)
vdp_register_4: .byte $03       ; Pattern table base / $800. $01 = $0800
vdp_register_5: .byte $76       ; Sprite attribute table base (currently unused)
vdp_register_6: .byte $03       ; Sprite pattern generator (currently unused)
vdp_register_7: .byte $00       ; FG/BG. 1=>Black, E=>Gray
vdp_end_register_inits:


;;;;;;;;;;;;;;;;;;; vdp_color ;;;;;;;;;;;;;;;;;;;;;
  .align 8
vdp_color:
  .binary "HER11.TIAC"
vdp_color_end:
  .byte $00

;;;;;;;;;;;;;;;;;;; vdp_patterns ;;;;;;;;;;;;;;;;;;;;;

  .align 8
vdp_pattern:
  .binary "HER11.TIAP"
; line drawing
  ;.byte $00,$00,$00,$FF,$FF,$00,$00,$00 ; lr
  ;.byte $18,$18,$18,$18,$18,$18,$18,$18 ; ud
  ;.byte $00,$00,$00,$F8,$F8,$18,$18,$18 ; ld
  ;.byte $00,$00,$00,$1F,$1F,$18,$18,$18 ; rd
  ;.byte $18,$18,$18,$F8,$F8,$00,$00,$00 ; lu
  ;.byte $18,$18,$18,$1F,$1F,$00,$00,$00 ; ur
  ;.byte $18,$18,$18,$FF,$FF,$18,$18,$18 ; lurd
; <nonsense for debug>
  ;.byte $07,$07,$07,$07,$07,$07,$07,$00 ; 07
  ;.byte $08,$08,$08,$08,$08,$08,$08,$00 ; 08
  ;.byte $09,$09,$09,$09,$09,$09,$09,$00 ; 09
  ;.byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$00 ; 0A
  ;.byte $0B,$0B,$0B,$0B,$0B,$0B,$0B,$00 ; 0B
  ;.byte $0C,$0C,$0C,$0C,$0C,$0C,$0C,$00 ; 0C
  ;.byte $0D,$0D,$0D,$0D,$0D,$0D,$0D,$00 ; 0D
  ;.byte $0E,$0E,$0E,$0E,$0E,$0E,$0E,$00 ; 0E
  ;.byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$00 ; 0F
  ;.byte $10,$10,$10,$10,$10,$10,$10,$00 ; 10
  ;.byte $11,$11,$11,$11,$11,$11,$11,$00 ; 11
  ;.byte $12,$12,$12,$12,$12,$12,$12,$00 ; 12
  ;.byte $13,$13,$13,$13,$13,$13,$13,$00 ; 13
  ;.byte $14,$14,$14,$14,$14,$14,$14,$00 ; 14
  ;.byte $15,$15,$15,$15,$15,$15,$15,$00 ; 15
  ;.byte $16,$16,$16,$16,$16,$16,$16,$00 ; 16
  ;.byte $17,$17,$17,$17,$17,$17,$17,$00 ; 17
  ;.byte $18,$18,$18,$18,$18,$18,$18,$00 ; 18
  ;.byte $19,$19,$19,$19,$19,$19,$19,$00 ; 19
  ;.byte $1A,$1A,$1A,$1A,$1A,$1A,$1A,$00 ; 1A
  ;.byte $1B,$1B,$1B,$1B,$1B,$1B,$1B,$00 ; 1B
  ;.byte $1C,$1C,$1C,$1C,$1C,$1C,$1C,$00 ; 1C
  ;.byte $1D,$1D,$1D,$1D,$1D,$1D,$1D,$00 ; 1D
  ;.byte $1E,$1E,$1E,$1E,$1E,$1E,$1E,$00 ; 1E
  ;.byte $1F,$1F,$1F,$1F,$1F,$1F,$1F,$00 ; 1F
; </nonsense>
  ;.byte $00,$00,$00,$00,$00,$00,$00,$00 ; ' '
  ;.byte $20,$20,$20,$00,$20,$20,$00,$00 ; !
  ;.byte $50,$50,$50,$00,$00,$00,$00,$00 ; "
  ;.byte $50,$50,$F8,$50,$F8,$50,$50,$00 ; #
  ;.byte $20,$78,$A0,$70,$28,$F0,$20,$00 ; $
  ;.byte $C0,$C8,$10,$20,$40,$98,$18,$00 ; %
  ;.byte $40,$A0,$A0,$40,$A8,$90,$68,$00 ; &
  ;.byte $20,$20,$40,$00,$00,$00,$00,$00 ; '
  ;.byte $20,$40,$80,$80,$80,$40,$20,$00 ; (
  ;.byte $20,$10,$08,$08,$08,$10,$20,$00 ; )
  ;.byte $20,$A8,$70,$20,$70,$A8,$20,$00 ; *
  ;.byte $00,$20,$20,$F8,$20,$20,$00,$00 ; +
  ;.byte $00,$00,$00,$00,$20,$20,$40,$00 ; ,
  ;.byte $00,$00,$00,$F8,$00,$00,$00,$00 ; -
  ;.byte $00,$00,$00,$00,$20,$20,$00,$00 ; .
  ;.byte $00,$08,$10,$20,$40,$80,$00,$00 ; /
  ;.byte $70,$88,$98,$A8,$C8,$88,$70,$00 ; 0
  ;.byte $20,$60,$20,$20,$20,$20,$70,$00 ; 1
  ;.byte $70,$88,$08,$30,$40,$80,$F8,$00 ; 2
  ;.byte $F8,$08,$10,$30,$08,$88,$70,$00 ; 3
  ;.byte $10,$30,$50,$90,$F8,$10,$10,$00 ; 4
  ;.byte $F8,$80,$F0,$08,$08,$88,$70,$00 ; 5
  ;.byte $38,$40,$80,$F0,$88,$88,$70,$00 ; 6
  ;.byte $F8,$08,$10,$20,$40,$40,$40,$00 ; 7
  ;.byte $70,$88,$88,$70,$88,$88,$70,$00 ; 8
  ;.byte $70,$88,$88,$78,$08,$10,$E0,$00 ; 9
  ;.byte $00,$00,$20,$00,$20,$00,$00,$00 ; :
  ;.byte $00,$00,$20,$00,$20,$20,$40,$00 ; ;
  ;.byte $10,$20,$40,$80,$40,$20,$10,$00 ; <
  ;.byte $00,$00,$F8,$00,$F8,$00,$00,$00 ; =
  ;.byte $40,$20,$10,$08,$10,$20,$40,$00 ; >
  ;.byte $70,$88,$10,$20,$20,$00,$20,$00 ; ?
  ;.byte $70,$88,$A8,$B8,$B0,$80,$78,$00 ; @
  ;.byte $20,$50,$88,$88,$F8,$88,$88,$00 ; A
  ;.byte $F0,$88,$88,$F0,$88,$88,$F0,$00 ; B
  ;.byte $70,$88,$80,$80,$80,$88,$70,$00 ; C
  ;.byte $F0,$88,$88,$88,$88,$88,$F0,$00 ; D
  ;.byte $F8,$80,$80,$F0,$80,$80,$F8,$00 ; E
  ;.byte $F8,$80,$80,$F0,$80,$80,$80,$00 ; F
  ;.byte $78,$80,$80,$80,$98,$88,$78,$00 ; G
  ;.byte $88,$88,$88,$F8,$88,$88,$88,$00 ; H
  ;.byte $70,$20,$20,$20,$20,$20,$70,$00 ; I
  ;.byte $08,$08,$08,$08,$08,$88,$70,$00 ; J
  ;.byte $88,$90,$A0,$C0,$A0,$90,$88,$00 ; K
  ;.byte $80,$80,$80,$80,$80,$80,$F8,$00 ; L
  ;.byte $88,$D8,$A8,$A8,$88,$88,$88,$00 ; M
  ;.byte $88,$88,$C8,$A8,$98,$88,$88,$00 ; N
  ;.byte $70,$88,$88,$88,$88,$88,$70,$00 ; O
  ;.byte $F0,$88,$88,$F0,$80,$80,$80,$00 ; P
  ;.byte $70,$88,$88,$88,$A8,$90,$68,$00 ; Q
  ;.byte $F0,$88,$88,$F0,$A0,$90,$88,$00 ; R
  ;.byte $70,$88,$80,$70,$08,$88,$70,$00 ; S
  ;.byte $F8,$20,$20,$20,$20,$20,$20,$00 ; T
  ;.byte $88,$88,$88,$88,$88,$88,$70,$00 ; U
  ;.byte $88,$88,$88,$88,$50,$50,$20,$00 ; V
  ;.byte $88,$88,$88,$A8,$A8,$D8,$88,$00 ; W
  ;.byte $88,$88,$50,$20,$50,$88,$88,$00 ; X
  ;.byte $88,$88,$50,$20,$20,$20,$20,$00 ; Y
  ;.byte $F8,$08,$10,$20,$40,$80,$F8,$00 ; Z
  ;.byte $F8,$C0,$C0,$C0,$C0,$C0,$F8,$00 ; [
  ;.byte $00,$80,$40,$20,$10,$08,$00,$00 ; \
  ;.byte $F8,$18,$18,$18,$18,$18,$F8,$00 ; ]
  ;.byte $00,$00,$20,$50,$88,$00,$00,$00 ; ^
  ;.byte $00,$00,$00,$00,$00,$00,$F8,$00 ; _
  ;.byte $40,$20,$10,$00,$00,$00,$00,$00 ; `
  ;.byte $00,$00,$70,$88,$88,$98,$68,$00 ; a
  ;.byte $80,$80,$F0,$88,$88,$88,$F0,$00 ; b
  ;.byte $00,$00,$78,$80,$80,$80,$78,$00 ; c
  ;.byte $08,$08,$78,$88,$88,$88,$78,$00 ; d
  ;.byte $00,$00,$70,$88,$F8,$80,$78,$00 ; e
  ;.byte $30,$40,$E0,$40,$40,$40,$40,$00 ; f
  ;.byte $00,$00,$70,$88,$F8,$08,$F0,$00 ; g
  ;.byte $80,$80,$F0,$88,$88,$88,$88,$00 ; h
  ;.byte $00,$40,$00,$40,$40,$40,$40,$00 ; i
  ;.byte $00,$20,$00,$20,$20,$A0,$60,$00 ; j
  ;.byte $00,$80,$80,$A0,$C0,$A0,$90,$00 ; k
  ;.byte $C0,$40,$40,$40,$40,$40,$60,$00 ; l
  ;.byte $00,$00,$D8,$A8,$A8,$A8,$A8,$00 ; m
  ;.byte $00,$00,$F0,$88,$88,$88,$88,$00 ; n
  ;.byte $00,$00,$70,$88,$88,$88,$70,$00 ; o
  ;.byte $00,$00,$70,$88,$F0,$80,$80,$00 ; p
  ;.byte $00,$00,$F0,$88,$78,$08,$08,$00 ; q
  ;.byte $00,$00,$70,$88,$80,$80,$80,$00 ; r
  ;.byte $00,$00,$78,$80,$70,$08,$F0,$00 ; s
  ;.byte $40,$40,$F0,$40,$40,$40,$30,$00 ; t
  ;.byte $00,$00,$88,$88,$88,$88,$78,$00 ; u
  ;.byte $00,$00,$88,$88,$90,$A0,$40,$00 ; v
  ;.byte $00,$00,$88,$88,$88,$A8,$D8,$00 ; w
  ;.byte $00,$00,$88,$50,$20,$50,$88,$00 ; x
  ;.byte $00,$00,$88,$88,$78,$08,$F0,$00 ; y
  ;.byte $00,$00,$F8,$10,$20,$40,$F8,$00 ; z
  ;.byte $38,$40,$20,$C0,$20,$40,$38,$00 ; {
  ;.byte $40,$40,$40,$00,$40,$40,$40,$00 ; |
  ;.byte $E0,$10,$20,$18,$20,$10,$E0,$00 ; }
  ;.byte $40,$A8,$10,$00,$00,$00,$00,$00 ; ~
  ;.byte $A8,$50,$A8,$50,$A8,$50,$A8,$00 ; checkerboard
vdp_pattern_end:

  .byte $00
