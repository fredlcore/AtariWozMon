# AtariWozMon
Atari 8-Bit port of Steve Wozniak's WozMon for the Apple I

 Atari WozMon is an Atari 8-bit adaptation of the machine language monitor which was built into the Apple I. Since this was programmed by Steven Wozniak at that time, this software is affectionately called "WozMon" since then. Especially remarkable is that this program uses less than 256 bytes of memory and still provides the basic functions of a machine language monitor: You can use it to read or modify single values or entire memory blocks, as well as target specific memory addresses to start a program.

Even today such a tool is still extremely useful if you still program directly on the "real" hardware. Because instead of writing long series of POKEs to change memory locations (or not having the possibility to do so under DOS in the first place), you can write the values directly into the desired memory locations with a quick jump to Atari WozMon. If you know the hexadecimal values of assembler commands, you can even program directly in machine language while using BASIC. 

Just changing the display list and store a small machine language routine for the display list interrupt? No problem (screenshot 4).
Quick direct access to the screen memory? Quickly done (screenshot 3).
Quickly read out a memory area? Nothing easier than that (screenshot 2).

After loading, Atari WozMon is stored in Page 6 where it is protected from BASIC, DOS or other programs and can be called again and again if needed.
To follow the ABBUC rules, an extra startup screen has been placed in Page 4, but this is not needed for the rest of the program. You can call the tool from BASIC with X=USR(1024) (with start screen/short manual) or X=USR(1536) (directly to the monitor) or from DOS with M (Run Address) and then 401 or 601. 

Atari WozMon has several advantages over the original, including the use of Atari's operating system screen routines. This makes Atari WozMon fit seamlessly into the BASIC editor, so that e.g. the screen content of BASIC is preserved when Atari WozMon is called, and even after quitting, the screen is not cleared, as you can see on the screenshots.

Atari WozMon is thus a useful tool that you can simply run as AUTORUN.SYS on the DOS disk, it does not consume any BASIC memory and is always ready when you need it.

The functions of Atari WozMon with examples:
(All memory locations are noted in hexadecimal, letters must always be uppercase, maximum input length is 36 characters per line).

Reading the memory location $0600:
```
600
0600: D8
```
 
Reading several memory locations:
```
600 604 60B
0600: D8
0604: 01
060B: A9
```
A dot before the address outputs all memory locations from the last used memory location ($060B in the last example) to the memory location after the dot:
```
.60F
05 9D 42 03
```

Reading memory range $0600 to $060F:
``` 
600.60F
0600: D8 A5 06 F0 01 68 A9 9B
0608: 20 DD 06 A9 05 9D 42 03  
```
 
Write memory location $A800 with value $A0:
``` 
A800:A0
A800: 00
```
The previously(!) contained value is output here. A repeated readout then brings the new value:
```
A800
A800: A0
```

Writing of several values from memory location $A800:
``` 
A800:A9 03 8D 00 A9
A800: A0
```
Only the first (previously contained) value is output. Check the writing by reading the memory area:
```
A800.A807
A800: A9 03 8D 00 A9 00 00
```
 
Jump (JMP) to the memory address and execute the program code there:
``` 
A79F R
```
(Jumps to the DOS 2.5 start address. Recommended way instead of "X" to get from Atari WozMon back to DOS under DOS)
 
Exit Atari WozMon (and get back to BASIC if necessary):
```
X
```
(DOS 2.5 unfortunately executes a JMP (and no JSR), so X does not work here. To get back to DOS, a jump to the memory location 
