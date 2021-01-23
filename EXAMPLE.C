#include "headers.h"

void print(char *str) {
  int i;
  for (i = 0; str[i] != 0; i++) {
    putchar(str[i]);
  }
}
void scan(char *str, int max) {
  if (max == 0) return;
  int pos = 0;
  while (max > 1) {
    char c = getchar();
    if (c == 10) break;
    str[pos++] = c;
    max--;
  }
  str[pos] = 0;
}

void main() {
  char name[32];
  print("Hello, friend!\n");
  print("What is your name?\n");
  scan(name, 32);
  print("Nice to meet you, ");
  print(name);
  print("!\n");
}
