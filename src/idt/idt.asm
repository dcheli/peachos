section .asm

;import functions from C
extern int21h_handler
extern no_interrupt_handler
extern isr80h_handler

; export the functions to C
global int21h   
global idt_load
global no_interrupt
global enable_interrupts
global disable_interrupts
global isr80h_wrapper

enable_interrupts:
    sti
    ret

disable_interrupts:
    cli
    ret
    
idt_load:
    push ebp
    mov ebp, esp
    mov ebx, [ebp+8]
    
    lidt [ebx]
    pop ebp
    ret

int21h:
    pushad  ; pushes all the general purpose regsiters
    call int21h_handler    ; this calls my C function
    popad
    iret

no_interrupt:
    pushad  ; pushes all the general purpose regsiters
    call no_interrupt_handler    ; this calls my C function
    popad
    iret

isr80h_wrapper:
    ; INTERRUPT FRAME STARTS
    pushad      ; pushes the general purpose registers to the stack

    ; INTERRUPT FRAME ENDS

    ; push the stack point so that we are pointing to the interrupt frame
    push esp
    push eax        ; eax contains the command that the processor should invoke
    call isr80h_handler
    mov dword[tmp_res], eax
    add esp, 8      ; returns out stack pointer to the place it was before we pushed the 2 elements above to the stack

    ; restore general purpose registers for userland
    popad
    mov eax, [tmp_res]
    iretd

section .data
; inside here is stored the return results from isr80h_handler
tmp_res: dd 0