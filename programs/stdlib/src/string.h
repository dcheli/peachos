#ifndef PEACHOS_STRING_H
#define PEACHOS_STRING_H

#include "string.h"

#include "string.h"
#include <stdbool.h>

char tolower(char s1);
int strlen(const char *ptr);
int strnlen(const char *ptr, int max);
int strnlen_terminator(const char *str, int max, char terminator);
int istrncmp(const char *str1, const char *str2, int n);
int strncmp(const char *str1, const char *str2, int n);
char* strncpy(char *dest, const char *src, int count);
char* strcpy(char *dest, const char *src);
bool isdigit(char c);
int tonumericdigit(char c);
char* strtok(char *str, const char *delimiters);

#endif