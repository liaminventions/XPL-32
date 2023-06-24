#!/bin/bash
echo "Input: "
read IN
echo "Output: "
read OUT
./tools/vasm6502_oldstyle -Fbin -dotdir -c02 $IN -o $OUT
