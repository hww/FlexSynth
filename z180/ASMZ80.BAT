asm800 -oson -ob  %1.s -s d:\zilog\zasm\asm816 -l -o  %1.o
mlink  %1.o -e 00000 -s MCODE ICODE WORK -o %1.bin   
mload  %1.bin -i -o  %1.hex 
HEXOBJ %1.HEX %1.COM I
REM mlist %1.o -o %1.lst
