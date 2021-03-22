section .asm

global insb
global insw
global outb
global outw

insb:
    ; create stack frame
    push ebp
    mov ebp, esp

    xor eax, eax    ; sets eax to 0
    mov edx, [ebp+8] ; this puts the port into the edx register
    in al, dx       ; this  places the value in the eax register, which C expects to see return values

    pop ebp
    ret

insw:
    ; create stack frame
    push ebp
    mov ebp, esp

    xor eax, eax
    mov edx, [ebp+8]
    in ax, dx       ; read 1 word

    pop ebp
    ret

outb:
    ; create stack frame
    push ebp
    mov ebp, esp
    
    xor eax, eax
    mov eax, [ebp+12]
    mov edx, [ebp+8]

    out dx, al      ; outputs 1 byte

    pop ebp
    ret

outw:
    push ebp
    mov ebp, esp

    xor eax, eax
    mov eax, [ebp+12]
    mov edx, [ebp+8]

    out dx, ax      ; outputs 1 word

    pop ebp
    ret