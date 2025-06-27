##
## This file is part of the libsigrokdecode project.
##
## Copyright (C) 2017 David Banks <dave@hoglet.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

'''
The 6502 is an 8-bit microprocessor.

This decoder requires the following inputs:
   d0..d7  - the 6502 data bus
   rnw     - the 6502 read / not write output
   sync    - the 6502 sync output

In addition, the following inputs are optional:
   rdy     - the 6502 ready input
   phi2    - the 6502 phi2 clock timing reference

If rdy is not connnected, it is assumed to be high (i.e. no wait states)

IMPORTANT:

If phi2 is not connected, the analyzer must be used in asynchronous capture
mode, with a sampling clock of at least 5x the 6502 clock.

If phi2 is connected, the analyzer must be configured in synchronous capture
mode.

Example sigrok-cli command for asynchronous mode:
=================================================

sigrok-cli \
  -d ols:conn=/dev/ttyUSB1:serialcomm=921600/8n1 \
  --config samplerate=10MHz:external_clock=off:clock_edge=f:captureratio=5 \
  --channels 0-11 \
  --protocol-decoders mos6502:d0=0:d1=1:d2=2:d3=3:d4=4:d5=5:d6=6:d7=7:rnw=8:sync=9:rdy=10:phi2=11 \
  --triggers 8=r \
  --protocol-decoder-annotations mos6502=instr \
  --samples=1000

mos6502-1: E364: LDA #40
mos6502-1: E366: STA 0D00
mos6502-1: E369: SEI
mos6502-1: E36A: LDA #53
mos6502-1: E36C: STA FE8E
mos6502-1: E36F: JSR E590
mos6502-1: E590: LDA #0F
mos6502-1: E592: STA F4
mos6502-1: E594: STA FE30
mos6502-1: E597: RTS
mos6502-1: E372: JMP 8020
mos6502-1: 8020: LDA #FE
mos6502-1: 8022: TRB FE34
mos6502-1: 8025: STZ DFDD
mos6502-1: 8028: TRB 0366
mos6502-1: 802B: CLD
mos6502-1: 802C: LDX #FF
mos6502-1: 802E: TXS
mos6502-1: 802F: STX FE63
mos6502-1: 8032: LDA #CF
mos6502-1: 8034: STA FE42
mos6502-1: 8037: LDY #20
mos6502-1: 8039: LDX #0A
mos6502-1: 803B: JSR 98E4
mos6502-1: 98E4: PHP
mos6502-1: 98E5: SEI
mos6502-1: 98E6: JSR 9906
mos6502-1: 9906: LDA #02
mos6502-1: 9908: STA FE40
mos6502-1: 990B: LDA #82
mos6502-1: 990D: STA FE40
mos6502-1: 9910: LDA #FF
mos6502-1: 9912: STA FE43
mos6502-1: 9915: STX FE4F
mos6502-1: 9918: LDA #C2
mos6502-1: 991A: STA FE40
mos6502-1: 991D: LDA #42
mos6502-1: 991F: STA FE40
mos6502-1: 9922: RTS
mos6502-1: 98E9: LDA #41
mos6502-1: 98EB: STA FE40
mos6502-1: 98EE: LDA #FF
mos6502-1: 98F0: STA FE43
mos6502-1: 98F3: LDA #4A
mos6502-1: 98F5: STA FE40
mos6502-1: 98F8: STY FE4F
mos6502-1: 98FB: BRA 98CC
mos6502-1: 98CC: LDA #42

Example sigrok-cli command for synchronous mode:
================================================

sigrok-cli \
  -d ols:conn=/dev/ttyUSB1:serialcomm=921600/8n1 \
  --config samplerate=2MHz:external_clock=on:clock_edge=f:captureratio=5 \
  --channels 0-11 \
  --protocol-decoders mos6502:d0=0:d1=1:d2=2:d3=3:d4=4:d5=5:d6=6:d7=7:rnw=8:sync=9:rdy=10 \
  --triggers 8=r \
  --protocol-decoder-annotations mos6502=instr \
  --samples=200

mos6502-1: E364: LDA #40
mos6502-1: E366: STA 0D00
mos6502-1: E369: SEI
mos6502-1: E36A: LDA #53
mos6502-1: E36C: STA FE8E
mos6502-1: E36F: JSR E590
mos6502-1: E590: LDA #0F
mos6502-1: E592: STA F4
mos6502-1: E594: STA FE30
mos6502-1: E597: RTS
mos6502-1: E372: JMP 8020
mos6502-1: 8020: LDA #FE
mos6502-1: 8022: TRB FE34
mos6502-1: 8025: STZ DFDD
mos6502-1: 8028: TRB 0366
mos6502-1: 802B: CLD
mos6502-1: 802C: LDX #FF
mos6502-1: 802E: TXS
mos6502-1: 802F: STX FE63
mos6502-1: 8032: LDA #CF
mos6502-1: 8034: STA FE42
mos6502-1: 8037: LDY #20
mos6502-1: 8039: LDX #0A
mos6502-1: 803B: JSR 98E4
mos6502-1: 98E4: PHP
mos6502-1: 98E5: SEI
mos6502-1: 98E6: JSR 9906
mos6502-1: 9906: LDA #02
mos6502-1: 9908: STA FE40
mos6502-1: 990B: LDA #82
mos6502-1: 990D: STA FE40
mos6502-1: 9910: LDA #FF
mos6502-1: 9912: STA FE43
mos6502-1: 9915: STX FE4F
mos6502-1: 9918: LDA #C2
mos6502-1: 991A: STA FE40
mos6502-1: 991D: LDA #42
mos6502-1: 991F: STA FE40
mos6502-1: 9922: RTS
mos6502-1: 98E9: LDA #41
mos6502-1: 98EB: STA FE40
mos6502-1: 98EE: LDA #FF
mos6502-1: 98F0: STA FE43
mos6502-1: 98F3: LDA #4A
mos6502-1: 98F5: STA FE40
mos6502-1: 98F8: STY FE4F
mos6502-1: 98FB: BRA 98CC
mos6502-1: 98CC: LDA #42
'''

from .pd import Decoder
