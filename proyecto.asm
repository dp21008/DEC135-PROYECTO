section .data
    msg_ingresa db "Ingresa una cadena (max 50): ", 0   ; Mensaje que se mostrará al usuario para pedir la cadena
    len_ingresa equ $ - msg_ingresa                     ; Longitud del mensaje anterior

    msg_otro db "Deseas realizar otro? (s/n): ", 0      ; Mensaje para preguntar si desea repetir
    len_otro equ $ - msg_otro                           ; Longitud del mensaje anterior

    msg_resultado db "Cadena ingresada: ", 0            ;------------Es de borrar esto (solo para pruebas)
    len_resultado equ $ - msg_resultado                 

    salto_linea db 0xA     ; salto de línea '\n'        ;------------Hasta aca es de borrar (solo para dar formato visual)



section .bss
    buffer resb 51      ; Reservar 51 bytes para la cadena (50 caracteres + '\n')
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
    mov rdx, 51             ; máximo de bytes a leer (50 + '\n')
    syscall                 ; llama a read(0, buffer, 51)
    mov [longitud], al      ; guardar en 'longitud' el número de bytes leídos (valor devuelto por read en rax)


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


    ; Mostrar mensaje de cadena ingresada       ------------------------------------------Esto es  de borrarlo
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_resultado
    mov rdx, len_resultado
    syscall

    ; Mostrar la cadena que se metio 
    movzx rdx, byte [longitud]
    dec rdx                 
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    syscall                         ;-----------------------------------------------------Hasta aca es de borrar

    

      ; Evaluar si se repite
    mov al, [respuesta]     ; cargar primer carácter de la respuesta
    cmp al, 's'             ; comparar si es 's'
    je IngresarCadena       ; si es 's', saltar a IngresarCadena para repetir el proceso

     ; Terminar programa
    mov rax, 60             ; syscall exit
    xor rdi, rdi            ; exit code 0
    syscall                 ; terminar el programa limpiamente