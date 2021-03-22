section .asm
global tss_load

; this loads in the task switch segment
tss_load:
    push ebp
    mov ebp, esp
    mov ax, [ebp+8] ;TSS Segment
    ltr ax
    pop ebp
    ret