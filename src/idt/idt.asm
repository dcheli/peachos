section .asm

;import functions from C

extern no_interrupt_handler
extern isr80h_handler
extern interrupt_handler

; export the functions to C
global idt_load
global no_interrupt
global enable_interrupts
global disable_interrupts
global isr80h_wrapper
global interrupt_pointer_table

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


no_interrupt:
    pushad  ; pushes all the general purpose regsiters
    call no_interrupt_handler    ; this calls my C function
    popad
    iret

%macro interrupt 1
    global int%1
    int%1:
        ; Interrupt Frame Start
        ; Already pushed ot us by the procesor upon entry to this interrupt
        ; uint32_t ip
        ; uint32_t cs
        ; uint32_t flags
        ; uint32_t sp
        ; uint32_t ss
        ; Pushes the general purpose registers to the stack
        pushad
        ; Interrupt Frame End
        push esp
        push dword %1
        call interrupt_handler
        add esp, 8
        popad
        iret
%endmacro

%assign i 0
%rep 512
    interrupt i
%assign i i+1
%endrep

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

%macro interrupt_array_entry 1
    dd int%1
%endmacro

interrupt_pointer_table:
%assign i 0
%rep 512
    interrupt_array_entry i
%assign i i+1
%endrep
