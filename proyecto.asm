section .data
    msg_ingresa db "Ingresa una cadena (max 50): ", 0   ; Mensaje que se mostrará al usuario para pedir la cadena
    len_ingresa equ $ - msg_ingresa                     ; Longitud del mensaje anterior

    msg_otro db "Deseas realizar otro? (s/n): ", 0      ; Mensaje para preguntar si desea repetir
    len_otro equ $ - msg_otro                           ; Longitud del mensaje anterior

    ; Definir mensajes de error para cuando la cadena ingresada exceda el límite de 50 caracteres
    msg_error_longitud db "La cadena ingresada excede el limite de 50 caracteres.", 0xA, 0 
    len_error_longitud equ $ - msg_error_longitud

    ; Nuevos mensajes para la funcionalidad de vocal
    msg_ingresa_vocal db "Ingresa una vocal (a, e, i, o, u): ", 0
    len_ingresa_vocal equ $ - msg_ingresa_vocal

    msg_error_vocal db "Error: Debes ingresar solo un caracter de vocal.", 10
    len_error_vocal equ $ - msg_error_vocal

    max_caracteres equ 50  ; Definirmos una variable para el límite maximo de caracteres de la cadena

section .bss
    buffer resb max_caracteres + 1      ; Reservar 51 bytes para la cadena (50 caracteres + '\n')
    respuesta resb 2    ; Reservar 2 bytes para respuesta del usuario ('s' o 'n' + '\n')
    longitud resb 1     ; Reservar 1 byte para almacenar la cantidad de caracteres leídos

section .text
    global _start       ; Punto de entrada del programa

_start:
IngresarCadena:
    ; Mostrar mensaje para ingresar cadena
    mov rax, 1              ; syscall write
    mov rdi, 1              ; file descriptor 1 (stdout)
    mov rsi, msg_ingresa    ; dirección del mensaje
    mov rdx, len_ingresa    ; longitud del mensaje
    syscall                 ; llama a write(1, msg_ingresa, len_ingresa)

    ; Leer cadena
    mov rax, 0              ; syscall read
    mov rdi, 0              ; file descriptor 0 (stdin)
    mov rsi, buffer         ; dirección donde guardar la cadena leída
    mov rdx, max_caracteres + 1 ; máximo de bytes a leer (50 + '\n')
    syscall                 ; llama a read(0, buffer, 51)

    mov [longitud], al      ; guardar en 'longitud' el número de bytes leídos (valor devuelto por read en rax)
    call ValidarLongitud    ; llamamos la etiqueta para validar la longitud de la cadena

IngresarVocal:
    ; Mostrar mensaje para ingresar vocal
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_ingresa_vocal
    mov rdx, len_ingresa_vocal
    syscall

    ; Leer hasta 51 bytes (para capturar toda la línea si es larga)
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, max_caracteres + 1
    syscall

    mov [longitud], al          ; guardar la cantidad leída

    ; Validar que sea solo 1 carácter + '\n' = 2 bytes
    cmp byte [longitud], 2
    je .vocal_valida

    ; Mostrar mensaje de error
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error_vocal
    mov rdx, len_error_vocal
    syscall

    ; Limpiar buffer SOLO si se leyeron 51 bytes (exceso de caracteres)
    cmp byte [longitud], max_caracteres + 1
    je .limpiar_buffer
    jmp IngresarVocal           ; volver a pedir la vocal sin limpiar

.limpiar_buffer:
    call LimpiarBufferEntrada   ; limpiar stdin solo si hay exceso
    jmp IngresarVocal

.vocal_valida:
    ; Continuar con el flujo normal
    jmp RealizarOtro

RealizarOtro:
    ; Preguntar al usuario si desea realizar otra operación
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, msg_otro       ; dirección del mensaje
    mov rdx, len_otro       ; longitud del mensaje
    syscall                 ; muestra mensaje "Deseas realizar otro?"

    ; Leer respuesta
    mov rax, 0              ; syscall read
    mov rdi, 0              ; stdin
    mov rsi, respuesta      ; buffer donde guardar la respuesta ('s' o 'n')
    mov rdx, 2              ; leer máximo 2 bytes ('s'/'n' + '\n')
    syscall                 ; leer respuesta del usuario

    ; Evaluar si se repite
    mov al, [respuesta]     ; cargar primer carácter de la respuesta
    cmp al, 's'             ; comparar si es 's'
    je IngresarCadena       ; si es 's', saltar a IngresarCadena para repetir el proceso

    ; Terminar programa
    mov rax, 60             ; syscall exit
    xor rdi, rdi            ; exit code 0
    syscall                 ; terminar el programa limpiamente

; ================================================================
; SUBRUTINA ValidarLongitud
; Entrada:
;   - RAX: Longitud de bytes leídos (incluyendo '\n' si existe)
;   - RSI: Puntero al buffer con la cadena ingresada
; Salida:
;   - Si es válida: Continúa ejecución (ret)
;   - Si no es válida: Muestra error y reinicia el proceso (jmp IngresarCadena)
; ================================================================
ValidarLongitud:
    ; Verificamos si la lectura incluye el '\n' (cuando el usuario presiona Enter)
    cmp byte [rsi + rax - 1], 0xA      ; Aqui comparamos si el último carácter es '\n' que en ASCII es 0xA
    je .tiene_salto_linea              ; Si es '\n', saltamos al siguiente paso tiene_salto_linea
    
    ; Si no tiene newline, entonces el usuario ingreso exactamente los 50 caracteres (sin Enter) 
    cmp rax, max_caracteres        ; Compara longitud con máximo permitido (50)
    jbe .longitud_valida           ; Si es menor o igual, entonces es una cadena válida
    
    ; Mostrar error cuando la Cadena excede límite (caso sin newline)
    jmp .mostrar_error_longitud

.tiene_salto_linea:
    ; Verificamos si la lectura incluye el '\n' (cuando el usuario presiona Enter)
    cmp rax, max_caracteres+1      ; Compara con 51 (50 caracteres + '\n')
    jbe .longitud_valida           ; Si longitud ≤ 51, entonces es una cadena válida

.mostrar_error_longitud:
    mov rax, 1                     ; Código de syscall para write
    mov rdi, 1                     ; Descriptor de archivo (stdout)
    mov rsi, msg_error_longitud    ; Puntero al mensaje de error
    mov rdx, len_error_longitud    ; Longitud del mensaje de error
    syscall                        ; Ejecutar syscall
    
    call LimpiarBufferEntrada      
    jmp IngresarCadena

.longitud_valida:
    ret     ; Retornar del subprograma

; ================================================================
; SUBRUTINA LimpiarBufferEntrada
; Limpia stdin leyendo bytes hasta encontrar un '\n' (salto de línea)
; Entrada:
;   - RSI: Puntero al buffer donde se guardará la cadena
; Salida:
;   - Si no encontramos '\n', seguimos limpiando
;   - Si encontramos '\n', retornamos
; ================================================================
LimpiarBufferEntrada:
    mov rsi, buffer    ; reutilizamos el buffer, leeremos 1 byte a la vez
.limpiar_loop:
    mov rax, 0         ; syscall read
    mov rdi, 0         ; stdin
    mov rdx, 1         ; leer 1 byte
    syscall

    cmp byte [rsi], 0xA   ; verificamos si el byte leido es '\n' (salto de línea)
    jne .limpiar_loop     ; si no, seguir limpiando

    ret