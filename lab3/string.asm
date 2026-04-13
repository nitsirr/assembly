BITS 64

global _start

section .rodata
    BUFF_SIZE equ 4096
    LINE_SIZE equ 65536

    SYS_READ equ 0
    SYS_WRITE equ 1
    SYS_OPEN equ 2
    SYS_CLOSE equ 3
    SYS_EXIT equ 60

section .data
    ; запишем сюда индекс
    ; файлового дескриптора
    input_fd dq 0
    buffer db BUFF_SIZE dup(0)
    line_buffer db LINE_SIZE dup(0)

_start:
    call parse_args
    call open_file
    xor r13, r13 ; for line length
    ; так же внутри и выводим
    call read_loop
    call close_file
    
    ; завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

parse_args:
    mov rax, [rsp]
    cmp rax, 2
    jl error_exit

    mov rdi, [rsp + 16] ; filename
    ret

open_file:
    ; TODO разобраться как работает этот
    ; сискол
    mov rax, SYS_OPEN
    xor rsi, rsi
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl error_exit

    mov [input_fd], rax
    ret

read_loop:
    ; заполняем буфер данными из файла
    mov rax, SYS_READ
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFF_SIZE
    syscall

    ; в rax кол-во прочитанных байт
    ; buffer содержит эти байты

    cmp rax, 0
    je eof

    cmp rax, 0
    jl error_exit

    mov r14, rax
    xor rcx, rcx

    jmp process_buffer

; обрабатываем буфер
process_buffer:
    cmp rcx, r14
    ; обработали весь буфер, нужно
    ; считывать дальше
    jge read_loop

    ; кладем символ в al
    mov al, [buffer + rcx]

    cmp al, 10 ; \n
    je line_done

    cmp r13, LINE_SIZE
    jge error_exit ; строка слишком длинная

    mov [line_buffer + r13], al ; записываем символ в начало буфера
    inc r13 ; увеличиваем длину строки

    inc rcx
    jmp process_buffer

line_done:

    ; TODO обработать строку

    xor r13, r13

    inc rcx
    jmp process_buffer

eof:
    cmp r13, 0
    je finish

    ; TODO обработать строку
    ; мы дошли до конца файла
    ; но в буфере есть данные
    ; которые нужно обработать

finish:
    call print_result
    ret

print_result:
    ; TODO вывести в stdout результат
    ret

close_file:
    mov rax, SYS_CLOSE
    mov rdi, [input_fd]
    syscall

error_exit:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall