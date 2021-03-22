ENTRY(_start)
OUTPUT_FORMAT(binary)   /* Create a flat binary file */
SECTIONS
{
    . = 0x4000000;
    .text : ALIGN(4096)
    {
        *(.text)
    }

    .asm : ALIGN(4096)
    {
        *(.asm)
    }
    
    .rodata : ALIGN(4096)
    {
        *(.rdata)
    }

    .data : ALIGN(4096)
    {
        *(.data)
    }

    .bss : ALIGN(4096)
    {  
        *(COMMON)
        *.(.bss)
    }

}
