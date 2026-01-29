; CRC.ASM - Versión en ensamblador Z80 para MSX-DOS
; Más compacta y rápida que la versión en C
; Ensamblar con: z80asm crc.asm -o crc.com

    ORG 0100h           ; Origen para .COM en MSX-DOS

; Área de datos
BDOS        EQU 0005h   ; Entrada a BDOS
FCB1        EQU 005Ch   ; FCB del primer parámetro
FCB2        EQU 006Ch   ; FCB del segundo parámetro
DMA         EQU 0080h   ; Buffer DMA por defecto

; Funciones BDOS
F_OPEN      EQU 0Fh     ; Abrir archivo
F_CLOSE     EQU 10h     ; Cerrar archivo
F_SEARCH    EQU 11h     ; Buscar primer archivo
F_READ      EQU 14h     ; Leer secuencial
F_WRITE     EQU 15h     ; Escribir secuencial
F_CREATE    EQU 16h     ; Crear archivo
F_SETDMA    EQU 1Ah     ; Establecer DMA
F_PRINT     EQU 09h     ; Imprimir string

START:
    ; Verificar parámetros
    LD A,(DMA)          ; Primer carácter del parámetro
    CP '-'
    JP NZ,SHOW_HELP
    
    LD A,(DMA+1)        ; Segundo carácter
    CP 'c'
    JP Z,CREATE_CRC
    CP 'C'
    JP Z,CREATE_CRC
    CP 'v'
    JP Z,VERIFY_CRC
    CP 'V'
    JP Z,VERIFY_CRC
    
SHOW_HELP:
    LD DE,MSG_HELP
    LD C,F_PRINT
    CALL BDOS
    RET

CREATE_CRC:
    LD DE,MSG_CREATE
    LD C,F_PRINT
    CALL BDOS
    
    ; Abrir archivo para leer
    LD DE,FCB2
    LD C,F_OPEN
    CALL BDOS
    CP 0FFh
    JP Z,ERROR_OPEN
    
    ; Inicializar CRC
    LD HL,0FFFFh
    LD (CRC_VALUE),HL
    
READ_LOOP:
    ; Leer bloque
    LD DE,FCB2
    LD C,F_READ
    CALL BDOS
    OR A
    JP NZ,READ_DONE     ; EOF o error
    
    ; Calcular CRC del bloque
    LD HL,DMA
    LD BC,128           ; Tamaño del bloque
    CALL CALC_CRC_BLOCK
    
    JP READ_LOOP

READ_DONE:
    ; Cerrar archivo
    LD DE,FCB2
    LD C,F_CLOSE
    CALL BDOS
    
    ; Mostrar CRC
    LD HL,(CRC_VALUE)
    CALL PRINT_CRC
    
    ; TODO: Guardar en archivo .CRC
    
    RET

VERIFY_CRC:
    LD DE,MSG_VERIFY
    LD C,F_PRINT
    CALL BDOS
    ; TODO: Implementar verificación
    RET

; Calcular CRC de un bloque
; HL = puntero al buffer
; BC = tamaño
CALC_CRC_BLOCK:
    PUSH BC
    LD BC,(CRC_VALUE)
    
CRC_BYTE_LOOP:
    LD A,(HL)           ; Leer byte
    XOR B               ; XOR con byte alto de CRC
    LD B,A
    
    LD A,8              ; 8 bits por byte
CRC_BIT_LOOP:
    SLA C               ; Desplazar CRC
    RL B
    JP NC,CRC_NO_XOR
    
    ; XOR con polinomio 0x8005
    LD A,C
    XOR 05h
    LD C,A
    LD A,B
    XOR 80h
    LD B,A
    
CRC_NO_XOR:
    DEC A
    JP NZ,CRC_BIT_LOOP
    
    INC HL
    POP DE
    DEC DE
    PUSH DE
    LD A,D
    OR E
    JP NZ,CRC_BYTE_LOOP
    
    LD (CRC_VALUE),BC
    POP BC
    RET

; Imprimir CRC en hexadecimal
PRINT_CRC:
    LD A,H
    CALL PRINT_HEX
    LD A,L
    CALL PRINT_HEX
    LD DE,MSG_CRLF
    LD C,F_PRINT
    CALL BDOS
    RET

PRINT_HEX:
    PUSH AF
    RRCA
    RRCA
    RRCA
    RRCA
    CALL PRINT_NIBBLE
    POP AF
    CALL PRINT_NIBBLE
    RET

PRINT_NIBBLE:
    AND 0Fh
    ADD A,30h
    CP 3Ah
    JP C,PRINT_DIGIT
    ADD A,7
PRINT_DIGIT:
    LD E,A
    LD C,02h            ; Función BDOS conout
    PUSH HL
    CALL BDOS
    POP HL
    RET

ERROR_OPEN:
    LD DE,MSG_ERROR
    LD C,F_PRINT
    CALL BDOS
    RET

; Mensajes
MSG_HELP:
    DB 'CRC v1.0 - Utilidad CRC para MSX-DOS',13,10
    DB 13,10
    DB 'Uso:',13,10
    DB '  CRC -c <archivo>  Crear .CRC',13,10
    DB '  CRC -v <archivo>  Verificar .CRC',13,10
    DB '$'

MSG_CREATE:
    DB 'Calculando CRC...',13,10,'$'

MSG_VERIFY:
    DB 'Verificando...',13,10,'$'

MSG_ERROR:
    DB 'Error: no se puede abrir el archivo',13,10,'$'

MSG_CRLF:
    DB 13,10,'$'

; Variables
CRC_VALUE:
    DW 0FFFFh

    END START
