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

    msg_error_no_vocal db "Error: El caracter ingresado no es una vocal valida.", 10 ; Mensaje de error si lo que ha ingresado el usuario no es una vocal
    len_error_no_vocal equ $ - msg_error_no_vocal

    max_caracteres equ 50  ; Definirmos una variable para el límite maximo de caracteres de la cadena

section .bss
    vocal resb 2                        ; Reservar 2 bytes para la vocal ingresada (1 caracter + '\n')
    buffer resb max_caracteres + 1      ; Reservar 51 bytes para la cadena (50 caracteres + '\n')
    respuesta resb 2                    ; Reservar 2 bytes para respuesta del usuario ('s' o 'n' + '\n')
    longitud resb 1                     ; Reservar 1 byte para almacenar la cantidad de caracteres leídos
    longitud_vocal resb 1               ; Reservar 1 byte para almacenar la cantidad de caracteres leídos para la vocal

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

    ; Leer hasta 2 bytes (para capturar toda la línea si es larga)
    mov rax, 0
    mov rdi, 0
    mov rsi, vocal
    mov rdx, 2
    syscall

    mov [longitud_vocal], al          ; guardar la cantidad leída
    call ValidarLongitudVocal

.verificar_vocal:
    ; Validar si el carácter ingresado es una vocal válida (a, e, i, o, u ya sean en minúsculas o mayúsculas)
    mov al, [vocal]        ; Cargar el primer carácter ingresado (sin el '\n')
    cmp al, 'a'
    je .vocal_valida     ; Si es 'a', es válido
    cmp al, 'e'
    je .vocal_valida     ; Si es 'e', es válido
    cmp al, 'i'
    je .vocal_valida     ; Si es 'i', es válido
    cmp al, 'o'
    je .vocal_valida     ; Si es 'o', es válido
    cmp al, 'u'
    je .vocal_valida     ; Si es 'u', es válido
    
    ; Comparamos ahora con vocales en mayúsculas
    cmp al, 'A'
    je .vocal_valida
    cmp al, 'E'
    je .vocal_valida
    cmp al, 'I'
    je .vocal_valida
    cmp al, 'O'
    je .vocal_valida
    cmp al, 'U'
    je .vocal_valida

    ; Si llegó aquí, es porque no es una vocal
    ; entonces mostramos el mensaje de error 
    mov rax, 1              ; syscall write
    mov rdi, 1              ; stdout
    mov rsi, msg_error_no_vocal ; mensaje que indica que no es una vocal
    mov rdx, len_error_no_vocal ; longitud del mensaje de error
    syscall

    ; Volvemos a pedir la vocal al usuario
    jmp IngresarVocal

.vocal_valida:
    ; Continuar a realizar el reemplazo de vocales en la cadena principal
    call SustituirVocalesEnCadena

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
; SUBRUTINA ValidarLongitudVocal
; Entrada:
;   - RAX: Longitud de bytes leídos (incluyendo '\n' si existe)
;   - RSI: Puntero al buffer con la vocal ingresada
; Salida:
;   - Si es válida: Continúa ejecución (ret)
;   - Si no es válida: Muestra error y reinicia el proceso (jmp IngresarVocal)
; ================================================================
ValidarLongitudVocal:
    ; Validacion de longitud vocal
    cmp byte [rsi+rax -1], 0xA
    je .tiene_salto_linea

    ; Si no tiene newline, entonces el usuario ingreso exactamente 1 caracter (sin enter)
    cmp rax, 1
    je .longitud_valida 

    jmp .mostrar_error_longitud

.tiene_salto_linea:
    ; Verificamos si la lectura incluye el '\n' (cuando el usuario presiona Enter)
    cmp rax, 2                   ; Compara con 2 (1 caracter + '\n')
    je .longitud_valida     ; Si longitud = 2, entonces es una cadena válida

.mostrar_error_longitud:
    ; Mostrar mensaje de error
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error_vocal
    mov rdx, len_error_vocal
    syscall

    call LimpiarBufferEntradaVocal   ; limpiar stdin solo si hay exceso
    jmp IngresarVocal
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


; ================================================================
; SUBRUTINA LimpiarBufferEntradaVocal
; Limpia stdin leyendo bytes hasta encontrar un '\n' (salto de línea)
; Entrada:
;   - RSI: Puntero al buffer donde se guarda la vocal
; Salida:
;   - Si no encontramos '\n', seguimos limpiando
;   - Si encontramos '\n', retornamos
; ================================================================
LimpiarBufferEntradaVocal:
    mov rsi, vocal    ; reutilizamos el buffer, leeremos 1 byte a la vez
.limpiar_loop:
    mov rax, 0         ; syscall read
    mov rdi, 0         ; stdin
    mov rdx, 1         ; leer 1 byte
    syscall

    cmp byte [rsi], 0xA   ; verificamos si el byte leido es '\n' (salto de línea)
    jne .limpiar_loop     ; si no, seguir limpiando

    ret



; ================================================================
; SUBRUTINA SustituirVocalesEnCadena
; Intercambia todas las vocales de la cadena por la vocal introducida
; Entrada:
;   - RSI: Puntero al buffer donde se guarda la cadena
;   - RCX: Contiene el numero de caracteres de la cadena
;   - AL: Contiene la vocal
; Salida:
;   - Impresión por consola de la cadena con la vocal sustituida
; ================================================================
SustituirVocalesEnCadena:
    mov rsi, buffer             ; RSI apunta al inicio de la cadena
    movzx rcx, byte [longitud]  ; RCX contiene el numero de caracteres de la cadena
    mov al, [vocal]             ; AL contiene la nueva vocal

.verificacion:
    cmp rcx, 0                  ; cuando el contador de caracteres llegue a 0, imprimimos
    je .imprimir

    mov bl, [rsi]

    ; Comparar con vocales minusculas
    cmp bl, 'a'
    je .reemplazar
    cmp bl, 'e'
    je .reemplazar
    cmp bl, 'i'
    je .reemplazar
    cmp bl, 'o'
    je .reemplazar
    cmp bl, 'u'
    je .reemplazar

    ; Comparar con vocales mayúsculas
    cmp bl, 'A'
    je .reemplazar
    cmp bl, 'E'
    je .reemplazar
    cmp bl, 'I'
    je .reemplazar
    cmp bl, 'O'
    je .reemplazar
    cmp bl, 'U'
    je .reemplazar

    jmp .siguiente

.reemplazar:
    mov [rsi], al               ; Reemplazar la vocal

.siguiente:
    inc rsi
    dec rcx
    jmp .verificacion

.imprimir:
    mov rax, 1                 ; syscall número 1 = sys_write
    mov rdi, 1                 ; descriptor de archivo = STDOUT
    mov rsi, buffer            ; mensaje a imprimir
    movzx rdx, byte [longitud] ; longitud del mensaje
    syscall

    ret