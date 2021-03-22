ENTRY(_start)
OUTPUT_FORMAT(binary)   /* Create a flat binary file */
SECTIONS
{
    . = 1M; /* our kernel will be loaded at 1MB memory; the origin*/
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