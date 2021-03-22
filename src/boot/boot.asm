ORG 0x7C00          ; memory base address
BITS 16

CODE_SEG equ gdt_code - gdt_start   ; becomes 0x8
DATA_SEG equ gdt_data - gdt_start   ; becomes 0x10

jmp short start
nop
    
; Start of BIOS Parameter block
; FAT16 Header
OEMIdentifier       db  'PEACHOS '
BytesPerSector      dw  0x200   ; 512 bytes; does change fixed sector size of the disk; usually ignored
SectorsPerCluster   db  0x80
ReservedSectors     dw  200     ; This is where we will store our kernel
FATCopies           db  0x02    ; One for the original; one of the backup
RootDirEntries      dw  0x40
NumSectors          dw  0x00
MediaType           db  0xF8
SectorsPerFat       dw  0x100
SectorsPerTrack     dw  0x20
NumberOfHeads       dw  0x40
HiddenSectors       dd  0x00
SectorsBig          dd  0x773594

; Extended BPB (Dos 4.0)
DriveNumber         db  0x80
WinNTBit            db  0x00
Signature           db  0x29
VolumeID            dd  0xD105
VolumeIDString      db  'PEACHOS BOO'
SystemIDString      db  'FAT16   '



start:
    jmp 0:step2     ; makes the code segment 0

step2:
    cli             ; clear interrupts
    mov ax, 0x00
    mov ds, ax      ; sets the data  segment register
    mov es, ax      ; sets the extra segment register
    mov ss, ax      ; sets the stack segment register
    mov sp, 0x7c00  ; sets the stack pointer to the top of the stack
    sti             ; enable interrupts

.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or  eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; GDT - this describes the GDT Table
gdt_start:      ; this is address to the start of the table
gdt_null:       ; null segment
    dd 0x0
    dd 0x0

; offset 0x8 - this is for the code segment
gdt_code:       ; CS SHOULD POINT TO THIS
    dw 0xffff   ; Limit first 0-15 bits - dw: define word - allocates 2 bytes
    dw 0        ; Base  first 0-15 bits 
    db 0        ; Base 16-23 bits               - db: define byte - allocates 1 byte
    db 0x9a     ; Access byte (segment type) - code segment descriptor
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits

; offset 0x10 - this is the data segment
gdt_data:       ; DS, SS, ES, FS, GS SHOULD POINT TO THIS
    dw 0xffff   ; Limit first 0-15 bits - dw: define word - allocates 2 bytes
    dw 0        ; Base  first 0-15 bits 
    db 0        ; Base 16-23 bits               - db: define byte - allocates 1 byte
    db 0x92     ; Access byte - data segment descriptor
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0        ; Base 24-31 bits
gdt_end:


gdt_descriptor:
    dw gdt_end - gdt_start -1   ; this will give us the size of the descriptor
    dd gdt_start 

[BITS 32]
load32:             ; load the kernel into memory and jump to it
    mov eax, 1      ; we will load into sector, because sector 0 is the boot sector
    mov ecx, 100    ; total number of sectors
    mov edi, 0x0100000  ; the address where we want to load the sectors into
    call ata_lba_read   ; this will load the sectors from disk to memory
    jmp CODE_SEG:0x100000
    
ata_lba_read:
    mov ebx, eax,   ; Backup the LBA for later
    ; Send the hightest 8 bits of the lba to the hard disk controller
    shr eax, 24 ; shift register
    or eax, 0xE0 ; selects the master drive
    mov dx, 0x1F6
    out dx, al  ; send to the controller
    ; Finish sending the highest 8 bits of the lba

    ; Send the total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ; Finished sending the total sectors to read

    ; Send more bits of the lba
    mov eax, ebx ; restore the backup lba
    mov dx, 0x1F3
    out dx, al
    ; Finished sending more bits of the lba

    ; Send more bits of the lba
    mov dx, 0x1F4
    mov eax, ebx    ; Restore the backup of lba
    shr eax, 8
    out dx, al
    ; Finished sending more bits of the lba

    ; Send upper 16 bits of the lba
    mov dx, 0x1F5
    mov eax, ebx    ; Restore te backup of lba
    shr eax, 16
    out dx, al
    ; Finished sending upper 16 bits of the lba

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

    ; Read all sectors into memory
.next_sector:
    push ecx

; Checking if we need to read; sometimes the controller has a delay
.try_again:
    mov dx, 0x1F7   ; read from port 0x1F7
    in al, dx
    test al, 8 
    jz .try_again

; We need to read 256 words (512 bytes, or 1 sector) at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ; end of reading sectors into memory
    ret

times 510-($ - $$) db 0 ; fill 510 bytes of data
dw 0xAA55 ;x86 is little endian, this is 0x55AA; this is the signature
