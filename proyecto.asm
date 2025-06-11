section .data
    msg_ingresa db "Ingresa una cadena (max 50): ", 0   ; Mensaje que se mostrará al usuario para pedir la cadena
    len_ingresa equ $ - msg_ingresa                     ; Longitud del mensaje anterior

    msg_otro db "Deseas realizar otro? (s/n): ", 0      ; Mensaje para preguntar si desea repetir
    len_otro equ $ - msg_otro                           ; Longitud del mensaje anterior

    ; Definir mensajes de error para cuando la cadena ingresada exceda el límite de 50 caracteres
    msg_error_longitud db "La cadena ingresada excede el limite de 50 caracteres.", 0xA, 0 
    len_error_longitud equ $ - msg_error_longitud
    max_caracteres equ 50  ; Definirmos una variable para el límite maximo de caracteres de la cadena


    ; msg_resultado db "Cadena ingresada: ", 0            ;------------Es de borrar esto (solo para pruebas)
    ; len_resultado equ $ - msg_resultado  
               
    ; salto_linea db 0xA     ; salto de línea '\n'        ;------------Hasta aca es de borrar (solo para dar formato visual)



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
    mov rdx, max_caracteres + 1             ; máximo de bytes a leer (50 + '\n')

    syscall                 ; llama a read(0, buffer, 51)
    mov [longitud], al      ; guardar en 'longitud' el número de bytes leídos (valor devuelto por read en rax)
    call ValidarLongitud    ; llamamos la etiqueta para validar la longitud de la cadena

    ; Preguntamos "Deseas realizar otro?" Solo si la cadena fue válida
    jmp RealizarOtro

RealizarOtro:
    ; Preguntar al usuario
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


    ; ; Mostrar mensaje de cadena ingresada       ------------------------------------------Esto es  de borrarlo
    ; mov rax, 1
    ; mov rdi, 1
    ; mov rsi, msg_resultado
    ; mov rdx, len_resultado
    ; syscall

    ; ; Mostrar la cadena que se metio 
    ; movzx rdx, byte [longitud]
    ; dec rdx                 
    ; mov rax, 1
    ; mov rdi, 1
    ; mov rsi, buffer
    ; syscall                         ;-----------------------------------------------------Hasta aca es de borrar

    

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
    ; Esto ocurre cuando se ingresan más de 50 caracteres sin Enter anq no debe ocurrir porque el read lo limita
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
    
    ; Limpiamos el stdin leyendo bytes hasta encontrar un '\n'
    ; Esto es importante para que se reinicie el proceso cuando se ingresa una cadena que exceda el límite
    call LimpiarBufferEntrada      
    ; Reiniciar el proceso, para solicitar nuevamente la cadena
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
    ; Usaremos un buffer temporal de 1 byte
    mov rsi, buffer    ; reutilizamos el buffer, leeremos 1 byte a la vez
.limpiar_loop:
    mov rax, 0         ; syscall read
    mov rdi, 0         ; stdin
    mov rdx, 1         ; leer 1 byte
    syscall

    cmp byte [rsi], 0xA   ; verificamos si el byte leido es '\n' (salto de línea)
    jne .limpiar_loop     ; si no, seguir limpiando

    ret
