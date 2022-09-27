@echo off
set /p input= "Input File: "
set /p output= "Output File: "
vasm6502_oldstyle -L a -Fbin -dotdir -c02 "%input%" -o D:\folder\%output%"