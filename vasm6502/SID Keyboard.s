SID = $B800
FREQLO1 = SID
FREQHI1 = SID + 1
PWLO1 = SID + 2
PWHI1 = SID + 3
CR1 = SID + 4
AD1 = SID + 5
SR1 = SID + 6
FREQLO2 = SID + 7
FREQHI2 = SID + 8
PWLO2 = SID + 9
PWHI2 = SID + 10
CR2 = SID + 11
AD2 = SID + 12
SR2 = SID + 13
FREQLO3 = SID + 14
FREQHI3 = SID + 15
PWLO3 = SID + 16
PWHI3 = SID + 17
CR3 = SID + 18
AD3 = SID + 19
SR3 = SID + 20
FCLO = SID + 21
FCHI = SID + 22
ResFlt = SID + 23
ModeVol = SID + 24
POTX = SID + 25
POTY = SID + 26
OSC3 = SID + 27
ENV3 = SID + 28

ACIA_DATA = $8000
ACIA_STATUS = $8001
ACIA_COMMAND = $8002
ACIA_CONTROL = $8003

Temp = $00

  .org $1000
Reset:
  ldy #0
  ldx #$18
  lda #0
InitSid:
  sta SID,y
  iny
  dex
  beq Start
  jmp InitSid
Start:
  lda #$0f
  sta ModeVol
Loop:
  jsr RDKEY
  sta Temp
  tax
Part1:
  lda Table,x
  sta FREQLO1
  lda Table2,x
  sta FREQHI1
  
  lda #$08
  sta PWHI1
  lda #$65
  sta CR1
  lda #$0c
  sta AD1
  lda #$aa
  sta SR1

  ldy #$ff
Outer:
  dey
  beq endloop
  ldx #$ff
Inner:
  nop 
  nop
  nop
  dex
  bne Inner
  jmp Outer
endloop:
  lda #$64
  sta CR1
  jmp Loop 
  
RDKEY:
  jsr Rxpoll
  lda ACIA_DATA
  rts

Txpoll:
  lda ACIA_STATUS
  and #$10
  beq Txpoll
  rts

Rxpoll:
  lda ACIA_STATUS
  and #$08
  beq Rxpoll
  rts

Table:
  .binary "Table.bin"
Table2:
  .binary "Table2.bin"
