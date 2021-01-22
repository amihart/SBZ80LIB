;Interrupt example
  org 0x0000
  jp _main
  ds 0x38 - 2
  ex af, af'
  ld a, '!'
  out (0x00), a
  ex af, af'
  reti
;Prints a null-terminated string
;  at memory address HL
_PutS:
  ld a, (hl)
  cp 0
  ret z
  out (0x00), a
  inc hl
  jr _PutS
;Reads in a line and stores it
;  at memory address HL with a max
;  size of B
_GetS:
  ld a, b
  cp 1
  jr z, _GetS_DONE
  in a, (0x00)
  cp 10
  jr z, _GetS_DONE
  ld (hl), a
  inc hl
  dec b
  jr _GetS
_GetS_DONE:
  ld a, 0
  ld (hl), a
  ret
  
_main:
  im 1
  di
  ;Text example
  ld hl, _msg1
  call _PutS
  ld hl, _name
  ld b, 32
  call _GetS
  ld hl, _msg2
  call _PutS
  ld hl, _name
  call _PutS
  ld hl, _msg3
  call _PutS
  ;Interrupt example
  ld hl, _msg4
  call _PutS
  in a, (0x00)
  ei
  ld hl, _msg5
  call _PutS
  di
  ld hl, _msg6
  call _PutS
  halt
  
_msg1:
  db "Hi! Welcome to this Zilog Z80 assembly example!", 10
  db "What might your name be?", 10, 0
_name:
  ds 32
_msg2:
  db "Hello there, ", 0
_msg3:
  db "! Nice to meet you!", 10, 0
_msg4:
  db "Press enter to see a cool interrupt example!", 10, 0
_msg5:
  db "Hello. This is a test. As this string gets "
  db "printed, something interesting happens. The "
  db "string is constantly interrupted by the "
  db "exclamation point. This is a simple example "
  db "of interrupts in Zilog Z80 assembly!", 0
_msg6:
  db 10
  db "Pretty cool, huh?", 10, 0

