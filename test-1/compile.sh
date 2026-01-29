#!/bin/bash
# Script de compilación para CRC.COM (MSX-DOS)

echo "Compilando CRC.COM para MSX-DOS..."

# Opción 1: Con SDCC (recomendado)
sdcc -mz80 --code-loc 0x0100 --data-loc 0 --no-std-crt0 -o crc.ihx crc.c

if [ $? -eq 0 ]; then
    # Convertir .ihx a .com
    hex2bin -e com crc.ihx
    echo "¡Compilación exitosa! Archivo: crc.com"
else
    echo "Error en la compilación"
    exit 1
fi

# Opción 2: Para Hi-Tech C (descomentar si usas Hi-Tech C)
# c -v -O -Ml crc.c -ocrc.com
