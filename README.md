# SBZ80LIB
A SmileBASIC library for Zilog Z80 assembly inspired by the PasocomMini MZ-80C.
This was written on Pi STARTER but I plan to eventually port it to 3DS and Switch.

To download, first make sure you have GIT installed onto your Pi STARTER. 

`print system$("sudo apt install git -y")`

Then, clone the repository.

`print system$("sudo git clone http://github.com/amihart/SBZ80LIB")`

Let's look at the example Zilog Z80 assembly program.

![img](https://i.imgur.com/piQLqjL.png)

How can we run this program using the library? First, we have to assemble it, and to do that we need an assembly. Nicely, you do not even have to leave Pi STARTER in order to install one. My preferred assembler is `Z80ASM`.

`print system$(sudo apt install z80asm -y)`

You can assemble the program to a hex file using this command. It's quite lengthy but Z80AM outputs raw binary files which do not have the proper headers to open in SmileBASIC, so we can make it instead output the file as a binary file. 

`save "txt:example.hex", system$("sudo z80asm example.asm -o - | xxd -u -c 1 | sed 's/.*://' | cut -d' ' -f2 | xargs | sed 's/ //g'")`

Now since we have our assembled file, let's try to run it in our library. We have to take note that the program is printing characters to the screen by writing a byte to port 0x00. It is also reading characters from user input by reading bytes from port 0x00. So in order to run the program, we must define the behavior of these ports. It also uses a Mode 1 interrupt, so we also have to tell it when interrupts occur. Take a look at this program below.

![img1](https://i.imgur.com/dJL986x.png)

First, I load the library, then, I load the Zilog Z80 program assembled to a hex file (`sudo apt install z80asm` for a Z80 assembler). Next, I define a callback for port-write instructions. In this case, I say if you attempt to write to port 0, then simply print the data you write to port 0 onto the screen assuming the data represents an ASCII character. The `EMUPOCB` command is used to designate which DEF block represents your callback for port-out instructions.

I then do the same for the port-in instructions and EMUPICB specifies which DEF block is used for port reads. In this case, I create a buffer called `stdin$` and if it is empty when you try to read it, then I pause for the user to type in some text. I then pop the first character out of the buffer and return that as what is read from port 0x00. 

Finally, I define my interrupt callback which is designated using `EMUINTCB`. Normally, interrupts are triggered by external hardware in the real world, so we have to specify when an interrupt should actually be triggered. This `DEF` block will be called repeatedly when interrupts are enabled, and if you ever return 1 for `FIRE%`, then the interrupt is fired. Mode 2 interrupts also expect a byte of data to be combined with the `I` register. Mode 0 interrupts aren't supported.

Once we've defined all our callbacks, we simply call EMURUN 0 to start the program.

![img](https://i.imgur.com/FG3U9RJ.png)

This library implements every instruction that the PasocomMini MZ-80C does and in fact was unit tested with it to ensure consistency. The only things that have not been fully tested are the repeating instructions (e.g. `LDIR`) and the interrupts, as these are not easy to unit test, so please report any bugs.

This library is accurate enough to even compile code using the Small Device C Compiler and then run the C code in SmileBASIC. Let's actually demonstrate this. Here is a simple C program that will print a few messages to the screen, ask you your name, let you type it in, then say it back to you.

![img](https://i.imgur.com/ABXzcr7.png)

This relies on two functions, a `getchar()` and a `putchar()`. I defined these in a file called `headers.h`.

[!img](https://i.imgur.com/y7wvz2A.png)

This file makes use of a few tricks with the compiler. I will be using the Small Device C Compiler here.

`print system$("sudo apt install sdcc -y")`

SDCC will position the very first function at the very beginning of your program. So we make this function call our MAIN function to ensure our program starts with MAIN. We then use `__naked` to get rid of any function prologues or epilogues the compiler sets up. All we want is for this function to do nothing other than call the main function and `HALT`. If you actually check the compiled binary, it compiled this to simply those 2 instructions. When our main program is finished, the `HALT` instruction will be called, which causes the library to stop running the program.

Look at the `putchar()` function. This is another compiler trick. If you use the `--reserve-flags-iy` register, it will always use the IX register for indexing. Therefore, we always be assured that the IX register will tell us where compiler-related information is. In this case, `IX + 4` is the starting address for any values passed in as parameters to a function. If it is a single byte, it will be at `IX + 4`. If it is two bytes, it will be at `IX + 4` and `IX + 5`. So in our assembly code, we first `PUSH AF` and later `POP AF` in order to avoid messing with registers and bugging out the compiler, and then we load the value at address `IX + 4` into the A register, and send that out port 0x00.

There may be a way to do this with one function, but I'm not sure, so I broke `getchar()` up into two functions. The first is `__getchari()` which is not intended to be called directly as it is wrapped by `getchar()`. Like `putchar()`, it grabs the arguments, but this time the argument is two bytes long because it is a pointer to whever the variable `c` is stored. It reads a byte from port 0x00 into the A register, and then stores that into the memory address pointed to by the argument. Meaning, `c` will now hold the value it read. We then use `(void)c;` to tell the compiler that we have indeed used this variable. The compiler ignores whatever is done in `__asm` blocks, so it will think it is unused unless we explicitly say it has been used. We finally then use `getchar()` to just wrap `__getchari()` into something nicer to use.

We can then compile it like so.

`print system$("sdcc -mz80 --no-std-crt0 --reserve-regs-iy --code-loc 0x0000 example.c -o ~tmp.hex")`

`print system$("echo $(cut -c 10- < ~tmp.hex | sed 's/..$//' | tr -d '\n') > example_c.hex")`

`print system$("rm -f ~tmp*")`

The first one actually compiles it. Here we specify that we are using a Z80 machine, that we do not need a CRT0, to reserve the IY flags for the trick we are doing (also these flags are used internally by many real Z80 computers so this option is something best to always use), we say the program starts at memory address 0x0000, and then to spit out a hex file. We name it `~tmp.hex`) because SDCC likes to spit out tons of other files which are junk and we do not need. The hex file is also formatted in an incredibly strange way, so the second line deformats it. The final line just deletes all the unneeded files it generated.

Finally, we can then run it simply by taking our same program but changing the `EMULOAD` function to load `example_c.hex` rather than `example.hex`. 

![img](https://i.imgur.com/7XZUXaN.png)

That is compiled C code running in SmileBASIC! I have gotten this to work on the 3DS as well and the Switch, but the downside is that you cannot install SDCC or Z80ASM on those machines, so any programs you write you will have to compile on your personal computer and transfer them over. I have been working on a Zilog Z80 assembler that runs in SmileBASIC you can find on the Switch public directory.

The SBZ80.LIB file has many more commands than the ones I just showed. Many are based off of the PasocomMini MZ-80C but others are original.
Here are the ones inspired by the PasocomMini MZ-80C.

-  'Input: ID number for register
-  'Output: The register's name as a string
  -  `EMUREGNAME$(ID%)`
-  'Input: Either numerical ID or name of register
-  'Output: The bit-width of the register
  -  `EMUREGSIZE%(ID)`
-  'Input: A memory and a byte
-  'Output: Writes the byte to the specified memory address
  -  `EMUMEM ADDR%, BYTE%`
-  'Input: A memory address
-  'Output: returns the byte at the specified memory address
  -  `EMUMEM(ADDR%)`
-  'Input: Nothing
-  'Output: 1 if the machine is running, 0 if it is not
  -  `EMUSTATUS()`
-  'Input: Nothing
-  'Output: 0
  -  `EMUCPUNO%()`
-  'Input: Nothing
-  'Output: The machine's name
  -  `EMUMACHINENAME$()`
-  'Input: Nothing
-  'Output: The CPU type and the number of registers
  -  `EMUCPUINFO OUT TYPE$, REG_COUNT%`
-  'Input: Nothing
-  'Output: 34
  -  `EMUREGCNT%()`
-  'Input: A memory address
-  'Ouput: The disassembled instruction at the memory address and the
-  '  instruction's byte-length
  -  `EMUDISASM ADDR% OUT CODE$, SIZE%`
-  'Input: Nothing
-  'Output: If EMUSTATUS() is 1, executes the next instruction
  -  `EMUSTEP`
-  'Input: Nothing
-  'Output: Continously calls EMUSTEP until a HALT (&H76) instruction
-  '  is reached
  -  `EMUTRACE`
-  'Input: A memory address
-  'Output: Jumps to the memory address then calls EMUTRACE
  -  `EMURUN ADDR%`
-  'Input: Nothing
-  'Output: Sets EMUSTATUS() to 0
  -  `EMUSTOP`

Here are the brand new ones.

-  'Input: A hex-formatted TXT: file or a byte-formatted DAT: file
-  'Output: Loads the file's data into memory starting at the
-  '  specified address
-  `EMULOAD ADDR%, FILE$`
-  'Input: A machine name
-  'Output: Sets the machine name
-  `EMUMACHINENAME NAME$`
-  'Input: The name of a DEF block
-  'Output: Sets a callback function for OUT instructions
-  `EMUPOCB DEF_BLOCK$`
-  'Input: The name of a DEF block
-  'Output: Sets a callback function for IN instructions
-  `EMUPICB DEF_BLOCK$`
-  'Input: The name of a DEF block
-  'Output: Sets a callback function for interrutps
-  `EMUINTCB DEF_BLOCK$`
-  'Input: Nothing
-  'Output: Sets EMUSTATUS() to 1
-  `EMUGO`

I already discossed the callback commands and `EMULOAD`. I added `EMUMACHINENAME` to also be able to change the machine name since this library doesn't actually emulate any real machines. Unlike the PasocomMini MZ-80C, `EMURUN` does not run the code *in parallel* with the SmileBASIC code. It is blocking and will continue blocking until it hits the HALT instruction. The command `EMUSTEP` executes only one instruction as long as as `EMUSTATUS()` is 1. You can use this instead for non-blocking execution. Just throw `EMUSTEP` in your main program loop and it will run in parallel. `EMUSTEP` will then step through the program alongside your regular program and could be stopped with `EMUSTOP` and started again with `EMUGO`. 
