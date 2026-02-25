BITS 64

global _start

; 0x4000000000000000 для ovf 2^62 * 4

section .data
    a dq 0x10000000
    b dd 0x10000000 ; 4
    c dd 0x40 ; 4
    d db 0x40 ; 1
    e dw 0x4000

section .text

_start:
    ; делим a / b
    mov rax, [a] ; загружаем обращаясь по адресу a и кладем что по адресу в регистр rax
    cqo ; тк idiv делает rdx:rax то нам надо инициализировать их обоих
    mov ebx, [b]
    movsxd rbx, ebx ; расширяем тк делимое 64 бита

    ; проверка
    cmp rbx, 0
    je divz_err

    idiv rbx
    ; сохраняем
    mov r8, rax


    ; делим с / d
    mov eax, [c]
    cdq
    mov bl, [d]
    movsx ebx, bl

    ; проверка 0
    cmp ebx, 0
    je divz_err

    idiv ebx
    ; сохраняем
    mov r9d, eax


    ; умножение a*b*c
    movsx rax, dword [b]
    movsx rbx, dword [c]
    imul rbx ; b*c

    ; проверка
    jo ovf_err

    mov rbx, [a]
    imul rbx ; a * (b*c)

    ; проверка
    ; jo ovf_err

    mov r10, rdx ; старшие биты
    mov r11, rax ; младшие биты
    

    ; умножение c*d
    mov eax, [c]
    movsx ebx, byte [d]
    imul ebx

    ; проверка не нужна!
    ; jo ovf_err

    ; умножение (c*d)*e
    movsx rbx, word [e]
    imul rbx

    ; проверка не нужна!
    ; jo ovf_err

    mov r12, rdx ; старшие
    mov r13, rax ; младшие


    ; числитель = a*b*c - c*d*e
    sub r11, r13
    sbb r10, r12 ; учитываем borrow

    ; проверка
    jo ovf_err


    ; знаменатель
    movsxd r9, r9d
    add r8, r9

    ; проверка
    jo ovf_err


    ; делим финал
    mov rax, r11
    mov rdx, r10

    ; проверка
    cmp r8, 0
    je divz_err
    
    idiv r8


    jmp exit_suc

exit_suc:
    mov rdi, 0 ; код завершения что все гуд
    jmp exit

divz_err:
    mov rdi, 2
    jmp exit

ovf_err:
    mov rdi, 1
    jmp exit

exit:
    mov rax, 60 ; помещаем в регистр код завершения программы
    ; через системный вызов
    syscall