  .org $0f11
start:
    LDX #0
read:
    LDA $8001
    AND #$08
    BEQ read
    LDA $8000
    STA $8000
    JMP read

