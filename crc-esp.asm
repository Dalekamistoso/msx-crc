; CRC.ASM - Utilidad CRC para MSX-DOS con soporte de comodines
; Ensamblar con: sjasm crc.asm crc.com
; Creado por DrWh0/Dalekamistoso (version inglesa)
; Modificado para soportar CRC32

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
        
        ; Leer comando (c, c2 o v)
        LD      A,(HL)
        CP      'c'
        JP      Z,CHECK_C2
        CP      'C'
        JP      Z,CHECK_C2
        CP      'v'
        JP      Z,CMD_VERIFY_WILD
        CP      'V'
        JP      Z,CMD_VERIFY_WILD
        JP      HELP

CHECK_C2:
        ; Verificar si es -c2 (CRC32) o solo -c (CRC16)
        INC     HL
        LD      A,(HL)
        CP      '2'
        JP      Z,CMD_CREATE_CRC32
        DEC     HL              ; Volver atras si no es '2'
        JP      CMD_CREATE_WILD

; ============================================
; Comando: Crear archivo CRC32 con comodines
; ============================================
CMD_CREATE_CRC32:
        ; Marcar que usaremos CRC32
        LD      A,1
        LD      (USE_CRC32),A
        JP      CMD_CREATE_WILD_COMMON

; ============================================
; Comando: Crear archivo CRC con comodines
; ============================================
CMD_CREATE_WILD:
        ; Marcar que usaremos CRC16
        XOR     A
        LD      (USE_CRC32),A
        
CMD_CREATE_WILD_COMMON:
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
        
        ; Verificar si usamos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,INIT_CRC32
        
        ; Inicializar CRC16 a 0FFFFh
        LD      HL,0FFFFh
        LD      (CRC_VAL),HL
        JP      READ_LOOP_START
        
INIT_CRC32:
        ; Inicializar CRC32 a 0FFFFFFFFh
        LD      HL,0FFFFh
        LD      (CRC_VAL),HL
        LD      (CRC_VAL+2),HL

READ_LOOP_START:
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
        
        ; Verificar si usamos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,USE_CRC32_UPDATE
        
        CALL    UPDATE_CRC16
        JP      READ_LOOP
        
USE_CRC32_UPDATE:
        CALL    UPDATE_CRC32
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
        
        ; Verificar si mostramos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,SHOW_CRC32
        
        LD      HL,(CRC_VAL)
        CALL    PRINT_HEX16
        JP      SHOW_CRC_DONE
        
SHOW_CRC32:
        LD      HL,(CRC_VAL+2)  ; High word
        CALL    PRINT_HEX16
        LD      HL,(CRC_VAL)    ; Low word
        CALL    PRINT_HEX16
        
SHOW_CRC_DONE:
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
        
        ; Guardar CRC leido y detectar tipo
        LD      A,(CRC_FILE_TYPE)
        LD      (USE_CRC32),A
        
        LD      HL,(CRC_FROM_FILE)
        LD      (SAVED_CRC),HL
        LD      HL,(CRC_FROM_FILE+2)
        LD      (SAVED_CRC+2),HL
        
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
        
        ; Inicializar registro
        XOR     A
        LD      (FCB1+12),A
        LD      (FCB1+32),A
        
        ; Verificar si usamos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,VERIFY_INIT_CRC32
        
        ; Inicializar CRC16
        LD      HL,0FFFFh
        LD      (CRC_VAL),HL
        JP      VERIFY_READ_START
        
VERIFY_INIT_CRC32:
        ; Inicializar CRC32
        LD      HL,0FFFFh
        LD      (CRC_VAL),HL
        LD      (CRC_VAL+2),HL

VERIFY_READ_START:
        ; Establecer buffer
        LD      DE,BUFFER
        LD      C,F_SETDTA
        CALL    BDOS

VERIFY_READ_LOOP:
        LD      DE,FCB1
        LD      C,F_READ
        CALL    BDOS
        OR      A
        JP      NZ,VERIFY_DONE
        
        LD      HL,BUFFER
        LD      BC,128
        
        ; Verificar si usamos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,VERIFY_USE_CRC32
        
        CALL    UPDATE_CRC16
        JP      VERIFY_READ_LOOP
        
VERIFY_USE_CRC32:
        CALL    UPDATE_CRC32
        JP      VERIFY_READ_LOOP

VERIFY_DONE:
        ; Cerrar archivo
        LD      DE,FCB1
        LD      C,F_CLOSE
        CALL    BDOS
        
        ; Mostrar CRC calculado
        LD      DE,MSG_CALC2
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Verificar si mostramos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,VERIFY_SHOW_CRC32
        
        LD      HL,(CRC_VAL)
        CALL    PRINT_HEX16
        JP      VERIFY_SHOW_DONE
        
VERIFY_SHOW_CRC32:
        LD      HL,(CRC_VAL+2)
        CALL    PRINT_HEX16
        LD      HL,(CRC_VAL)
        CALL    PRINT_HEX16
        
VERIFY_SHOW_DONE:
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Mostrar CRC guardado
        LD      DE,MSG_SAVED
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Verificar si mostramos CRC32 o CRC16
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,VERIFY_SHOW_SAVED_CRC32
        
        LD      HL,(SAVED_CRC)
        CALL    PRINT_HEX16
        JP      VERIFY_COMPARE
        
VERIFY_SHOW_SAVED_CRC32:
        LD      HL,(SAVED_CRC+2)
        CALL    PRINT_HEX16
        LD      HL,(SAVED_CRC)
        CALL    PRINT_HEX16
        
VERIFY_COMPARE:
        LD      DE,MSG_CRLF
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Comparar CRCs
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,COMPARE_CRC32
        
        ; Comparar CRC16
        LD      HL,(CRC_VAL)
        LD      DE,(SAVED_CRC)
        OR      A
        SBC     HL,DE
        JP      Z,VERIFY_OK
        JP      VERIFY_BAD
        
COMPARE_CRC32:
        ; Comparar CRC32 (high word)
        LD      HL,(CRC_VAL+2)
        LD      DE,(SAVED_CRC+2)
        OR      A
        SBC     HL,DE
        JP      NZ,VERIFY_BAD
        
        ; Comparar CRC32 (low word)
        LD      HL,(CRC_VAL)
        LD      DE,(SAVED_CRC)
        OR      A
        SBC     HL,DE
        JP      NZ,VERIFY_BAD

VERIFY_OK:
        LD      DE,MSG_OK
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Restaurar DTA de busqueda
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        RET

VERIFY_BAD:
        LD      DE,MSG_BAD
        LD      C,F_STROUT
        CALL    BDOS
        
        ; Restaurar DTA de busqueda
        LD      DE,SEARCHDTA
        LD      C,F_SETDTA
        CALL    BDOS
        RET

; ============================================
; Calcular CRC16
; Entrada: HL = buffer, BC = longitud
; ============================================
UPDATE_CRC16:
        PUSH    BC
        PUSH    DE
        PUSH    HL

UPDATE_LOOP16:
        LD      A,B
        OR      C
        JP      Z,UPDATE_END16
        
        LD      A,(HL)
        LD      DE,(CRC_VAL)
        XOR     E
        LD      E,A
        
        LD      B,8
BIT_LOOP16:
        SRL     D
        RR      E
        JP      NC,NO_XOR16
        
        LD      A,D
        XOR     0A0h
        LD      D,A
        LD      A,E
        XOR     01h
        LD      E,A

NO_XOR16:
        DJNZ    BIT_LOOP16
        
        LD      (CRC_VAL),DE
        
        INC     HL
        POP     BC
        DEC     BC
        PUSH    BC
        JP      UPDATE_LOOP16

UPDATE_END16:
        POP     HL
        POP     DE
        POP     BC
        RET

; ============================================
; Calcular CRC32
; Entrada: HL = buffer, BC = longitud
; Usa el polinomio IEEE 802.3: 0xEDB88320
; ============================================
UPDATE_CRC32:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    IX

UPDATE_LOOP32:
        LD      A,B
        OR      C
        JP      Z,UPDATE_END32
        
        ; XOR byte con low byte del CRC
        LD      A,(HL)
        LD      DE,(CRC_VAL)
        XOR     E
        LD      E,A
        
        ; Cargar high word del CRC en IX
        PUSH    HL
        LD      HL,(CRC_VAL+2)
        PUSH    HL
        POP     IX
        POP     HL
        
        ; Guardar contador de bytes
        PUSH    BC
        
        ; Procesar 8 bits
        LD      B,8
        
BIT_LOOP32:
        ; Verificar bit menos significativo de E
        BIT     0,E
        JP      Z,NO_CARRY32
        
        ; Hay carry (bit 0 = 1), hacer shift y luego XOR con polinomio
        ; Primero hacer shift right de 32 bits
        PUSH    IX
        POP     BC
        SRL     B
        RR      C
        PUSH    BC
        POP     IX
        
        SRL     D
        RR      E
        
        ; Ahora XOR con polinomio 0xEDB88320
        ; Low word: 0x8320
        LD      A,E
        XOR     20h
        LD      E,A
        LD      A,D
        XOR     83h
        LD      D,A
        
        ; High word: 0xEDB8
        PUSH    IX
        POP     BC
        LD      A,C
        XOR     0B8h
        LD      C,A
        LD      A,B
        XOR     0EDh
        LD      B,A
        PUSH    BC
        POP     IX
        
        JP      SHIFT_DONE32
        
NO_CARRY32:
        ; No hay carry, solo hacer shift right de 32 bits
        PUSH    IX
        POP     BC
        SRL     B
        RR      C
        PUSH    BC
        POP     IX
        
        SRL     D
        RR      E

SHIFT_DONE32:
        DJNZ    BIT_LOOP32
        
        ; Guardar resultado
        LD      (CRC_VAL),DE
        PUSH    IX
        POP     DE
        LD      (CRC_VAL+2),DE
        
        ; Restaurar contador de bytes
        POP     BC
        
        INC     HL
        DEC     BC
        LD      A,B
        OR      C
        JP      NZ,UPDATE_LOOP32

UPDATE_END32:
        POP     IX
        POP     HL
        POP     DE
        POP     BC
        RET

; ============================================
; Imprimir nombre de archivo desde FCB1
; ============================================
PRINT_FCB_NAME:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        
        ; Imprimir nombre (8 caracteres)
        LD      HL,FCB1+1
        LD      B,8
PRINT_NAME:
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
        DJNZ    PRINT_NAME

PRINT_EXT:
        ; Imprimir punto
        LD      E,'.'
        LD      C,F_CONOUT
        PUSH    HL
        CALL    BDOS
        POP     HL
        
        ; Imprimir extension (3 caracteres)
        LD      HL,FCB1+9
        LD      B,3
PRINT_EXT_LOOP:
        LD      A,(HL)
        CP      ' '
        JP      Z,PRINT_DONE
        LD      E,A
        LD      C,F_CONOUT
        PUSH    BC
        PUSH    HL
        CALL    BDOS
        POP     HL
        POP     BC
        INC     HL
        DJNZ    PRINT_EXT_LOOP

PRINT_DONE:
        POP     HL
        POP     DE
        POP     BC
        RET

; ============================================
; Imprimir numero hexadecimal de 16 bits
; Entrada: HL = numero
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
        CALL    PRINT_NIB
        POP     AF
        CALL    PRINT_NIB
        RET

PRINT_NIB:
        AND     0Fh
        ADD     A,30h
        CP      3Ah
        JP      C,PRINT_CHAR
        ADD     A,7
PRINT_CHAR:
        LD      E,A
        LD      C,F_CONOUT
        PUSH    HL
        CALL    BDOS
        POP     HL
        RET

; ============================================
; Crear archivo .CRC
; ============================================
CREATE_CRC_FILE:
        ; Copiar FCB1 a CRCFCB
        LD      HL,FCB1
        LD      DE,CRCFCB
        LD      BC,16
        LDIR
        
        ; Cambiar extension a .CRC
        LD      HL,EXT_CRC
        LD      DE,CRCFCB+9
        LD      BC,3
        LDIR
        
        ; Resetear campos
        XOR     A
        LD      (CRCFCB+12),A
        LD      (CRCFCB+14),A
        LD      (CRCFCB+15),A
        LD      (CRCFCB+32),A
        
        ; Crear archivo
        LD      DE,CRCFCB
        LD      C,F_CREATE
        CALL    BDOS
        INC     A
        JP      Z,ERR_CREATE_SKIP
        
        ; Construir contenido del archivo
        LD      HL,BUFFER
        LD      DE,BUFFER
        
        ; Escribir CRC en hexadecimal
        LD      A,(USE_CRC32)
        OR      A
        JP      NZ,WRITE_CRC32_HEX
        
        ; Escribir CRC16 (4 digitos)
        LD      HL,(CRC_VAL)
        CALL    HEX_TO_TEXT
        JP      WRITE_FILENAME
        
WRITE_CRC32_HEX:
        ; Escribir CRC32 (8 digitos)
        LD      HL,(CRC_VAL+2)  ; High word primero
        CALL    HEX_TO_TEXT
        LD      HL,(CRC_VAL)    ; Low word
        CALL    HEX_TO_TEXT

WRITE_FILENAME:
        ; Escribir espacio
        LD      A,' '
        LD      (DE),A
        INC     DE
        
        ; Copiar nombre del archivo (8 caracteres)
        LD      HL,FCB1+1
        LD      B,8

COPY_NAME_LOOP2:
        LD      A,(HL)
        CP      ' '
        JP      Z,COPY_EXT2
        LD      (DE),A
        INC     HL
        INC     DE
        DJNZ    COPY_NAME_LOOP2

COPY_EXT2:
        ; Agregar punto
        LD      A,'.'
        LD      (DE),A
        INC     DE
        
        ; Copiar extension (3 caracteres)
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
; Salida: CRC_FROM_FILE, CRC_FILE_TYPE, Carry = error
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
        
        ; Detectar si es CRC16 o CRC32
        ; CRC16: 4 digitos hex + espacio (posicion 4)
        ; CRC32: 8 digitos hex + espacio (posicion 8)
        LD      A,(BUFFER+4)
        CP      ' '
        JP      Z,IS_CRC16
        
        ; Debe ser CRC32
        LD      A,1
        LD      (CRC_FILE_TYPE),A
        
        ; Parsear 8 caracteres hex
        LD      HL,BUFFER
        CALL    TEXT_TO_HEX32
        JP      CRC_READ_OK
        
IS_CRC16:
        ; Es CRC16
        XOR     A
        LD      (CRC_FILE_TYPE),A
        
        ; Parsear 4 caracteres hex
        LD      HL,BUFFER
        CALL    TEXT_TO_HEX16
        
        ; Limpiar high word
        LD      HL,0
        LD      (CRC_FROM_FILE+2),HL

CRC_READ_OK:
        OR      A               ; Clear carry = OK
        RET

CRC_ERR:
        SCF                     ; Set carry = error
        RET

; ============================================
; Convertir 4 caracteres HEX a numero (CRC16)
; Entrada: HL = puntero al texto
; Salida: CRC_FROM_FILE (16 bits)
; ============================================
TEXT_TO_HEX16:
        LD      DE,0
        LD      B,4

PARSE_HEX16:
        LD      A,(HL)
        SUB     30h
        CP      10
        JP      C,IS_DIGIT16
        SUB     7               ; A-F

IS_DIGIT16:
        ; DE = DE * 16 + A
        PUSH    BC
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
        
        POP     BC
        INC     HL
        DJNZ    PARSE_HEX16
        
        ; Guardar resultado
        LD      (CRC_FROM_FILE),DE
        RET

; ============================================
; Convertir 8 caracteres HEX a numero (CRC32)
; Entrada: HL = puntero al texto
; Salida: CRC_FROM_FILE (32 bits)
; ============================================
TEXT_TO_HEX32:
        ; Parsear primeros 4 digitos (high word)
        PUSH    HL
        CALL    TEXT_TO_HEX16
        LD      HL,(CRC_FROM_FILE)
        LD      (CRC_FROM_FILE+2),HL
        POP     HL
        
        ; Avanzar 4 posiciones
        INC     HL
        INC     HL
        INC     HL
        INC     HL
        
        ; Parsear siguientes 4 digitos (low word)
        CALL    TEXT_TO_HEX16
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
        DB      'CRC v3.0 - Verificador de CRC para MSX-DOS',13,10
        DB      'Programado por DrWh0/Dalekmistoso',13,10
	DB      'Web: https://github.com/Dalekamistoso/msx-crc',13,10
        DB      13,10
        DB      'Uso:',13,10
        DB      '  CRC -c <file>    Crea archivo .CRC (CRC16)',13,10
        DB      '  CRC -c2 <file>   Crea archivo .CRC (CRC32)',13,10
        DB      '  CRC -v <file>    Verificar archivo (auto-detectar)',13,10
        DB      13,10
        DB      'Wildcards supported (* and ?)',13,10
        DB      13,10
        DB      'Examples:',13,10
        DB      '  CRC -c GAME.ROM',13,10
        DB      '  CRC -c2 GAME.ROM',13,10
        DB      '  CRC -v GAME.ROM',13,10
        DB      '  CRC -c *.ROM',13,10
        DB      '  CRC -c2 *.BIN',13,10
        DB      '  CRC -v *.ROM',13,10
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
        DB      'CRC guardado:      $'

MSG_OK:
        DB      'OK - Archivo correcto',13,10,'$'

MSG_BAD:
        DB      'ERROR - Archivo corrupto',13,10,'$'

MSG_SAVED_IN:
        DB      'Guardado en archivo .CRC',13,10,'$'

MSG_ERRFILE:
        DB      'Error: Archivo(s) no encontrado(s)',13,10,'$'

MSG_ERRFILE_SKIP:
        DB      '  Error: No se pudo abrir',13,10,'$'

MSG_ERRCRC_SKIP:
        DB      '  Error: Archivo .CRC no encontrado',13,10,'$'

MSG_ERRCREATE_SKIP:
        DB      '  Error: No se pudo crear archivo .CRC',13,10,'$'

MSG_CRLF:
        DB      13,10,'$'

EXT_CRC:
        DB      'CRC'

; ============================================
; Variables
; ============================================
CRC_VAL:
        DS      4               ; 32 bits para CRC32, solo usa 2 para CRC16

SAVED_CRC:
        DS      4               ; 32 bits

CRC_FROM_FILE:
        DS      4               ; 32 bits

USE_CRC32:
        DB      0               ; 0=CRC16, 1=CRC32

CRC_FILE_TYPE:
        DB      0               ; 0=CRC16, 1=CRC32 (detectado en verificacion)

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
