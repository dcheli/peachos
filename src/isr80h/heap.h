#ifndef ISR80_HEAP_H
#define ISR80_HEAP_H

struct interrupt_frame; // forward reference for this structure

void* isr80h_command4_malloc(struct interrupt_frame *frame);
void* isr80h_command5_free(struct interrupt_frame *frame);

#endif