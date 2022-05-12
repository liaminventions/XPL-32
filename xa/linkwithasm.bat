
set /p msg= "Commit Message: "
copy xpls.bin ..\osi_basic-master\
copy ..\SYSMON65-main\SYSMON65-main\sysmon.bin *
copy sysmon.bin ..\osi_basic-master\
cd ..\osi_basic-master\
ca65 osi_bas.s -o osi_bas.o -l
ld65 -C osi_bas.cfg osi_bas.o -o osi_bas.bin
ca65 "osi_bas - Copy.s" -o "osi_bas - Copy.o" -l
ld65 -C "osi_bas - Copy.cfg" "osi_bas - Copy.o" -o "osi_bas - Copy.bin"
COPY /B osi_bas.bin + xpls.bin + sysmon.bin ROM.BIN
cd ..
git add *
git status
git commit -m "%msg%"
git push -u origin main
cd xa
pause