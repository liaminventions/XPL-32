#!/bin/bash
cp xpl.BIN ../osi_basic-master/xpl.BIN
cd ../osi_basic-master
rm ROM.BIN
cp osi_bas.bin ROM.BIN
cat xpl.BIN >> ROM.BIN
cd ../xa
