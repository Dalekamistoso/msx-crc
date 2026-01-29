# CRC.COM - Utilidad CRC para MSX-DOS por Dalekamistoso/DrWh0


## Descripción:

Programa para MSX-DOS que crea y verifica archivos empleando ficheros
de CRC (Cyclic Redundancy Check).

Útil para verificar la integridad de archivos, ROMs, backups, etc.

## Características:

- Calcula CRC-16 de cualquier archivo
- Crea archivos .CRC con el checksum
- Verifica archivos contra sus checksums guardados
- Soporta comodines (crea un .crc por cada archivo)
- Optimizado para MSX (Z80)
- Tamaño pequeño y rápido

## Compilación

### Con SJASM 0.42c:

* Ve a https://www.xl2s.tk/

* Descargar SJASM 0.42c (sjasm42c.zip)

* Copia los archivos de este proyecto en una carpeta vacía.

* Descomprime el contenido del zip del compilador junto a este .asm
  (El make.bat busca archivo "sjasm.exe" en la ruta actual)

* Ejecuta make.bat adjunto para compilarlo o escribe manualmente:

  sjasm.exe -s crc-sjasm.asm crc.com


## Manual de uso de la aplicación

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
Esto buscará y comparará el archivo original `ARCHIVO.CRC` con la 
información almacenada en `ARCHIVO.CRC`

## Ejemplos:

```
A> CRC -c GAME.ROM
Calculando CRC de 'GAME.ROM'...
CRC: A5F3 guardado en 'GAME.ROM.crc'

A> CRC -v GAME.ROM
Verificando 'GAME.ROM'...
CRC calculado: A5F3
CRC guardado:  A5F3
OK - El archivo es correcto
```

## Formato del archivo de CRC:

Actualmente implemento CRC16, está previsto añadir CRC32

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

## Limitaciones

- Nombres de archivo limitados a 79 caracteres
- De momento no hay soporte de CRC32

## Autor

Creado por DrWh0

Más proyectos en: 

https://x.com/Dalekamistoso
https://github.com/Dalekamistoso

Versión 2.1 (29/01/2026)
