#!/bin/bash
udisksctl mount -b /dev/sda1
vasm6502_oldstyle -Fbin -dotdir -c02 "$1" -o /run/media/$USER/XPL/root/"$2" -L a.list
cd ..
./sd.sh
udisksctl unmount -b /dev/sda1
./git_add.sh
cd vasm6502
