@echo off
REM Script de compilación para CRC.COM (MSX-DOS) en Windows
REM Requiere SDCC instalado en Windows

echo Compilando CRC.COM para MSX-DOS...
echo.

REM Compilar con SDCC
sdcc -mz80 --code-loc 0x0100 --data-loc 0 --no-std-crt0 -o crc.ihx crc.c

if errorlevel 1 (
    echo.
    echo Error en la compilacion
    pause
    exit /b 1
)

REM Convertir .ihx a .com
hex2bin -e com crc.ihx

if errorlevel 1 (
    echo.
    echo Error al convertir a .COM
    pause
    exit /b 1
)

echo.
echo Compilacion exitosa! Archivo: crc.com
echo.
echo El archivo crc.com esta listo para copiar a tu MSX
pause
