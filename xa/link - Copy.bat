@echo off
set /p msg= "Commit Message: "
copy xpl.BIN ..\osi_basic_master
cd ..\osi_basic-master
ca65 osi_bas.s -o osi_bas.o -l
ld65 -C osi_bas.cfg osi_bas.o -o osi_bas.bin
ca65 "osi_bas - Copy.s" -o "osi_bas - Copy.o" -l
ld65 -C "osi_bas - Copy.cfg" "osi_bas - Copy.o" -o "osi_bas - Copy.bin"
COPY /B osi_bas.bin + xpl.BIN ROM.BIN
cd xa
pause