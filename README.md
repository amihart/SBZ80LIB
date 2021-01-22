# SBZ80LIB
A SmileBASIC library for Zilog Z80 assembly inspired by the PasocomMini MZ-80C. Let's look at the example Zilog Z80 assembly

![img](https://i.imgur.com/piQLqjL.png)

How can we run this program using the library? First we have to take note that the program is printing characters to the screen by writing a byte to port 0x00. It is also reading characters from user input by reading bytes from port 0x00. So in order to run the program, we must define the behavior of these ports. It also uses a Mode 1 interrupt, so we also have to tell it when interrupts occur. Take a look at this program below.

![img1](https://i.imgur.com/dJL986x.png)

First, I load the library, then, I load the Zilog Z80 program compiled to a hex file. Next, I define a callback for port-write instructions. In this case, I say if you attempt to write to port 0, then simply print the data you write to port 0 onto the screen assuming the data represents an ASCII character. The EMUPOCB command is used to designate which DEF block represents your callback for port-out instructions.

I then do the same for the port-in instructions and EMUPICB specifies which DEF block is used for port reads. In this case, I create a buffer called "stdin$" and if it is empty when you try to read it, then I pause for the user to type in some text. I then pop the first character out of the buffer and return that as what is read from port 0x00. 

Finally, I define my interrupt callback which is designated using EMUINTCB. Normally, interrupts are triggered by external hardware in the real world, so we have to specify when an interrupt should actually be triggered. This DEF block will be called repeatedly when interrupts are enabled, and if you ever return 1 for FIRE%, then the interrupt is fired. Mode 2 interrupts also expect a byte of data to be combined with the I register. Mode 0 interrupts aren't supported.

Once we've defined all our callbacks, we simply call EMURUN 0 to start the program.

![img](https://i.imgur.com/FG3U9RJ.png)

This library implements every instruction that the PasocomMini MZ-80C does and in fact was unit tested with it to ensure consistency. The only things that have not been fully tested are the repeating instructions (e.g. LDIR) and the interrupts, as these are not easy to unit test, so please report any bugs.

This library is accurate enough to even compile code using the Small Device C Compiler and then run the C code in SmileBASIC. 
