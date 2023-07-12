#!/bin/bash
./asm.sh
./link.sh
cd ../osi_basic-master
./asm.sh
./rom.sh
cd ..
./git_add.sh "$1"
