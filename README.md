# SBZ80LIB
Hosted on `https://github.com/amihart/SBZ80LIB`.
Most recent public keys: (3DS: `C323Q5GP`); (Switch: `4TKMVH34J`)
A SmileBASIC library for Zilog Z80 assembly inspired by the PasocomMini MZ-80C.
This was written on Pi STARTER but I added compatibility functions so it will work on 3DS and Switch.

To download, first make sure you have `GIT` installed onto your Pi STARTER. 

`print system$("sudo apt install git -y")`

Then, clone the repository.

`print system$("sudo git clone http://github.com/amihart/SBZ80LIB")`

Let's look at the example Zilog Z80 assembly program.

![img](https://i.imgur.com/JNR1V6h.png)

How can we run this program using the library? First, we have to assemble it, and to do that we need an assembler. Nicely, you do not even have to leave Pi STARTER in order to install one. My preferred assembler is `Z80ASM`.

`print system$("sudo apt install z80asm -y")`

You can assemble the program to a hex file using this command. It's quite lengthy but `Z80ASM` outputs raw binary files which do not have the proper headers to open in SmileBASIC, so we can make it instead output the file as a hex file. 

`save "txt:example.hex", system$("sudo z80asm example.asm -o - | xxd -u -c 1 | sed 's/.*://' | cut -d' ' -f2 | xargs | sed 's/ //g'")`

Now since we have our assembled file, let's try to run it in our library. We have to take note that the program is printing characters to the screen by writing a byte to port 0x00. It is also reading characters from user input by reading bytes from port 0x00. So in order to run the program, we must define the behavior of these ports. It also uses a Mode 1 interrupt, so we also have to tell it when interrupts occur. Take a look at this program below.

![img1](https://i.imgur.com/dJL986x.png)

First, I load the library, then, I load the Zilog Z80 program assembled to a hex file. Next, I define a callback for port-write instructions. In this case, I say if you attempt to write to port 0, then simply print the data you write to port 0 onto the screen assuming the data represents an ASCII character. The `EMUPOCB` command is used to designate which `DEF` block represents your callback for port-out instructions.

I then do the same for the port-in instructions and `EMUPICB` specifies which `DEF` block is used for port reads. In this case, I create a buffer called `stdin$` and if it is empty when you try to read it, then I pause for the user to type in some text. I then pop the first character out of the buffer and return that as what is read from port 0x00. 

Finally, I define my interrupt callback which is designated using `EMUINTCB`. Normally, interrupts are triggered by external hardware in the real world, so we have to specify when an interrupt should actually be triggered. This `DEF` block will be called repeatedly when interrupts are enabled, and if you ever return 1 for `FIRE%`, then the interrupt is fired. Mode 2 interrupts also expect a byte of data to be combined with the `I` register. Mode 0 interrupts aren't supported.

Once we've defined all our callbacks, we simply call `EMURUN 0` to start the program.

![img](https://i.imgur.com/FG3U9RJ.png)

This library implements every instruction that the PasocomMini MZ-80C does and in fact was unit tested with it to ensure consistency. The only things that have not been fully tested are the repeating instructions (e.g. `LDIR`) and the interrupts, as these are not easy to unit test, so please report any bugs.

The SBZ80.LIB file has many more commands than the ones I just showed. Many are based off of the PasocomMini MZ-80C but others are original.
Here are the ones inspired by the PasocomMini MZ-80C.

-  'Input: ID number for register
-  'Output: The register's name as a string
  -  `EMUREGNAME$(ID%)`
-  'Input: String  name of register
-  'Output: The bit-width of the register
  -  `EMUREGSIZE%(r$)`
-  'Input: String name of register and a value
-  'Output: Sets the register to the specified value
  -  `EMUREG r$, VALUE%`
-  'Input: String name of register
-  'Output: Returns the value within a specified register
  -  `EMUREG%(ID)`
-  'Input: A memory address and a byte
-  'Output: Writes the byte to the specified memory address
  -  `EMUMEM ADDR%, BYTE%`
-  'Input: A memory address
-  'Output: returns the byte at the specified memory address
  -  `EMUMEM$(ADDR%)`
-  'Input: Nothing
-  'Output: 1 if the machine is running, 0 if it is not
  -  `EMUSTATUS%()`
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
-  'Output: If EMUSTATUS%() is 1, executes the next instruction
  -  `EMUSTEP`
-  'Input: Nothing
-  'Output: Continously calls EMUSTEP until a HALT (&H76) instruction
-  '  is reached
  -  `EMUTRACE`
-  'Input: A memory address
-  'Output: Jumps to the memory address then calls EMUTRACE
  -  `EMURUN ADDR%`
-  'Input: Nothing
-  'Output: Sets EMUSTATUS%() to 0
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
-  'Output: Sets EMUSTATUS%() to 1
-  `EMUCONT`
-  Input: Nothing
-  Output: A string representing the current state of the machine
-  `EMUSTATE$()`
-  Input: A state-string
-  Output: Restores the machine to a previous state
-  `EMUSTATE STATE$`
-  Input: Argument number
-  Output: Returns an argument passed into a function (assuming you compiled the C code using the Small Device C Compiler)
-  `EMUPARAM%(n%)`
-  Input: A 16-bit return value
-  Output: Sets the return value of a function (assuming you compiled the C code using the Small Device C Compiler)
-  `EMURET v%`
-  Input: A memory address
-  Output: Returns a zero-terminated string from the machine's memory
-  `EMUSTR$(addr%)`

I already discussed the callback commands and `EMULOAD`. I added `EMUMACHINENAME` to also be able to change the machine name since this library doesn't actually emulate any real machines. Unlike the PasocomMini MZ-80C, `EMURUN` does not run the code *in parallel* with the SmileBASIC code. It is blocking and will continue blocking until it hits the HALT instruction. The command `EMUSTEP` executes only one instruction as long as as `EMUSTATUS%()` is 1. You can use this instead for non-blocking execution. Just throw `EMUSTEP` in your main program loop and it will run in parallel. `EMUSTEP` will then step through the program alongside your regular program and could be stopped with `EMUSTOP` and started again with `EMUCONT`. 

Update: ~~In order to avoid having to maintain multiple versions, there are now "compatibility functions" at the top of the library and the example file. The library requires 2 slots now to run, 1 slot for the library itself, and another for the compatibility functions. If the slot it is using conflicts with your program, you can change it by changing `C_SLOT%` at the top of the file.~~

Update 2: Dropped support for some commands like `EMUREG%()` accepting multiple data types (registers represented as their string name or integer ID) because the trick I used to do it apparently does not work in SmileBASIC 4 causing issues on the Switch. All functions that could accept IDs or register names now only can accept register names. I also added `EMUSTATE$()` and `EMUSTATE`. Using `EMUSTATE$()` with the dollar sign rather than the percent sign will not return whether or not the interpreter is running but a string representing the current state of the machine, which then can be restored later using `EMUSTATE`.

Update 3: Updated the compatbility functions to no longer require an additional slot. Also added a few commands. The `EMUPARAM` and `EMURET` are meant to be used along side SDCC. If you trigger a port callback within a function, you can identify which function caused the port callback by checking the port data, and then use `EMUPARAM` to read the parameters of that function and `EMURET` to set a return value. Effectively you can have the C code call a SmileBASIC function.
