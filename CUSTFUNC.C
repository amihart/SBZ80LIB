#include <stdio.h>

int CUSTOM_FUNC(int a, int b) __naked {
  __asm
    out (0x01), a
    ret
  __endasm;
  (void)a;
  (void)b;
}

void main() {
  int p1 = 4545;
  int p2 = 22211;
  printf("Calling custom function with arguments %i and %i.\n", p1, p2);
  int ret = CUSTOM_FUNC(p1, p2);
  printf("Results: %i\n", ret);
}

