[BITS 32]
global _start
global kernel_registers

extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp

    ; enable the A20 line
    in al, 0x92     ; in reads from the address bus
    or al, 2
    out 0x92, al    ; writes to the address bus    

    ; remap the master PIC (note this could be done in C)
    mov al, 00010001b   ; puts the PIC in initialization mode
    out 0x20, al        ; Tell master PIC

    mov al, 0x20        ; Interrupt 0x20 is where master ISR should start
    out 0x21, al

    mov al, 00000001b   ; put the PIC in x86 mode
    out 0x21, al 
    ; End remap of master PIC


    call kernel_main
    jmp $

kernel_registers:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    ret
    
times 512-($ - $$) db 0 ; this is for proper alignment