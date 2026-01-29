# CRC.COM - Utilidad CRC para MSX-DOS (29/01/2026)

<img width="1280" height="960" alt="crc-esp" src="https://github.com/user-attachments/assets/bbbd3cea-4d95-4dfb-839e-a668e9c23f73" />

_<u>(English manual & screenshot below the spanish text)</u>_

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
  (El 'make.bat' busca el archivo "sjasm.exe" en la misma ruta de crc.asm)

* Ejecuta "make.bat" adjunto para compilarlo o bien manualmente:

  sjasm.exe -s crc.asm crc.com


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

Versión 2.0 (29/01/2026) - Primera versión pública


----------------------------------------------------
 ## ENGLISH VERSION OF THE USAGE MANUAL 
----------------------------------------------------

# CRC.COM - CRC utility for MSX-DOS (29/01/2026)

<img width="1280" height="960" alt="crc-eng" src="https://github.com/user-attachments/assets/1be620c9-32cb-4f20-b249-98ffeaebd1e8" />

## Description

Program for MSX-DOS that creates & verifies files using CRC (Cyclic Redundancy Check) files.

Useful for verifying the integrity of files, ROMs, backups, etc.

## Features

- Calculates CRC-16 for any file
- Creates .CRC files with checksum data
- Compares files against their saved checksums (verify)
- Supports wildcards (creates a .crc for each file)
- Optimised for MSX (Z80)
- Small size and fast

## Compilation instructions

### SJASM 0.42c (the version I used to create this program):

* Go to https://www.xl2s.tk/

* Download SJASM 0.42c (sjasm42c.zip)

* Copy the files from this project into an empty folder.

* Unzip the contents of the compiler zip file next to this .asm file.
  (The 'make-eng.bat' file looks for the ‘sjasm.exe’ file in the same path as crc-eng.asm)

* Run the attached ‘make-eng.bat’ file to compile it, or do it manually typing:

  sjasm.exe -s crc-eng.asm crc-eng.com


## User manual

* Note: If you run ‘crc’ without parameters, it will display a summary of usage

### Create CRC file:
```
CRC -c FILE.EXT
```
This will create a `FILE.CRC` with the checksum of the `FILE.EXT` file.

### Verify file:
```
CRC -v FILE.EXT 
```
This will search for and compare the original file `FILE.EXT` with the 
information stored in the file `FILE.CRC` in the same directory

## Example:

```
A> CRC -c MIF.EXE
Calculating CRC of “MIF.EXE”
CRC: 7233
Saved to .CRC file (This will create “MIF.CRC”

A> CRC -v  MIF
Verifying “MIF.EXE”...
Calculated CRC: 7233
Saved CRC: 7233
OK - file correct
```

## CRC file format:

Currently implementing CRC16, I plan adding optional CRC32

## Technical notes:

- Algorithm: CRC-16 with polynomial 0x8005
- Initial value: 0xFFFF
- Buffer size: 128 bytes (optimised for MSX)
- Compatible with MSX-DOS 1 and MSX-DOS 2

## Suitable for:

1. **Verifying files**: Ensure that your files are not corrupted
2. **Backups**: Verify that copies are identical and correct
3. **Transfers**: Check that files were transferred correctly
4. **Disk files**: Detect damaged sectors or read errors

## Return codes

- 0: Success (verification correct)
- 1: Error (file corrupt, not found, etc.)

## Current limitations (version 2.0):

- Does not support subdirectories (MSX-DOS1)
- No CRC32 support

## Author:

Created by Dalekamistoso/DrWh0

More projects at: 

https://x.com/Dalekamistoso
https://github.com/Dalekamistoso

Version 2.0 (2026/01/29) - First public version 
