tools/ca65 osi_bas.s -o osi_bas.o -l
tools/ld65 -C osi_bas.cfg osi_bas.o -o osi_bas.bin

tools/ca65 "osi_bas - Copy.s" -o "osi_bas - Copy.o" -l
tools/ld65 -C "osi_bas - Copy.cfg" "osi_bas - Copy.o" -o "osi_bas - Copy.bin"

COPY /B osi_bas.bin + xpl.BIN ROM.BIN
pause
