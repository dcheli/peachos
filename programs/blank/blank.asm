[BITS 32]

section .asm
global _start

_start:

    push message
    mov eax, 1  ; command print
    int 0x80
    add esp, 4  ; this functions like a pop
    jmp $


section .data 
message: db 'Booting CheliOS!', 0
