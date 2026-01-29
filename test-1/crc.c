/*
 * CRC.COM - Utilidad CRC para MSX-DOS
 * Crea y verifica archivos .CRC
 * Compilar con: sdcc -mz80 --code-loc 0x0100 --data-loc 0 -o crc.com crc.c
 */

#include <stdio.h>
#include <string.h>

#define POLY 0x8005  /* Polinomio CRC-16 */
#define BUFFER_SIZE 128

/* Calcular CRC-16 de un bloque de datos */
unsigned int calc_crc16(unsigned char *data, unsigned int len, unsigned int crc) {
    unsigned int i, j;
    
    for (i = 0; i < len; i++) {
        crc ^= ((unsigned int)data[i]) << 8;
        for (j = 0; j < 8; j++) {
            if (crc & 0x8000)
                crc = (crc << 1) ^ POLY;
            else
                crc <<= 1;
        }
    }
    return crc;
}

/* Calcular CRC de un archivo completo */
int calculate_file_crc(char *filename, unsigned int *result) {
    FILE *fp;
    unsigned char buffer[BUFFER_SIZE];
    unsigned int crc = 0xFFFF;
    size_t bytes;
    
    fp = fopen(filename, "rb");
    if (!fp) {
        printf("Error: no se puede abrir '%s'\r\n", filename);
        return -1;
    }
    
    while ((bytes = fread(buffer, 1, BUFFER_SIZE, fp)) > 0) {
        crc = calc_crc16(buffer, bytes, crc);
    }
    
    fclose(fp);
    *result = crc;
    return 0;
}

/* Crear archivo .CRC */
int create_crc_file(char *filename) {
    unsigned int crc;
    FILE *fp;
    char crcname[80];
    
    printf("Calculando CRC de '%s'...\r\n", filename);
    
    if (calculate_file_crc(filename, &crc) != 0)
        return -1;
    
    /* Crear nombre del archivo .CRC */
    strcpy(crcname, filename);
    strcat(crcname, ".crc");
    
    fp = fopen(crcname, "w");
    if (!fp) {
        printf("Error: no se puede crear '%s'\r\n", crcname);
        return -1;
    }
    
    fprintf(fp, "%04X %s\r\n", crc, filename);
    fclose(fp);
    
    printf("CRC: %04X guardado en '%s'\r\n", crc, crcname);
    return 0;
}

/* Verificar archivo contra su .CRC */
int verify_crc_file(char *filename) {
    unsigned int crc, stored_crc;
    FILE *fp;
    char crcname[80];
    char stored_filename[80];
    
    printf("Verificando '%s'...\r\n", filename);
    
    if (calculate_file_crc(filename, &crc) != 0)
        return -1;
    
    /* Abrir archivo .CRC */
    strcpy(crcname, filename);
    strcat(crcname, ".crc");
    
    fp = fopen(crcname, "r");
    if (!fp) {
        printf("Error: no se encuentra '%s'\r\n", crcname);
        return -1;
    }
    
    fscanf(fp, "%x %s", &stored_crc, stored_filename);
    fclose(fp);
    
    printf("CRC calculado: %04X\r\n", crc);
    printf("CRC guardado:  %04X\r\n", stored_crc);
    
    if (crc == stored_crc) {
        printf("OK - El archivo es correcto\r\n");
        return 0;
    } else {
        printf("ERROR - El archivo esta corrupto o modificado\r\n");
        return -1;
    }
}

/* Mostrar ayuda */
void show_help(void) {
    printf("CRC v1.0 - Utilidad CRC para MSX-DOS\r\n");
    printf("\r\n");
    printf("Uso:\r\n");
    printf("  CRC -c <archivo>  Crear archivo .CRC\r\n");
    printf("  CRC -v <archivo>  Verificar archivo con .CRC\r\n");
    printf("\r\n");
    printf("Ejemplos:\r\n");
    printf("  CRC -c GAME.ROM   (crea GAME.ROM.crc)\r\n");
    printf("  CRC -v GAME.ROM   (verifica contra GAME.ROM.crc)\r\n");
}

/* Programa principal */
int main(int argc, char *argv[]) {
    if (argc != 3) {
        show_help();
        return 1;
    }
    
    if (strcmp(argv[1], "-c") == 0) {
        return create_crc_file(argv[2]);
    } else if (strcmp(argv[1], "-v") == 0) {
        return verify_crc_file(argv[2]);
    } else {
        show_help();
        return 1;
    }
}
