# CRC (Nombre provisional) - Utilidad CRC para MSX-DOS

## Descripción
Programa para MSX-DOS que crea y verifica archivos CRC (Cyclic Redundancy Check).
Útil para verificar la integridad de archivos, ROMs, backups, etc.

## Características
- Calcula CRC-16 de cualquier archivo
- Crea archivos .CRC con el checksum
- Verifica archivos contra sus checksums guardados
- Optimizado para MSX (Z80)
- Tamaño pequeño y rápido

## Compilación

### Con SJASM 0.42c
Ve a https://www.xl2s.tk/

Ve al apartado Sjasm -> Descargar SJASM 0.42c

Copia los archivos de este proyecto en una carpeta vacía.

Descomprime el contenido zip en una subcarpeta llamada "sjasm".

Usa el archivo make.bat adjunto para ejecutarlo o escribe manualmente:

sjasm.exe -s crc-sjasm.asm

Tendrás un archivo .out; renómbralo a .com y ¡listo!


## Uso

### Crear archivo CRC:
```
CRC -c ARCHIVO.EXT
```
Esto creará `ARCHIVO.EXT.crc` con el checksum.

### Verificar archivo:
```
CRC -v ARCHIVO.EXT 
```
Esto comparará el archivo con `ARCHIVO.EXT.crc`

## Ejemplos

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

## Formato del archivo .CRC

El archivo .CRC contiene una línea con:
```
<CRC_HEX> <NOMBRE_ARCHIVO>
```

Ejemplo:
```
A5F3 GAME.ROM
```

## Notas técnicas

- Algoritmo: CRC-16 con polinomio 0x8005
- Valor inicial: 0xFFFF
- Tamaño de buffer: 128 bytes (optimizado para MSX)
- Compatible con MSX-DOS 1 y MSX-DOS 2

## Casos de uso

1. **Verificar ROMs**: Asegúrate de que tus ROMs no estén corruptas
2. **Backups**: Verifica que las copias sean idénticas
3. **Transferencias**: Comprueba que los archivos se transfirieron correctamente
4. **Archivos de disco**: Detecta sectores dañados o errores de lectura

## Códigos de retorno

- 0: Éxito (verificación correcta)
- 1: Error (archivo corrupto, no encontrado, etc.)

## Limitaciones

- No soporta wildcards (*.*, etc.)
- Nombres de archivo limitados a 79 caracteres
- Un archivo a la vez

## Autor

Creado por DrWh0

Más proyectos en: 

https://x.com/Dalekamistoso
https://github.com/Dalekamistoso

Versión 1.0
