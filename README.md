# XPL-32
![](https://raw.githubusercontent.com/liaminventions/XPL-32/main/images/xpl.png)
[![Assemble ROM](https://github.com/liaminventions/XPL-32/actions/workflows/rom.yml/badge.svg)](https://github.com/liaminventions/XPL-32/actions/workflows/rom.yml/badge.svg)

The XPL-32 is a homebrew 8-bit 6502 laptop, with four 48-pin expansion slots, and a 22-pin I/O port.
 ### XPL-32 stands for:
eXpandable 
Personal 
Laptop 
with 32k ram
# [Blog](https://unstinkableinventions.wordpress.com/)
Here I will post hardware updates to the XPL and more.

Also, be sure to check info.txt to know if there are any issues when i code.
# Hardware Overview
## CPU
A 6502, of course. A W65C02 to be exact. 

[Datasheet](https://eater.net/datasheets/w65c02s.pdf)
## I/O
For the I/O, I've got a W65C22 VIA. Port A, Port B and the handshake bits connect to the I/O slot.
However PA7 is connected to the Video Switch Relay (VSR)
[W65C22 Datasheet](https://eater.net/datasheets/w65c22.pdf)
## Video
The XPL-32 has an expandable monochrome terminal display that uses a 6551 ACIA  at $8000 and two arduinos.
[This is the video and keyboard processer. (not made by me)](http://searle.x10host.com/MonitorKeyboard/index.html)
The video can be switched to the composite input EXTVID (on the expansion port) by toggling the VSR. (a relay that switches beetween native video and EXTVID.)

So far, for Video expansions, I've made a TMS9918a one. (the same video processer used in the TI-99/4a and the MSX)
## Sound
There is a 6581 SID at $B800 ($D400 in the c64) onboard with its potentiometer (POTX and POTY) and external sound (EXTSND) inputs on the expansion port.
I programmed support to convert most SID files, as well.
# Memory Map
![](https://raw.githubusercontent.com/liaminventions/XPL-32/main/images/memory_map.jpg)
# Tools I Use
## PCB Design
I currently use [EAGLE](https://www.autodesk.com/products/eagle/free-download)
## 3D Modeling
[Fusion 360](https://www.autodesk.com/products/fusion-360/overview?us_oa=dotcom-us&us_si=4e5471dc-07ed-4416-80c0-6f3e9f7c15b4&us_pt=NINVFUS&us_at=%5Bobject%20Object%5D&term=1-YEAR&tab=subscription&plc=F360)
## Coding
[VIM](https://www.vim.org/) or [vscode](https://code.visualstudio.com/) for coding.
[xa](https://github.com/pfusik/xasm), [ca65](https://github.com/cc65/cc65) (from cc65), and [vasm](http://sun.hasenbraten.de/vasm/) for assembly.

I have "xa 6502 cross assembler" syntax highlighting in vim, and the "vasm" extension in vscode.

most source files are .s, but some are .a65 or .asm
