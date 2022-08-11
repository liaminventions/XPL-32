#!/bin/bash
./asm.sh
./link.sh
cd ../osi_basic-master
./rom.sh
cd ..
./git_add.sh
