; stage2.asm
; Lesson 4: Green Progress Bar Animation

[org 0x0000]
[bits 16]

VIDEO_SEG equ 0xB800
WIDTH     equ 80
HEIGHT    equ 25

start:
    cli
    mov ax, cs
    mov ds, ax

    mov ax, VIDEO_SEG
    mov es, ax

    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    mov byte [color], 0x0F

    call clear_screen

    mov bl, 0x0A
    call set_color
    mov si, title
    call print_string
    call newline
    call newline

    mov bl, 0x0F
    call set_color
    mov si, booting
    call print_string
    call newline
    call newline

    mov byte [progress], 0

progress_loop:
    call draw_progress
    call delay

    inc byte [progress]
    cmp byte [progress], 21
    jne progress_loop

    call newline
    call newline

    mov bl, 0x0A
    call set_color
    mov si, complete
    call print_string

hang:
    jmp hang

; -------------------------
; draw_progress
; progress: 0 ~ 20
; -------------------------
draw_progress:
    mov byte [cursor_x], 0
    mov byte [cursor_y], 5

    mov bl, 0x0F
    call set_color
    mov al, '['
    call print_char

    xor si, si          ; SI 作为进度条位置计数器 0~19

.bar_loop:
    cmp si, 20
    jae .bar_done

    mov ax, si
    cmp al, [progress]
    jb .filled

.empty:
    mov bl, 0x08
    call set_color
    mov al, 176         ; 浅灰色空格块，也可以改成 ' '
    call print_char
    jmp .next

.filled:
    mov bl, 0x0A
    call set_color
    mov al, 219         ; 绿色实心块
    call print_char

.next:
    inc si
    jmp .bar_loop

.bar_done:
    mov bl, 0x0F
    call set_color
    mov al, ']'
    call print_char

    mov al, ' '
    call print_char
    mov al, ' '
    call print_char

    mov al, [progress]
    mov bl, 5
    mul bl              ; progress 0~20 → percent 0~100
    call print_percent

    ret

; -------------------------
; print_percent
; input: AL = 0 ~ 100
; -------------------------
print_percent:
    cmp al, 100
    jne .not_100

    mov al, '1'
    call print_char
    mov al, '0'
    call print_char
    mov al, '0'
    call print_char
    jmp .percent

.not_100:
    xor ah, ah
    mov bl, 10
    div bl

    cmp al, 0
    jne .two_digit

    mov al, ' '
    call print_char
    mov al, ' '
    call print_char
    mov al, ah
    add al, '0'
    call print_char
    jmp .percent

.two_digit:
    mov bh, ah

    mov ah, 0
    add al, '0'
    call print_char

    mov al, bh
    add al, '0'
    call print_char

    mov al, ' '
    call print_char

.percent:
    mov al, '%'
    call print_char
    ret

; -------------------------
; set_color
; BL = color
; -------------------------
set_color:
    mov [color], bl
    ret

; -------------------------
; clear_screen
; -------------------------
clear_screen:
    xor di, di
    mov cx, WIDTH * HEIGHT

.clear:
    mov word [es:di], 0x0720
    add di, 2
    loop .clear

    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    ret

; -------------------------
; print_string
; DS:SI = string
; -------------------------
print_string:
.next:
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp .next
.done:
    ret

; -------------------------
; print_char
; AL = char
; -------------------------
print_char:
    cmp al, 13
    je newline
    cmp al, 10
    je newline

    push ax
    push bx
    push dx
    push di

    mov dl, al

    xor ax, ax
    mov al, [cursor_y]
    mov bl, WIDTH
    mul bl

    xor bx, bx
    mov bl, [cursor_x]
    add ax, bx

    shl ax, 1
    mov di, ax

    mov al, dl
    mov ah, [color]
    mov [es:di], ax

    inc byte [cursor_x]
    cmp byte [cursor_x], WIDTH
    jb .done

    call newline

.done:
    pop di
    pop dx
    pop bx
    pop ax
    ret

; -------------------------
; newline
; -------------------------
newline:
    mov byte [cursor_x], 0
    inc byte [cursor_y]
    ret

; -------------------------
; delay
; -------------------------
delay:
    push cx
    push dx

    mov cx, 0xFFFF
.d1:
    mov dx, 0x0040
.d2:
    dec dx
    jnz .d2
    loop .d1

    pop dx
    pop cx
    ret

; -------------------------
; data
; -------------------------
cursor_x db 0
cursor_y db 0
color    db 0x0F
progress db 0

title    db "==================== MyOS Boot Loader ====================", 0
booting  db "Booting MyOS...", 0
complete db "Boot Complete!", 0

times 2048-($-$$) db 0