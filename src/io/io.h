#ifndef IO_H
#define IO_H

unsigned char insb(unsigned short port);            // reads 1 byte
unsigned short insw(unsigned short port);           // reads 1 word (2 bytes)

void outb(unsigned short port, unsigned char val);  // writes 1 byte
void outw(unsigned short port, unsigned char val);  // writes 1 word (2 bytes)

#endif