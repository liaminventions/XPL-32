@echo off
set /p input= "Input File: "
set /p output= "Output File: "
vasm6502_oldstyle -Fbin -dotdir -c02 "%input%" -o "%output%" -L a.list