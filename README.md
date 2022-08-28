# XPL-32
The XPL-32 is a homebrew 6502 laptop, with four 48-pin expansion slots, and a 22-pin I/O port.
 ### XPL-32 stands for:
eXpandable 
Personal 
Laptop 
with 32k ram
# [Blog](unstinkableinventions.wordpress.com)
Here I will post hardware updates to the XPL and more.
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
There is a 6581 SID at $B800 (also in the c64) onboard with its potentiometer (POTX and POTY) and external sound (EXTSND) inputs on the expansion port.
I programmed support to convert most SID files, as well.
# Memory Map
![](https://raw.githubusercontent.com/liaminventions/XPL-32/main/images/memory_map.jpg)
