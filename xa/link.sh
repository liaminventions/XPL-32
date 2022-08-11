#!/bin/bash
cp xpl.BIN ../osi_basic-master/xpl.BIN
cd ../osi_basic-master
cat osi_bas.bin xpl.BIN > ROM.BIN
cd ../xa
