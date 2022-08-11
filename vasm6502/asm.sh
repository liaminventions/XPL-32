#!/bin/bash
echo "Input: "
read IN
echo "Output: "
read OUT
./vasm6502_oldstyle -Fbin -dotdir -c02 $IN -o /mnt/usb/folder/$OUT
