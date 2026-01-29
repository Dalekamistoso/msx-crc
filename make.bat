del crc-sjasm.com
del *.out
del log.txt

sjasm\sjasm.exe -s crc-sjasm.asm > log.txt
copy crc-sjasm.out crc-sjasm.com

type log.txt

pause


