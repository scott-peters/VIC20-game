# CPSC599.82 - Retrogames

Assignments & Project Repo for CPSC 599.82 - Retrogames
Group 9: Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir

----
## FINAL PROJECT -- SURVIVAL HUNT

**FYI, THE GAME IS SUPER SMOOTH ON MAME AND/OR THE ONLINE EMULATOR. YEAHHHH!!! I made the mistake of showing it off using VICE in class for the demo.**

The paratext and the game is available in the folder "Final Game - SURVIVAL HUNT".
There ARE bugs, but I did the best I could.

The game uses joysticks so when the screen says "space", it means "fire" on the joystick.
There are now even more blocks/mazes/paths added.

**Overall, even though there were a lot of problems, I genuinely enjoyed doing this (especially scrolling). Thanks for a wild semester!** 

**CHEATS:**

Writing `$ff` to `0a` in zeropage will give you full powerup, press FIRE (on joystick) to activate the speedup!


## Assignment 2
### Steps to generate `.prg` files
If `dasm` exists in the user's PATH:
```make
make
```
If `dasm` exists in a custom location:
```make
make DASM=path/to/dasm
```
Optional build arguments:
To generate listings, add `LISTINGS=1` while running ``make``.
To compile just a single file, pass in the filename using the ``FILE`` argument. `make FILE=path/to/file`
By default, the makefile will generate the ``prgs`` for all the ``.s`` files in the current directory it's being run from.

To clean all files generated:
```make
make clean
```

The python script ``compress.py`` was used to compress the data and is available under Tools. 
Python script ``compress.py`` usage:
```
usage: compress.py [-h] [-type {generic,screenSpecificRLE,custom}] [-fill FILL] -input INPUT [-output OUTPUT] [-address ADDRESS [ADDRESS ...]]

options:
  -h, --help            show this help message and exit
  -type {generic,screenSpecificRLE,custom}
                        Spcify type of compression. Default is generic RLE.
  -fill FILL            Fill with value. Used for screenSpecific RLE encoding. Default is 0x20 which is a space
  -input INPUT          Data to encode in binary
  -output OUTPUT        Output file of compressed data. Default is out.bin
  -address ADDRESS [ADDRESS ...]
                        The destination addresses in hex form. Used with screenSpecificRLE.
```
This will compress the screen data using either generic RLE, title-specific RLE or a custom scheme to produce an ouptut binary file which can be included using ``incbin`` in ``dasm``.

### Files:
1. ``screendata-rle.bin`` contains the entire screen data compressed using generic RLE. It uses the form (length, screen code).
1. ``screendata-rlespecific.bin`` contains the screen data compressed using RLE specific to the screen. See below for details about the scheme. 
1. ``screendata-zx0.bin`` contains the entire screen data compressed using ZX0 scheme.
1. ``screendata-zx02.bin`` contains the screen data compressed using ZX02 scheme.
1. ``screendata-exomizer.bin`` contains the screen data compressed using Exomizer.
1. ``customData.bin`` contains the screen data compressed using a custom method. See below for more details.
1. ``title.bin`` contains the original screen memory data.  **PLEASE DO NOT EDIT OR REPLACE THIS**.
1. ``onlydata;.bin`` contains the individual lines delimited by 00. **PLEASE DO NOT EDIT OR REPLACE THIS**.
1. ``zx02_decomp.asm`` contains the decompressor for ZX02. This is included in the main `.s` file. **DO NOT COMPILE THIS**
1. ``zx0_decomp.asm`` contains the decompressor for ZX0. This is included in the main `.s` file. **DO NOT COMPILE THIS**
1. ``exodecrunch.asm`` contains the decompressor for Exomizer. This is included in the main `.s` file. **DO NOT COMPILE THIS**
1. ``1_rle-generic.s``. As the name states, it's a generic RLE decompressor which decompresses the title screen data to memory.  
1. ``2_rle-specific.s``. The RLE decompressor specific to screen data.
1. ``3_zx02.s`` uses the ZX02 compressed data to display the screen. 
1. ``4_zx0.s`` uses the ZX0 compressed data to display the screen.
1. ``5_custom.s`` uses the custom scheme to display the screen.
1. ``6_exomizer.s`` uses the exomizer compressed data to display the screen.


### Command & Arguments used to generate compressed data:

1. **RLE**: ``python3 rle.py -input ../Assignment-2/title.bin`` 
1. **RLE Sepcific**: ``python3 compress.py -type screenSpecificRLE -input ../Assignment-2/onlydata.bin -address 0x1e01 0x1e30 0x1e75 0x1e9e 0x1eca 0x1ef7 0x1f22 0x1f61``
1. **ZX02**: ``zx02-2/src/zx02 title.bin``
1. **ZX0**: ``zx0-6502-main/src/zx0 title.bin``
1. **Custom**: ``python3 compress.py -type custom -input ../Assignment-2/onlydata.bin -address 0x1e01 0x1e30 0x1e75 0x1e9e 0x1eca 0x1ef7 0x1f22 0x1f61``
1. **Exomizer**: ``exomizer mem title.bin@0x1e00 -l none -o screendata-exomizer.bin``

### RLE

This uses the generic RLE compression scheme. The compressed data is in the form: (length, code). This works for any arbitrary data.

### Data-Specific RLE

The first byte indicates the fill to use, that is the code with which to fill the screen. Then, two bytes denote the screen address and the rest is the same as RLE until it encounters a 0, which is an indication to read the screen address again. Once it encounters 0 in the high address, this indicates the end of data. The regex: `FILL,(POSITIONHI,POSITIONLO,(LENGTH,SCREENCODE)+,($00))+,$00`. 

### Custom Scheme -- Not really compression but does give the best result

There isn't much to this scheme. This is same as the title-specific RLE but with the length removed. After looking at the data, we didn't have any repetition. I did try to find some patterns using distances, rotation, transforming, etc. but couldn't find anything obvious. As compression due to RLE was poor, there was no need to compress the screen data. The first byte represents the fill to use, that is the character code when there is no data to display. This, in our data set is a space. Then, two bytes denote the screen position. From there, it is regular data until a 00 is encountered. 00 is used a delimiter to go to a different offset. And finally, a second $00 indicates end of data. This is the regex: FILL,(POSITIONHI,POSITIONLO,SCREENCODE+,$00)+,$00

This scheme can be used for anything but doesn't perform data compression.

For the data-specific RLE scheme and custom scheme, we can reduce the data by 1 byte by removing the fill. And a few more bytes by not including end of line. However, when I tried this, the decompression code became a bit bigger so I stopped pursuing it. I also tried huffman encoding and some bitwise compression schemes but once again, the decompression code size takes a hit. There must be some smart way to do it, I just didn't find it! I'll wait for Dr. Aycock to present his custom compression scheme on Friday. 

### RESULTS

**NOTE: Consider Exomizer instead of ZX0 as both ZX02 and ZX0 give the same result.**

Compression Ratios

Original Data Size: 139 bytes
Original `.prg` size (with data): 249 bytes

Compression Ratio $$ = {Uncompressed Size \over Compressed Size } $$

B = bytes

| Scheme | Input Data Size | Output Data Size | `.prg` Size | Decompression Code Size | Compression Ratio (prgs) | Compression Ratio (data w/ original) | Compression Ratio (data w/input) |
|:------:|:----------:|:-----------:|:-----------------------:|:---------:|:---------:|:-------------:|:--------------:|
| RLE	   |	 512 B    |		219 B 		|		 308 B |		89 B  | 0.8084415584415584    | 0.634703196347032  | 2.3378995433789953  |
| RLE Specific|	110 B |		224 B     |		 327 B |		103 B	|	0.7614678899082569    | 0.6205357142857143 | 0.49107142857142855 |     
| ZX02	 |		512 B	  |	  118 B     |		 304 B |		186 B	|	0.819078947368421	    | 1.1779661016949152 | 4.338983050847458   |
| ZX0	   |		512 B	  |		118 B     |		 304 B |		186 B	|	0.819078947368421	    | 1.1779661016949152 | 4.338983050847458   |    
| Exomizer |  512 B   |   133 B     |    635 B |    502 B | 0.3921259842519685    | 1.0451127819548873 | 3.8496240601503757  |
| Custom |		110 B	  |		128 B     |		 218 B |		90 B	|	1.1422018348623852	  | 1.0859375          | 0.859375            |


You might be wondering why two compression ratios exist for data. This is due to the input to the compressor itself. The 512 bytes input is the entire screen downloaded from MAME. The specific ones (110 bytes) don't contain the spaces. They only contain 00 to indicate end of line. 


------


## Assignment 1

### Steps to generate `.prg` files
If DASM exists in the user's PATH:
```
make
```
If DASM exists in a custom location:
```
make DASM=path/to/dasm
```
Optional build arguments:
To generate listings, add `LISTINGS=1` while running ``make``.
To compile just a single file, pass in the filename using the ``FILE`` argument. `make FILE=path/to/file`
By default, the makefile will generate the ``prgs`` for all the ``.s`` files in the current directory it's being run from.

To clean all files generated:
```
make clean
```

### Tests:
1. ``1_hello.s``, ``1_hello_misc_change_colours``: Hello World & Hello World Colour variation. The data bytes have been generated by a preprocessor tool. This tool can be found under the tools directory.
2. ``reverse.s``: Gets a max input string of 55 characters and prints it out reversed.
3. ``3_megitsuneBM.s``: Plays メギツネ (Megistune) by ベビメタル (Babymetal). This took way too much time as the oscialltors were wayyyy off tune. I manually had to play most notes and figure out what the correct values were. They still sound a bit off though. 
4. ``5_bordertest.s``: Tests border colour changes
5. ``6_borderwithcharacters.s``: Tests colour combinations and ROM character set
6. ``4_customChar.s``: Draws a 16x8 smiley face. Tests custom characters and how to fiddle with the screen registers.
7. ``7_joystick.s``: Draws a small tiger like creature and moves it around using the keyboard. Unfortunately, none of us had numpads so we couldn't test the actual joystick interface. 
8. ``8_irq.s``: Tests interrutpts and screen raster values to change background color. I still haven't found the exact half of the scanlines. 
9. ``16scroll.s``: 16 pixel vertical scroll.
10. ``title.s``: A simple title screen.
11. ``gunshot.s``: Plays a gunshot sample. For the game.

I admit, we should've started early. Nothing's going to change if I keep thinking about it though :)

DEMOLISH!!! (Sleep deprived and listening to deathcore at 4 in the morning so I get to say this)

----
