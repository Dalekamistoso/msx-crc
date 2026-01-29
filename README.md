# CRC.COM - Utilidad CRC para MSX-DOS (29/01/2026)


## Descripción

Programa para MSX-DOS que crea y verifica archivos empleando ficheros
de CRC (Cyclic Redundancy Check).

Útil para verificar la integridad de archivos, ROMs, backups, etc.

## Características

- Calcula CRC-16 de cualquier archivo
- Crea archivos .CRC con el checksum
- Verifica archivos contra sus checksums guardados
- Soporta comodines (crea un .crc por cada archivo)
- Optimizado para MSX (Z80)
- Tamaño pequeño y rápido

## Instrucciones de compilación

### SJASM 0.42c (la versión con la que creé este programa):

* Ve a https://www.xl2s.tk/

* Descargar SJASM 0.42c (sjasm42c.zip)

* Copia los archivos de este proyecto en una carpeta vacía.

* Descomprime el contenido del zip del compilador junto a este .asm
  (El make.bat busca archivo "sjasm.exe" en la misma ruta de crc.asm)

* Ejecuta "make.bat" adjunto para compilarlo o bien manualmente:

  sjasm.exe -s crc-sjasm.asm crc.com


## Manual de uso

* Nota: Si ejecutas "crc" sin parámetros mostrará un resumen de uso

### Crear archivo CRC:
```
CRC -c ARCHIVO.EXT
```
Esto creará un `ARCHIVO.CRC` con el checksum del archivo `ARCHIVO.EXT`.

### Verificar archivo:
```
CRC -v ARCHIVO.EXT 
```
Esto buscará y comparará el archivo original `ARCHIVO.EXT` con la 
información almacenada en el archivo `ARCHIVO.CRC` del mismo directorio

## Ejemplo:

```
A> CRC -c MIF.EXE
Calculando CRC de 'MIF.EXE'
CRC: 7233
Guardado en archivo .CRC (Esto creará 'MIF.CRC'

A> CRC -v  MIF.EXE
Verificando ' MIF.EXE'...
CRC calculado: 7233
CRC guardado:  7233
OK - archivo correcto
```

## Formato del archivo de CRC:

Actualmente implemento CRC16, está previsto añadir CRC32 opcional

## Notas técnicas:

- Algoritmo: CRC-16 con polinomio 0x8005
- Valor inicial: 0xFFFF
- Tamaño de buffer: 128 bytes (optimizado para MSX)
- Compatible con MSX-DOS 1 y MSX-DOS 2

## Indicado para:

1. **Verificar archivos**: Asegúrate que tus archivos no estén corruptos
2. **Backups**: Verifica que las copias sean idénticas y correctas
3. **Transferencias**: Comprueba que los archivos se transfirieron correctamente
4. **Archivos de disco**: Detecta sectores dañados o errores de lectura

## Códigos de retorno

- 0: Éxito (verificación correcta)
- 1: Error (archivo corrupto, no encontrado, etc.)

## Limitaciones actuales (versión 2.0):

- No soporta subdirectorios (MSX-DOS1)
- No hay soporte de CRC32

## Autor:

Creado por Dalekamistoso/DrWh0

Más proyectos en: 

https://x.com/Dalekamistoso
https://github.com/Dalekamistoso

Versión 2.0 (29/01/2026) - Primera versión publicada
