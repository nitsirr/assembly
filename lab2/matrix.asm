BITS 64

global _start


section .data
    ROWS equ 2
    COLUMNS equ 2
    EL_SIZE equ 4 ; размер элемента

    rows db ROWS
    columns db COLUMNS

    align EL_SIZE ; тк у нас элемент 4 байта
    matrix dd 1, 2
           dd 3, 4

    col_ptrs times COLUMNS dq 0 ; тк указатель 8 байт
    array_max times COLUMNS dd 0 ; 

    temp_matr times ROWS*COLUMNS dd 0

    MIN equ -2147483648

_start:
    mov r8d, columns
    xor edi, edi ; i = 0

for_cols:
    cmp edi, r8d
    jge cols_end

    mov r9d, rows
    xor esi, esi ; j = 0

    ; тело внешний цикл


    ; создание массива указателей
    ; TODO чекнуть на возможности арифметики
    lea rdx, [matrix + rdi*EL_SIZE]
    mov [col_ptrs + rdi*8], rdx

    ; сохраним сюда максимальный
    ; эл столбца
    mov r10d, MIN
    ; указатель на i столбец
    mov rbx, [col_ptrs + rdi*8]


for_rows:
    cmp esi, r9d
    jge rows_end

    ; начало внутренний цикл


    ; считываем элемент j строки
    mov edx, [rbx]

    ; находим максимальный элемент
    cmp edx, r10d
    jle skip_update
    mov r10d, edx
skip_update:
    
    ; делаем j+1 по строке
    add rbx, COLUMNS*EL_SIZE


    ; конец внутренний цикл

    inc esi
    jmp for_rows

rows_end:
    ; сохраняем макс элемент столбца
    mov [array_max + edi * EL_SIZE], r10d


    ; конец внешний цикл

    inc edi
    jmp for_cols


cols_end:
    
    xor edi, edi
    inc edi ; (1, len - 1)

sort_loop:
    cmp edi, r8d
    jge sort_done

    ; подгружаем ключ (для поиска и сдвига)
    mov r11d, [array_max + rdi*EL_SIZE]
    ; подргружаем указатель на столбец
    ; для поиска и сдвига
    mov r10, [col_ptrs + rdi*8]

    ; подгружаем диапазон для поиска
    mov r12d, edi
    call binary_search

    ; счетчик для сдвига
    ; edi - длина отсортированного 
    ; текущего массива
    mov ecx, edi
shift_loop:
    cmp ecx, esi ; в esi лежит позиция для вставки
    jle shift_done

    ; сдвиг для максимумов
    mov eax, [array_max + rcx*EL_SIZE - EL_SIZE]
    mov [array_max + rcx*EL_SIZE], eax

    ; сдвиг для указателей
    mov rax, [col_ptrs + rcx*8 - 8]
    mov [col_ptrs + rcx*8], rax

    dec ecx
    jmp shift_loop

shift_done:
    ; вставляем на нужную позицию
    ; максимальный элемент и нужный указатель
    mov [array_max + rsi*EL_SIZE], r11d
    mov [col_ptrs + rsi*8], r10

    inc edi
    jmp sort_loop

; r12d = диапазон (1, lenght - 1) 
; r11d = key
binary_search:
    xor esi, esi ; left = 0 
    ; потом в esi будет лежать нужная позиция
    mov edx, r12d;

binary_loop:
    cmp esi, edx
    jge binary_done

    ; (left + right) / 2
    mov ecx, esi
    add ecx, edx
    shr ecx, 1

    mov eax, [array_max + rcx*EL_SIZE]
    cmp eax, r11d
    jle move_left
    jmp move_right

; left = mid + 1
move_left:
    lea esi, [rcx + 1]
    jmp binary_loop


; right = mid
move_right:
    mov edx, ecx
    jmp binary_loop

binary_done:
    ret

sort_done:

    ; осталось только переписать
    ; исходную матрицу

    mov r8d, columns
    xor edi, edi ; i = 0
for_cols_temp:
    cmp edi, r8d
    jge cols_end_temp

    mov r9d, rows
    xor esi, esi ; j = 0

    ; тело внешний цикл

    ; указатель на i столбец
    mov rbx, [col_ptrs + rdi*8]

for_rows_temp:
    cmp esi, r9d
    jge rows_end_temp

    ; начало внутренний цикл


    ; считываем элемент в j строке
    mov eax, [rbx]

    ; ищем j строку
    ; pos = (j*COLUMNS + i)*EL_SIZE
    mov edx, esi
    imul edx, COLUMNS
    add edx, edi
    mov [temp_matr + rdx*EL_SIZE], eax

    ; получаем следующий элемент
    add rbx, COLUMNS*EL_SIZE


    ; конец внутренний цикл

    inc esi
    jmp for_rows_temp

rows_end_temp:


    ; конец внешний цикл

    inc edi
    jmp for_cols_temp


cols_end_temp:

    mov ecx, COLUMNS*ROWS
    xor esi, esi

copy_loop:
    mov eax, [temp_matr + rsi*4]
    mov [matrix + rsi*4], eax
    inc esi
    loop copy_loop

    mov rdi, 0
    mov rax, 60
    syscall