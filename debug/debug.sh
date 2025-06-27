#!/bin/bash
./decode6502 -h -s -c 65c02 --phi2=11 --rst= --sync=9 <"$1" >"$2"
