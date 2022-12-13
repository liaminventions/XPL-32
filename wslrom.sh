cd osi_basic-master/
ca65 osi_bas.s -o osi_bas.o -l a.list
ld65 -C osi_bas.cfg osi_bas.o -o osi_bas.bin
ca65 "osi_bas - Copy.s" -o "osi_bas - Copy.o" -l b.list
ld65 -C "osi_bas - Copy.cfg" "osi_bas - Copy.o" -o "osi_bas - Copy.bin"
cd ../xa
./xa mon11.a65 -o xpl.BIN
cp xpl.BIN ../osi_basic-master/xpl.BIN
cd ../osi_basic-master
rm ROM.BIN
cp osi_bas.bin ROM.BIN
cat xpl.BIN >> ROM.BIN
cd ../xa