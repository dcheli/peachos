[BITS 32]
section .asm

global print:function
global peachos_getkey:function
global peachos_putchar:function
global peachos_malloc:function
global peachos_free:function
global peachos_process_load_start:function
global peachos_system:function
global peachos_process_get_arguments:function
global peachos_exit:function

print:
    push ebp
    mov ebp, esp
    push dword[ebp+8]
    mov eax, 1  ; command print
    int 0x80
    add esp,4
    pop ebp
    ret

peachos_getkey:
    push ebp
    mov ebp, esp
    mov eax, 2  ; getkey
    int 0x80    ; invoke the kernel
    pop ebp
    ret

;void peachos_putchar(char c)
peachos_putchar:
    push ebp
    mov ebp, esp
    mov eax, 3  ; putchar
    push dword[ebp+8]   ; variable "c"
    int 0x80    ; invoke the kernel
    add esp,4
    pop ebp
    ret


; void * peachos_malloc(size_t size)

peachos_malloc:
    push ebp
    mov ebp, esp
    mov eax, 4  ; malloc
    push dword[ebp+8]   ;variable size
    int 0x80
    add esp, 4  ;restore the stack
    pop ebp
    ret

; void peachos_free(void *ptr)
peachos_free:
    push ebp
    mov ebp, esp
    mov eax, 5  ; free
    push dword[ebp+8]   ;variable size
    int 0x80
    add esp, 4  ;restore the stack
    pop ebp
    ret

; void peachos_process_load_start(const char* filename)
peachos_process_load_start:
    push ebp
    mov ebp, esp
    mov eax, 6  ; command
    push dword[ebp+8]   ;variable filename
    int 0x80
    add esp, 4  ;restore the stack
    pop ebp
    ret

; int peachos_system(struct command_argument *arguments)
peachos_system:
    push ebp
    mov ebp, esp
    mov eax, 7  ; command
    push dword[ebp+8]   ;variable arguments
    int 0x80
    add esp, 4  ;restore the stack pointer
    pop ebp
    ret

; void peachos_process_get_arguments(struct process_arguments *arguments)
peachos_process_get_arguments:
    push ebp
    mov ebp, esp
    mov eax, 8  ; command
    push dword[ebp+8]   ;variable arguments
    int 0x80
    add esp, 4  ;restore the stack
    pop ebp
    ret

; void peachos_exit()
peachos_exit:
    push ebp
    mov ebp, esp
    mov eax, 9 ; Command 9 process exit
    int 0x80
    pop ebp
    ret