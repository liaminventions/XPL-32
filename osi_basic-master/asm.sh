#!/bin/bash
ca65 osi_bas.s -o osi_bas.o -l a.list
ld65 -C osi_bas.cfg osi_bas.o -o osi_bas.bin

ca65 "osi_bas - Copy.s" -o "osi_bas - Copy.o" -l b.list
ld65 -C "osi_bas - Copy.cfg" "osi_bas - Copy.o" -o "osi_bas - Copy.bin"

cd ../xa
./link.sh
