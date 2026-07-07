; boot.asm
; Stage1 Bootloader: load Stage2 from disk

[org 0x7C00]
[bits 16]

STAGE2_SEG equ 0x1000
STAGE2_OFF equ 0x0000
STAGE2_SECTORS equ 4

start:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [BOOT_DRIVE], dl

    mov ax, STAGE2_SEG
    mov es, ax
    mov bx, STAGE2_OFF

    mov ah, 0x02
    mov al, STAGE2_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    int 0x13

    jc disk_error

    jmp STAGE2_SEG:STAGE2_OFF

disk_error:
    mov si, error_msg

print_error:
    lodsb
    cmp al, 0
    je hang
    mov ah, 0x0E
    int 0x10
    jmp print_error

hang:
    jmp hang

BOOT_DRIVE db 0
error_msg db "Disk read error!", 0

times 510-($-$$) db 0
dw 0xAA55