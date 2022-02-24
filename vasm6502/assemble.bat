#!/bin/bash
set -ex

FILE="${1:-tms}"

vasm6502_oldstyle -chklabels -wfail -x -wdc02 -Fbin -dotdir $FILE.s -o D:\folder\$FILE.xpl