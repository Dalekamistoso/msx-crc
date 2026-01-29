; CRC.ASM - Utilidad CRC para MSX-DOS con soporte de comodines
; Ensamblar con: sjasm crc.asm crc.com

; Constantes del sistema
BDOS        EQU     0005h       ; Entrada a BDOS
FCB1        EQU     005Ch       ; FCB del primer parametro
FCB2        EQU     006Ch       ; FCB del segundo parametro  
DTA         EQU     0080h       ; Disk Transfer Area

; Funciones BDOS
F_CONOUT    EQU     02h         ; Salida de caracter a consola
F_STROUT    EQU     09h         ; Salida de string (termina en $)
F_OPEN      EQU     0Fh         ; Abrir archivo
F_CLOSE     EQU     10h         ; Cerrar archivo
F_SFIRST    EQU     11h         ; Buscar primer archivo
F_SNEXT     EQU     12h         ; Buscar siguiente archivo
F_READ      EQU     14h         ; Leer registro secuencial
F_WRITE     EQU     15h         ; Escribir registro secuencial
F_CREATE    EQU     16h         ; Crear archivo
F_SETDTA    EQU     1Ah         ; Establecer Disk Transfer Area

        ORG     0100h           ; Inicio de programa .COM

START:
        ; Saltar espacios iniciales en DTA
        LD      HL,DTA+1
        LD      A,(DTA)         ; Longitud
        OR      A
        JP      Z,HELP

SKIP_SPACES:
        LD      A,(HL)
        CP      ' '
        JP      NZ,CHECK_DASH
        INC     HL
        JP      SKIP_SPACES

CHECK_DASH:
        CP      '-'
        JP      NZ,HELP
        INC     HL
        
        ; Leer comando (c o v)
        LD      A,(HL)
        CP      'c'
        JP      Z,CMD_CREATE_WILD
        CP      'C'
        JP      Z,CMD_CREATE_WILD
        CP      'v'
        JP      Z,CMD_VERIFY_WILD
        CP      'V'
        JP      Z,CMD_VERIFY_WILD
        JP      HELP

; ============================================
; Comando: Crear archivo CRC con comodines
; ============================================
CMD_CREATE_WILD:
        ; Guardar FCB2 original como patron de busqueda
        LD      HL,FCB2
        LD      DE,SEARCHFCB
        LD      BC,37
        LDIR
        
        ; Verificar si hay patron de busqueda
        LD      A,(FCB2+1)
        CP      ' '
        JP      Z,HELP
        
        ; Establecer DTA para busqueda
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        
        ; Buscar primer archivo
        LD      DE,SEARCHFCB
        LD      C,F_SFIRST
        CALL    BDOS
        INC     A
        JP      Z,ERR_NOFILE    ; No se encontraron archivos
        
CREATE_LOOP:
        ; Copiar nombre encontrado de SEARCHDTA a FCB1
        CALL    COPY_FOUND_TO_FCB1
        
        ; Procesar este archivo
        CALL    PROCESS_CREATE
        
        ; Buscar siguiente archivo
        LD      DE,SEARCHFCB
        LD      C,F_SNEXT
        CALL    BDOS
        INC     A
        JP      NZ,CREATE_LOOP  ; Si hay mas archivos, continuar
        
        ; Terminar
        RET

; ============================================
; Comando: Verificar archivo CRC con comodines
; ============================================
CMD_VERIFY_WILD:
        ; Guardar FCB2 original como patron de busqueda
        LD      HL,FCB2
        LD      DE,SEARCHFCB
        LD      BC,37
        LDIR
        
        ; Verificar si hay patron de busqueda
        LD      A,(FCB2+1)
        CP      ' '
        JP      Z,HELP
        
        ; Establecer DTA para busqueda
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        
        ; Buscar primer archivo
        LD      DE,SEARCHFCB
        LD      C,F_SFIRST
        CALL    BDOS
        INC     A
        JP      Z,ERR_NOFILE
        
VERIFY_LOOP_WILD:
        ; Copiar nombre encontrado de SEARCHDTA a FCB1
        CALL    COPY_FOUND_TO_FCB1
        
        ; Procesar este archivo
        CALL    PROCESS_VERIFY
        
        ; Buscar siguiente archivo
        LD      DE,SEARCHFCB
        LD      C,F_SNEXT
        CALL    BDOS
        INC     A
        JP      NZ,VERIFY_LOOP_WILD
        
        ; Terminar
        RET

; ============================================
; Copiar nombre de archivo encontrado a FCB1
; ============================================
COPY_FOUND_TO_FCB1:
        ; El DTA de busqueda tiene el FCB en offset 0
        ; Copiar drive
        LD      A,(SEARCHDTA)
        LD      (FCB1),A
        
        ; Copiar nombre (8 bytes)
        LD      HL,SEARCHDTA+1
        LD      DE,FCB1+1
        LD      BC,8
        LDIR
        
        ; Copiar extension (3 bytes)
        LD      HL,SEARCHDTA+9
        LD      DE,FCB1+9
        LD      BC,3
        LDIR
        
        ; Limpiar resto del FCB1
        XOR     A
        LD      (FCB1+12),A     ; EX
        LD      (FCB1+13),A     ; S1
        LD      (FCB1+14),A     ; S2
        LD      (FCB1+15),A     ; RC
        LD      HL,0
        LD      (FCB1+16),HL    ; D0-D1
        LD      (FCB1+18),HL    ; D2-D3
        LD      (FCB1+20),HL    ; D4-D5
        LD      (FCB1+22),HL    ; D6-D7
        LD      (FCB1+24),HL    ; D8-D9
        LD      (FCB1+26),HL    ; D10-D11
        LD      (FCB1+28),HL    ; D12-D13
        LD      (FCB1+30),HL    ; D14-D15
        XOR     A
        LD      (FCB1+32),A     ; CR
        LD      (FCB1+33),HL    ; R0-R1
        LD      (FCB1+35),HL    ; R2-R3
        
        RET

; ============================================
; Procesar un archivo para crear CRC
; ============================================
PROCESS_CREATE:
        ; Mostrar mensaje
        LD      DE,MSG_CALC
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Mostrar nombre del archivo
        CALL    PRINT_FCB_NAME
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Restaurar DTA normal
        LD      DE,DTA
        LD      C,F_SETDTA
        CALL    BDOS
        
        ; Abrir archivo para lectura
        LD      DE,FCB1
        LD      C,F_OPEN
        CALL    BDOS
        INC     A
        JP      Z,ERR_NOFILE_SKIP
        
        ; Inicializar registro de lectura
        XOR     A
        LD      (FCB1+12),A     ; EX = 0
        LD      (FCB1+14),A     ; S1 = 0
        LD      (FCB1+15),A     ; S2 = 0
        LD      (FCB1+32),A     ; CR = 0
        
        ; Inicializar CRC a 0FFFFh
        LD      HL,0FFFFh
        LD      (CRC_VAL),HL
        
        ; Establecer buffer de lectura
        LD      DE,BUFFER
        LD      C,F_SETDTA
        CALL    BDOS

READ_LOOP:
        ; Leer siguiente registro (128 bytes)
        LD      DE,FCB1
        LD      C,F_READ
        CALL    BDOS
        OR      A
        JP      NZ,READ_DONE
        
        ; Calcular CRC del bloque leido
        LD      HL,BUFFER
        LD      BC,128
        CALL    UPDATE_CRC
        
        JP      READ_LOOP

READ_DONE:
        ; Cerrar archivo de entrada
        LD      DE,FCB1
        LD      C,F_CLOSE
        CALL    BDOS
        
        ; Mostrar CRC calculado
        LD      DE,MSG_CRC
        LD      C,F_STROUT
        CALL    BDOS
        
        LD      HL,(CRC_VAL)
        CALL    PRINT_HEX16
        
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Crear archivo .CRC
        CALL    CREATE_CRC_FILE
        
        ; Restaurar DTA de busqueda
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        
        RET

; ============================================
; Procesar un archivo para verificar CRC
; ============================================
PROCESS_VERIFY:
        ; Guardar FCB1 en SAVEFCB
        LD      HL,FCB1
        LD      DE,SAVEFCB
        LD      BC,37
        LDIR
        
        ; Mostrar mensaje
        LD      DE,MSG_VERIFY
        LD      C,F_STROUT
        CALL    BDOS
        
        CALL    PRINT_FCB_NAME
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Restaurar DTA normal
        LD      DE,DTA
        LD      C,F_SETDTA
        CALL    BDOS
        
        ; Primero leer el archivo .CRC
        CALL    READ_CRC_FILE
        JP      C,ERR_NOCRC_SKIP
        
        ; Guardar CRC leido
        LD      HL,(CRC_FROM_FILE)
        LD      (SAVED_CRC),HL
        
        ; Restaurar FCB1 original
        LD      HL,SAVEFCB
        LD      DE,FCB1
        LD      BC,37
        LDIR
        
        ; Resetear el FCB1 para apertura
        XOR     A
        LD      (FCB1+12),A     ; EX = 0
        LD      (FCB1+14),A     ; S1 = 0
        LD      (FCB1+15),A     ; S2 = 0
        LD      (FCB1+32),A     ; CR = 0
        
        ; Abrir el archivo original
        LD      DE,FCB1
        LD      C,F_OPEN
        CALL    BDOS
        INC     A
        JP      Z,ERR_NOFILE_SKIP
        
        ; Calcular CRC del archivo
        LD      HL,0FFFFh
        LD      (CRC_VAL),HL
        
        LD      DE,BUFFER
        LD      C,F_SETDTA
        CALL    BDOS

VERIFY_LOOP:
        LD      DE,FCB1
        LD      C,F_READ
        CALL    BDOS
        OR      A
        JP      NZ,VERIFY_DONE
        
        LD      HL,BUFFER
        LD      BC,128
        CALL    UPDATE_CRC
        
        JP      VERIFY_LOOP

VERIFY_DONE:
        LD      DE,FCB1
        LD      C,F_CLOSE
        CALL    BDOS
        
        ; Mostrar CRCs
        LD      DE,MSG_CALC2
        LD      C,F_STROUT
        CALL    BDOS
        
        LD      HL,(CRC_VAL)
        CALL    PRINT_HEX16
        
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        LD      DE,MSG_SAVED
        LD      C,F_STROUT
        CALL    BDOS
        
        LD      HL,(SAVED_CRC)
        CALL    PRINT_HEX16
        
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Comparar
        LD      HL,(CRC_VAL)
        LD      DE,(SAVED_CRC)
        OR      A
        SBC     HL,DE
        JP      Z,VERIFY_OK
        
        ; Error: no coinciden
        LD      DE,MSG_BAD
        LD      C,F_STROUT
        CALL    BDOS
        JP      VERIFY_RESTORE_DTA

VERIFY_OK:
        LD      DE,MSG_OK
        LD      C,F_STROUT
        CALL    BDOS

VERIFY_RESTORE_DTA:
        ; Restaurar DTA de busqueda
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        
        RET

; ============================================
; Calcular CRC-16 de un bloque
; Entrada: HL = puntero al buffer
;          BC = tamano del buffer
; ============================================
UPDATE_CRC:
        ; Guardar el contador de bytes
        PUSH    BC
        
        ; Cargar el CRC actual en DE
        LD      DE,(CRC_VAL)

CRC_LOOP:
        ; Obtener byte del buffer
        LD      A,(HL)
        
        ; XOR con parte alta del CRC
        XOR     D
        LD      D,A
        
        ; Procesar 8 bits
        PUSH    BC
        LD      B,8

BIT_LOOP:
        ; Shift left del CRC (DE)
        SLA     E
        RL      D
        JP      NC,NO_XOR
        
        ; XOR con polinomio 0x8005
        LD      A,E
        XOR     05h
        LD      E,A
        LD      A,D
        XOR     80h
        LD      D,A

NO_XOR:
        DJNZ    BIT_LOOP
        
        POP     BC
        
        ; Siguiente byte
        INC     HL
        DEC     BC
        
        ; Verificar si quedan bytes
        LD      A,B
        OR      C
        JP      NZ,CRC_LOOP
        
        ; Guardar resultado
        LD      (CRC_VAL),DE
        
        ; Restaurar BC original
        POP     BC
        RET

; ============================================
; Imprimir numero hexadecimal de 16 bits
; Entrada: HL = numero a imprimir
; ============================================
PRINT_HEX16:
        LD      A,H
        CALL    PRINT_HEX8
        LD      A,L
        CALL    PRINT_HEX8
        RET

PRINT_HEX8:
        PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    PRINT_NIBBLE
        POP     AF
        CALL    PRINT_NIBBLE
        RET

PRINT_NIBBLE:
        AND     0Fh
        ADD     A,30h           ; '0'
        CP      3Ah             ; '9'+1
        JP      C,PRINT_CHAR
        ADD     A,7             ; Ajuste para A-F

PRINT_CHAR:
        LD      E,A
        LD      C,F_CONOUT
        PUSH    HL
        CALL    BDOS
        POP     HL
        RET

; ============================================
; Imprimir nombre del archivo desde FCB1
; ============================================
PRINT_FCB_NAME:
        LD      HL,FCB1+1
        LD      B,8
        PUSH    BC
        PUSH    HL

PRINT_NAME_LOOP:
        LD      A,(HL)
        CP      ' '
        JP      Z,PRINT_EXT
        LD      E,A
        LD      C,F_CONOUT
        PUSH    BC
        PUSH    HL
        CALL    BDOS
        POP     HL
        POP     BC
        INC     HL
        DJNZ    PRINT_NAME_LOOP

PRINT_EXT:
        LD      E,'.'
        LD      C,F_CONOUT
        PUSH    BC
        CALL    BDOS
        POP     BC
        
        POP     HL
        POP     BC
        LD      HL,FCB1+9
        LD      B,3
        PUSH    BC
        PUSH    HL

PRINT_EXT_LOOP:
        LD      A,(HL)
        CP      ' '
        JP      Z,END_PRINT_NAME
        LD      E,A
        LD      C,F_CONOUT
        PUSH    BC
        PUSH    HL
        CALL    BDOS
        POP     HL
        POP     BC
        INC     HL
        DJNZ    PRINT_EXT_LOOP

END_PRINT_NAME:
        POP     HL
        POP     BC
        RET

; ============================================
; Crear archivo .CRC con el CRC calculado
; ============================================
CREATE_CRC_FILE:
        ; Copiar FCB1 a CRCFCB y cambiar extension
        LD      HL,FCB1
        LD      DE,CRCFCB
        LD      BC,16
        LDIR
        
        ; Cambiar extension a .CRC
        LD      HL,EXT_CRC
        LD      DE,CRCFCB+9
        LD      BC,3
        LDIR
        
        ; Resetear campos del FCB
        XOR     A
        LD      (CRCFCB+12),A   ; EX = 0
        LD      (CRCFCB+14),A   ; S1 = 0
        LD      (CRCFCB+15),A   ; S2 = 0
        LD      (CRCFCB+32),A   ; CR = 0
        
        ; Borrar archivo si existe
        LD      DE,CRCFCB
        LD      C,13h           ; Delete file
        CALL    BDOS
        
        ; Crear archivo nuevo
        LD      DE,CRCFCB
        LD      C,F_CREATE
        CALL    BDOS
        INC     A
        JP      Z,ERR_CREATE_SKIP
        
        ; Inicializar registro
        XOR     A
        LD      (CRCFCB+32),A
        
        ; Preparar buffer con el CRC en formato texto
        LD      HL,(CRC_VAL)
        LD      DE,BUFFER
        CALL    HEX_TO_TEXT
        
        ; Agregar espacio
        LD      A,' '
        LD      (DE),A
        INC     DE
        
        ; Agregar nombre del archivo
        LD      HL,FCB1+1
        LD      B,8

COPY_NAME2:
        LD      A,(HL)
        CP      ' '
        JP      Z,COPY_EXT2
        LD      (DE),A
        INC     HL
        INC     DE
        DJNZ    COPY_NAME2

COPY_EXT2:
        LD      A,'.'
        LD      (DE),A
        INC     DE
        
        LD      HL,FCB1+9
        LD      B,3

COPY_EXT_LOOP2:
        LD      A,(HL)
        CP      ' '
        JP      Z,END_COPY
        LD      (DE),A
        INC     HL
        INC     DE
        DJNZ    COPY_EXT_LOOP2

END_COPY:
        ; Agregar CR+LF
        LD      A,13
        LD      (DE),A
        INC     DE
        LD      A,10
        LD      (DE),A
        INC     DE
        
        ; Rellenar resto con EOF (1Ah)
        LD      A,1Ah
FILL_EOF:
        LD      (DE),A
        INC     DE
        LD      A,E
        AND     7Fh             ; Hasta completar 128 bytes
        JP      NZ,FILL_EOF
        
        ; Escribir al archivo
        LD      DE,BUFFER
        LD      C,F_SETDTA
        CALL    BDOS
        
        LD      DE,CRCFCB
        LD      C,F_WRITE
        CALL    BDOS
        
        ; Cerrar archivo
        LD      DE,CRCFCB
        LD      C,F_CLOSE
        CALL    BDOS
        
        ; Mensaje
        LD      DE,MSG_SAVED_IN
        LD      C,F_STROUT
        CALL    BDOS
        
        RET

; ============================================
; Convertir HEX (HL) a texto en (DE)
; ============================================
HEX_TO_TEXT:
        LD      A,H
        CALL    HEX8_TO_TEXT
        LD      A,L
        CALL    HEX8_TO_TEXT
        RET

HEX8_TO_TEXT:
        PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    NIB_TO_TEXT
        POP     AF
        CALL    NIB_TO_TEXT
        RET

NIB_TO_TEXT:
        AND     0Fh
        ADD     A,30h
        CP      3Ah
        JP      C,STORE_CHAR
        ADD     A,7
STORE_CHAR:
        LD      (DE),A
        INC     DE
        RET

; ============================================
; Leer CRC del archivo .CRC
; Salida: HL = CRC leido, Carry = error
; ============================================
READ_CRC_FILE:
        ; Copiar FCB1 a CRCFCB y cambiar extension
        LD      HL,FCB1
        LD      DE,CRCFCB
        LD      BC,16
        LDIR
        
        ; Cambiar extension a .CRC
        LD      HL,EXT_CRC
        LD      DE,CRCFCB+9
        LD      BC,3
        LDIR
        
        ; Resetear campos del FCB
        XOR     A
        LD      (CRCFCB+12),A   ; EX = 0
        LD      (CRCFCB+14),A   ; S1 = 0
        LD      (CRCFCB+15),A   ; S2 = 0
        LD      (CRCFCB+32),A   ; CR = 0
        
        ; Abrir archivo .CRC
        LD      DE,CRCFCB
        LD      C,F_OPEN
        CALL    BDOS
        INC     A
        JP      Z,CRC_ERR
        
        ; Inicializar registro
        XOR     A
        LD      (CRCFCB+32),A
        
        ; Leer primer registro
        LD      DE,BUFFER
        LD      C,F_SETDTA
        CALL    BDOS
        
        LD      DE,CRCFCB
        LD      C,F_READ
        CALL    BDOS
        OR      A
        JP      NZ,CRC_ERR
        
        ; Cerrar archivo
        LD      DE,CRCFCB
        LD      C,F_CLOSE
        CALL    BDOS
        
        ; Parsear los primeros 4 caracteres como HEX
        LD      HL,BUFFER
        CALL    TEXT_TO_HEX
        
        ; Guardar en variable temporal
        LD      (CRC_FROM_FILE),HL
        
        OR      A               ; Clear carry = OK
        RET

CRC_ERR:
        SCF                     ; Set carry = error
        RET

; ============================================
; Convertir 4 caracteres HEX a numero
; Entrada: HL = puntero al texto
; Salida: HL = numero
; ============================================
TEXT_TO_HEX:
        LD      DE,0
        LD      B,4

PARSE_HEX:
        LD      A,(HL)
        SUB     30h
        CP      10
        JP      C,IS_DIGIT
        SUB     7               ; A-F

IS_DIGIT:
        ; DE = DE * 16 + A
        PUSH    BC              ; Guardar B (contador)
        PUSH    HL
        LD      H,D
        LD      L,E
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      D,H
        LD      E,L
        POP     HL
        
        LD      C,A
        LD      B,0
        EX      DE,HL
        ADD     HL,BC
        EX      DE,HL
        
        POP     BC              ; Restaurar B (contador)
        INC     HL
        DJNZ    PARSE_HEX
        
        EX      DE,HL
        RET

; ============================================
; Mostrar ayuda
; ============================================
HELP:
        LD      DE,MSG_HELP
        LD      C,F_STROUT
        CALL    BDOS
        RET

; ============================================
; Errores
; ============================================
ERR_NOFILE:
        LD      DE,MSG_ERRFILE
        LD      C,F_STROUT
        CALL    BDOS
        RET

ERR_NOFILE_SKIP:
        LD      DE,MSG_ERRFILE_SKIP
        LD      C,F_STROUT
        CALL    BDOS
        ; Restaurar DTA de busqueda antes de continuar
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        RET

ERR_NOCRC_SKIP:
        LD      DE,MSG_ERRCRC_SKIP
        LD      C,F_STROUT
        CALL    BDOS
        ; Restaurar DTA de busqueda antes de continuar
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        RET

ERR_CREATE_SKIP:
        LD      DE,MSG_ERRCREATE_SKIP
        LD      C,F_STROUT
        CALL    BDOS
        RET

; ============================================
; Mensajes
; ============================================
MSG_HELP:
        DB      'MSX-CRC v2.0 - Verificador CRC para MSX-DOS',13,10
        DB      'Creado por DrWh0/Dalekmistoso',13,10
		DB      'Web: https://github.com/Dalekamistoso/msx-crc',13,10
                DB      13,10
        DB      'Uso:',13,10
        DB      '  CRC -c <archivo>   Crear archivo .CRC',13,10
        DB      '  CRC -v <archivo>   Verificar archivo',13,10
        DB      13,10
        DB      'Soporta comodines (* y ?)',13,10
        DB      13,10
        DB      'Ejemplos:',13,10
        DB      '  CRC -c GAME.ROM',13,10
        DB      '  CRC -v GAME.ROM',13,10
        DB      '  CRC -c *.ROM',13,10
        DB      '  CRC -v *.BIN',13,10
        DB      '$'

MSG_CALC:
        DB      'Calculando CRC de: $'

MSG_VERIFY:
        DB      'Verificando: $'

MSG_CRC:
        DB      'CRC: $'

MSG_CALC2:
        DB      'CRC calculado: $'

MSG_SAVED:
        DB      'CRC guardado:  $'

MSG_OK:
        DB      'OK - Archivo correcto',13,10,'$'

MSG_BAD:
        DB      'ERROR - Archivo corrupto',13,10,'$'

MSG_SAVED_IN:
        DB      'Guardado en archivo .CRC',13,10,'$'

MSG_ERRFILE:
        DB      'Error: No se encontraron archivos',13,10,'$'

MSG_ERRFILE_SKIP:
        DB      '  Error: No se puede abrir',13,10,'$'

MSG_ERRCRC_SKIP:
        DB      '  Error: No se encuentra archivo .CRC',13,10,'$'

MSG_ERRCREATE_SKIP:
        DB      '  Error: No se puede crear archivo .CRC',13,10,'$'

MSG_CRLF:
        DB      13,10,'$'

EXT_CRC:
        DB      'CRC'

; ============================================
; Variables
; ============================================
CRC_VAL:
        DW      0FFFFh

SAVED_CRC:
        DW      0

CRC_FROM_FILE:
        DW      0

CRCFCB:
        DS      37              ; FCB para archivo .CRC

SAVEFCB:
        DS      37              ; FCB guardado para restaurar

SEARCHFCB:
        DS      37              ; FCB para busqueda con comodines

SEARCHDTA:
        DS      128             ; DTA para busqueda de archivos

BUFFER:
        DS      128             ; Buffer de lectura
