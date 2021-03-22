#include "kernel.h"
#include <stdint.h>
#include <stddef.h>
#include "idt/idt.h"
#include "memory/heap/kheap.h"
#include "memory/paging/paging.h"
#include "disk/disk.h"
#include "fs/pparser.h"
#include "string/string.h"
#include "disk/streamer.h"
#include "fs/file.h"
#include "gdt/gdt.h"
#include "config.h"
#include "memory/memory.h"
#include "task/tss.h"
#include "task/task.h"
#include "task/process.h"
#include "status.h"
#include "isr80h/isr80h.h"

uint16_t *video_mem = 0;
uint16_t terminal_row = 0;
uint16_t terminal_col = 0;

uint16_t terminal_make_char(char c, char color) {

    return (color << 8) | c; // this returns the c/color in little endian 
}

void terminal_putchar(int x, int y, char c, char color) {
    video_mem[(y*VGA_WIDTH) + x] = terminal_make_char(c, color); 
}


void terminal_writechar(char c, char color) {
    if(c =='\n') {
        terminal_col = 0;
        terminal_row +=1;
        return;
    }
    terminal_putchar(terminal_col, terminal_row, c, color);
    terminal_col += 1;
    if(terminal_col >= VGA_WIDTH) {
        terminal_col = 0;
        terminal_row += 1;
    }
}

void terminial_initialize()
{
    terminal_row = 0;
    terminal_col = 0;

    video_mem = (uint16_t *)(0xB8000);
    for(int y = 0; y < VGA_HEIGHT; y++) {
        for(int x = 0; x < VGA_WIDTH; x++) {
            terminal_putchar(x, y, ' ', 0);
        }
        
    }
}


void print(const char *str) {
    size_t len = strlen(str);
    for(int i = 0; i < len; i++)
        terminal_writechar(str[i], 15);

}

// static says it's accessible ONLY from kernel.c


static struct  paging_4gb_chunk *kernel_chunk = 0;

void panic(const char *msg){
    print(msg);
    while(1){}
}

void kernel_page(){
    kernel_registers();
    paging_switch(kernel_chunk);
}

struct tss tss;
struct gdt gdt_real[PEACHOS_TOTAL_GDT_SEGMENTS];
struct gdt_structured gdt_structured[PEACHOS_TOTAL_GDT_SEGMENTS] = {
    {.base = 0x00, .limit = 0x00, .type = 0x00},            // NULL segment
    {.base = 0x00, .limit = 0xFFFFFFFF, .type = 0x9a},      // kernel code segment
    {.base = 0x00, .limit = 0xFFFFFFFF, .type = 0x92},      // kernel data segment 
    {.base = 0x00, .limit = 0xFFFFFFFF, .type = 0xF8},      // user code segment
    {.base = 0x00, .limit = 0xFFFFFFFF, .type = 0xF2},       // user data segment
    {.base = (uint32_t)&tss, .limit = sizeof(tss), .type = 0xE9}   // TSS segment       
};


void kernel_main(){

    terminial_initialize();

    
    memset(gdt_real, 0x00, sizeof(gdt_real));
    
    // convert get_structured to gdt_real
    gdt_structured_to_gdt(gdt_real, gdt_structured, PEACHOS_TOTAL_GDT_SEGMENTS);
    gdt_load(gdt_real, sizeof(gdt_real));
    

    // Initialize  the heap
    kheap_init();
    
    // Initialize filesystems
    fs_init();

    // Setup the TSS
    memset(&tss, 0x00, sizeof(tss));
    tss.esp0 = 0x600000;
    tss.ss0 = KERNEL_DATA_SELECTOR;

    // Load the TSS
    tss_load(0x28);     // 0x28 is the offset in the gdt real


    // search and initialize the disks
    disk_search_and_init();
    
    //Initialize the interupt descriptor table
    idt_init();

    // Setup paging
    kernel_chunk = paging_new_4gb(PAGING_IS_WRITABLE | PAGING_IS_PRESENT | PAGING_ACCESS_FROM_ALL);

    // Switch to kernel paging chunk
    paging_switch(kernel_chunk); 

  
    // Enable paging
    enable_paging();

    // Register the kernel commands
    isr80h_register_commands();
    struct process *process = 0;
    
    int res = process_load("0:/blank.bin", &process);

    if(res != PEACHOS_ALL_OK){
        panic("Failed to load blank.bin\n");
    }

    task_run_first_ever_task();
    
    while(1){
        
    }
}