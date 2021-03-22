#ifndef STRING_H
#define STRING_H

#include <stdbool.h>

int strlen(const char *ptr);
int strnlen(const char *ptr, int max);
int tonumericdigit(char c);
bool isdigit(char c);
char* strcpy(char *dest, const char *src);
char * strncpy(char *dest, const char *src, int count);
int strnlen_terminator(const char *str, int max, char terminator);
char tolower(char s1);
int istrncmp(const char *str1, const char *str2, int n);
int strncmp(const char *str1, const char *str2, int n);

#endif